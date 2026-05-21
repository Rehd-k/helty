// Models for structured encounter history / examination questionnaires.

enum QuestionType {
  yesNo,
  singleChoice,
  multiChoice,
  text,
  number,
}

/// When to show a follow-up question (e.g. after Yes on a parent yes/no).
class VisibleWhen {
  const VisibleWhen({
    required this.questionId,
    this.equals,
    this.equalsBool,
    this.contains,
  });

  final String questionId;
  final String? equals;
  final bool? equalsBool;
  final String? contains;

  bool matches(QuestionnaireAnswers answers) {
    final raw = answers[questionId];
    if (equalsBool != null) {
      if (raw is bool) return raw == equalsBool;
      if (raw is String) {
        final lower = raw.toLowerCase();
        if (equalsBool!) {
          return lower == 'true' || lower == 'yes';
        }
        return lower == 'false' || lower == 'no';
      }
      return false;
    }
    if (equals != null) return raw?.toString() == equals;
    if (contains != null) {
      if (raw is List) return raw.map((e) => e.toString()).contains(contains);
      return false;
    }
    return true;
  }
}

class QuestionOption {
  const QuestionOption({required this.value, required this.label});

  final String value;
  final String label;
}

class QuestionDef {
  const QuestionDef({
    required this.id,
    required this.label,
    required this.type,
    this.options = const [],
    this.hint,
    this.maxLines = 1,
    this.visibleWhen,
    this.isOther = false,
  });

  final String id;
  final String label;
  final QuestionType type;
  final List<QuestionOption> options;
  final String? hint;
  final int maxLines;
  final VisibleWhen? visibleWhen;

  /// Marks the section-level "Other / additional details" free-text field.
  final bool isOther;
}

class EncounterSectionDef {
  const EncounterSectionDef({
    required this.id,
    required this.title,
    this.subtitle,
    required this.questions,
  });

  final String id;
  final String title;
  final String? subtitle;
  final List<QuestionDef> questions;

  QuestionDef? get otherQuestion {
    for (final q in questions) {
      if (q.isOther) return q;
    }
    return null;
  }

  List<QuestionDef> get nonOtherQuestions =>
      questions.where((q) => !q.isOther).toList();
}

/// Per-section answers keyed by question id.
typedef QuestionnaireAnswers = Map<String, dynamic>;

/// All sections keyed by section id.
typedef EncounterQuestionnaireState = Map<String, QuestionnaireAnswers>;

bool answerIsEmpty(dynamic value) {
  if (value == null) return true;
  if (value is bool) return false;
  if (value is String) return value.trim().isEmpty;
  if (value is List) return value.isEmpty;
  if (value is num) return false;
  return true;
}

List<String> answerAsStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
  }
  if (value is String && value.isNotEmpty) {
    return [value];
  }
  return [];
}

String? answerAsDisplayString(dynamic value, QuestionDef question) {
  if (answerIsEmpty(value)) return null;
  switch (question.type) {
    case QuestionType.yesNo:
      if (value is bool) return value ? 'Yes' : 'No';
      return value.toString();
    case QuestionType.singleChoice:
      final v = value.toString();
      for (final o in question.options) {
        if (o.value == v) return o.label;
      }
      return v;
    case QuestionType.multiChoice:
      final labels = <String>[];
      for (final item in answerAsStringList(value)) {
        final match = question.options.where((o) => o.value == item);
        labels.add(match.isEmpty ? item : match.first.label);
      }
      return labels.join(', ');
    case QuestionType.text:
    case QuestionType.number:
      return value.toString().trim();
  }
}
