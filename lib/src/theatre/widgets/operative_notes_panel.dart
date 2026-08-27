import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/theatre/models/theatre_models.dart';
import 'package:helty/src/theatre/widgets/operative_note_editor.dart';

class OperativeNotesPanel extends StatelessWidget {
  const OperativeNotesPanel({
    super.key,
    required this.request,
    required this.notes,
    required this.canWrite,
    this.compact = false,
    this.onChanged,
  });

  final SurgeryRequest request;
  final List<TheatreOperativeNote> notes;
  final bool canWrite;
  final bool compact;
  final VoidCallback? onChanged;

  bool get _unlocked => request.status.allowsOperativeNotes;

  Future<void> _openEditor(
    BuildContext context, {
    TheatreOperativeNote? existing,
  }) async {
    final saved = await showOperativeNoteEditorSheet(
      context: context,
      request: request,
      existing: existing,
    );
    if (saved) onChanged?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                compact ? 'OP notes' : 'Operative notes',
                style: (compact
                        ? theme.textTheme.titleSmall
                        : theme.textTheme.titleMedium)
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (canWrite && _unlocked)
              compact
                  ? IconButton(
                      tooltip: 'Add OP note',
                      onPressed: () => _openEditor(context),
                      icon: const Icon(Icons.add_rounded),
                    )
                  : FilledButton.tonalIcon(
                      onPressed: () => _openEditor(context),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add OP note'),
                    ),
          ],
        ),
        if (canWrite && !_unlocked) ...[
          const SizedBox(height: 8),
          Text(
            'OP notes can be added once surgery is in progress.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (notes.isEmpty)
          Text(
            _unlocked ? 'No operative notes yet.' : '',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          )
        else
          for (var i = 0; i < notes.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            _OperativeNoteCard(
              note: notes[i],
              canEdit: canWrite && _unlocked,
              onEdit: () => _openEditor(context, existing: notes[i]),
            ),
          ],
      ],
    );
  }
}

class _OperativeNoteCard extends StatelessWidget {
  const _OperativeNoteCard({
    required this.note,
    required this.canEdit,
    required this.onEdit,
  });

  final TheatreOperativeNote note;
  final bool canEdit;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final preview = note.narrative.trim().isNotEmpty
        ? note.narrative.trim()
        : (note.additionalNotes?.trim() ?? '');
    final when = note.createdAt != null
        ? DateFormatter.dateTime(note.createdAt!)
        : null;

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: canEdit ? onEdit : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [
                        note.authorName,
                        if (when != null) when,
                      ].join(' · '),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (canEdit)
                    Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                ],
              ),
              if (preview.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  preview,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
