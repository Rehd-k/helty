import 'dart:async';
import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/doctor/specialty/encounter_specialty_forms_panel.dart';
import 'package:helty/src/doctor/specialty/encounter_specialty_gate.dart';
import 'package:helty/src/doctor/encounter/widgets/doctor_encounter_patient_header.dart';
import 'package:helty/src/doctor/encounter/widgets/patient_previous_encounters_sheet.dart';
import 'package:helty/src/models/encounter_model.dart';
import 'package:helty/src/models/patient_vitals_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';
import 'package:helty/src/doctor/encounter/encounter_amend_helper.dart';
import 'package:helty/src/emergency/services/emergency_service.dart';
import 'package:helty/src/emergency/widgets/ed_disposition_dialog.dart';
import 'package:helty/src/emergency/widgets/esi_badge.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/services/waiting_patient_service.dart';

const double _contentMaxWidth = 1440;

/// Provides encounterId, patientId, optional doctorId, and optional pre-loaded vitals to tab content.
class EncounterScope extends InheritedWidget {
  const EncounterScope({
    super.key,
    required this.encounterId,
    required this.patientId,
    this.doctorId,
    this.patientVitals,
    this.amendMode = false,
    this.editReason,
    this.isEmergency = false,
    this.emergencyVisitId,
    this.edEsiLevel,
    required super.child,
  });

  final String encounterId;
  final String patientId;
  final String? doctorId;
  final PatientVitalsModel? patientVitals;

  /// Amending a completed encounter (versioned saves + optional editReason).
  final bool amendMode;

  /// Stored on each history row when amending a completed encounter.
  final String? editReason;

  /// True when encounterType is EMERGENCY.
  final bool isEmergency;

  /// Linked EmergencyVisit id when available.
  final String? emergencyVisitId;

  /// ESI from triage, if known.
  final int? edEsiLevel;

  static EncounterScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EncounterScope>();

  @override
  bool updateShouldNotify(EncounterScope old) =>
      encounterId != old.encounterId ||
      patientId != old.patientId ||
      doctorId != old.doctorId ||
      patientVitals != old.patientVitals ||
      amendMode != old.amendMode ||
      editReason != old.editReason ||
      isEmergency != old.isEmergency ||
      emergencyVisitId != old.emergencyVisitId ||
      edEsiLevel != old.edEsiLevel;
}

@RoutePage()
class DoctorEncounterViewScreen extends StatefulWidget {
  final String encounterId;
  final String patientId;
  final String? patientVitalsJson;

  /// When true, amends a completed encounter (no complete button, versioned saves).
  final bool amendMode;

  /// Optional linked EmergencyVisit id from ED board.
  final String? emergencyVisitId;

  const DoctorEncounterViewScreen({
    super.key,
    required this.encounterId,
    required this.patientId,
    this.patientVitalsJson,
    this.amendMode = false,
    this.emergencyVisitId,
  });

  @override
  State<DoctorEncounterViewScreen> createState() =>
      _DoctorEncounterViewScreenState();
}

class _DoctorEncounterViewScreenState extends State<DoctorEncounterViewScreen> {
  final _patientService = PatientService();
  final _encounterService = EncounterService();
  final _emergencyService = EmergencyService();
  final _waitingPatientService = WaitingPatientService();

  Patient? _patient;
  EncounterModel? _encounter;
  bool _loadingPatient = false;
  String? _patientError;
  PatientVitalsModel? _patientVitals;
  bool _completing = false;
  bool _specialtyGateDismissed = false;
  bool _specialtyGateOverlayScheduled = false;
  String? _editReason;
  bool _amendReasonPrompted = false;
  bool _isEmergency = false;
  String? _emergencyVisitId;
  int? _edEsiLevel;

  @override
  void initState() {
    super.initState();
    if (widget.amendMode) {
      _specialtyGateDismissed = true;
    }
    _parseVitals();
    if (_patientVitals == null) {
      unawaited(_loadVitalsByEncounter());
    }
    _loadPatient();
    _loadEncounter().then((_) => _maybeSetupEmergency());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.amendMode && !_amendReasonPrompted) {
        _amendReasonPrompted = true;
        unawaited(_promptAmendReason());
        return;
      }
      if (_isEmergency || _specialtyGateDismissed || _specialtyGateOverlayScheduled) {
        return;
      }
      _specialtyGateOverlayScheduled = true;
      EncounterSpecialtyGate.showBlockingOverlay(
        context,
        encounterId: widget.encounterId,
        onUserFinished: () {
          if (!mounted) return;
          setState(() => _specialtyGateDismissed = true);
        },
      );
    });
  }

  Future<void> _maybeSetupEmergency() async {
    if (!_isEmergency || !mounted) return;
    try {
      await _emergencyService.enableEmergencyModules(widget.encounterId);
    } catch (_) {}
    if (!mounted) return;
    setState(() => _specialtyGateDismissed = true);
  }

  Future<void> _promptAmendReason() async {
    final reason = await showAmendReasonDialog(context);
    if (!mounted) return;
    setState(() => _editReason = reason);
  }

  Future<void> _changeAmendReason() async {
    final reason = await showChangeAmendReasonDialog(
      context,
      currentReason: _editReason,
    );
    if (!mounted || reason == null) return;
    setState(() => _editReason = reason);
  }

  Future<void> _loadEncounter() async {
    try {
      final enc = await _encounterService.getById(
        widget.encounterId,
        expand: ['clinicalSections', 'specialtyModules'],
      );
      if (!mounted) return;

      final isEm = enc?.isEmergency == true;
      int? esi;
      if (enc != null) {
        esi = _emergencyService.esiFromEncounter(enc);
      }

      String? visitId = widget.emergencyVisitId;
      if (isEm && visitId == null) {
        final visit = await _emergencyService.getVisit(widget.encounterId);
        visitId = visit?.id;
        esi ??= visit?.esiLevel;
      }

      setState(() {
        _encounter = enc;
        _isEmergency = isEm;
        _emergencyVisitId = visitId ?? widget.encounterId;
        _edEsiLevel = esi;
        if (isEm) _specialtyGateDismissed = true;
      });
    } catch (_) {
      if (mounted) setState(() => _encounter = null);
    }
  }

  void _parseVitals() {
    final json = widget.patientVitalsJson;
    if (json == null || json.isEmpty) return;
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      _patientVitals = PatientVitalsModel.fromJson(map);
    } catch (_) {
      // ignore invalid JSON
    }
  }

  /// Loads triage vitals when not passed via route (ED board, outpatient list, etc.).
  Future<void> _loadVitalsByEncounter() async {
    try {
      final list = await _waitingPatientService.fetchVitalsByEncounter(
        widget.encounterId,
      );
      if (!mounted || list.isEmpty) return;
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() => _patientVitals = list.first);
    } catch (_) {
      // Vitals are optional on examination; ignore fetch errors.
    }
  }

  Future<void> _loadPatient() async {
    setState(() {
      _loadingPatient = true;
      _patientError = null;
    });
    try {
      final p = await _patientService.getPatientById(widget.patientId);
      if (!mounted) return;
      setState(() {
        _patient = p;
        _loadingPatient = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _patientError = 'Failed to load patient: $e';
        _loadingPatient = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load patient: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AutoTabsRouter(
      routes: const [
        DoctorEncounterHistoryTab(),
        DoctorEncounterExaminationTab(),
        DoctorEncounterDiagnosisTab(),
        DoctorEncounterInvestigationsTab(),
        DoctorEncounterImagingTab(),
        DoctorEncounterPrescriptionTab(),
        DoctorEncounterProceduresTab(),
        DoctorEncounterNotesTab(),
        DoctorEncounterAdmissionTab(),
        DoctorEncounterFollowUpTab(),
      ],
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);

        return EncounterScope(
          encounterId: widget.encounterId,
          patientId: widget.patientId,
          doctorId: _encounter?.doctorId,
          patientVitals: _patientVitals,
          amendMode: widget.amendMode,
          editReason: _editReason,
          isEmergency: _isEmergency,
          emergencyVisitId: _emergencyVisitId,
          edEsiLevel: _edEsiLevel,
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double horizontalPadding = constraints.maxWidth > 1400
                      ? 32
                      : 20;

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: _contentMaxWidth,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          24,
                          horizontalPadding,
                          24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeaderRow(context),
                            const SizedBox(height: 16),
                            _buildPatientHeader(context),
                            const SizedBox(height: 20),
                            Expanded(
                              child: AbsorbPointer(
                                absorbing: !_specialtyGateDismissed,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildTabsStrip(context, tabsRouter),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color: colorScheme.surface,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4.0),
                                            child: child,
                                          ),
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
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDisposition() async {
    final enc = _encounter;
    if (enc == null) return;

    final hasDiagnosis = (enc.primaryIcdCode != null &&
            enc.primaryIcdCode!.trim().isNotEmpty) ||
        enc.linkedDiagnoses.isNotEmpty;

    final result = await showEdDispositionDialog(
      context,
      encounterId: widget.encounterId,
      visitId: _emergencyVisitId ?? widget.encounterId,
      hasDiagnosis: hasDiagnosis,
    );
    if (!mounted || result == null) return;

    if (result.navigateToAdmissionTab) {
      final tabsRouter = AutoTabsRouter.of(context);
      tabsRouter.setActiveIndex(8);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete admission details on the Admission tab.'),
        ),
      );
      return;
    }

    await _loadEncounter();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('ED disposition recorded.')),
    );
    context.router.maybePop();
  }

  Future<void> _completeEncounter() async {
    setState(() => _completing = true);
    try {
      await _encounterService.complete(widget.encounterId);
      if (!mounted) return;
      await _loadEncounter();
      if (!mounted) return;
      setState(() => _completing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Encounter completed. Patient file closed.'),
        ),
      );
      context.router.maybePop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _completing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete encounter: $e')),
      );
    }
  }

  Widget _buildHeaderRow(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isCompleted = _encounter?.isCompleted == true;
    final isAmend = widget.amendMode;
    final isEm = _isEmergency;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isAmend
                  ? 'Amend encounter'
                  : isEm
                  ? 'Emergency encounter'
                  : 'Encounter',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  isAmend
                      ? 'Changes are saved to edit history'
                      : isEm
                      ? 'Emergency department clinical workspace'
                      : 'OPD encounter view',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (isEm && _edEsiLevel != null) ...[
                  const SizedBox(width: 12),
                  EsiBadge(esiLevel: _edEsiLevel, compact: true),
                ],
              ],
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OutlinedButton.icon(
                onPressed: () {
                  PatientPreviousEncountersSheet.show(
                    context,
                    patientId: widget.patientId,
                    currentEncounterId: widget.encounterId,
                  );
                },
                icon: const Icon(Icons.history, size: 18),
                label: const Text('Previous encounters'),
              ),
            ),
            if (isAmend)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton.icon(
                  onPressed: _changeAmendReason,
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: Text(
                    _editReason != null && _editReason!.isNotEmpty
                        ? 'Reason set'
                        : 'Set reason',
                  ),
                ),
              ),
            if (_specialtyGateDismissed && !isCompleted && !isAmend)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    EncounterSpecialtyFormsPanel.showSheet(
                      context,
                      encounterId: widget.encounterId,
                      patientId: widget.patientId,
                      editReason: _editReason,
                    );
                  },
                  icon: const Icon(Icons.grid_view_rounded, size: 20),
                  label: const Text('Specialty forms'),
                ),
              ),
            if (isAmend)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    EncounterSpecialtyFormsPanel.showSheet(
                      context,
                      encounterId: widget.encounterId,
                      patientId: widget.patientId,
                      editReason: _editReason,
                    );
                  },
                  icon: const Icon(Icons.grid_view_rounded, size: 20),
                  label: const Text('Specialty forms'),
                ),
              ),
            if (isCompleted || isAmend)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: scheme.tertiary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 18,
                      color: scheme.tertiary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Completed',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            else if (_specialtyGateDismissed && !isAmend)
              FilledButton.icon(
                onPressed: _completing
                    ? null
                    : isEm
                    ? _openDisposition
                    : _completeEncounter,
                icon: _completing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isEm ? Icons.call_split_rounded : Icons.done_all,
                        size: 18,
                      ),
                label: Text(
                  _completing
                      ? 'Completing…'
                      : isEm
                      ? 'Disposition'
                      : 'Finish with patient',
                ),
              ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: scheme.primary.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.medical_services_outlined,
                    size: 18,
                    color: scheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isEm ? 'Doctor module • ED' : 'Doctor module • OPD',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPatientHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_loadingPatient) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.15)),
        ),
        child: SizedBox(
          height: 64,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.6,
              color: scheme.primary,
            ),
          ),
        ),
      );
    }

    if (_patientError != null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: scheme.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _patientError!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.error,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: _loadPatient,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final patient = _patient;
    final name = patient != null
        ? '${patient.title} ${patient.firstName} ${patient.surname}'
        : 'Unknown Patient';
    final ageYears = patient != null
        ? DateTime.now().year - patient.dob.year
        : null;
    final ageGender = [
      if (ageYears != null) '$ageYears yrs',
      if (patient != null && patient.gender.isNotEmpty) patient.gender,
    ].join(' • ');
    final hospitalNumber = patient != null
        ? patient.patientId
        : widget.patientId;
    // Patient model has no allergies/chronic/past admissions; use placeholders until API supports
    final allergies = <String>[];
    final chronicConditions = <String>[];
    const pastAdmissionsCount = 0;
    final insurance = patient?.hmo;

    return DoctorEncounterPatientHeader(
      patientName: name.trim(),
      ageGender: ageGender,
      hospitalNumber: hospitalNumber,
      allergies: allergies,
      chronicConditions: chronicConditions,
      pastAdmissionsCount: pastAdmissionsCount,
      insurance: insurance,
    );
  }

  Widget _buildTabsStrip(BuildContext context, TabsRouter tabsRouter) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    const labels = [
      'History',
      'Examination',
      'Diagnosis',
      'Investigations',
      'Imaging',
      'Prescription',
      'Procedures',
      'Notes',
      'Admission',
      'Follow-up',
    ];

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceBright.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(labels.length, (index) {
            final bool selected = tabsRouter.activeIndex == index;
            final label = labels[index];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => tabsRouter.setActiveIndex(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? scheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? scheme.onPrimary
                          : scheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
