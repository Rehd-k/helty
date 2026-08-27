import 'dart:async';
import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/doctor/completed/edit_history/encounter_edit_history_sheet.dart';
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
import 'package:helty/src/doctor/templates/widgets/encounter_template_picker_sheet.dart';
import 'package:helty/src/doctor/templates/widgets/save_encounter_template_dialog.dart';
import 'package:helty/src/pharmacy/utils/medication_workflow_patient_type.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/models/super_admin_department_preview.dart';
import 'package:helty/src/services/admission_service.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/services/staff_service.dart';
import 'package:helty/src/services/waiting_patient_service.dart';

/// Resolves write access from encounter [editMeta] (defaults for ongoing charts).
bool encounterCanEdit(EncounterModel? enc) {
  if (enc == null) return false;
  final meta = enc.editMeta;
  if (meta != null) return meta.canEdit;
  return !enc.isCompleted;
}

/// Provides encounterId, patientId, optional doctorId, and optional pre-loaded vitals to tab content.
class EncounterScope extends InheritedWidget {
  const EncounterScope({
    super.key,
    required this.encounterId,
    required this.patientId,
    this.doctorId,
    this.treatingDoctorId,
    this.actingStaffId,
    this.patientVitals,
    this.amendMode = false,
    this.editReason,
    this.canEdit = true,
    this.requiresVersionedEdits = false,
    this.isSharedInpatientEncounter = false,
    this.canEditAsCoveringPhysician = false,
    this.isEmergency = false,
    this.emergencyVisitId,
    this.edEsiLevel,
    this.encounterType,
    this.reloadGeneration = 0,
    this.isOutpatient = false,
    this.activeAdmissionId,
    this.patientWard,
    this.pregnancyId,
    this.onEncounterUpdated,
    required super.child,
  });

  final String encounterId;
  final String patientId;

  /// Refetch parent encounter after a clinical save (e.g. diagnosis).
  final Future<void> Function()? onEncounterUpdated;

  /// Acting physician id for orders and clinical writes (when [canEdit]).
  final String? doctorId;

  /// Original admitting / treating doctor on the encounter.
  final String? treatingDoctorId;

  /// Logged-in staff performing edits (same as [doctorId] when editing).
  final String? actingStaffId;
  final PatientVitalsModel? patientVitals;
  final String? encounterType;

  /// Incremented when a template is applied so tabs refetch drafts.
  final int reloadGeneration;

  /// OPD ward with no ACTIVE admission — doctor sends requestedQuantity on prescribe.
  final bool isOutpatient;

  /// Active admission id for inpatient prescribe (from encounter or admission lookup).
  final String? activeAdmissionId;

  /// Patient ward name when known (e.g. OPD).
  final String? patientWard;

  /// Linked ongoing pregnancy when ordering from antenatal chart.
  final String? pregnancyId;

  /// Amending a completed encounter (versioned saves + optional editReason).
  final bool amendMode;

  /// Stored on each history row when amending a completed encounter.
  final String? editReason;

  /// Current user may perform clinical writes on this chart.
  final bool canEdit;

  /// Encounter is COMPLETED — saves should include optional editReason.
  final bool requiresVersionedEdits;

  /// Linked to an ACTIVE admission (shared inpatient chart).
  final bool isSharedInpatientEncounter;

  /// User is editing as covering physician (not the admitting doctor).
  final bool canEditAsCoveringPhysician;

  /// True when [amendMode] or [requiresVersionedEdits] (versioned PATCH/diagnosis).
  bool get versionedEdits => amendMode || requiresVersionedEdits;

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
      treatingDoctorId != old.treatingDoctorId ||
      actingStaffId != old.actingStaffId ||
      patientVitals != old.patientVitals ||
      amendMode != old.amendMode ||
      editReason != old.editReason ||
      canEdit != old.canEdit ||
      requiresVersionedEdits != old.requiresVersionedEdits ||
      isSharedInpatientEncounter != old.isSharedInpatientEncounter ||
      canEditAsCoveringPhysician != old.canEditAsCoveringPhysician ||
      isEmergency != old.isEmergency ||
      emergencyVisitId != old.emergencyVisitId ||
      edEsiLevel != old.edEsiLevel ||
      encounterType != old.encounterType ||
      reloadGeneration != old.reloadGeneration ||
      isOutpatient != old.isOutpatient ||
      activeAdmissionId != old.activeAdmissionId ||
      patientWard != old.patientWard ||
      pregnancyId != old.pregnancyId;
}

@RoutePage()
class DoctorEncounterViewScreen extends ConsumerStatefulWidget {
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
  ConsumerState<DoctorEncounterViewScreen> createState() =>
      _DoctorEncounterViewScreenState();
}

class _DoctorEncounterViewScreenState
    extends ConsumerState<DoctorEncounterViewScreen> {
  final _patientService = PatientService();
  final _encounterService = EncounterService();
  final _admissionService = AdmissionService();
  final _emergencyService = EmergencyService();
  final _waitingPatientService = WaitingPatientService();
  final _staffService = StaffService();

  Patient? _patient;
  EncounterModel? _encounter;
  String? _resolvedDoctorName;
  String? _resolvedUpdatedByName;
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
  int _reloadGeneration = 0;
  bool _isOutpatient = false;
  String? _activeAdmissionId;
  String? _patientWard;

  /// Built once so parent [setState]s (patient, vitals, doctor name) do not
  /// recreate AutoTabsRouter routes and remount Chart (scroll snap + reload).
  late final List<PageRouteInfo> _encounterTabRoutes = [
    const DoctorEncounterChartTab(),
    DoctorEncounterHistoryTab(),
    DoctorEncounterExaminationTab(),
    DoctorEncounterDiagnosisTab(),
    DoctorEncounterInvestigationsTab(),
    DoctorEncounterImagingTab(),
    DoctorEncounterSurgeryTab(),
    DoctorEncounterPrescriptionTab(),
    DoctorEncounterProceduresTab(),
    DoctorEncounterNotesTab(),
    DoctorEncounterAdmissionTab(),
    DoctorEncounterFollowUpTab(),
  ];

  void _notifyTemplateApplied() {
    setState(() => _reloadGeneration++);
  }

  Future<void> _loadTemplate() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    await EncounterTemplatePickerSheet.show(
      context,
      scope: scope,
      onApplied: _notifyTemplateApplied,
    );
  }

  Future<void> _saveAsTemplate() async {
    final created = await SaveEncounterTemplateDialog.show(
      context,
      encounterId: widget.encounterId,
      encounterType: _encounter?.encounterType,
    );
    if (!mounted || created == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Saved template "${created.name}"')));
  }

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
    _loadEncounter().then((_) {
      _maybeSetupEmergency();
      _maybePromptVersionedEditReason();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.amendMode && !_amendReasonPrompted) {
        _amendReasonPrompted = true;
        unawaited(_promptAmendReason());
        return;
      }
      if (_isEmergency ||
          _specialtyGateDismissed ||
          _specialtyGateOverlayScheduled) {
        return;
      }
      final enc = _encounter;
      if (enc != null && enc.isSharedInpatient) {
        setState(() => _specialtyGateDismissed = true);
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

  void _maybePromptVersionedEditReason() {
    if (!mounted || _amendReasonPrompted || widget.amendMode) return;
    final enc = _encounter;
    if (enc == null) return;
    final meta = enc.editMeta;
    if (meta == null) return;
    if (!meta.requiresVersionedEdits || !meta.canEdit) return;
    _amendReasonPrompted = true;
    unawaited(_promptAmendReason());
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
        if (enc?.isSharedInpatient == true || widget.amendMode) {
          _specialtyGateDismissed = true;
        }
      });
      if (enc != null) {
        unawaited(_resolveDoctorName(enc));
        unawaited(_resolveUpdatedByName(enc));
        if (_patient != null) {
          unawaited(_resolveMedicationPatientContext());
        }
      }
    } catch (_) {
      if (mounted) setState(() => _encounter = null);
    }
  }

  Future<void> _resolveUpdatedByName(EncounterModel enc) async {
    final updatedBy = enc.updatedBy;
    if (updatedBy == null) {
      if (!mounted) return;
      setState(() => _resolvedUpdatedByName = null);
      return;
    }
    final display = updatedBy.displayName.trim();
    if (display.isNotEmpty && display != updatedBy.id) {
      if (!mounted) return;
      setState(() => _resolvedUpdatedByName = 'Dr $display');
      return;
    }
    if (!mounted) return;
    setState(() => _resolvedUpdatedByName = null);
  }

  Future<void> _resolveDoctorName(EncounterModel enc) async {
    final display = enc.doctorDisplayName?.trim();
    if (display != null && display.isNotEmpty) {
      if (!mounted) return;
      setState(() => _resolvedDoctorName = enc.doctorLabel);
      return;
    }

    final doctorId = enc.doctorId.trim();
    if (doctorId.isEmpty) return;

    try {
      final staff = await _staffService.getStaffById(doctorId);
      if (!mounted) return;
      setState(() => _resolvedDoctorName = 'Dr ${staff.fullName}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _resolvedDoctorName = enc.doctorLabel);
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
        _patientWard = p.ward;
      });
      await _resolveMedicationPatientContext();
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

  Future<void> _resolveMedicationPatientContext() async {
    final ctx = await resolveMedicationPatientContext(
      patient: _patient,
      admissionService: _admissionService,
      encounterAdmissionId: _encounter?.admissionId,
    );
    if (!mounted) return;
    setState(() {
      _isOutpatient = ctx.isOutpatient;
      _activeAdmissionId = ctx.activeAdmissionId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final enc = _encounter;
    final meta = enc?.editMeta;
    final canEdit = encounterCanEdit(enc);
    final requiresVersionedEdits = meta?.requiresVersionedEdits == true;
    final isSharedInpatient = enc?.isSharedInpatient == true;
    final canEditAsCovering = meta?.canEditAsCoveringPhysician == true;
    final staff = ref.watch(authProvider).staff;
    final actingStaffId = canEdit ? staff?.id.trim() : null;
    final scopeDoctorId = (actingStaffId != null && actingStaffId.isNotEmpty)
        ? actingStaffId
        : enc?.doctorId;

    return AutoTabsRouter(
      routes: _encounterTabRoutes,
      builder: (context, child) {
        final tabsRouter = AutoTabsRouter.of(context);

        return EncounterScope(
          encounterId: widget.encounterId,
          patientId: widget.patientId,
          doctorId: scopeDoctorId,
          treatingDoctorId: enc?.doctorId,
          actingStaffId: actingStaffId,
          patientVitals: _patientVitals,
          amendMode: widget.amendMode,
          editReason: _editReason,
          canEdit: canEdit,
          requiresVersionedEdits: requiresVersionedEdits,
          isSharedInpatientEncounter: isSharedInpatient,
          canEditAsCoveringPhysician: canEditAsCovering,
          isEmergency: _isEmergency,
          emergencyVisitId: _emergencyVisitId,
          edEsiLevel: _edEsiLevel,
          encounterType: enc?.encounterType,
          reloadGeneration: _reloadGeneration,
          isOutpatient: _isOutpatient,
          activeAdmissionId: _activeAdmissionId,
          patientWard: _patientWard,
          onEncounterUpdated: _loadEncounter,
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            body: SafeArea(
              child: ResponsiveBody(
                maxWidth: 1440,
                builder: (context, bp) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeaderRow(context),
                    if (_buildEditMetaBanner(context) != null) ...[
                      const SizedBox(height: 12),
                      _buildEditMetaBanner(context)!,
                    ],
                    const SizedBox(height: 16),
                    _buildPatientHeader(context),
                    const SizedBox(height: 20),
                    Expanded(
                      child: AbsorbPointer(
                        absorbing: !_specialtyGateDismissed,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
          ),
        );
      },
    );
  }

  Future<void> _openDisposition() async {
    await _loadEncounter();
    if (!mounted) return;

    final enc = _encounter;
    if (enc == null) return;

    final hasDiagnosis =
        (enc.primaryIcdCode != null && enc.primaryIcdCode!.trim().isNotEmpty) ||
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
      tabsRouter.setActiveIndex(10);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete admission details on the Admission tab.'),
        ),
      );
      return;
    }

    await _loadEncounter();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ED disposition recorded.')));
    context.router.maybePop();
  }

  Future<void> _completeEncounter({bool asSuperAdmin = false}) async {
    if (asSuperAdmin) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('End encounter'),
          content: const Text(
            'End this encounter as super admin? The treating doctor edit check is skipped and you will not be stamped as lastUpdatedBy.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('End encounter'),
            ),
          ],
        ),
      );
      if (ok != true) return;
    }
    setState(() => _completing = true);
    try {
      await _encounterService.complete(widget.encounterId);
      if (!mounted) return;
      await _loadEncounter();
      if (!mounted) return;
      setState(() => _completing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            asSuperAdmin
                ? 'Encounter ended by super admin.'
                : 'Encounter completed. Patient file closed.',
          ),
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

  Widget? _buildEditMetaBanner(BuildContext context) {
    final enc = _encounter;
    if (enc == null) return null;
    final meta = enc.editMeta;
    final canEdit = encounterCanEdit(enc);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    String? message;
    Color? bgColor;
    IconData icon = Icons.info_outline;

    if (meta?.canEditAsCoveringPhysician == true) {
      message = 'You are editing as covering physician.';
      bgColor = scheme.primaryContainer.withValues(alpha: 0.5);
      icon = Icons.medical_information_outlined;
    } else if (!canEdit) {
      message = 'Read-only chart — you cannot edit this encounter.';
      bgColor = scheme.surfaceContainerHighest.withValues(alpha: 0.6);
      icon = Icons.lock_outline;
    }

    if (message == null) return null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.onSurface),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: theme.textTheme.bodySmall)),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enc = _encounter;
    final isCompleted = enc?.isCompleted == true;
    final isAmend = widget.amendMode;
    final isEm = _isEmergency;
    final isSharedInpatient = enc?.isSharedInpatient == true;
    final canEdit = encounterCanEdit(enc);
    final meta = enc?.editMeta;
    final versionedEdits = isAmend || meta?.requiresVersionedEdits == true;
    final isSuperAdmin = staffIsSuperAdmin(ref.watch(authProvider).staff);
    final canSuperAdminEnd =
        isSuperAdmin && !isCompleted && !isAmend && !canEdit;

    return ResponsiveToolbar(
      leading: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isAmend
                ? 'Amend encounter'
                : isSharedInpatient
                ? 'Inpatient chart'
                : isEm
                ? 'Emergency encounter'
                : 'Encounter',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                isAmend
                    ? 'Changes are saved to edit history'
                    : isSharedInpatient
                    ? 'Shared inpatient clinical chart'
                    : isEm
                    ? 'Emergency department clinical workspace'
                    : 'OPD encounter view',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (isEm && _edEsiLevel != null)
                EsiBadge(esiLevel: _edEsiLevel, compact: true),
            ],
          ),
        ],
      ),
      actions: [
        IconButton.outlined(
          tooltip: 'Previous encounters',
          onPressed: () {
            PatientPreviousEncountersSheet.show(
              context,
              patientId: widget.patientId,
              currentEncounterId: widget.encounterId,
            );
          },
          icon: const Icon(Icons.history, size: 18),
        ),
        if (enc != null && (meta?.hasEdits == true || versionedEdits))
          IconButton.outlined(
            tooltip: 'Edit history',
            onPressed: () => EncounterEditHistorySheet.show(
              context,
              encounterId: widget.encounterId,
              encounter: enc,
            ),
            icon: const Icon(Icons.fact_check_outlined, size: 18),
          ),
        if (!isCompleted && canEdit)
          IconButton.outlined(
            tooltip: 'Load template',
            onPressed: _loadTemplate,
            icon: const Icon(Icons.description_outlined, size: 18),
          ),
        if (!isCompleted && canEdit)
          IconButton.outlined(
            tooltip: 'Save as template',
            onPressed: _saveAsTemplate,
            icon: const Icon(Icons.save_as_outlined, size: 18),
          ),
        if (versionedEdits && canEdit)
          IconButton.outlined(
            tooltip: _editReason != null && _editReason!.isNotEmpty
                ? 'Reason set'
                : 'Set reason',
            onPressed: _changeAmendReason,
            icon: const Icon(Icons.edit_note, size: 18),
          ),
        if (_specialtyGateDismissed && !isCompleted && canEdit && !isAmend)
          IconButton.filledTonal(
            tooltip: 'Specialty forms',
            onPressed: () {
              EncounterSpecialtyFormsPanel.showSheet(
                context,
                encounterId: widget.encounterId,
                patientId: widget.patientId,
                editReason: _editReason,
                readOnly: !canEdit,
              );
            },
            icon: const Icon(Icons.grid_view_rounded, size: 20),
          ),
        if ((isAmend || (isSharedInpatient && canEdit)) &&
            _specialtyGateDismissed)
          IconButton.filledTonal(
            tooltip: 'Specialty forms',
            onPressed: () {
              EncounterSpecialtyFormsPanel.showSheet(
                context,
                encounterId: widget.encounterId,
                patientId: widget.patientId,
                editReason: _editReason,
                readOnly: !canEdit,
              );
            },
            icon: const Icon(Icons.grid_view_rounded, size: 20),
          ),
        if (isCompleted || isAmend || (isSharedInpatient && isCompleted))
          Tooltip(
            message: 'Completed',
            child: Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: scheme.tertiary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 18,
                color: scheme.tertiary,
              ),
            ),
          )
        else if (_specialtyGateDismissed && !isAmend && canEdit)
          IconButton.filled(
            tooltip: _completing
                ? 'Completing…'
                : isEm
                ? 'Disposition'
                : 'Finish with patient',
            onPressed: _completing
                ? null
                : isEm
                ? _openDisposition
                : () => _completeEncounter(),
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
          )
        else if (canSuperAdminEnd)
          IconButton.filledTonal(
            tooltip: _completing ? 'Ending…' : 'End encounter (super admin)',
            onPressed: _completing
                ? null
                : () => _completeEncounter(asSuperAdmin: true),
            icon: _completing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.stop_circle_outlined, size: 18),
          ),
        Tooltip(
          message: isEm
              ? 'Doctor module • ED'
              : isSharedInpatient
              ? 'Doctor module • Inpatient'
              : 'Doctor module • OPD',
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              Icons.medical_services_outlined,
              size: 18,
              color: scheme.primary,
            ),
          ),
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
    final name = patient != null ? patient.displayName : 'Unknown Patient';
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

    final isSharedInpatient = _encounter?.isSharedInpatient == true;

    return DoctorEncounterPatientHeader(
      patientName: name.trim(),
      ageGender: ageGender,
      hospitalNumber: hospitalNumber,
      allergies: allergies,
      chronicConditions: chronicConditions,
      pastAdmissionsCount: pastAdmissionsCount,
      insurance: insurance,
      doctorName: _resolvedDoctorName,
      doctorLabel: isSharedInpatient ? 'Admitting doctor' : 'Doctor',
      createdByName: () {
        final name = _encounter?.createdBy?.displayName.trim();
        if (name == null || name.isEmpty) return null;
        if (name == _encounter?.createdBy?.id) return null;
        return name;
      }(),
      lastUpdatedByName: _resolvedUpdatedByName,
      avatarUrl: patient?.avatarUrl,
      firstName: patient?.firstName,
      surname: patient?.surname,
    );
  }

  Widget _buildTabsStrip(BuildContext context, TabsRouter tabsRouter) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    const labels = [
      'Chart',
      'History',
      'Examination',
      'Diagnosis',
      'Investigations',
      'Imaging',
      'Surgery',
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
                      color: selected ? scheme.onPrimary : scheme.onSurface,
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
