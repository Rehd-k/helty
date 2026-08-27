import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/doctor/encounter/questionnaire/encounter_narrative_compiler.dart';
import 'package:helty/src/doctor/encounter/questionnaire/encounter_question_models.dart';
import 'package:helty/src/doctor/encounter/questionnaire/encounter_questionnaire_section.dart';
import 'package:helty/src/doctor/encounter/questionnaire/operative_note_compiler.dart';
import 'package:helty/src/doctor/encounter/questionnaire/operative_note_questionnaire_defs.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/theatre/models/theatre_models.dart';
import 'package:helty/src/theatre/providers/theatre_providers.dart';

EncounterQuestionnaireState answersForNewOperativeNote(SurgeryRequest request) {
  String? nameFor(TheatreTeamRole role) {
    final names = (request.theatreCase?.team ?? const <TheatreTeamMember>[])
        .where((m) => m.role == role)
        .map((m) => m.staff?.displayName.trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    if (names.isEmpty) return null;
    return names.join(', ');
  }

  return prefillOperativeNoteAnswers(
    procedureName: request.service?.name,
    surgeon: nameFor(TheatreTeamRole.surgeon) ??
        request.schedule?.surgeon?.displayName,
    assistant: nameFor(TheatreTeamRole.assistant),
    anaesthetist: nameFor(TheatreTeamRole.anaesthetist) ??
        request.schedule?.anaesthetist?.displayName,
    scrub: nameFor(TheatreTeamRole.scrub) ??
        request.schedule?.scrubNurse?.displayName,
  );
}

Future<bool> showOperativeNoteEditorSheet({
  required BuildContext context,
  required SurgeryRequest request,
  TheatreOperativeNote? existing,
}) async {
  final saved = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.94,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      builder: (_, controller) => OperativeNoteEditor(
        request: request,
        existing: existing,
        scrollController: controller,
      ),
    ),
  );
  return saved == true;
}

class OperativeNoteEditor extends ConsumerStatefulWidget {
  const OperativeNoteEditor({
    super.key,
    required this.request,
    this.existing,
    this.scrollController,
  });

  final SurgeryRequest request;
  final TheatreOperativeNote? existing;
  final ScrollController? scrollController;

  @override
  ConsumerState<OperativeNoteEditor> createState() =>
      _OperativeNoteEditorState();
}

class _OperativeNoteEditorState extends ConsumerState<OperativeNoteEditor> {
  late EncounterQuestionnaireState _answers;
  late final TextEditingController _additionalNotesCtrl;
  final _directEditControllers = <String, TextEditingController>{};
  final _useDirectEditOnSave = <String, bool>{};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _additionalNotesCtrl = TextEditingController();
    for (final section in operativeNoteQuestionnaireSections) {
      _directEditControllers[section.id] = TextEditingController();
      _useDirectEditOnSave[section.id] = false;
    }
    final existing = widget.existing;
    if (existing != null) {
      _answers = parseOperativeNoteAnswers(existing.answersJson);
      _additionalNotesCtrl.text = existing.additionalNotes ?? '';
      if (existing.answersJson.isEmpty &&
          existing.narrative.trim().isNotEmpty &&
          _additionalNotesCtrl.text.trim().isEmpty) {
        _additionalNotesCtrl.text = existing.narrative.trim();
      }
    } else {
      _answers = answersForNewOperativeNote(widget.request);
    }
  }

  @override
  void dispose() {
    for (final c in _directEditControllers.values) {
      c.dispose();
    }
    _additionalNotesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final staffId = ref.read(authProvider).staff?.id;
    if (staffId == null || staffId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be signed in to save notes.')),
      );
      return;
    }

    final sectionTexts = <String, String>{};
    for (final section in operativeNoteQuestionnaireSections) {
      final note = resolveSectionNote(
        section: section,
        answers: _answers[section.id] ?? {},
        directEditController: _directEditControllers[section.id],
        useDirectEdit: _useDirectEditOnSave[section.id] ?? false,
      );
      if (note != null && note.isNotEmpty) {
        sectionTexts[section.id] = note;
      }
    }

    final extra = _additionalNotesCtrl.text.trim();
    final narrative = buildOperativeNoteNarrative(
      sectionTexts: sectionTexts,
      additionalNotes: extra.isEmpty ? null : extra,
    );
    if (narrative.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fill in at least one section or additional notes.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final api = ref.read(theatreApiServiceProvider);
      if (widget.existing == null) {
        await api.createOperativeNote(
          widget.request.id,
          answersJson: serializeOperativeNoteAnswers(_answers),
          narrative: narrative,
          additionalNotes: extra.isEmpty ? null : extra,
        );
      } else {
        await api.updateOperativeNote(
          widget.request.id,
          widget.existing!.id,
          answersJson: serializeOperativeNoteAnswers(_answers),
          narrative: narrative,
          additionalNotes: extra.isEmpty ? null : extra,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final existing = widget.existing;
    return Material(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    existing == null ? 'New OP note' : 'Edit OP note',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Text(
                  widget.request.service?.name ?? 'Surgery',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                for (final section in operativeNoteQuestionnaireSections)
                  EncounterQuestionnaireSection(
                    key: ValueKey('${existing?.id ?? 'new'}-${section.id}'),
                    section: section,
                    answers: _answers[section.id] ?? {},
                    directEditController: _directEditControllers[section.id],
                    onAnswersChanged: (next) {
                      _answers[section.id] = next;
                      _useDirectEditOnSave[section.id] = false;
                    },
                    onDirectEditChanged: () {
                      _useDirectEditOnSave[section.id] = true;
                    },
                  ),
                Text(
                  'Additional notes',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _additionalNotesCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText:
                        'Free-hand operative notes not covered by the questions above',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
