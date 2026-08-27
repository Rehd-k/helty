import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_admission_tab.dart';
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_diagnosis_tab.dart';
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_examination_tab.dart';
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_follow_up_tab.dart';
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_history_tab.dart';
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_imaging_tab.dart';
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_notes_tab.dart';
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_prescription_tab.dart';
import 'package:helty/src/doctor/encounter/tabs/doctor_encounter_surgery_tab.dart';

@RoutePage()
class DoctorEncounterChartTab extends StatefulWidget {
  const DoctorEncounterChartTab({super.key});

  @override
  State<DoctorEncounterChartTab> createState() =>
      _DoctorEncounterChartTabState();
}

class _DoctorEncounterChartTabState extends State<DoctorEncounterChartTab>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();
  final _historyKey = GlobalKey();
  final _examinationKey = GlobalKey();
  final _diagnosisKey = GlobalKey();
  final _imagingKey = GlobalKey();
  final _surgeryKey = GlobalKey();
  final _prescriptionKey = GlobalKey();
  final _notesKey = GlobalKey();
  final _admissionKey = GlobalKey();
  final _followUpKey = GlobalKey();

  @override
  bool get wantKeepAlive => true;

  List<_ChartJumpTarget> get _jumps => [
    _ChartJumpTarget(label: 'Histories', key: _historyKey),
    _ChartJumpTarget(label: 'Examination', key: _examinationKey),
    _ChartJumpTarget(label: 'Diagnosis', key: _diagnosisKey),
    _ChartJumpTarget(label: 'Imaging', key: _imagingKey),
    _ChartJumpTarget(label: 'Surgery', key: _surgeryKey),
    _ChartJumpTarget(label: 'Prescription', key: _prescriptionKey),
    _ChartJumpTarget(label: 'Notes', key: _notesKey),
    _ChartJumpTarget(label: 'Admission', key: _admissionKey),
    _ChartJumpTarget(label: 'Follow-up', key: _followUpKey),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _jumpTo(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      alignment: 0.02,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return PrimaryScrollController.none(
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          primary: false,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final jump in _jumps)
                    ActionChip(
                      label: Text(jump.label),
                      onPressed: () => _jumpTo(jump.key),
                      side: BorderSide(
                        color: scheme.outline.withValues(alpha: 0.35),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              _ChartSection(
                title: 'Histories',
                anchorKey: _historyKey,
                child: const DoctorEncounterHistoryTab(
                  key: ValueKey('chart-history'),
                  embedded: true,
                ),
              ),
              _ChartSection(
                title: 'Examination',
                anchorKey: _examinationKey,
                child: const DoctorEncounterExaminationTab(
                  key: ValueKey('chart-examination'),
                  embedded: true,
                ),
              ),
              _ChartSection(
                title: 'Diagnosis',
                anchorKey: _diagnosisKey,
                child: const DoctorEncounterDiagnosisTab(
                  key: ValueKey('chart-diagnosis'),
                  embedded: true,
                ),
              ),
              _ChartSection(
                title: 'Imaging',
                anchorKey: _imagingKey,
                child: const DoctorEncounterImagingTab(
                  key: ValueKey('chart-imaging'),
                  embedded: true,
                ),
              ),
              _ChartSection(
                title: 'Surgery',
                anchorKey: _surgeryKey,
                child: const DoctorEncounterSurgeryTab(
                  key: ValueKey('chart-surgery'),
                  embedded: true,
                ),
              ),
              _ChartSection(
                title: 'Prescription',
                anchorKey: _prescriptionKey,
                child: const DoctorEncounterPrescriptionTab(
                  key: ValueKey('chart-prescription'),
                  embedded: true,
                ),
              ),
              _ChartSection(
                title: 'Notes',
                anchorKey: _notesKey,
                child: const DoctorEncounterNotesTab(
                  key: ValueKey('chart-notes'),
                  embedded: true,
                ),
              ),
              _ChartSection(
                title: 'Admission',
                anchorKey: _admissionKey,
                child: const DoctorEncounterAdmissionTab(
                  key: ValueKey('chart-admission'),
                  embedded: true,
                ),
              ),
              _ChartSection(
                title: 'Follow-up',
                anchorKey: _followUpKey,
                child: const DoctorEncounterFollowUpTab(
                  key: ValueKey('chart-follow-up'),
                  embedded: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartJumpTarget {
  const _ChartJumpTarget({required this.label, required this.key});

  final String label;
  final GlobalKey key;
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.title,
    required this.child,
    this.anchorKey,
  });

  final String title;
  final Widget child;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              key: anchorKey,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Divider(color: scheme.outlineVariant),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
