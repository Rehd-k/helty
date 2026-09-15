import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/nurses/inpatients/tabs/inpatient_ward_round_tab.dart'
    show showWardRoundNoteDialog;
import 'package:helty/src/nurses/inpatients/ward_round_note_draft.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_sidebar.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_ui_tabs.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/patient_header_card.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/auth/nursing_permissions.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/ward_round_note_service.dart';
import 'package:helty/src/widgets/helty_surface.dart';

import '../../admissions/admission_discharge_helpers.dart';
import '../../admissions/discharge_admission_dialog.dart';
import '../../admissions/discharge_summary_dialog.dart';
import '../../helper/date.formatter.dart';
import '../../../app_router.gr.dart';
import '../../models/admission_billing_clearance_models.dart';
import '../../models/admission_model.dart';
import '../../models/medication_order_model.dart';
import 'package:helty/src/pharmacy/utils/medication_workflow_patient_type.dart';
import '../../services/admission_service.dart';
import 'tabs/inpatient_consumables_tab.dart';

@RoutePage()
class InpatientPatientViewScreen extends ConsumerStatefulWidget {
  final String admissionId;
  final String? ward;
  final String? bedNumber;
  final String? attendingDoctor;
  final String? diagnosis;
  final DateTime? admissionDate;
  final List<String>? allergies;
  final String? codeStatus;
  final List<String>? riskFlags;
  final bool readOnly;

  const InpatientPatientViewScreen({
    super.key,
    required this.admissionId,
    this.ward,
    this.bedNumber,
    this.attendingDoctor,
    this.diagnosis,
    this.admissionDate,
    this.allergies,
    this.codeStatus,
    this.riskFlags,
    this.readOnly = false,
  });

  @override
  ConsumerState<InpatientPatientViewScreen> createState() =>
      _InpatientPatientViewScreenState();
}

class _InpatientPatientViewScreenState
    extends ConsumerState<InpatientPatientViewScreen> {
  final _admissionService = AdmissionService();

  Patient? _patient;
  AdmissionModel? _admission;
  bool _loadingPatient = false;
  String? _patientError;
  int _uiTabIndex = 0;
  bool _clearingNurses = false;
  TabsRouter? _tabsRouter;

  void _selectUiTab(int index) {
    setState(() => _uiTabIndex = index);
    final routerIndex = InpatientUiTabs.routerIndexForUiTab(index);
    if (routerIndex != null) {
      _tabsRouter?.setActiveIndex(routerIndex);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _resumeOrOpenWardRoundNote({WardRoundNoteDraft? draft}) async {
    final staff = ref.read(authProvider).staff;
    final doctorId = staff?.id ?? staff?.staffId ?? '';
    if (doctorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must be logged in as a doctor to add a ward round note.',
          ),
        ),
      );
      return;
    }

    final result = await showWardRoundNoteDialog(
      context: context,
      admissionId: widget.admissionId,
      doctorId: doctorId,
      wardRoundNoteService: WardRoundNoteService(),
      initialDraft: draft,
    );
    if (!mounted) return;

    switch (result?.outcome) {
      case WardRoundNoteDialogOutcome.saved:
        ref.read(wardRoundNoteDraftProvider.notifier).state = null;
      case WardRoundNoteDialogOutcome.minimized:
        ref.read(wardRoundNoteDraftProvider.notifier).state = result?.draft;
      case WardRoundNoteDialogOutcome.discarded:
      case null:
        ref.read(wardRoundNoteDraftProvider.notifier).state = null;
    }
  }

  void _discardWardRoundDraft() {
    ref.read(wardRoundNoteDraftProvider.notifier).state = null;
  }

  /// Same identity labels as [PatientHeaderCard] / [_buildPatientHeader].
  ({String name, String hospNo})? _patientIdentityLabels() {
    final patient = _patient;
    if (patient == null) return null;
    final nameParts = <String>[
      if (patient.title.trim().isNotEmpty) patient.title.trim(),
      patient.firstName.trim(),
      patient.surname.trim(),
    ].where((s) => s.isNotEmpty).toList();
    final name = nameParts.isEmpty ? 'Unknown patient' : nameParts.join(' ');
    final hospNo = patient.patientId.isNotEmpty ? patient.patientId : '—';
    return (name: name, hospNo: hospNo);
  }

  Future<void> _loadPatient() async {
    setState(() {
      _loadingPatient = true;
      _patientError = null;
      _patient = null;
      _admission = null;
    });

    try {
      _admission = await _admissionService.getOneById(widget.admissionId);
      if (!mounted) return;
      setState(() {
        _patient = _admission?.patient;
        _loadingPatient = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _patientError = 'Failed to load patient: $e';
        _loadingPatient = false;
        _patient = null;
        _admission = null;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load patient: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final auth = ref.watch(authProvider);
    final staff = auth.staff;
    final role = staff?.staffRole.toLowerCase() ?? '';
    final accountType = staff?.accountType?.name.toLowerCase() ?? '';
    final staffId = staff?.id ?? staff?.staffId;

    final isDoctor =
        role == 'doctor' ||
        role == 'consultant' ||
        role == 'resident' ||
        role == 'intern' ||
        role == 'junior_resident' ||
        role == 'senior_resident' ||
        role == 'chief_resident' ||
        role == 'medical_student' ||
        accountType == 'physician' ||
        accountType == 'consultant' ||
        accountType == 'inpatient_doctor';
    final isNurse = isNursingStaff(ref.watch(authProvider).staff);

    final identity = _patientIdentityLabels();
    final wardRoundDraft = ref.watch(wardRoundNoteDraftProvider);
    final WardRoundNoteDraft? draftForChip =
        (wardRoundDraft != null &&
            wardRoundDraft.admissionId == widget.admissionId)
        ? wardRoundDraft
        : null;

    return InpatientViewScope(
      patientId: _patient?.id ?? '',
      admissionId: widget.admissionId,
      encounterId: _admission?.encounterId,
      embeddedMedicationOrders:
          _admission?.encounterMedicationOrders ??
          const <MedicationOrderModel>[],
      patientDisplayName: identity?.name,
      hospitalNumber: identity?.hospNo,
      staffId: staffId,
      role: role,
      accountType: accountType,
      isDoctor: isDoctor,
      isNurse: isNurse,
      admissionStatus: _admission?.status,
      isOutpatient:
          isOpdWardName(_patient?.ward ?? widget.ward) &&
          !isActiveAdmissionStatus(_admission?.status),
      readOnly: widget.readOnly,
      onSelectTab: _selectUiTab,
      child: AutoTabsRouter(
        routes: [
          InpatientOverviewRoute(),
          InpatientVitalsRoute(
            admissionId: widget.admissionId,
            vitals: _admission?.patientVitals ?? [],
          ),
          InpatientMedicationsRoute(),
          InpatientIVRoute(),
          InpatientIORoute(),
          InpatientNotesRoute(),
          InpatientWoundAssessmentRoute(),
          InpatientWardRoundTab(),
          InpatientProceduresRoute(),
          InpatientCarePlanRoute(),
          InpatientMonitoringRoute(),
          InpatientLabResultsRoute(),
          InpatientImagingResultsRoute(),
          InpatientAlertsRoute(),
          InpatientHandoverRoute(),
        ],
        builder: (context, child) {
          _tabsRouter = AutoTabsRouter.of(context);

          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: SafeArea(
              child: Stack(
                children: [
                  ResponsiveBody(
                    center: false,
                    bottomPadding: 12,
                    builder: (context, bp) {
                      final showRail =
                          bp.maxWidth >= kInpatientSidebarBreakpoint;
                      final compact = !showRail;

                      final tabContent =
                          _uiTabIndex == InpatientUiTabs.consumables
                          ? _buildTabContentShell(
                              colorScheme,
                              child: const InpatientConsumablesScreen(),
                            )
                          : _buildTabContentShell(colorScheme, child: child);

                      final sidebar = InpatientSidebar(
                        admission: _admission,
                        fillHeight: showRail,
                        onLocationUpdated: _loadPatient,
                      );

                      final mainColumn = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeaderRow(
                            context,
                            compact: compact,
                            isDoctor: isDoctor,
                          ),
                          const SizedBox(height: 10),
                          _buildPatientHeader(context),
                          const SizedBox(height: 10),
                          _buildTabsStrip(context, compact: compact),
                          const SizedBox(height: 10),
                          Expanded(child: tabContent),
                        ],
                      );

                      if (showRail) {
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 9, child: mainColumn),
                            const SizedBox(width: 12),
                            Expanded(flex: 3, child: sidebar),
                          ],
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: mainColumn),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 280,
                            child: SingleChildScrollView(child: sidebar),
                          ),
                        ],
                      );
                    },
                  ),
                  if (draftForChip != null)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: _buildWardRoundDraftBar(colorScheme, draftForChip),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildWardRoundDraftBar(
    ColorScheme colorScheme,
    WardRoundNoteDraft draft,
  ) {
    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.edit_note_outlined,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ward round note in progress',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            TextButton(
              onPressed: _discardWardRoundDraft,
              child: Text(
                'Discard',
                style: TextStyle(color: colorScheme.onPrimaryContainer),
              ),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: () => _resumeOrOpenWardRoundNote(draft: draft),
              child: const Text('Resume'),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveEncounterPatientId() {
    final patient = _patient;
    final id = patient?.id?.trim();
    if (id != null && id.isNotEmpty) return id;
    final hospitalId = patient?.patientId.trim();
    if (hospitalId != null && hospitalId.isNotEmpty) return hospitalId;
    return _admission?.patientId.trim() ?? '';
  }

  void _openEncounter() {
    final encounterId = _admission?.encounterId?.trim();
    if (encounterId == null || encounterId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No encounter linked to this admission.')),
      );
      return;
    }

    final patientId = _resolveEncounterPatientId();
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Patient ID unavailable.')));
      return;
    }

    context.router.push(
      DoctorEncounterViewRoute(encounterId: encounterId, patientId: patientId),
    );
  }

  Widget _buildHeaderRow(
    BuildContext context, {
    required bool compact,
    required bool isDoctor,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    const title = 'Inpatient Patient View';
    final subtitle = widget.readOnly
        ? 'Read-only clinical record'
        : 'Bedside overview';

    final encounterId = _admission?.encounterId?.trim();
    final hasEncounter = encounterId != null && encounterId.isNotEmpty;

    final admission = _admission;
    final showDischargeSummary =
        admission != null &&
        (admission.isPendingBillingClearance ||
            admission.status.isDischarged ||
            admission.status.isDeceased ||
            (admission.dischargeSummary?.trim().isNotEmpty ?? false) ||
            admission.clinicallyDischargedAt != null);

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: compact ? WrapAlignment.start : WrapAlignment.end,
      children: [
        if (admission != null && showDischargeSummary)
          _headerPill(
            label: 'Discharge summary',
            icon: Icons.description_outlined,
            color: InpatientMetrics.iconIndigo,
            onPressed: () => showDischargeSummaryDialog(
              context: context,
              admission: admission,
              onOpenEncounter: hasEncounter ? _openEncounter : null,
            ),
          ),
        if (!widget.readOnly && isDoctor && hasEncounter)
          _headerPill(
            label: 'Encounter',
            icon: Icons.medical_information_outlined,
            color: InpatientMetrics.iconBlue,
            onPressed: _openEncounter,
          ),
        if (!widget.readOnly &&
            _admission != null &&
            _admission!.isPendingBillingClearance &&
            _admission!.nursesClearedAt == null)
          _headerPill(
            label: 'Clear for discharge',
            icon: Icons.check_circle_outline,
            color: InpatientMetrics.waitAmber,
            onPressed: _clearingNurses ? null : _clearNursesForDischarge,
          )
        else if (!widget.readOnly &&
            _admission != null &&
            _admission!.isActiveAdmission)
          _headerPill(
            label: 'Discharge',
            icon: Icons.logout,
            color: InpatientMetrics.waitGreen,
            onPressed: _attemptDischarge,
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: widget.readOnly
                ? scheme.onSurfaceVariant
                : InpatientMetrics.iconPurple,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.readOnly
                    ? Icons.visibility_outlined
                    : Icons.apartment_outlined,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                widget.readOnly ? 'Read-only view' : 'Inpatient module',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final titleBlock = Row(
      children: [
        IconButton(
          tooltip: 'Back',
          onPressed: () => context.router.maybePop(),
          icon: const Icon(Icons.arrow_back),
          visualDensity: VisualDensity.compact,
        ),
        const HeltySolidIcon(
          icon: Icons.hotel_outlined,
          color: InpatientMetrics.iconIndigo,
          size: 34,
          iconSize: 18,
          radius: AppTheme.radiusMd,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeltyEllipsisText(
                text: title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
              HeltyEllipsisText(
                text: subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [titleBlock, const SizedBox(height: 10), actions],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        const SizedBox(width: 12),
        actions,
      ],
    );
  }

  Widget _headerPill({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: _clearingNurses && label.startsWith('Clear')
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Icon(icon, size: 16),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
    );
  }

  Future<void> _attemptDischarge() async {
    final admission = _admission;
    if (admission == null) return;
    final payload = await showDischargeAdmissionDialog(context);
    if (payload == null || !mounted) return;
    try {
      final updated = await performClinicalDischarge(
        service: _admissionService,
        admissionId: admission.id,
        payload: payload,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(dischargeSuccessMessage(updated))));
      await _loadPatient();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Discharge failed: $e')));
    }
  }

  Future<void> _clearNursesForDischarge() async {
    final admission = _admission;
    if (admission == null || _clearingNurses) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear for discharge'),
        content: Text(
          admission.billingClearedAt == null
              ? 'Record nurse clearance for ${admission.patient.displayName}? '
                    'Discharge finalizes when billing clearance is also complete.'
              : 'Record nurse clearance for ${admission.patient.displayName}? '
                    'The patient will be finalized to OPD.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _clearingNurses = true);
    try {
      final updated = await _admissionService.nursesClearance(admission.id);
      if (!mounted) return;
      final finalized =
          updated.status.isDischarged || updated.status.isDeceased;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            finalized
                ? 'Nurse clearance recorded. Patient moved to OPD.'
                : 'Nurse clearance recorded. Awaiting billing clearance.',
          ),
        ),
      );
      await _loadPatient();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Nurse clearance failed: $e')));
    } finally {
      if (mounted) setState(() => _clearingNurses = false);
    }
  }

  Widget _buildDischargeClearanceBanner(AdmissionModel admission) {
    if (!admission.isPendingBillingClearance) {
      return const SizedBox.shrink();
    }

    final awaitingPayment = admission.billingClearedAt == null;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bg = awaitingPayment
        ? scheme.errorContainer
        : scheme.tertiaryContainer;
    final fg = awaitingPayment
        ? scheme.onErrorContainer
        : scheme.onTertiaryContainer;
    final message = awaitingPayment
        ? 'Discharged — awaiting payment'
        : 'Billing cleared — awaiting nurse clearance';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                awaitingPayment
                    ? Icons.payments_outlined
                    : Icons.local_hospital_outlined,
                color: fg,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (!widget.readOnly &&
                  admission.nursesClearedAt == null &&
                  !awaitingPayment)
                FilledButton(
                  onPressed: _clearingNurses ? null : _clearNursesForDischarge,
                  child: const Text('Clear for discharge'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPatientHeader(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (_loadingPatient) {
      return SectionCard(
        title: 'Patient',
        subtitle: 'Loading patient details...',
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
      return SectionCard(
        title: 'Patient',
        subtitle: 'Unable to load patient details',
        actions: [
          TextButton.icon(
            onPressed: _loadPatient,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
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
          ],
        ),
      );
    }

    final patient = _patient;
    final admission = _admission;

    if (patient == null || admission == null) {
      return SectionCard(
        title: 'Patient',
        subtitle: 'No patient data available',
        actions: [
          TextButton.icon(
            onPressed: _loadPatient,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
        child: Row(
          children: [
            Icon(Icons.info_outline, color: scheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Waiting for backend response...',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final nameParts = <String>[
      if (patient.title.trim().isNotEmpty) patient.title.trim(),
      patient.firstName.trim(),
      patient.surname.trim(),
    ].where((s) => s.isNotEmpty).toList();
    final name = nameParts.isEmpty ? 'Unknown patient' : nameParts.join(' ');

    final ageLabel = DateFormatter.patientAgeFromDob(patient.dob);
    final genderLabel = patient.gender.trim().isEmpty
        ? '—'
        : patient.gender.trim();
    final ageGender = '$ageLabel, $genderLabel';

    final hospitalNumber = patient.patientId.isNotEmpty
        ? patient.patientId
        : '—';

    final ward = _wardDisplay(admission);
    final bed = admission.bedPreference?.trim().isNotEmpty == true
        ? admission.bedPreference!
        : '—';
    final doctor = _attendingDoctorDisplay(admission);
    final diagnosis = _diagnosisDisplay(admission);

    final admissionInstant = admission.displayAdmissionInstant;
    final admissionDateStr = admissionInstant != null
        ? DateFormatter.fullDate(admissionInstant)
        : '—';

    String? lengthOfStay;
    if (admissionInstant != null) {
      final d = DateFormatter.calendarDaysSince(admissionInstant);
      lengthOfStay = d == 1 ? '1 day' : '$d days';
    }

    final allergies = patient.allergies
        .map((a) => a.name.trim())
        .where((n) => n.isNotEmpty)
        .toList();

    final st = admission.status.toUpperCase();
    final codeStatus = (st == 'ACTIVE' || st == 'ADMITTED')
        ? 'Full Code'
        : (admission.status.isNotEmpty ? admission.status : '—');

    final riskFlags = <String>[
      if (admission.isolationRequired) 'Isolation required',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildDischargeClearanceBanner(admission),
        PatientHeaderCard(
          patientName: name,
          ageGender: ageGender,
          hospitalNumber: hospitalNumber,
          ward: ward,
          bedNumber: bed,
          attendingDoctor: doctor,
          diagnosis: diagnosis,
          admissionDate: admissionDateStr,
          createdBy: admission.createdByName,
          lengthOfStay: lengthOfStay,
          allergies: allergies,
          codeStatus: codeStatus,
          riskFlags: riskFlags,
          avatarUrl: patient.avatarUrl,
          firstName: patient.firstName,
          surname: patient.surname,
        ),
      ],
    );
  }

  String _wardDisplay(AdmissionModel a) {
    final w = a.ward?.trim();
    if (w != null && w.isNotEmpty) return w;
    final n = a.wardEntity?['name']?.toString().trim();
    if (n != null && n.isNotEmpty) return n;
    return '—';
  }

  String _attendingDoctorDisplay(AdmissionModel a) {
    final display = a.attendingDoctor?.displayName ?? '';
    if (display.isNotEmpty) return display;
    return '—';
  }

  String _diagnosisDisplay(AdmissionModel a) {
    for (final s in [
      a.primaryDiagnosis,
      a.provisionalDiagnosis,
      a.admissionReason,
      a.reason,
    ]) {
      final t = s?.trim();
      if (t != null && t.isNotEmpty) return t;
    }
    return '—';
  }

  Widget _buildTabContentShell(
    ColorScheme colorScheme, {
    required Widget child,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(color: colorScheme.surface),
        child: Padding(padding: const EdgeInsets.all(4.0), child: child),
      ),
    );
  }

  Widget _buildTabsStrip(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labels = InpatientUiTabs.labels;

    final tabPadding = EdgeInsets.symmetric(
      horizontal: compact ? 12 : 14,
      vertical: compact ? 10 : 8,
    );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.all(4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(labels.length, (index) {
            final bool selected = _uiTabIndex == index;
            final label = labels[index];

            return Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => _selectUiTab(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  alignment: Alignment.center,
                  padding: tabPadding,
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
