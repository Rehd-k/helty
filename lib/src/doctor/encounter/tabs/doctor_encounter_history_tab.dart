import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/doctor/encounter/encounter_amend_helper.dart';
import 'package:helty/src/doctor/encounter/encounter_tab_reload.dart';
import 'package:helty/src/doctor/encounter/questionnaire/encounter_question_models.dart';
import 'package:helty/src/doctor/encounter/questionnaire/encounter_questionnaire_section.dart';
import 'package:helty/src/doctor/encounter/questionnaire/history_questionnaire_defs.dart';
import 'package:helty/src/doctor/encounter/widgets/encounter_tab_scroll_shell.dart';
import 'package:helty/src/services/encounter_service.dart';

@RoutePage()
class DoctorEncounterHistoryTab extends StatefulWidget {
  const DoctorEncounterHistoryTab({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<DoctorEncounterHistoryTab> createState() =>
      _DoctorEncounterHistoryTabState();
}

class _DoctorEncounterHistoryTabState extends State<DoctorEncounterHistoryTab> {
  final _encounterService = EncounterService();

  final _answers = <String, QuestionnaireAnswers>{};
  final _savedNotes = <String, String?>{};
  final _directEditControllers = <String, TextEditingController>{};
  final _useDirectEditOnSave = <String, bool>{};

  bool _loading = false;
  bool _loaded = false;
  bool _draftLoadScheduled = false;
  int _lastReloadGeneration = 0;

  @override
  void initState() {
    super.initState();
    for (final section in historyQuestionnaireSections) {
      _answers[section.id] = {};
      _directEditControllers[section.id] = TextEditingController();
      _useDirectEditOnSave[section.id] = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reloadEncounterTabIfTemplateApplied(
      context: context,
      lastReloadGeneration: _lastReloadGeneration,
      updateLastReloadGeneration: (v) => _lastReloadGeneration = v,
      loaded: _loaded,
      reload: _loadDraft,
    );
    if (!_draftLoadScheduled) {
      _draftLoadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadDraft();
      });
    }
  }

  @override
  void dispose() {
    for (final c in _directEditControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDraft() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    setState(() => _loading = true);
    try {
      final enc = await _encounterService.getById(scope.encounterId);
      if (!mounted) return;
      if (enc != null) {
        _savedNotes['chiefComplaint'] = enc.chiefComplaint;
        _savedNotes['hpi'] = enc.hpi;
        _savedNotes['pmh'] = enc.pmh;
        _savedNotes['surgicalHistory'] = enc.surgicalHistory;
        _savedNotes['drugHistory'] = enc.drugHistory;
        _savedNotes['allergyHistory'] = enc.allergyHistory;
        _savedNotes['familyHistory'] = enc.familyHistory;
        _savedNotes['socialHistory'] = enc.socialHistory;
      }
      setState(() {
        _loading = false;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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

  Future<void> _saveDraft() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    setState(() => _loading = true);
    try {
      final body = <String, dynamic>{};
      for (final section in historyQuestionnaireSections) {
        final apiField = historySectionApiFields[section.id];
        if (apiField == null) continue;
        body[apiField] = _noteForSection(section);
      }
      await _encounterService.update(
        scope.encounterId,
        encounterPatchWithAmend(scope, body),
      );
      if (!mounted) return;
      for (final section in historyQuestionnaireSections) {
        final note = _noteForSection(section);
        _savedNotes[section.id] = note;
        _useDirectEditOnSave[section.id] = false;
      }
      showEncounterSaveSnackBar(
        context,
        scope: scope,
        ongoingMessage: 'Draft saved',
      );
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      showEncounterEditErrorSnackBar(context, e);
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = EncounterScope.of(context);
    if (scope == null) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text('Encounter context not available')),
      );
    }

    final readOnly = !scope.canEdit;

    if (_loading && !_loaded) {
      return widget.embedded
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          : const Center(child: CircularProgressIndicator());
    }

    return EncounterTabScrollShell(
      embedded: widget.embedded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ResponsiveToolbar(
            actions: [
              if (!readOnly)
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Voice typing not yet integrated'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.mic_none, size: 18),
                  label: const Text('Voice typing'),
                ),
              if (!readOnly)
                FilledButton.icon(
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
            ],
          ),
          const SizedBox(height: 24),
          for (final section in historyQuestionnaireSections)
            EncounterQuestionnaireSection(
              key: ValueKey(section.id),
              section: section,
              answers: _answers[section.id] ?? {},
              savedNote: _savedNotes[section.id],
              directEditController: _directEditControllers[section.id],
              readOnly: readOnly,
              onAnswersChanged: (next) {
                _answers[section.id] = next;
                _useDirectEditOnSave[section.id] = false;
              },
              onDirectEditChanged: () {
                _useDirectEditOnSave[section.id] = true;
              },
            ),
        ],
      ),
    );
  }
}
