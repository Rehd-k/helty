import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_metrics.dart';
import 'package:helty/src/widgets/helty_surface.dart';

import '../../specialty/widgets/clinical_form_shared.dart';
import 'encounter_narrative_compiler.dart';
import 'encounter_question_models.dart';

/// One expandable history/examination section with structured questions.
class EncounterQuestionnaireSection extends StatefulWidget {
  const EncounterQuestionnaireSection({
    super.key,
    required this.section,
    required this.answers,
    required this.onAnswersChanged,
    this.savedNote,
    this.directEditController,
    this.onDirectEditChanged,
    this.initiallyExpanded = false,
    this.readOnly = false,
  });

  final EncounterSectionDef section;
  final QuestionnaireAnswers answers;
  final ValueChanged<QuestionnaireAnswers> onAnswersChanged;

  /// Previously saved narrative from API (read-only reference).
  final String? savedNote;

  /// When user edits note directly, this controller holds override text.
  final TextEditingController? directEditController;

  final VoidCallback? onDirectEditChanged;
  final bool initiallyExpanded;
  final bool readOnly;

  @override
  State<EncounterQuestionnaireSection> createState() =>
      _EncounterQuestionnaireSectionState();
}

class _EncounterQuestionnaireSectionState
    extends State<EncounterQuestionnaireSection> {
  bool _expanded = false;
  bool _showDirectEdit = false;
  bool _useDirectEditOnSave = false;
  late QuestionnaireAnswers _answers;

  @override
  void initState() {
    super.initState();
    _answers = Map<String, dynamic>.from(widget.answers);
    _expanded = widget.initiallyExpanded;
    _showDirectEdit =
        widget.directEditController?.text.trim().isNotEmpty == true;
    _useDirectEditOnSave = _showDirectEdit;
    widget.directEditController?.addListener(_onDirectEditListener);
  }

  @override
  void didUpdateWidget(EncounterQuestionnaireSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.directEditController != widget.directEditController) {
      oldWidget.directEditController?.removeListener(_onDirectEditListener);
      widget.directEditController?.addListener(_onDirectEditListener);
    }
  }

  @override
  void dispose() {
    widget.directEditController?.removeListener(_onDirectEditListener);
    super.dispose();
  }

  void _onDirectEditListener() {
    _useDirectEditOnSave = true;
    widget.onDirectEditChanged?.call();
    setState(() {});
  }

  String get _generatedNote =>
      EncounterNarrativeCompiler.compileSection(widget.section, _answers);

  String? get effectiveNoteForSave {
    if (_useDirectEditOnSave &&
        widget.directEditController != null &&
        widget.directEditController!.text.trim().isNotEmpty) {
      return widget.directEditController!.text.trim();
    }
    final compiled = _generatedNote.trim();
    return compiled.isEmpty ? null : compiled;
  }

  void _setAnswer(String questionId, dynamic value) {
    final next = Map<String, dynamic>.from(_answers);
    if (answerIsEmpty(value)) {
      next.remove(questionId);
    } else {
      next[questionId] = value;
    }
    _useDirectEditOnSave = false;
    setState(() => _answers = next);
    widget.onAnswersChanged(next);
  }

  bool _isVisible(QuestionDef q) {
    if (q.visibleWhen == null) return true;
    return q.visibleWhen!.matches(_answers);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final generated = _generatedNote;
    final hasContent =
        generated.isNotEmpty ||
        (widget.savedNote?.trim().isNotEmpty == true) ||
        (widget.directEditController?.text.trim().isNotEmpty == true);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: HeltySurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    HeltySolidIcon(
                      icon: _iconForSection(widget.section.id),
                      color: _colorForSection(widget.section.id),
                      size: 26,
                      iconSize: 14,
                      radius: 7,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HeltyEllipsisText(
                            text: widget.section.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (widget.section.subtitle != null) ...[
                            const Gap(2),
                            HeltyEllipsisText(
                              text: widget.section.subtitle!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (hasContent) ...[
                      const HeltySolidIcon(
                        icon: Icons.check,
                        color: InpatientMetrics.waitGreen,
                        size: 18,
                        iconSize: 11,
                        radius: 5,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            if (_expanded) ...[
              const Divider(height: 1),
              AbsorbPointer(
                absorbing: widget.readOnly,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (widget.savedNote?.trim().isNotEmpty == true) ...[
                        _SavedNoteBanner(text: widget.savedNote!.trim()),
                        const Gap(16),
                      ],
                      ...widget.section.questions
                          .where((q) => !q.isOther && _isVisible(q))
                          .map(
                            (q) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _QuestionField(
                                key: ValueKey(q.id),
                                question: q,
                                value: _answers[q.id],
                                onChanged: (v) => _setAnswer(q.id, v),
                              ),
                            ),
                          ),
                      if (widget.section.otherQuestion != null &&
                          _isVisible(widget.section.otherQuestion!)) ...[
                        _QuestionField(
                          key: ValueKey(widget.section.otherQuestion!.id),
                          question: widget.section.otherQuestion!,
                          value: _answers[widget.section.otherQuestion!.id],
                          onChanged: (v) =>
                              _setAnswer(widget.section.otherQuestion!.id, v),
                        ),
                        const Gap(8),
                      ],
                      _GeneratedPreview(text: generated),
                      if (!widget.readOnly) ...[
                        const Gap(12),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showDirectEdit = !_showDirectEdit;
                              if (_showDirectEdit &&
                                  widget.directEditController != null &&
                                  widget.directEditController!.text.isEmpty &&
                                  generated.isNotEmpty) {
                                widget.directEditController!.text = generated;
                              }
                            });
                          },
                          icon: Icon(
                            _showDirectEdit
                                ? Icons.edit_off_outlined
                                : Icons.edit_outlined,
                            size: 18,
                          ),
                          label: Text(
                            _showDirectEdit
                                ? 'Hide direct edit'
                                : 'Edit note directly',
                          ),
                        ),
                      ],
                      if (_showDirectEdit &&
                          widget.directEditController != null) ...[
                        const Gap(8),
                        TextFormField(
                          controller: widget.directEditController,
                          maxLines: 4,
                          decoration: InputDecoration(
                            labelText: 'Note for ${widget.section.title}',
                            hintText: 'Overrides generated note when saved',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                          onChanged: (_) {
                            _useDirectEditOnSave = true;
                            widget.onDirectEditChanged?.call();
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SavedNoteBanner extends StatelessWidget {
  const _SavedNoteBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      title: Text(
        'Saved note',
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _GeneratedPreview extends StatelessWidget {
  const _GeneratedPreview({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Generated note',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(6),
          Text(
            text.isEmpty ? '— (answer questions above)' : text,
            style: theme.textTheme.bodySmall?.copyWith(
              fontStyle: text.isEmpty ? FontStyle.italic : FontStyle.normal,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionField extends StatefulWidget {
  const _QuestionField({
    super.key,
    required this.question,
    required this.value,
    required this.onChanged,
  });

  final QuestionDef question;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  @override
  State<_QuestionField> createState() => _QuestionFieldState();
}

class _QuestionFieldState extends State<_QuestionField> {
  TextEditingController? _textController;

  bool get _usesTextController =>
      widget.question.type == QuestionType.text ||
      widget.question.type == QuestionType.number;

  @override
  void initState() {
    super.initState();
    if (_usesTextController) {
      _textController = TextEditingController(
        text: widget.value?.toString() ?? '',
      );
    }
  }

  @override
  void didUpdateWidget(_QuestionField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_textController != null && oldWidget.value != widget.value) {
      final external = widget.value?.toString() ?? '';
      if (_textController!.text != external) {
        _textController!.text = external;
      }
    }
  }

  @override
  void dispose() {
    _textController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClinicalLabeledField(
      label: widget.question.label,
      child: _buildControl(context),
    );
  }

  Widget _buildControl(BuildContext context) {
    final question = widget.question;
    final value = widget.value;
    final onChanged = widget.onChanged;

    switch (question.type) {
      case QuestionType.yesNo:
        final bool? selected = value is bool
            ? value
            : value == null
            ? null
            : value.toString().toLowerCase() == 'true' ||
                  value.toString().toLowerCase() == 'yes';
        return SegmentedButton<bool?>(
          segments: const [
            ButtonSegment<bool?>(value: true, label: Text('Yes')),
            ButtonSegment<bool?>(value: false, label: Text('No')),
          ],
          selected: selected == null ? {} : {selected},
          emptySelectionAllowed: true,
          onSelectionChanged: (s) {
            if (s.isEmpty) {
              onChanged(null);
            } else {
              onChanged(s.first);
            }
          },
        );
      case QuestionType.singleChoice:
        final current = value?.toString() ?? '';
        return InputDecorator(
          decoration: InputDecoration(
            hintText: question.hint ?? 'Select',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: current.isEmpty ? null : current,
              hint: Text(question.hint ?? 'Select'),
              items: question.options
                  .map(
                    (o) => DropdownMenuItem<String>(
                      value: o.value,
                      child: Text(o.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) => onChanged(v),
            ),
          ),
        );
      case QuestionType.multiChoice:
        final selected = answerAsStringList(value).toSet();
        return Wrap(
          spacing: 8,
          runSpacing: 4,
          children: question.options.map((o) {
            final isSelected = selected.contains(o.value);
            return FilterChip(
              label: Text(o.label),
              selected: isSelected,
              onSelected: (sel) {
                final next = Set<String>.from(selected);
                if (sel) {
                  next.add(o.value);
                } else {
                  next.remove(o.value);
                }
                onChanged(next.toList());
              },
            );
          }).toList(),
        );
      case QuestionType.number:
        return TextFormField(
          controller: _textController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
          ],
          decoration: InputDecoration(
            hintText: question.hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          onChanged: (v) => onChanged(v.trim().isEmpty ? null : v.trim()),
        );
      case QuestionType.text:
        return TextFormField(
          controller: _textController,
          maxLines: question.maxLines,
          decoration: InputDecoration(
            hintText: question.hint ?? 'Enter ${question.label.toLowerCase()}',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
          ),
          onChanged: (v) => onChanged(v.isEmpty ? null : v),
        );
    }
  }
}

/// Resolves narrative text for a section on save.
String? resolveSectionNote({
  required EncounterSectionDef section,
  required QuestionnaireAnswers answers,
  required TextEditingController? directEditController,
  required bool useDirectEdit,
}) {
  final direct = directEditController?.text.trim() ?? '';
  final compiled = EncounterNarrativeCompiler.compileSectionOrNull(
    section,
    answers,
  );

  if (useDirectEdit && direct.isNotEmpty) return direct;
  if (compiled != null && compiled.isNotEmpty) return compiled;
  if (direct.isNotEmpty) return direct;
  return null;
}

IconData _iconForSection(String id) {
  return switch (id) {
    'chiefComplaint' => Icons.sick_outlined,
    'hpi' => Icons.timeline,
    'pmh' => Icons.history_edu_outlined,
    'surgicalHistory' => Icons.local_hospital_outlined,
    'drugHistory' => Icons.medication_outlined,
    'allergyHistory' => Icons.warning_amber_rounded,
    'familyHistory' => Icons.family_restroom_outlined,
    'socialHistory' => Icons.groups_outlined,
    'general' => Icons.person_search_outlined,
    'cvs' => Icons.favorite_outline,
    'resp' => Icons.air,
    'abdomen' => Icons.health_and_safety_outlined,
    'cns' => Icons.psychology_outlined,
    'msk' => Icons.accessibility_new_outlined,
    'ent' => Icons.hearing_outlined,
    'skin' => Icons.texture_outlined,
    'procedure' => Icons.medical_services_outlined,
    'team' => Icons.groups_outlined,
    'diagnoses' => Icons.medical_information_outlined,
    'consent' => Icons.fact_check_outlined,
    'anaesthesia' => Icons.airline_seat_flat_outlined,
    'preparation' => Icons.cleaning_services_outlined,
    'findings' => Icons.search_outlined,
    'details' => Icons.notes_outlined,
    'closure' => Icons.healing_outlined,
    'counts' => Icons.pin_outlined,
    'complications' => Icons.report_gmailerrorred_outlined,
    'outcome' => Icons.flag_outlined,
    _ => Icons.quiz_outlined,
  };
}

Color _colorForSection(String id) {
  return switch (id) {
    'chiefComplaint' || 'general' || 'procedure' => InpatientMetrics.iconBlue,
    'hpi' || 'resp' || 'team' => InpatientMetrics.iconTeal,
    'pmh' || 'abdomen' || 'diagnoses' => InpatientMetrics.iconPurple,
    'surgicalHistory' || 'cvs' || 'consent' => InpatientMetrics.waitRed,
    'drugHistory' || 'msk' || 'anaesthesia' => InpatientMetrics.waitAmber,
    'allergyHistory' || 'ent' || 'preparation' => InpatientMetrics.iconPink,
    'familyHistory' || 'cns' || 'findings' => InpatientMetrics.iconIndigo,
    'socialHistory' || 'skin' || 'details' => InpatientMetrics.waitGreen,
    'closure' => InpatientMetrics.iconBlue,
    'counts' => InpatientMetrics.iconTeal,
    'complications' => InpatientMetrics.waitRed,
    'outcome' => InpatientMetrics.waitGreen,
    _ => InpatientMetrics.iconIndigo,
  };
}
