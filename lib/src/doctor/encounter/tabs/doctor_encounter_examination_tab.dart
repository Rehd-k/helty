import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/doctor/encounter/questionnaire/encounter_narrative_compiler.dart';
import 'package:helty/src/doctor/encounter/questionnaire/encounter_question_models.dart';
import 'package:helty/src/doctor/encounter/questionnaire/encounter_questionnaire_section.dart';
import 'package:helty/src/doctor/encounter/questionnaire/examination_questionnaire_defs.dart';
import 'package:helty/src/services/encounter_service.dart';

@RoutePage()
class DoctorEncounterExaminationTab extends StatefulWidget {
  const DoctorEncounterExaminationTab({super.key});

  @override
  State<DoctorEncounterExaminationTab> createState() =>
      _DoctorEncounterExaminationTabState();
}

class _DoctorEncounterExaminationTabState
    extends State<DoctorEncounterExaminationTab> {
  final _encounterService = EncounterService();
  late final TextEditingController _additionalNotesCtrl;

  final _answers = <String, QuestionnaireAnswers>{};
  final _savedNotes = <String, String?>{};
  final _directEditControllers = <String, TextEditingController>{};
  final _useDirectEditOnSave = <String, bool>{};

  bool _loading = false;
  bool _loaded = false;
  Map<String, String?> _vitals = {};
  bool _initialLoadScheduled = false;

  @override
  void initState() {
    super.initState();
    _additionalNotesCtrl = TextEditingController();
    for (final section in examinationQuestionnaireSections) {
      _answers[section.id] = {};
      _directEditControllers[section.id] = TextEditingController();
      _useDirectEditOnSave[section.id] = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialLoadScheduled) {
      _initialLoadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadDraft();
          _applyVitalsFromScope();
        }
      });
    }
  }

  void _applyVitalsFromScope() {
    final scope = EncounterScope.of(context);
    final v = scope?.patientVitals;
    if (v == null) return;
    setState(() {
      _vitals = {
        if (v.systolic != null || v.diastolic != null)
          'BP': '${v.systolic ?? '—'}/${v.diastolic ?? '—'}',
        if (v.pulseRate != null) 'HR': '${v.pulseRate}',
        if (v.temperature != null) 'Temp': '${v.temperature}°C',
        if (v.spo2 != null) 'SpO2': '${v.spo2}%',
        if (v.height != null) 'Height': '${v.height} cm',
        if (v.weight != null) 'Weight': '${v.weight} kg',
        if (v.bmi != null) 'BMI': v.bmi!.toStringAsFixed(1),
      };
    });
  }

  @override
  void dispose() {
    for (final c in _directEditControllers.values) {
      c.dispose();
    }
    _additionalNotesCtrl.dispose();
    super.dispose();
  }

  void _applyLoadedExaminationNotes(String? notes) {
    final parsed = parseExaminationNotes(notes);
    for (final section in examinationQuestionnaireSections) {
      final text = parsed[section.id];
      _savedNotes[section.id] = text;
      if (text != null && text.isNotEmpty) {
        _directEditControllers[section.id]?.text = text;
        _useDirectEditOnSave[section.id] = true;
      }
    }
    if (notes != null && notes.trim().isNotEmpty) {
      final labeledKeys = parsed.keys.toSet();
      if (labeledKeys.isEmpty) {
        _additionalNotesCtrl.text = notes.trim();
      }
    }
  }

  String? _noteForSection(EncounterSectionDef section) {
    return resolveSectionNote(
      section: section,
      answers: _answers[section.id] ?? {},
      directEditController: _directEditControllers[section.id],
      useDirectEdit: _useDirectEditOnSave[section.id] ?? false,
    );
  }

  Future<void> _loadDraft() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    setState(() => _loading = true);
    try {
      final enc = await _encounterService.getById(scope.encounterId);
      if (!mounted) return;
      _applyLoadedExaminationNotes(enc?.examinationNotes);
      setState(() {
        _loading = false;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveDraft() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    setState(() => _loading = true);

    final sectionTexts = <String, String>{};
    for (final section in examinationQuestionnaireSections) {
      final note = _noteForSection(section);
      if (note != null && note.isNotEmpty) {
        sectionTexts[section.id] = note;
      }
    }

    final notes = buildExaminationNotesBlob(
      sectionTexts: sectionTexts,
      additionalNotes: _additionalNotesCtrl.text.trim().isEmpty
          ? null
          : _additionalNotesCtrl.text.trim(),
    );

    try {
      await _encounterService.update(scope.encounterId, {
        'examinationNotes': notes.isEmpty ? null : notes,
      });
      if (!mounted) return;
      for (final section in examinationQuestionnaireSections) {
        _savedNotes[section.id] = sectionTexts[section.id];
        _useDirectEditOnSave[section.id] = false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Examination draft saved')),
      );
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = EncounterScope.of(context);
    if (scope == null) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text('Encounter context not available')),
      );
    }

    if (_loading && !_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_vitals.isNotEmpty) ...[
            Text(
              'Vitals (read-only)',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: _vitals.entries
                  .map(
                    (e) => Chip(
                      label: Text('${e.key}: ${e.value ?? "—"}'),
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
          ],
          for (final section in examinationQuestionnaireSections)
            EncounterQuestionnaireSection(
              key: ValueKey(section.id),
              section: section,
              answers: _answers[section.id] ?? {},
              savedNote: _savedNotes[section.id],
              directEditController: _directEditControllers[section.id],
              onAnswersChanged: (next) {
                _answers[section.id] = next;
                _useDirectEditOnSave[section.id] = false;
              },
              onDirectEditChanged: () {
                _useDirectEditOnSave[section.id] = true;
              },
            ),
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Additional notes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _additionalNotesCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: 'Extra examination findings not covered above',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _loading ? null : _saveDraft,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: const Text('Save draft'),
            ),
          ),
        ],
      ),
    );
  }
}
