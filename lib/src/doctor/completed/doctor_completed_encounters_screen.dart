import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/doctor/completed/completed_encounters_metrics.dart';
import 'package:helty/src/doctor/completed/edit_history/encounter_edit_history_sheet.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounters_card.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounters_filter_bar.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounters_header.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounters_kpi_strip.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounters_sidebar.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounters_table.dart';
import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/models/encounter_model.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/services/staff_service.dart';

@RoutePage()
class DoctorCompletedEncountersScreen extends ConsumerStatefulWidget {
  const DoctorCompletedEncountersScreen({super.key});

  @override
  ConsumerState<DoctorCompletedEncountersScreen> createState() =>
      _DoctorCompletedEncountersScreenState();
}

class _DoctorCompletedEncountersScreenState
    extends ConsumerState<DoctorCompletedEncountersScreen> {
  final _encounterService = EncounterService();
  final _patientService = PatientService();
  final _staffService = StaffService();
  final _listKey = GlobalKey();
  final _searchCtrl = TextEditingController();

  List<EncounterModel> _encounters = [];
  List<CompletedActivityNote> _notes = [];
  final Map<String, Patient> _patientCache = {};
  final Map<String, String> _doctorNameCache = {};
  bool _loading = false;
  bool _reloadQueued = false;
  bool _queuedReset = false;
  String? _error;
  String _searchQuery = '';
  String? _selectedVisitType;
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  /// Physicians only: `false` = all completed (no doctorId); `true` = filter by logged-in doctor.
  bool _physicianShowMineOnly = false;

  static const int _rowsPerPage = 20;
  int _skip = 0;

  @override
  void initState() {
    super.initState();
    _fromDate = AppTimezone.startOfDay();
    _toDate = AppTimezone.endOfDay();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _searchQuery) {
        setState(() {
          _searchQuery = q;
          _skip = 0;
        });
      }
    });
    _loadEncounters(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Same criteria as [HomeScreen] physician menu — toggles "mine only" on completed list.
  bool _isPhysicianStaff(Staff? staff) {
    if (staff == null) return false;
    final at = staff.accountType?.name.toLowerCase() ?? '';
    final r = staff.staffRole.toLowerCase();
    return at == 'physician' ||
        at == 'consultant' ||
        at == 'inpatient_doctor' ||
        r == 'doctor' ||
        r == 'consultant' ||
        r == 'resident' ||
        r == 'intern' ||
        r == 'junior_resident' ||
        r == 'senior_resident' ||
        r == 'chief_resident' ||
        r == 'medical_student';
  }

  Future<void> _loadEncounters({bool reset = false}) async {
    if (reset) _skip = 0;
    if (_loading) {
      _reloadQueued = true;
      _queuedReset = _queuedReset || reset;
      return;
    }

    final staff = ref.read(authProvider).staff;
    if (staff == null) {
      setState(() {
        _loading = false;
        _error = 'Not logged in.';
      });
      return;
    }

    final physician = _isPhysicianStaff(staff);
    final String? doctorIdFilter;
    if (physician && _physicianShowMineOnly) {
      final id = staff.id.trim();
      doctorIdFilter = id.isNotEmpty ? id : null;
    } else {
      doctorIdFilter = null;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _encounterService.fetchOutpatientEncounters(
        doctorId: doctorIdFilter,
        status: 'COMPLETED',
        take: 200,
        fromDate: _fromDate,
        toDate: _toDate,
      );
      if (!mounted) return;
      list.sort(
        (a, b) => CompletedEncountersMetrics.closedAt(
          b,
        ).compareTo(CompletedEncountersMetrics.closedAt(a)),
      );
      final types = CompletedEncountersMetrics.uniqueVisitTypes(list);
      setState(() {
        _encounters = list;
        _loading = false;
        if (_selectedVisitType != null && !types.contains(_selectedVisitType)) {
          _selectedVisitType = null;
        }
      });
      _loadPatientsForEncounters(list);
      _loadDoctorsForEncounters(list);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load encounters: $e')));
    }
    if (_reloadQueued && mounted) {
      final queuedReset = _queuedReset;
      _reloadQueued = false;
      _queuedReset = false;
      await _loadEncounters(reset: queuedReset);
    }
  }

  Future<void> _loadPatientsForEncounters(List<EncounterModel> list) async {
    final ids = <String>{};
    for (final e in list) {
      if (!_patientCache.containsKey(e.patientId)) {
        ids.add(e.patientId);
      }
    }
    if (ids.isEmpty) return;
    final updates = <String, Patient>{};
    for (final id in ids) {
      try {
        final p = await _patientService.getPatientById(id);
        updates[id] = p;
      } catch (_) {
        // skip failed patient load
      }
      if (!mounted) return;
    }
    if (updates.isNotEmpty && mounted) {
      setState(() => _patientCache.addAll(updates));
    }
  }

  Future<void> _loadDoctorsForEncounters(List<EncounterModel> list) async {
    final ids = <String>{};
    for (final e in list) {
      if (e.doctorDisplayName?.trim().isNotEmpty == true) continue;
      final id = e.doctorId.trim();
      if (id.isEmpty || _doctorNameCache.containsKey(id)) continue;
      ids.add(id);
    }
    if (ids.isEmpty) return;
    final updates = <String, String>{};
    for (final id in ids) {
      try {
        final staff = await _staffService.getStaffById(id);
        updates[id] = staff.fullName;
      } catch (_) {
        // skip failed staff load
      }
      if (!mounted) return;
    }
    if (updates.isNotEmpty && mounted) {
      setState(() => _doctorNameCache.addAll(updates));
    }
  }

  String _doctorLabel(EncounterModel encounter) {
    final nested = encounter.doctorDisplayName?.trim();
    if (nested != null && nested.isNotEmpty) return 'Dr $nested';
    final cached = _doctorNameCache[encounter.doctorId.trim()];
    if (cached != null && cached.isNotEmpty) return 'Dr $cached';
    final id = encounter.doctorId.trim();
    return id.isNotEmpty ? id : '—';
  }

  List<EncounterModel> get _filteredEncounters {
    var list = _encounters;
    if (_selectedVisitType != null) {
      list = list
          .where(
            (e) =>
                CompletedEncountersMetrics.visitTypeLabel(e) ==
                _selectedVisitType,
          )
          .toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((e) {
        final patient = _patientCache[e.patientId];
        final name = CompletedEncountersMetrics.patientName(
          e,
          patient,
        ).toLowerCase();
        final complaint = CompletedEncountersMetrics.complaint(e).toLowerCase();
        final doctor = _doctorLabel(e).toLowerCase();
        final mrn = CompletedEncountersMetrics.mrn(patient).toLowerCase();
        return name.contains(q) ||
            complaint.contains(q) ||
            doctor.contains(q) ||
            mrn.contains(q) ||
            e.patientId.toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  int get _effectiveSkip {
    final len = _filteredEncounters.length;
    if (len == 0 || _skip <= 0) return 0;
    if (_skip >= len) {
      return ((len - 1) ~/ _rowsPerPage) * _rowsPerPage;
    }
    return _skip;
  }

  List<EncounterModel> get _pagedEncounters {
    final filtered = _filteredEncounters;
    final skip = _effectiveSkip;
    if (skip >= filtered.length) return const [];
    final end = (skip + _rowsPerPage).clamp(0, filtered.length);
    return filtered.sublist(skip, end);
  }

  bool get _hasMore =>
      _effectiveSkip + _rowsPerPage < _filteredEncounters.length;

  String get _emptyMessage {
    if (_error != null && _encounters.isEmpty) return _error!;
    if (_encounters.isEmpty) return 'No completed encounters yet.';
    return 'No matches for search or visit type.';
  }

  String get _editedLabel {
    final n = CompletedEncountersMetrics.editedCount(_encounters);
    return n == null ? '—' : '$n';
  }

  String get _avgDurationLabel {
    return CompletedEncountersMetrics.averageDurationLabel(_encounters) ?? '—';
  }

  void _addNote(String message) {
    setState(() {
      _notes = [
        CompletedActivityNote(at: AppTimezone.now(), message: message),
        ..._notes,
      ];
      if (_notes.length > 50) {
        _notes = _notes.take(50).toList();
      }
    });
  }

  void _goPrev() {
    if (_skip <= 0) return;
    setState(() {
      final next = _skip - _rowsPerPage;
      _skip = next < 0 ? 0 : next;
    });
  }

  void _goNext() {
    if (!_hasMore) return;
    setState(() => _skip += _rowsPerPage);
  }

  void _scrollToList() {
    final ctx = _listKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      alignment: 0.08,
    );
  }

  void _openEncounter(EncounterModel encounter) {
    final name = CompletedEncountersMetrics.patientName(
      encounter,
      _patientCache[encounter.patientId],
    );
    _addNote('Opened encounter for $name.');
    context.router.push(
      DoctorCompletedEncounterViewRoute(
        encounterId: encounter.id,
        patientId: encounter.patientId,
      ),
    );
  }

  void _openEditHistory(EncounterModel encounter) {
    final name = CompletedEncountersMetrics.patientName(
      encounter,
      _patientCache[encounter.patientId],
    );
    _addNote('Opened edit history for $name.');
    EncounterEditHistorySheet.show(
      context,
      encounterId: encounter.id,
      encounter: encounter,
    );
  }

  Widget _listPanel({required bool useCards}) {
    final displayed = _pagedEncounters;
    if (useCards) {
      return KeyedSubtree(
        key: _listKey,
        child: CompletedEncounterCardList(
          encounters: displayed,
          patientOf: (e) => _patientCache[e.patientId],
          doctorLabelOf: _doctorLabel,
          skip: _effectiveSkip,
          loading: _loading,
          emptyMessage: _emptyMessage,
          total: _filteredEncounters.length,
          hasMore: _hasMore,
          pageSize: _rowsPerPage,
          onPrev: _goPrev,
          onNext: _goNext,
          onView: _openEncounter,
          onEditHistory: _openEditHistory,
        ),
      );
    }
    return KeyedSubtree(
      key: _listKey,
      child: CompletedEncountersTable(
        encounters: displayed,
        patientOf: (e) => _patientCache[e.patientId],
        doctorLabelOf: _doctorLabel,
        skip: _effectiveSkip,
        loading: _loading,
        emptyMessage: _emptyMessage,
        total: _filteredEncounters.length,
        hasMore: _hasMore,
        pageSize: _rowsPerPage,
        onPrev: _goPrev,
        onNext: _goNext,
        onView: _openEncounter,
        onEditHistory: _openEditHistory,
      ),
    );
  }

  Widget _sidebar({bool fillHeight = false}) {
    return CompletedEncountersSidebar(
      doctorCounts: CompletedEncountersMetrics.doctorCounts(
        encounters: _filteredEncounters,
        doctorLabel: _doctorLabel,
      ),
      notes: _notes,
      onRefresh: () => _loadEncounters(reset: true),
      onViewList: _scrollToList,
      onOpenOngoing: () =>
          context.router.push(const DoctorOngoingEncountersRoute()),
      onOpenWalkIn: () => context.router.push(const DoctorWalkInQueueRoute()),
      onViewAllNotes: () => showCompletedEncountersNotesDialog(context, _notes),
      fillHeight: fillHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final staff = ref.watch(authProvider.select((s) => s.staff));
    final showPhysicianScopeToggle = _isPhysicianStaff(staff);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final compact = width < CompletedEncountersMetrics.cardBreakpoint;
          final showSideBySide =
              width >= CompletedEncountersMetrics.sidebarBreakpoint;
          final useCards = compact;
          final useSnapKpis = width < 520;

          final header = CompletedEncountersHeader(compact: compact);
          final kpis = CompletedEncountersKpiStrip(
            totalInRange: _encounters.length,
            closedToday: CompletedEncountersMetrics.completedTodayCount(
              _encounters,
            ),
            editedLabel: _editedLabel,
            avgDurationLabel: _avgDurationLabel,
            useSnapStrip: useSnapKpis,
          );
          final filters = CompletedEncountersFilterBar(
            searchController: _searchCtrl,
            showScopeToggle: showPhysicianScopeToggle,
            mineOnly: _physicianShowMineOnly,
            onMineOnlyChanged: (mine) {
              setState(() => _physicianShowMineOnly = mine);
              _loadEncounters(reset: true);
            },
            visitTypes: CompletedEncountersMetrics.uniqueVisitTypes(
              _encounters,
            ),
            selectedVisitType: _selectedVisitType,
            onVisitTypeChanged: (value) {
              setState(() {
                _selectedVisitType = value;
                _skip = 0;
              });
            },
            onDateFilterChanged: (query, category, from, to) {
              setState(() {
                _fromDate = from ?? AppTimezone.startOfDay();
                _toDate = to ?? AppTimezone.endOfDay();
              });
              _loadEncounters(reset: true);
            },
            onDateRefresh: () => _loadEncounters(reset: true),
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
              Expanded(child: _listPanel(useCards: useCards)),
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
                    child: _listPanel(useCards: useCards),
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
