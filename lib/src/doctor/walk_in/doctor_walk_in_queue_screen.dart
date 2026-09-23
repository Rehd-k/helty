import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/doctor/walk_in/walk_in_queue_metrics.dart';
import 'package:helty/src/doctor/walk_in/widgets/walk_in_filter_bar.dart';
import 'package:helty/src/doctor/walk_in/widgets/walk_in_kpi_strip.dart';
import 'package:helty/src/doctor/walk_in/widgets/walk_in_patient_card.dart';
import 'package:helty/src/doctor/walk_in/widgets/walk_in_queue_header.dart';
import 'package:helty/src/doctor/walk_in/widgets/walk_in_queue_table.dart';
import 'package:helty/src/doctor/walk_in/widgets/walk_in_sidebar.dart';
import 'package:helty/src/doctor/widgets/start_encounter_dialog.dart';
import 'package:helty/src/frontdesk/widgets/check_in_patient_dialog.dart';
import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/models/consulting_room_model.dart';
import 'package:helty/src/models/consultation_credit_model.dart';
import 'package:helty/src/models/consultation_credit_utils.dart';
import 'package:helty/src/models/patient_vitals_model.dart';
import 'package:helty/src/models/waiting_patient_model.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/department_service.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/services/invoice_service.dart';
import 'package:helty/src/services/waiting_patient_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kSavedConsultingRoomId = 'doctor_walkin_consulting_room_id';

@RoutePage()
class DoctorWalkInQueueScreen extends ConsumerStatefulWidget {
  const DoctorWalkInQueueScreen({super.key});

  @override
  ConsumerState<DoctorWalkInQueueScreen> createState() =>
      _DoctorWalkInQueueScreenState();
}

class _DoctorWalkInQueueScreenState
    extends ConsumerState<DoctorWalkInQueueScreen> {
  final _waitingService = WaitingPatientService();
  final _encounterService = EncounterService();
  final _invoiceService = InvoiceService();
  final _departmentService = DepartmentService();
  final _queueKey = GlobalKey();
  final _searchCtrl = TextEditingController();

  List<WaitingPatientModel> _patients = [];
  List<ConsultingRoomModel> _consultingRooms = [];
  List<Department> _departments = [];
  List<WalkInActivityNote> _notes = [];
  ConsultingRoomModel? _selectedRoom;
  String? _selectedDepartmentId;
  String _statusValue = 'all';
  final bool _sortLongestFirst = true;
  bool _loading = false;
  bool _reloadQueued = false;
  bool _queuedReset = false;
  bool _loadingRooms = false;
  String _searchQuery = '';
  static const int _rowsPerPage = 20;
  int _skip = 0;
  int _total = 0;
  bool _hasMore = false;
  int? _inConsultationTotal;
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _fromDate = AppTimezone.startOfDay();
    _toDate = AppTimezone.endOfDay();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _searchQuery) {
        _searchQuery = q;
        _loadPatients(reset: true);
      }
    });
    _loadSavedRoomAndData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  bool? get _seenFilter {
    switch (_statusValue) {
      case 'waiting':
        return false;
      case 'inConsultation':
        return true;
      default:
        return null;
    }
  }

  String? get _selectedDepartmentName {
    if (_selectedDepartmentId == null) return null;
    for (final d in _departments) {
      if (d.id == _selectedDepartmentId) return d.name;
    }
    return null;
  }

  List<WaitingPatientModel> get _displayedPatients {
    return WalkInQueueMetrics.applyClientFilters(
      patients: _patients,
      departmentName: _selectedDepartmentName,
      longestWaitFirst: _sortLongestFirst,
    );
  }

  String get _avgWaitLabel {
    final avg = WalkInQueueMetrics.averageWait(_displayedPatients);
    if (avg == null) return '—';
    return WalkInQueueMetrics.formatWait(avg);
  }

  String get _emptyMessage {
    if (_selectedDepartmentId != null) {
      return 'No patients match the selected department on this page.';
    }
    return 'No patients match the current filters.';
  }

  List<WalkInRoomCount> get _roomCounts {
    final displayed = _displayedPatients;
    final counts = <String, int>{};
    for (final room in _consultingRooms) {
      counts[room.name] = 0;
    }
    for (final waiting in displayed) {
      final name = WalkInQueueMetrics.roomName(waiting);
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final rows = counts.entries
        .map((e) => WalkInRoomCount(name: e.key, count: e.value))
        .toList();
    rows.sort((a, b) => b.count.compareTo(a.count));
    return rows;
  }

  WaitingPatientQuery _baseQuery({bool? seen, int skip = 0, int take = 20}) {
    return WaitingPatientQuery(
      q: _searchQuery.isEmpty ? null : _searchQuery,
      consultingRoomId: _selectedRoom?.id,
      unassignedOnly: false,
      seen: seen,
      skip: skip,
      take: take,
      fromDate: _fromDate,
      toDate: _toDate,
      sortBy: 'createdAt',
      sortOrder: _sortLongestFirst ? 'asc' : 'desc',
    );
  }

  Future<void> _loadSavedRoomAndData() async {
    setState(() => _loadingRooms = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_kSavedConsultingRoomId) ?? '';
      final rooms = await _waitingService.fetchConsultingRooms();
      List<Department> departments = const [];
      try {
        departments = await _departmentService.fetchDepartments();
      } catch (_) {
        departments = const [];
      }
      if (!mounted) return;
      ConsultingRoomModel? room;
      if (savedId.isNotEmpty) {
        try {
          room = rooms.firstWhere((r) => r.id == savedId);
        } catch (_) {
          room = null;
        }
      }
      setState(() {
        _consultingRooms = rooms;
        _departments = departments;
        _selectedRoom = room;
        _loadingRooms = false;
      });
      await _loadPatients(reset: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingRooms = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load consulting rooms: $e')),
      );
    }
  }

  Future<void> _onConsultingRoomChanged(ConsultingRoomModel? room) async {
    setState(() => _selectedRoom = room);
    final prefs = await SharedPreferences.getInstance();
    if (room != null) {
      await prefs.setString(_kSavedConsultingRoomId, room.id);
    } else {
      await prefs.remove(_kSavedConsultingRoomId);
    }
    await _loadPatients(reset: true);
  }

  Future<void> _loadKpis() async {
    try {
      final resp = await _waitingService.fetchWaitingPatients(
        _baseQuery(seen: true, skip: 0, take: 1),
      );
      if (!mounted) return;
      setState(() => _inConsultationTotal = resp.total);
    } catch (_) {
      if (!mounted) return;
      setState(() => _inConsultationTotal = null);
    }
  }

  Future<void> _loadPatients({bool reset = false}) async {
    if (reset) _skip = 0;
    if (_loading) {
      _reloadQueued = true;
      _queuedReset = _queuedReset || reset;
      return;
    }

    setState(() => _loading = true);
    try {
      final resp = await _waitingService.fetchWaitingPatients(
        _baseQuery(seen: _seenFilter, skip: _skip, take: _rowsPerPage),
      );
      if (!mounted) return;
      setState(() {
        _patients = resp.data;
        _total = resp.total;
        _hasMore = resp.hasMore;
        _loading = false;
      });
      await _loadKpis();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load patients: $e')));
    }
    if (_reloadQueued && mounted) {
      final queuedReset = _queuedReset;
      _reloadQueued = false;
      _queuedReset = false;
      await _loadPatients(reset: queuedReset);
    }
  }

  void _addNote(String message) {
    setState(() {
      _notes = [
        WalkInActivityNote(at: AppTimezone.now(), message: message),
        ..._notes,
      ];
      if (_notes.length > 50) {
        _notes = _notes.take(50).toList();
      }
    });
  }

  void _goPrev() {
    if (_skip <= 0) return;
    final next = _skip - _rowsPerPage;
    _skip = next < 0 ? 0 : next;
    _loadPatients();
  }

  void _goNext() {
    if (!_hasMore) return;
    _skip += _rowsPerPage;
    _loadPatients();
  }

  void _openAddWalkIn() {
    context.router.push(PatientFormRoute());
  }

  Future<void> _openCheckIn() async {
    await showDialog<void>(
      context: context,
      builder: (_) => CheckInPatientDialog(
        onReEnlisted: () {
          _addNote('Patient checked in to the walk-in queue.');
          _loadPatients(reset: true);
        },
      ),
    );
  }

  void _scrollToQueue() {
    final ctx = _queueKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      alignment: 0.08,
    );
  }

  Future<void> _pickPatientThenAssign() async {
    final displayed = _displayedPatients;
    if (displayed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No patients in the current queue. Use a row menu when patients are listed.',
          ),
        ),
      );
      return;
    }
    final picked = await showDialog<WaitingPatientModel>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Assign consulting room'),
          content: SizedBox(
            width: 420,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: displayed.length,
              itemBuilder: (context, i) {
                final waiting = displayed[i];
                return ListTile(
                  title: Text(WalkInQueueMetrics.patientName(waiting)),
                  subtitle: Text(WalkInQueueMetrics.roomName(waiting)),
                  onTap: () => Navigator.of(ctx).pop(waiting),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
    if (picked != null) await _assignRoom(picked);
  }

  Future<void> _assignRoom(WaitingPatientModel waiting) async {
    if (_consultingRooms.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No consulting rooms available.')),
      );
      return;
    }
    ConsultingRoomModel? current =
        waiting.consultingRoom ??
        _roomById(waiting.consultingRoomId) ??
        _selectedRoom ??
        _consultingRooms.first;

    final room = await showDialog<ConsultingRoomModel>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Assign room · ${WalkInQueueMetrics.patientName(waiting)}',
          ),
          content: DropdownButtonFormField<ConsultingRoomModel>(
            initialValue: current,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Consulting room',
              border: OutlineInputBorder(),
            ),
            items: _consultingRooms
                .map(
                  (r) => DropdownMenuItem(
                    value: r,
                    child: Text(r.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: (v) => current = v,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(current),
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
    if (room == null) return;
    try {
      await _waitingService.updateWaitingPatientAssignment(
        invoiceId: waiting.invoiceId,
        consultingRoomId: room.id,
      );
      if (!mounted) return;
      _addNote(
        '${WalkInQueueMetrics.patientName(waiting)} assigned to ${room.name}.',
      );
      await _loadPatients();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to assign room: $e')));
    }
  }

  ConsultingRoomModel? _roomById(String id) {
    if (id.isEmpty) return null;
    for (final room in _consultingRooms) {
      if (room.id == id) return room;
    }
    return null;
  }

  void _onView(WaitingPatientModel waiting) {
    final encounterId = waiting.encounterId;
    if (encounterId != null && encounterId.isNotEmpty) {
      final vitalsJson = waiting.patientVitals != null
          ? jsonEncode(waiting.patientVitals!.toJson())
          : null;
      context.router.push(
        DoctorEncounterViewRoute(
          encounterId: encounterId,
          patientId: waiting.patientId,
          patientVitalsJson: vitalsJson,
        ),
      );
      return;
    }
    _onPatientDoubleTap(waiting);
  }

  void _onRowActivate(WaitingPatientModel waiting) {
    final encounterId = waiting.encounterId;
    if (waiting.seen && encounterId != null && encounterId.isNotEmpty) {
      _onView(waiting);
      return;
    }
    _onPatientDoubleTap(waiting);
  }

  void _onPatientDoubleTap(WaitingPatientModel waiting) {
    final staff = ref.read(authProvider).staff;
    final doctorId = staff?.id ?? staff?.staffId ?? '';
    if (doctorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to start an encounter.')),
      );
      return;
    }
    _showStartEncounterDialog(waiting, doctorId);
  }

  Future<void> _showStartEncounterDialog(
    WaitingPatientModel waiting,
    String doctorId,
  ) async {
    final displayName = WalkInQueueMetrics.patientName(waiting);
    final patientId = waiting.patientId;

    ConsultationServiceLine? fifoCredit;
    try {
      final invoices = await _invoiceService.fetchPaidWithoutEncounter(
        patientId: patientId,
      );
      if (invoices.isNotEmpty) {
        fifoCredit = invoices.first.primaryConsultationCredit;
      }
    } catch (_) {
      fifoCredit = waiting.primaryConsultationCredit;
    }

    if (!mounted) return;

    final result = await showDialog<_StartEncounterResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StartEncounterDialog(
        patientName: displayName,
        consultationCredit: fifoCredit ?? waiting.primaryConsultationCredit,
        onOpen: () async {
          try {
            final encounter = await _encounterService.startOutpatient(
              patientId: patientId,
              doctorId: doctorId,
              visitType: 'Walk-in',
            );
            if (!ctx.mounted) return;
            Navigator.of(ctx).pop(
              _StartEncounterResult(
                encounterId: encounter.id,
                patientId: patientId,
                patientVitals: waiting.patientVitals,
              ),
            );
          } on OutpatientStartException catch (e) {
            if (!ctx.mounted) return;
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(mapOutpatientStartError(e.message))),
            );
          } catch (e) {
            if (!ctx.mounted) return;
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text('Failed to start encounter: $e')),
            );
          }
        },
      ),
    );

    if (result != null && mounted) {
      _addNote('Started consultation for $displayName.');
      final vitalsJson = result.patientVitals != null
          ? jsonEncode(result.patientVitals!.toJson())
          : null;
      await context.router.push(
        DoctorEncounterViewRoute(
          encounterId: result.encounterId,
          patientId: result.patientId,
          patientVitalsJson: vitalsJson,
        ),
      );
      if (mounted) await _loadPatients();
    }
  }

  Widget _queuePanel({required bool useCards}) {
    final displayed = _displayedPatients;
    if (useCards) {
      return KeyedSubtree(
        key: _queueKey,
        child: WalkInPatientCardList(
          patients: displayed,
          skip: _skip,
          loading: _loading,
          emptyMessage: _emptyMessage,
          total: _total,
          hasMore: _hasMore,
          pageSize: _rowsPerPage,
          onPrev: _goPrev,
          onNext: _goNext,
          onStart: _onPatientDoubleTap,
          onView: _onView,
          onAssignRoom: _assignRoom,
          onDoubleTap: _onRowActivate,
        ),
      );
    }
    return KeyedSubtree(
      key: _queueKey,
      child: WalkInQueueTable(
        patients: displayed,
        skip: _skip,
        loading: _loading,
        emptyMessage: _emptyMessage,
        total: _total,
        hasMore: _hasMore,
        pageSize: _rowsPerPage,
        onPrev: _goPrev,
        onNext: _goNext,
        onStart: _onPatientDoubleTap,
        onView: _onView,
        onAssignRoom: _assignRoom,
        onDoubleTap: _onRowActivate,
      ),
    );
  }

  Widget _sidebar({bool fillHeight = false}) {
    return WalkInSidebar(
      roomCounts: _roomCounts,
      notes: _notes,
      onNewWalkIn: _openAddWalkIn,
      onCheckIn: _openCheckIn,
      onAssignDepartment: _pickPatientThenAssign,
      onViewQueue: _scrollToQueue,
      onViewAllNotes: () => showWalkInNotesDialog(context, _notes),
      fillHeight: fillHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final compact = width < WalkInQueueMetrics.cardBreakpoint;
          final showSideBySide = width >= WalkInQueueMetrics.sidebarBreakpoint;
          final useCards = compact;
          final useSnapKpis = width < 520;

          final header = WalkInQueueHeader(compact: compact);
          final kpis = WalkInKpiStrip(
            totalInQueue: _total,
            inConsultation: _inConsultationTotal,
            avgWaitLabel: _avgWaitLabel,
            useSnapStrip: useSnapKpis,
          );
          final filters = WalkInFilterBar(
            searchController: _searchCtrl,
            consultingRooms: _consultingRooms,
            selectedRoom: _selectedRoom,
            onRoomChanged: _onConsultingRoomChanged,
            loadingRooms: _loadingRooms,
            departments: _departments,
            selectedDepartmentId: _selectedDepartmentId,
            onDepartmentChanged: (id) =>
                setState(() => _selectedDepartmentId = id),
            statusValue: _statusValue,
            onStatusChanged: (value) {
              setState(() => _statusValue = value);
              _loadPatients(reset: true);
            },
            onDateFilterChanged: (query, category, from, to) {
              setState(() {
                _fromDate = from ?? DateTime.now();
                _toDate = to ?? DateTime.now();
              });
              _loadPatients(reset: true);
            },
            onDateRefresh: () => _loadPatients(reset: true),
            compact: compact,
            fromDate: _fromDate,
            toDate: _toDate,
          );

          final mainColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 10),
              kpis,
              const SizedBox(height: 10),
              filters,
              const SizedBox(height: 10),
              Expanded(child: _queuePanel(useCards: useCards)),
            ],
          );

          if (showSideBySide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 9, child: mainColumn),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: _sidebar(fillHeight: true)),
              ],
            );
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final bounded = constraints.maxHeight.isFinite;
              if (bounded) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: mainColumn),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 280,
                      child: SingleChildScrollView(
                        child: _sidebar(fillHeight: false),
                      ),
                    ),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  header,
                  const SizedBox(height: 10),
                  kpis,
                  const SizedBox(height: 10),
                  filters,
                  const SizedBox(height: 10),
                  SizedBox(
                    height: compact ? 480 : 520,
                    child: _queuePanel(useCards: useCards),
                  ),
                  const SizedBox(height: 10),
                  _sidebar(),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _StartEncounterResult {
  const _StartEncounterResult({
    required this.encounterId,
    required this.patientId,
    this.patientVitals,
  });
  final String encounterId;
  final String patientId;
  final PatientVitalsModel? patientVitals;
}
