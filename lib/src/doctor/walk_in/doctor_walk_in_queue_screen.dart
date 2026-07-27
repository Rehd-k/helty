import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/consulting_room_model.dart';
import 'package:helty/src/doctor/widgets/start_encounter_dialog.dart';
import 'package:helty/src/models/patient_vitals_model.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/src/models/waiting_patient_model.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/models/consultation_credit_model.dart';
import 'package:helty/src/models/consultation_credit_utils.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/services/invoice_service.dart';
import 'package:helty/src/services/waiting_patient_service.dart';
import 'package:helty/src/widgets/consultation_credit_chip.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../widgets/date.filter.dart';

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

  List<WaitingPatientModel> _patients = [];
  List<ConsultingRoomModel> _consultingRooms = [];
  ConsultingRoomModel? _selectedRoom;
  bool _loading = false;
  bool _loadingRooms = false;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  static const int _rowsPerPage = 50;
  int _skip = 0;
  int _total = 0;
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();

  @override
  void initState() {
    super.initState();
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

  Future<void> _loadSavedRoomAndData() async {
    setState(() => _loadingRooms = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_kSavedConsultingRoomId) ?? '';
      final rooms = await _waitingService.fetchConsultingRooms();
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

  Future<void> _loadPatients({bool reset = false}) async {
    if (_loading) return;
    if (reset) _skip = 0;

    setState(() => _loading = true);
    try {
      final resp = await _waitingService.fetchWaitingPatients(
        WaitingPatientQuery(
          q: _searchQuery.isEmpty ? null : _searchQuery,
          consultingRoomId: _selectedRoom?.id,
          unassignedOnly: false,
          skip: _skip,
          take: _rowsPerPage,
          fromDate: _fromDate,
          toDate: _toDate,
        ),
      );
      if (!mounted) return;
      setState(() {
        _patients = resp.data;
        _total = resp.total;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load patients: $e')));
    }
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
    final patient = waiting.patient;
    final displayName = patient != null
        ? patient.displayName
        : 'Unknown';
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
              SnackBar(
                content: Text(mapOutpatientStartError(e.message)),
              ),
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
      final vitalsJson = result.patientVitals != null
          ? jsonEncode(result.patientVitals!.toJson())
          : null;
      context.router.push(
        DoctorEncounterViewRoute(
          encounterId: result.encounterId,
          patientId: result.patientId,
          patientVitalsJson: vitalsJson,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ResponsiveToolbar(
              leading: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Walk-in Queue',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select your consulting room. Double-tap a patient to open their file.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              actions: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_total in queue',
                        style: TextStyle(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ResponsiveRowColumn(
              first: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search by name, ID, consultation...',
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
              second: DropdownButtonFormField<ConsultingRoomModel?>(
                initialValue: _selectedRoom,
                decoration: InputDecoration(
                  labelText: 'Consulting room',
                  labelStyle: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                hint: const Text('Select room'),
                items: [
                  const DropdownMenuItem<ConsultingRoomModel?>(
                    value: null,
                    child: Text('All rooms'),
                  ),
                  ..._consultingRooms.map(
                    (room) => DropdownMenuItem<ConsultingRoomModel?>(
                      value: room,
                      child: Text(room.name),
                    ),
                  ),
                ],
                onChanged: _loadingRooms
                    ? null
                    : (room) => _onConsultingRoomChanged(room),
              ),
            ),
            const SizedBox(height: 10),
            FromToDateFilter(
              doRefresh: () => _loadPatients(reset: true),
              dateFilter: true,
              onFilterChanged:
                  (
                    String query,
                    String category,
                    DateTime? from,
                    DateTime? to,
                  ) {
                    setState(() {
                      _fromDate = from ?? DateTime.now();
                      _toDate = to ?? DateTime.now();
                      _loadPatients(reset: true);
                    });
                  },
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ResponsiveDataTable(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!bp.isMobile)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withValues(alpha: 0.04),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 4,
                              child: Text(
                                'PATIENT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'CONSULTATION',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'TIME',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                'STATUS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Divider(
                      height: 1,
                      color: colorScheme.outline.withValues(alpha: 0.1),
                    ),
                    Expanded(
                      child: _loading
                          ? const Center(child: CircularProgressIndicator())
                          : _patients.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _selectedRoom == null
                                        ? 'Select a consulting room to see waiting patients.'
                                        : 'No patients in this room.',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              itemCount: _patients.length,
                              separatorBuilder: (_, __) => Divider(
                                height: 1,
                                color: colorScheme.outline.withValues(
                                  alpha: 0.08,
                                ),
                              ),
                              itemBuilder: (context, index) {
                                final w = _patients[index];
                                final patient = w.patient;
                                final name = patient != null
                                    ? patient.displayName
                                    : 'Unknown';
                                final consultation = w.consultationName ?? '—';
                                final time = DateFormatter.dateTime(
                                  w.createdAt.toLocal(),
                                );
                                final isWaiting = w.status == 'Waiting';
                                return Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onDoubleTap: () => _onPatientDoubleTap(w),
                                    child: bp.isMobile
                                        ? _buildMobileQueueRow(
                                            context,
                                            colorScheme,
                                            name,
                                            consultation,
                                            time,
                                            isWaiting,
                                            w,
                                          )
                                        : _buildDesktopQueueRow(
                                            context,
                                            colorScheme,
                                            name,
                                            consultation,
                                            time,
                                            isWaiting,
                                            w,
                                          ),
                                  ),
                                );
                              },
                            ),
                    ),
                    if (_patients.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Text(
                          'Showing ${_patients.length} of $_total • Double-tap a row to open patient file',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileQueueRow(
    BuildContext context,
    ColorScheme colorScheme,
    String name,
    String consultation,
    String time,
    bool isWaiting,
    WaitingPatientModel w,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              w.patient != null
                  ? PatientAvatar.fromPatient(
                      w.patient!,
                      size: 36,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      foregroundColor: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    )
                  : PatientAvatar(
                      firstName: name.trim(),
                      size: 36,
                      backgroundColor: colorScheme.primary.withValues(
                        alpha: 0.12,
                      ),
                      foregroundColor: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isWaiting
                      ? Colors.orange.withValues(alpha: 0.12)
                      : Colors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  w.status,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isWaiting ? Colors.orange[800] : Colors.green[700],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            consultation,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (w.primaryConsultationCredit != null &&
              w.primaryConsultationCredit!.hasCreditMetadata) ...[
            const SizedBox(height: 4),
            ConsultationCreditChip.fromLine(
              line: w.primaryConsultationCredit!,
              compact: true,
            ),
          ],
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopQueueRow(
    BuildContext context,
    ColorScheme colorScheme,
    String name,
    String consultation,
    String time,
    bool isWaiting,
    WaitingPatientModel w,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Row(
              children: [
                w.patient != null
                    ? PatientAvatar.fromPatient(
                        w.patient!,
                        size: 36,
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        foregroundColor: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      )
                    : PatientAvatar(
                        firstName: name.trim(),
                        size: 36,
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        foregroundColor: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                const SizedBox(width: 12),
                Text(
                  name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  consultation,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (w.primaryConsultationCredit != null &&
                    w.primaryConsultationCredit!.hasCreditMetadata) ...[
                  const SizedBox(height: 4),
                  ConsultationCreditChip.fromLine(
                    line: w.primaryConsultationCredit!,
                    compact: true,
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isWaiting
                    ? Colors.orange.withValues(alpha: 0.12)
                    : Colors.green.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                w.status,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isWaiting ? Colors.orange[800] : Colors.green[700],
                ),
              ),
            ),
          ),
        ],
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
