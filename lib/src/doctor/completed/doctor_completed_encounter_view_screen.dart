import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/doctor/completed/edit_history/encounter_edit_history_sheet.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounter_scope.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/encounter_edit_meta.dart';
import 'package:helty/src/doctor/specialty/encounter_specialty_forms_panel.dart';
import 'package:helty/src/doctor/encounter/widgets/doctor_encounter_patient_header.dart';
import 'package:helty/src/models/encounter_model.dart';
import 'package:helty/src/paitients/patient_model.dart';
import 'package:helty/src/paitients/patient_service.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/services/staff_service.dart';

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
  final _staffService = StaffService();

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
      final enc = await _encounterService.getById(
        widget.encounterId,
        expand: const ['specialtyModules', 'clinicalSections'],
      );
      EncounterModel? encounter = enc;
      if (enc != null &&
          (enc.doctorDisplayName?.trim().isEmpty ?? true) &&
          enc.doctorId.trim().isNotEmpty) {
        try {
          final doctor = await _staffService.getStaffById(enc.doctorId.trim());
          encounter = enc.copyWith(doctorDisplayName: doctor.fullName);
        } catch (_) {}
      }
      Patient? patient;
      try {
        patient = await _patientService.getPatientById(widget.patientId);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _encounter = encounter;
        _patient = patient;
        _loading = false;
        if (encounter == null) _error = 'Encounter not found.';
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
                  color: colorScheme.onSurfaceVariant,
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
      onRefresh: _load,
      child: AutoTabsRouter(
        routes: const [
          CompletedEncounterSummaryTab(),
          CompletedEncounterHistoryTab(),
          CompletedEncounterExaminationTab(),
          CompletedEncounterNotesTab(),
          CompletedEncounterDiagnosisTab(),
          CompletedEncounterLabsTab(),
          CompletedEncounterImagingTab(),
          CompletedEncounterSurgeryTab(),
          CompletedEncounterPrescriptionsTab(),
          CompletedEncounterAppointmentsTab(),
          CompletedEncounterFollowUpTab(),
        ],
        builder: (context, child) {
          final tabsRouter = AutoTabsRouter.of(context);
          final name = patient != null
              ? patient.displayName
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
                ..._buildEditMetaActions(context, encounter),
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
              child: ResponsiveBody(
                maxWidth: 1440,
                builder: (context, bp) => Column(
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
                      avatarUrl: patient?.avatarUrl,
                      firstName: patient?.firstName,
                      surname: patient?.surname,
                    ),
                    if (encounter.editMeta != null) ...[
                      const SizedBox(height: 12),
                      _buildEditMetaBanner(context, encounter.editMeta!),
                    ],
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
          );
        },
      ),
    );
  }

  List<Widget> _buildEditMetaActions(
    BuildContext context,
    EncounterModel encounter,
  ) {
    final meta = encounter.editMeta;
    if (meta == null) return [];

    return [
      if (meta.hasEdits)
        Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Center(
            child: Tooltip(
              message: _editedTooltip(meta),
              child: Chip(
                label: Text(
                  meta.editCount > 1
                      ? 'Edited (${meta.editCount})'
                      : 'Edited',
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ),
      TextButton.icon(
        onPressed: () => EncounterEditHistorySheet.show(
          context,
          encounterId: widget.encounterId,
          encounter: encounter,
        ),
        icon: const Icon(Icons.history, size: 18),
        label: const Text('Edit history'),
      ),
      if (meta.canEdit)
        FilledButton.icon(
          onPressed: () async {
            await context.router.push(
              DoctorEncounterViewRoute(
                encounterId: widget.encounterId,
                patientId: widget.patientId,
                amendMode: !meta.isSharedInpatientEncounter,
              ),
            );
            if (mounted) await _load();
          },
          icon: const Icon(Icons.edit, size: 18),
          label: Text(
            meta.isSharedInpatientEncounter ? 'Edit chart' : 'Amend',
          ),
        ),
    ];
  }

  String _editedTooltip(EncounterEditMeta meta) {
    final parts = <String>[
      'Amended ${meta.editCount} time(s)',
    ];
    if (meta.lastEditedAt != null) {
      parts.add(
        'Last: ${DateFormatter.dateTime(meta.lastEditedAt!)}',
      );
    }
    return parts.join('\n');
  }

  Widget _buildEditMetaBanner(BuildContext context, EncounterEditMeta meta) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    String message;
    if (meta.canEditAsCoveringPhysician) {
      message =
          'You may edit this inpatient chart as covering physician while '
          'the admission is active.';
    } else if (meta.isSharedInpatientEncounter && meta.canEdit) {
      message = meta.hasEdits
          ? 'This inpatient chart has post-admission edits. '
              'Use Edit history to review prior versions.'
          : 'This is the shared inpatient chart for an active admission.';
    } else if (meta.hasEdits) {
      message =
          'This encounter has been amended after completion. '
          'Use Edit history to review prior versions.';
    } else {
      message =
          'You can amend this completed encounter if corrections are needed.';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 20, color: scheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
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
      'Surgery',
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
                          : scheme.onSurface,
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
