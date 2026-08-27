import 'encounter_narrative_compiler.dart';
import 'encounter_question_models.dart';
import 'operative_note_questionnaire_defs.dart';

EncounterQuestionnaireState emptyOperativeNoteAnswers() {
  return {
    for (final section in operativeNoteQuestionnaireSections) section.id: <String, dynamic>{},
  };
}

EncounterQuestionnaireState prefillOperativeNoteAnswers({
  String? procedureName,
  String? surgeon,
  String? assistant,
  String? anaesthetist,
  String? scrub,
}) {
  final state = emptyOperativeNoteAnswers();
  if (procedureName != null && procedureName.trim().isNotEmpty) {
    state['procedure'] = {'name': procedureName.trim()};
  }
  final team = <String, dynamic>{};
  if (surgeon != null && surgeon.trim().isNotEmpty) {
    team['surgeon'] = surgeon.trim();
  }
  if (assistant != null && assistant.trim().isNotEmpty) {
    team['assistant'] = assistant.trim();
  }
  if (anaesthetist != null && anaesthetist.trim().isNotEmpty) {
    team['anaesthetist'] = anaesthetist.trim();
  }
  if (scrub != null && scrub.trim().isNotEmpty) {
    team['scrub'] = scrub.trim();
  }
  if (team.isNotEmpty) state['team'] = team;
  return state;
}

EncounterQuestionnaireState parseOperativeNoteAnswers(dynamic raw) {
  final state = emptyOperativeNoteAnswers();
  if (raw is! Map) return state;
  for (final section in operativeNoteQuestionnaireSections) {
    final sectionRaw = raw[section.id];
    if (sectionRaw is! Map) continue;
    final answers = <String, dynamic>{};
    for (final entry in sectionRaw.entries) {
      final key = entry.key.toString();
      if (key.isEmpty) continue;
      answers[key] = entry.value;
    }
    state[section.id] = answers;
  }
  return state;
}

Map<String, dynamic> serializeOperativeNoteAnswers(
  EncounterQuestionnaireState answers,
) {
  final out = <String, dynamic>{};
  for (final section in operativeNoteQuestionnaireSections) {
    final sectionAnswers = answers[section.id] ?? {};
    final cleaned = <String, dynamic>{};
    for (final entry in sectionAnswers.entries) {
      if (answerIsEmpty(entry.value)) continue;
      cleaned[entry.key] = entry.value;
    }
    if (cleaned.isNotEmpty) out[section.id] = cleaned;
  }
  return out;
}

String compileOperativeNoteNarrative({
  required EncounterQuestionnaireState answers,
  String? additionalNotes,
}) {
  final sectionTexts = <String, String>{};
  for (final section in operativeNoteQuestionnaireSections) {
    final text = EncounterNarrativeCompiler.compileSectionOrNull(
      section,
      answers[section.id] ?? {},
    );
    if (text != null && text.isNotEmpty) {
      sectionTexts[section.id] = text;
    }
  }
  return buildOperativeNoteNarrative(
    sectionTexts: sectionTexts,
    additionalNotes: additionalNotes,
  );
}
