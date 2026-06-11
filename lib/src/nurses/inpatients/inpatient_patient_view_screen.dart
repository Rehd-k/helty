import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/patient_header_card.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/auth/nursing_permissions.dart';
import 'package:helty/src/providers/auth_provider.dart';

import '../../admissions/discharge_admission_dialog.dart';
import '../../helper/date.formatter.dart';
import '../../../app_router.gr.dart';
import '../../models/admission_model.dart';
import '../../models/medication_order_model.dart';
import '../../services/admission_service.dart';

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

  @override
  void initState() {
    super.initState();
    _loadPatient();
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
          InpatientAlertsRoute(),
          InpatientHandoverRoute(),
        ],
        builder: (context, child) {
          final tabsRouter = AutoTabsRouter.of(context);

          return Scaffold(
            backgroundColor: colorScheme.surface,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bool compact =
                      constraints.maxWidth < kInpatientCompactBreakpoint;
                  final double horizontalPadding = compact
                      ? 16
                      : (constraints.maxWidth > 1400 ? 32 : 20);
                  final double verticalPadding = compact ? 16 : 24;

                  final tabContent = _buildTabContentShell(
                    colorScheme,
                    child: child,
                  );

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: kInpatientContentMaxWidth,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          verticalPadding,
                          horizontalPadding,
                          verticalPadding,
                        ),
                        child: compact
                            ? CustomScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                slivers: [
                                  SliverToBoxAdapter(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        _buildHeaderRow(
                                          context,
                                          compact: compact,
                                        ),
                                        SizedBox(height: compact ? 12 : 16),
                                        _buildPatientHeader(context),
                                        SizedBox(height: compact ? 16 : 20),
                                      ],
                                    ),
                                  ),
                                  SliverPersistentHeader(
                                    pinned: true,
                                    delegate: _PinnedTabStripDelegate(
                                      height: _pinnedTabStripHeight(compact),
                                      color: colorScheme.surface,
                                      child: _buildTabsStrip(
                                        context,
                                        tabsRouter,
                                        compact: compact,
                                      ),
                                    ),
                                  ),
                                  SliverFillRemaining(
                                    hasScrollBody: true,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: tabContent,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _buildHeaderRow(context, compact: compact),
                                  SizedBox(height: compact ? 12 : 16),
                                  _buildPatientHeader(context),
                                  SizedBox(height: compact ? 16 : 20),
                                  _buildTabsStrip(
                                    context,
                                    tabsRouter,
                                    compact: compact,
                                  ),
                                  SizedBox(height: compact ? 12 : 16),
                                  Expanded(child: tabContent),
                                ],
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context, {required bool compact}) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    const title = 'Inpatient Patient View';
    const subtitle = 'Bedside overview';

    final titleStyle = theme.textTheme.headlineSmall?.copyWith(
      fontWeight: FontWeight.bold,
      color: scheme.onSurface,
    );
    final subtitleStyle = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurface.withValues(alpha: 0.7),
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: compact ? WrapAlignment.start : WrapAlignment.end,
      children: [
        FilledButton.tonalIcon(
          onPressed: _admission == null ? null : _attemptDischarge,
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Discharge'),
        ),
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
                Icons.monitor_heart_outlined,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Inpatient module',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final titleBlock = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: titleStyle,
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: subtitleStyle,
        ),
      ],
    );

    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [titleBlock, const SizedBox(height: 12), actions],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: titleBlock),
        actions,
      ],
    );
  }

  Future<void> _attemptDischarge() async {
    final admission = _admission;
    if (admission == null) return;
    final payload = await showDischargeAdmissionDialog(context);
    if (payload == null || !mounted) return;
    try {
      await _admissionService.dischargeAdmission(
        admission.id,
        outcome: payload.outcome,
        dischargeSummary: payload.dischargeSummary,
        otherImportantNotes: payload.otherImportantNotes,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient discharged successfully')),
      );
      await _loadPatient();
    } on AdmissionDischargeBlockedException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Discharge failed: $e')));
    }
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
                  color: scheme.onSurface.withValues(alpha: 0.75),
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

    return PatientHeaderCard(
      patientName: name,
      ageGender: ageGender,
      hospitalNumber: hospitalNumber,
      ward: ward,
      bedNumber: bed,
      attendingDoctor: doctor,
      diagnosis: diagnosis,
      admissionDate: admissionDateStr,
      lengthOfStay: lengthOfStay,
      allergies: allergies,
      codeStatus: codeStatus,
      riskFlags: riskFlags,
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

  Widget _buildTabsStrip(
    BuildContext context,
    TabsRouter tabsRouter, {
    required bool compact,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final labels = [
      'Overview',
      'Vitals',
      'Medications',
      'IV',
      'I&O',
      'Notes',
      'Wound',
      'Ward round',
      'Procedures',
      'Care Plan',
      'Monitoring',
      'Lab Results',
      'Alerts',
      'Handover',
    ];

    final tabPadding = EdgeInsets.symmetric(
      horizontal: compact ? 12 : 16,
      vertical: compact ? 14 : 8,
    );

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
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => tabsRouter.setActiveIndex(index),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: compact ? 48 : 0),
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
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? scheme.onPrimary
                              : scheme.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
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

/// Vertical extent of [_InpatientPatientViewScreenState._buildTabsStrip] for
/// [SliverPersistentHeader] — must stay in sync with tab chip min heights.
double _pinnedTabStripHeight(bool compact) {
  return compact ? 56 : 52;
}

class _PinnedTabStripDelegate extends SliverPersistentHeaderDelegate {
  _PinnedTabStripDelegate({
    required this.height,
    required this.color,
    required this.child,
  });

  final double height;
  final Color color;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: color,
      elevation: overlapsContent ? 1 : 0,
      shadowColor: Colors.black26,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabStripDelegate oldDelegate) {
    return oldDelegate.height != height ||
        oldDelegate.color != color ||
        oldDelegate.child != child;
  }
}
