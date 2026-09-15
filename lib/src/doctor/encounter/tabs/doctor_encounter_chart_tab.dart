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
import 'package:helty/src/doctor/encounter/widgets/encounter_ui_tabs.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_chart_table.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';

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
    _ChartJumpTarget(
      spec: EncounterUiTabs.history,
      label: 'Histories',
      key: _historyKey,
    ),
    _ChartJumpTarget(spec: EncounterUiTabs.examination, key: _examinationKey),
    _ChartJumpTarget(spec: EncounterUiTabs.diagnosis, key: _diagnosisKey),
    _ChartJumpTarget(spec: EncounterUiTabs.imaging, key: _imagingKey),
    _ChartJumpTarget(spec: EncounterUiTabs.surgery, key: _surgeryKey),
    _ChartJumpTarget(spec: EncounterUiTabs.prescription, key: _prescriptionKey),
    _ChartJumpTarget(spec: EncounterUiTabs.notes, key: _notesKey),
    _ChartJumpTarget(spec: EncounterUiTabs.admission, key: _admissionKey),
    _ChartJumpTarget(spec: EncounterUiTabs.followUp, key: _followUpKey),
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

    return PrimaryScrollController.none(
      child: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          primary: false,
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const InpatientTabToolbar(
                icon: Icons.folder_shared_outlined,
                iconColor: InpatientMetrics.iconPurple,
                title: 'Chart',
                subtitle: 'Full encounter record',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final jump in _jumps)
                    EncounterJumpChip(
                      spec: jump.spec,
                      label: jump.label,
                      onPressed: () => _jumpTo(jump.key),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              _ChartSection(
                title: 'Histories',
                icon: Icons.history,
                iconColor: InpatientMetrics.iconBlue,
                anchorKey: _historyKey,
                child: const DoctorEncounterHistoryTab(
                  key: ValueKey('chart-history'),
                  embedded: true,
                ),
              ),
              _ChartSection(
                title: 'Examination',
                icon: Icons.accessibility_new_outlined,
                iconColor: InpatientMetrics.iconTeal,
                anchorKey: _examinationKey,
                child: const DoctorEncounterExaminationTab(
                  key: ValueKey('chart-examination'),
                  embedded: true,
                ),
              ),
              _ChartSection(
                title: 'Diagnosis',
                icon: Icons.medical_information_outlined,
                iconColor: InpatientMetrics.iconPurple,
                anchorKey: _diagnosisKey,
                child: const DoctorEncounterDiagnosisTab(
                  key: ValueKey('chart-diagnosis'),
                  embedded: true,
                ),
              ),
              _ChartSection(
                title: 'Imaging',
                icon: Icons.photo_camera_outlined,
                iconColor: InpatientMetrics.iconIndigo,
                anchorKey: _imagingKey,
                child: const DoctorEncounterImagingTab(
                  key: ValueKey('chart-imaging'),
                  embedded: true,
                ),
              ),
              _ChartSection(
                title: 'Surgery',
                icon: Icons.local_hospital_outlined,
                iconColor: InpatientMetrics.waitRed,
                anchorKey: _surgeryKey,
                child: const DoctorEncounterSurgeryTab(
                  key: ValueKey('chart-surgery'),
                  embedded: true,
                ),
              ),
              _ChartSection(
                title: 'Prescription',
                icon: Icons.medication_outlined,
                iconColor: InpatientMetrics.waitAmber,
                anchorKey: _prescriptionKey,
                child: const DoctorEncounterPrescriptionTab(
                  key: ValueKey('chart-prescription'),
                  embedded: true,
                ),
              ),
              _ChartSection(
                title: 'Notes',
                icon: Icons.notes_outlined,
                iconColor: InpatientMetrics.iconPink,
                anchorKey: _notesKey,
                child: const DoctorEncounterNotesTab(
                  key: ValueKey('chart-notes'),
                  embedded: true,
                ),
              ),
              _ChartSection(
                title: 'Admission',
                icon: Icons.hotel_outlined,
                iconColor: InpatientMetrics.iconIndigo,
                anchorKey: _admissionKey,
                child: const DoctorEncounterAdmissionTab(
                  key: ValueKey('chart-admission'),
                  embedded: true,
                ),
              ),
              _ChartSection(
                title: 'Follow-up',
                icon: Icons.event_available_outlined,
                iconColor: InpatientMetrics.waitGreen,
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
  const _ChartJumpTarget({required this.spec, required this.key, this.label});

  final EncounterTabSpec spec;
  final GlobalKey key;
  final String? label;
}

class _ChartSection extends StatelessWidget {
  const _ChartSection({
    required this.title,
    required this.child,
    required this.icon,
    required this.iconColor,
    this.anchorKey,
  });

  final String title;
  final Widget child;
  final IconData icon;
  final Color iconColor;
  final Key? anchorKey;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: RepaintBoundary(
        child: SectionCard(
          title: title,
          icon: icon,
          iconColor: iconColor,
          child: KeyedSubtree(key: anchorKey, child: child),
        ),
      ),
    );
  }
}
