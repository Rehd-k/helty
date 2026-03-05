import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/doctor/encounter/widgets/doctor_encounter_patient_header.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';

const double _contentMaxWidth = 1440;

/// Provides encounterId and patientId to tab content.
class EncounterScope extends InheritedWidget {
  const EncounterScope({
    super.key,
    required this.encounterId,
    required this.patientId,
    required super.child,
  });

  final String encounterId;
  final String patientId;

  static EncounterScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<EncounterScope>();

  @override
  bool updateShouldNotify(EncounterScope old) =>
      encounterId != old.encounterId || patientId != old.patientId;
}

@RoutePage()
class DoctorEncounterViewScreen extends StatefulWidget {
  final String encounterId;
  final String patientId;

  const DoctorEncounterViewScreen({
    super.key,
    required this.encounterId,
    required this.patientId,
  });

  @override
  State<DoctorEncounterViewScreen> createState() =>
      _DoctorEncounterViewScreenState();
}

class _DoctorEncounterViewScreenState extends State<DoctorEncounterViewScreen> {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load patient: $e')),
        );
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
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            body: SafeArea(
              child: LayoutBuilder(
              builder: (context, constraints) {
                final double horizontalPadding =
                    constraints.maxWidth > 1400 ? 32 : 20;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
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
          ),
        );
      },
    );
  }

  Widget _buildHeaderRow(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Encounter',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'OPD encounter view',
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
              Icon(Icons.medical_services_outlined, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Text(
                'Doctor module • OPD',
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
            child: CircularProgressIndicator(strokeWidth: 2.6, color: scheme.primary),
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
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.error),
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
    final ageYears =
        patient != null ? DateTime.now().year - patient.dob.year : null;
    final ageGender = [
      if (ageYears != null) '$ageYears yrs',
      if (patient != null && patient.gender.isNotEmpty) patient.gender,
    ].join(' • ');
    final hospitalNumber =
        patient != null ? patient.patientId : widget.patientId;
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
