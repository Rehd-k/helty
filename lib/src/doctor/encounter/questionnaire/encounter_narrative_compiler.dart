import 'encounter_question_models.dart';

/// Compiles structured questionnaire answers into clinical narrative prose.
class EncounterNarrativeCompiler {
  const EncounterNarrativeCompiler._();

  static String compileSection(
    EncounterSectionDef section,
    QuestionnaireAnswers answers,
  ) {
    final parts = <String>[];

    for (final q in section.nonOtherQuestions) {
      if (q.visibleWhen != null && !q.visibleWhen!.matches(answers)) {
        continue;
      }
      final display = answerAsDisplayString(answers[q.id], q);
      if (display == null || display.isEmpty) continue;
      parts.add('${q.label}: $display');
    }

    final other = section.otherQuestion;
    if (other != null) {
      final otherText = answers[other.id]?.toString().trim();
      if (otherText != null && otherText.isNotEmpty) {
        parts.add(otherText);
      }
    }

    return parts.join('. ').trim();
  }

  static String? compileSectionOrNull(
    EncounterSectionDef section,
    QuestionnaireAnswers answers,
  ) {
    final text = compileSection(section, answers);
    return text.isEmpty ? null : text;
  }
}

/// Parses examination notes blob into per-section text by label prefix.
Map<String, String> parseExaminationNotes(String? notes) {
  if (notes == null || notes.trim().isEmpty) return {};

  const labels = {
    'general': 'General',
    'cvs': 'CVS',
    'resp': 'Resp',
    'abdomen': 'Abdomen',
    'cns': 'CNS',
    'msk': 'MSK',
    'ent': 'ENT',
    'skin': 'Skin',
  };

  final result = <String, String>{};
  final lines = notes.split('\n');
  String? currentKey;
  final buffer = StringBuffer();

  void flush() {
    final key = currentKey;
    if (key == null) return;
    final text = buffer.toString().trim();
    if (text.isNotEmpty) result[key] = text;
    buffer.clear();
  }

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;

    String? matchedKey;
    String? remainder;
    for (final e in labels.entries) {
      final prefix = '${e.value}:';
      if (trimmed.startsWith(prefix)) {
        matchedKey = e.key;
        remainder = trimmed.substring(prefix.length).trim();
        break;
      }
    }

    if (matchedKey != null) {
      flush();
      currentKey = matchedKey;
      if (remainder != null && remainder.isNotEmpty) {
        buffer.writeln(remainder);
      }
    } else if (currentKey != null) {
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(trimmed);
    }
  }
  flush();

  return result;
}

String buildExaminationNotesBlob({
  required Map<String, String> sectionTexts,
  String? additionalNotes,
}) {
  const order = [
    ('general', 'General'),
    ('cvs', 'CVS'),
    ('resp', 'Resp'),
    ('abdomen', 'Abdomen'),
    ('cns', 'CNS'),
    ('msk', 'MSK'),
    ('ent', 'ENT'),
    ('skin', 'Skin'),
  ];

  final parts = <String>[];
  for (final e in order) {
    final text = sectionTexts[e.$1]?.trim();
    if (text != null && text.isNotEmpty) {
      parts.add('${e.$2}: $text');
    }
  }
  final extra = additionalNotes?.trim();
  if (extra != null && extra.isNotEmpty) {
    parts.add(extra);
  }
  return parts.join('\n\n');
}

String buildOperativeNoteNarrative({
  required Map<String, String> sectionTexts,
  String? additionalNotes,
}) {
  const order = [
    ('procedure', 'Procedure'),
    ('team', 'Team'),
    ('diagnoses', 'Diagnoses'),
    ('consent', 'Consent'),
    ('anaesthesia', 'Anaesthesia'),
    ('preparation', 'Preparation'),
    ('findings', 'Findings'),
    ('details', 'Procedure details'),
    ('closure', 'Closure'),
    ('counts', 'Counts'),
    ('complications', 'Complications'),
    ('outcome', 'Outcome'),
  ];

  final parts = <String>[];
  for (final e in order) {
    final text = sectionTexts[e.$1]?.trim();
    if (text != null && text.isNotEmpty) {
      parts.add('${e.$2}: $text');
    }
  }
  final extra = additionalNotes?.trim();
  if (extra != null && extra.isNotEmpty) {
    parts.add(extra);
  }
  return parts.join('\n\n');
}
