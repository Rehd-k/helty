import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounter_scope.dart';
import 'package:helty/src/doctor/specialty/encounter_specialty_forms_panel.dart';
import 'package:helty/src/doctor/encounter/widgets/doctor_encounter_patient_header.dart';
import 'package:helty/src/models/encounter_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';
import 'package:helty/src/services/encounter_service.dart';

const double _contentMaxWidth = 1440;

@RoutePage()
class DoctorCompletedEncounterViewScreen extends StatefulWidget {
  final String encounterId;
  final String patientId;

  const DoctorCompletedEncounterViewScreen({
    super.key,
    required this.encounterId,
    required this.patientId,
  });

  @override
  State<DoctorCompletedEncounterViewScreen> createState() =>
      _DoctorCompletedEncounterViewScreenState();
}

class _DoctorCompletedEncounterViewScreenState
    extends State<DoctorCompletedEncounterViewScreen> {
  final _encounterService = EncounterService();
  final _patientService = PatientService();

  EncounterModel? _encounter;
  Patient? _patient;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final enc = await _encounterService.getById(widget.encounterId);
      Patient? patient;
      try {
        patient = await _patientService.getPatientById(widget.patientId);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _encounter = enc;
        _patient = patient;
        _loading = false;
        if (enc == null) _error = 'Encounter not found.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_loading && _encounter == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Completed encounter'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.router.maybePop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Loading encounter…',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null && _encounter == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text('Completed encounter'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.router.maybePop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(_error!, textAlign: TextAlign.center),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final encounter = _encounter!;
    final patient = _patient;

    return CompletedEncounterScope(
      encounter: encounter,
      patient: patient,
      child: AutoTabsRouter(
        routes: const [
          CompletedEncounterSummaryTab(),
          CompletedEncounterHistoryTab(),
          CompletedEncounterExaminationTab(),
          CompletedEncounterNotesTab(),
          CompletedEncounterDiagnosisTab(),
          CompletedEncounterLabsTab(),
          CompletedEncounterImagingTab(),
          CompletedEncounterPrescriptionsTab(),
          CompletedEncounterAppointmentsTab(),
          CompletedEncounterFollowUpTab(),
        ],
        builder: (context, child) {
          final tabsRouter = AutoTabsRouter.of(context);
          final name = patient != null
              ? '${patient.title} ${patient.firstName} ${patient.surname}'
              : 'Patient ${widget.patientId}';
          final ageYears = patient != null
              ? DateTime.now().year - patient.dob.year
              : null;
          final ageGender = [
            if (ageYears != null) '$ageYears yrs',
            if (patient != null && patient.gender.isNotEmpty) patient.gender,
          ].join(' • ');
          final hospitalNumber = patient?.patientId ?? widget.patientId;

          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              title: const Text('Completed encounter'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.router.maybePop(),
              ),
              actions: [
                IconButton(
                  tooltip: 'Specialty forms',
                  icon: const Icon(Icons.grid_view_rounded),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      showDragHandle: true,
                      builder: (ctx) => DraggableScrollableSheet(
                        expand: false,
                        initialChildSize: 0.92,
                        minChildSize: 0.5,
                        maxChildSize: 0.98,
                        builder: (_, __) => EncounterSpecialtyFormsPanel(
                          encounterId: widget.encounterId,
                          patientId: widget.patientId,
                          readOnly: true,
                          title: 'Specialty forms (read-only)',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DoctorEncounterPatientHeader(
                          patientName: name.trim(),
                          ageGender: ageGender,
                          hospitalNumber: hospitalNumber,
                          allergies: const [],
                          chronicConditions: const [],
                          pastAdmissionsCount: 0,
                          insurance: patient?.hmo,
                        ),
                        const SizedBox(height: 16),
                        _buildTabsStrip(context, tabsRouter, theme, colorScheme),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colorScheme.surface,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: child,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabsStrip(
    BuildContext context,
    TabsRouter tabsRouter,
    ThemeData theme,
    ColorScheme scheme,
  ) {
    const labels = [
      'Summary',
      'History',
      'Examination',
      'Notes',
      'Diagnosis',
      'Labs',
      'Imaging',
      'Rx',
      'Appointments',
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
            final selected = tabsRouter.activeIndex == index;
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
                    labels[index],
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
