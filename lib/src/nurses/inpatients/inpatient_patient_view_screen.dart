import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/patient_header_card.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';

import '../../helper/date.formatter.dart';
import '../../../app_router.gr.dart';

const double _contentMaxWidth = 1440;

@RoutePage()
class InpatientPatientViewScreen extends StatefulWidget {
  final String patientId;
  final String? admissionId;
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
    required this.patientId,
    this.admissionId,
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
  State<InpatientPatientViewScreen> createState() =>
      _InpatientPatientViewScreenState();
}

class _InpatientPatientViewScreenState
    extends State<InpatientPatientViewScreen> {
  final _patientService = PatientService();

  Patient? _patient;
  bool _loadingPatient = false;
  String? _patientError;

  @override
  void initState() {
    super.initState();
    _loadPatient();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load patient: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InpatientViewScope(
      patientId: widget.patientId,
      admissionId: widget.admissionId,
      child: AutoTabsRouter(
        routes: [
          InpatientOverviewRoute(),
          InpatientVitalsRoute(),
          InpatientMedicationsRoute(),
          InpatientIVRoute(),
          InpatientIORoute(),
          InpatientNotesRoute(),
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
                );
              },
            ),
          ),
        );
        },
      ),
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final title = 'Inpatient Patient View';
    final subtitle = 'Bedside overview for nurses';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
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
                'Inpatient module • Nurses',
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

    final ward = widget.ward ?? '—';
    final bed = widget.bedNumber ?? '—';
    final doctor = widget.attendingDoctor ?? '—';
    final diagnosis = widget.diagnosis ?? '—';

    final admissionDateStr = widget.admissionDate != null
        ? DateFormatter.fullDate(widget.admissionDate!)
        : '—';

    final allergies = widget.allergies ?? const [];
    final codeStatus = widget.codeStatus ?? 'Full Code';
    final riskFlags = widget.riskFlags ?? const [];

    return PatientHeaderCard(
      patientName: name.trim(),
      ageGender: ageGender,
      hospitalNumber: hospitalNumber,
      ward: ward,
      bedNumber: bed,
      attendingDoctor: doctor,
      diagnosis: diagnosis,
      admissionDate: admissionDateStr,
      allergies: allergies,
      codeStatus: codeStatus,
      riskFlags: riskFlags,
    );
  }

  Widget _buildTabsStrip(BuildContext context, TabsRouter tabsRouter) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final labels = [
      'Overview',
      'Vitals',
      'Medications',
      'IV',
      'I&O',
      'Notes',
      'Ward round',
      'Procedures',
      'Care Plan',
      'Monitoring',
      'Lab Results',
      'Alerts',
      'Handover',
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
