import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/extensions/capitalizer.extention.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/helper/quill_content_helper.dart';
import 'package:helty/src/models/ward_round_note_model.dart';
import 'package:helty/src/nurses/inpatients/ward_round_note_draft.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/ward_round_note_service.dart';
import 'package:helty/src/shared/department_colors.dart';
import 'package:helty/src/widgets/expandable_rich_content.dart';

/// Opens the SOAP ward round note dialog. Returns whether a note was saved.
Future<WardRoundNoteDialogResult?> showWardRoundNoteDialog({
  required BuildContext context,
  required String admissionId,
  required String doctorId,
  WardRoundNoteService? wardRoundNoteService,
  WardRoundNoteDraft? initialDraft,
}) {
  return showDialog<WardRoundNoteDialogResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _AddWardRoundNoteDialog(
      admissionId: admissionId,
      doctorId: doctorId,
      wardRoundNoteService: wardRoundNoteService ?? WardRoundNoteService(),
      initialDraft: initialDraft,
    ),
  );
}

enum _WardRoundSortField { date, author }

DateTime _noteSortInstant(WardRoundNoteModel note) =>
    note.createdAt ?? note.roundDate;

String _authorSortKey(WardRoundNoteModel note) =>
    (note.doctorDisplayName ?? note.doctorId).toLowerCase();

String _sortSubtitle(_WardRoundSortField field, bool ascending) {
  if (field == _WardRoundSortField.date) {
    return ascending ? 'sorted by date, oldest first' : 'sorted by date, newest first';
  }
  return ascending ? 'sorted by author, A→Z' : 'sorted by author, Z→A';
}

String _directionTooltip(_WardRoundSortField field, bool ascending) {
  if (field == _WardRoundSortField.date) {
    return ascending ? 'Oldest first' : 'Newest first';
  }
  return ascending ? 'A→Z' : 'Z→A';
}

@RoutePage()
class InpatientWardRoundTab extends ConsumerStatefulWidget {
  const InpatientWardRoundTab({super.key});

  @override
  ConsumerState<InpatientWardRoundTab> createState() =>
      _InpatientWardRoundTabState();
}

class _InpatientWardRoundTabState extends ConsumerState<InpatientWardRoundTab> {
  final _wardRoundNoteService = WardRoundNoteService();
  List<WardRoundNoteModel> _notes = [];
  bool _loading = true;
  String? _error;
  String? _lastLoadedAdmissionId;
  _WardRoundSortField _sortField = _WardRoundSortField.date;
  bool _sortAscending = false;

  List<WardRoundNoteModel> get _sortedNotes {
    final list = List<WardRoundNoteModel>.from(_notes);
    list.sort((a, b) {
      int cmp;
      if (_sortField == _WardRoundSortField.author) {
        cmp = _authorSortKey(a).compareTo(_authorSortKey(b));
        if (cmp == 0) {
          cmp = _noteSortInstant(b).compareTo(_noteSortInstant(a));
        }
      } else {
        cmp = _noteSortInstant(a).compareTo(_noteSortInstant(b));
      }
      return _sortAscending ? cmp : -cmp;
    });
    return list;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final admissionId = InpatientViewScope.of(context)?.admissionId;
    if (admissionId != null && admissionId != _lastLoadedAdmissionId) {
      _lastLoadedAdmissionId = admissionId;
      _loadNotes(admissionId);
    }
  }

  Future<void> _loadNotes(String admissionId) async {
    if (admissionId.isEmpty) {
      setState(() {
        _notes = [];
        _loading = false;
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _wardRoundNoteService.listByAdmission(admissionId);
      if (!mounted) return;
      setState(() {
        _notes = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showAddNoteDialog() async {
    final admissionId = InpatientViewScope.of(context)?.admissionId;
    final staff = ref.read(authProvider).staff;
    final doctorId = staff?.id ?? staff?.staffId ?? '';
    if (admissionId == null || admissionId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Admission context missing. Open this patient from Ward Rounds or Inpatients list.',
          ),
        ),
      );
      return;
    }
    if (doctorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You must be logged in as a doctor to add a ward round note.',
          ),
        ),
      );
      return;
    }

    final existingDraft = ref.read(wardRoundNoteDraftProvider);
    final initialDraft =
        existingDraft?.admissionId == admissionId ? existingDraft : null;

    final result = await showWardRoundNoteDialog(
      context: context,
      admissionId: admissionId,
      doctorId: doctorId,
      wardRoundNoteService: _wardRoundNoteService,
      initialDraft: initialDraft,
    );
    if (!mounted) return;

    switch (result?.outcome) {
      case WardRoundNoteDialogOutcome.saved:
        ref.read(wardRoundNoteDraftProvider.notifier).state = null;
        final id = InpatientViewScope.of(context)?.admissionId;
        if (id != null) _loadNotes(id);
      case WardRoundNoteDialogOutcome.minimized:
        ref.read(wardRoundNoteDraftProvider.notifier).state = result?.draft;
      case WardRoundNoteDialogOutcome.discarded:
      case null:
        ref.read(wardRoundNoteDraftProvider.notifier).state = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final admissionId = InpatientViewScope.of(context)?.admissionId;

    return ResponsiveBody(
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (admissionId == null || admissionId.isEmpty)
            SectionCard(
              title: 'Ward round notes',
              subtitle:
                  'Open this patient from Ward Rounds or Inpatients list with an admission to see and add notes.',
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No admission context.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else ...[
            SectionCard(
              title: 'Ward round (progress) notes',
              subtitle: _notes.isEmpty
                  ? 'SOAP notes for this admission. Doctors can add new notes.'
                  : 'SOAP notes · ${_sortSubtitle(_sortField, _sortAscending)}',
              actions: [
                FilledButton.icon(
                  onPressed: _loading ? null : _showAddNoteDialog,
                  icon: const Icon(Icons.add_comment, size: 18),
                  label: const Text('Add round note'),
                ),
              ],
              child: _buildNotesContent(theme, colorScheme),
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildNotesContent(ThemeData theme, ColorScheme colorScheme) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: LayoutBuilder(
          builder: (context, c) {
            final narrow = c.maxWidth < 420;
            final message = Text(
              _error!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
              ),
            );
            final retry = TextButton(
              onPressed: () {
                final id = InpatientViewScope.of(context)?.admissionId;
                if (id != null) _loadNotes(id);
              },
              child: const Text('Retry'),
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.error,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: message),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerLeft, child: retry),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                const SizedBox(width: 8),
                Expanded(child: message),
                retry,
              ],
            );
          },
        ),
      );
    }
    if (_notes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Text(
          'No ward round notes yet. Use "Add round note" to document a round.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final sorted = _sortedNotes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _WardRoundSortBar(
          noteCount: _notes.length,
          sortField: _sortField,
          sortAscending: _sortAscending,
          onSortFieldChanged: (field) => setState(() => _sortField = field),
          onDirectionToggle: () =>
              setState(() => _sortAscending = !_sortAscending),
        ),
        const SizedBox(height: 16),
        ...sorted.map((n) => _NoteTile(note: n)),
      ],
    );
  }
}

class _WardRoundSortBar extends StatelessWidget {
  const _WardRoundSortBar({
    required this.noteCount,
    required this.sortField,
    required this.sortAscending,
    required this.onSortFieldChanged,
    required this.onDirectionToggle,
  });

  final int noteCount;
  final _WardRoundSortField sortField;
  final bool sortAscending;
  final ValueChanged<_WardRoundSortField> onSortFieldChanged;
  final VoidCallback onDirectionToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final countChip = Chip(
      visualDensity: VisualDensity.compact,
      label: Text(
        noteCount == 1 ? '1 note' : '$noteCount notes',
        style: theme.textTheme.labelSmall,
      ),
      backgroundColor: scheme.primaryContainer.withValues(alpha: 0.5),
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );

    final directionButton = Tooltip(
      message: _directionTooltip(sortField, sortAscending),
      child: FilledButton.tonalIcon(
        onPressed: onDirectionToggle,
        icon: Icon(
          sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
          size: 18,
        ),
        label: Text(
          sortField == _WardRoundSortField.date
              ? (sortAscending ? 'Oldest' : 'Newest')
              : (sortAscending ? 'A→Z' : 'Z→A'),
        ),
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.15)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final narrow = c.maxWidth < 520;
          final segmented = SegmentedButton<_WardRoundSortField>(
            segments: narrow
                ? const [
                    ButtonSegment(
                      value: _WardRoundSortField.date,
                      label: Text('Date'),
                      icon: Icon(Icons.schedule, size: 16),
                    ),
                    ButtonSegment(
                      value: _WardRoundSortField.author,
                      label: Text('Author'),
                      icon: Icon(Icons.person_outline, size: 16),
                    ),
                  ]
                : const [
                    ButtonSegment(
                      value: _WardRoundSortField.date,
                      label: Text('Date'),
                      icon: Icon(Icons.schedule, size: 16),
                    ),
                    ButtonSegment(
                      value: _WardRoundSortField.author,
                      label: Text('Author'),
                      icon: Icon(Icons.person_outline, size: 16),
                    ),
                  ],
            selected: {sortField},
            onSelectionChanged: (s) {
              if (s.isNotEmpty) onSortFieldChanged(s.first);
            },
            showSelectedIcon: false,
          );

          if (narrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Text(
                      'Sort by',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    countChip,
                  ],
                ),
                const SizedBox(height: 10),
                segmented,
                const SizedBox(height: 10),
                Align(alignment: Alignment.centerRight, child: directionButton),
              ],
            );
          }

          return Row(
            children: [
              Text(
                'Sort by',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: segmented),
              const SizedBox(width: 12),
              directionButton,
              const SizedBox(width: 8),
              countChip,
            ],
          );
        },
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  const _NoteTile({required this.note});

  final WardRoundNoteModel note;

  static const _soapSections = [
    _SoapSectionDef(
      key: 'subjective',
      label: 'Subjective',
      shortLabel: 'S',
      color: DepartmentColors.radiology,
    ),
    _SoapSectionDef(
      key: 'objective',
      label: 'Objective',
      shortLabel: 'O',
      color: DepartmentColors.frontDesk,
    ),
    _SoapSectionDef(
      key: 'assessment',
      label: 'Assessment',
      shortLabel: 'A',
      color: DepartmentColors.billing,
    ),
    _SoapSectionDef(
      key: 'plan',
      label: 'Plan',
      shortLabel: 'P',
      color: DepartmentColors.emergency,
    ),
  ];

  String? _fieldContent(String key) {
    switch (key) {
      case 'subjective':
        return note.subjective;
      case 'objective':
        return note.objective;
      case 'assessment':
        return note.assessment;
      case 'plan':
        return note.plan;
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateTimeStr =
        DateFormatter.dateTime(_noteSortInstant(note));
    final authorName = note.doctorDisplayName
        ?.trim()
        .split(RegExp(r'\s+'))
        .map((part) => part.capitalize())
        .join(' ');
    final hasAuthor = authorName != null && authorName.isNotEmpty;

    final sections = _soapSections
        .where((s) {
          final content = _fieldContent(s.key);
          return content != null && content.isNotEmpty;
        })
        .toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (hasAuthor)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer
                              .withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.medical_services_outlined,
                              size: 14,
                              color: colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Recorded By $authorName',
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dateTimeStr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...sections.map(
                  (section) => _SoapSectionTile(
                    section: section,
                    content: _fieldContent(section.key)!,
                    useShortLabel: MediaQuery.sizeOf(context).width < 480,
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

class _SoapSectionDef {
  const _SoapSectionDef({
    required this.key,
    required this.label,
    required this.shortLabel,
    required this.color,
  });

  final String key;
  final String label;
  final String shortLabel;
  final Color color;
}

class _SoapSectionTile extends StatelessWidget {
  const _SoapSectionTile({
    required this.section,
    required this.content,
    required this.useShortLabel,
  });

  final _SoapSectionDef section;
  final String content;
  final bool useShortLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: section.color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(10),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: section.color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        useShortLabel ? section.shortLabel : section.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: section.color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ExpandableRichContent(
                      content: content,
                      modalTitle: section.label,
                      previewMaxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoapEditorSlot {
  const _SoapEditorSlot({
    required this.label,
    required this.shortLabel,
    required this.color,
    required this.controller,
    required this.focusNode,
    required this.scrollController,
  });

  final String label;
  final String shortLabel;
  final Color color;
  final QuillController controller;
  final FocusNode focusNode;
  final ScrollController scrollController;
}

double _wardRoundDialogWidth(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final pad = MediaQuery.paddingOf(context).horizontal;
  return math.max(360.0, math.min(980.0, size.width - pad - 24));
}

double _wardRoundDialogHeight(BuildContext context) {
  final size = MediaQuery.sizeOf(context);
  final pad = MediaQuery.paddingOf(context).vertical;
  return math.max(520.0, math.min(size.height - pad - 32, size.height * 0.88));
}

class _SoapCollapsedHeader extends StatelessWidget {
  const _SoapCollapsedHeader({
    required this.slot,
    required this.onTap,
    required this.hasContent,
    this.preview,
  });

  final _SoapEditorSlot slot;
  final VoidCallback onTap;
  final bool hasContent;
  final String? preview;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: slot.color, width: 4),
              bottom: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: slot.color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  slot.shortLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: slot.color,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slot.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (preview != null && preview!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        preview!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ] else if (!hasContent)
                      Text(
                        'Tap to write…',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.4),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasContent)
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: scheme.primary.withValues(alpha: 0.7),
                ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SoapExpandedPanel extends StatelessWidget {
  const _SoapExpandedPanel({
    super.key,
    required this.slot,
    required this.onCollapseTap,
  });

  final _SoapEditorSlot slot;
  final VoidCallback onCollapseTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          left: BorderSide(color: slot.color, width: 4),
          bottom: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: slot.color.withValues(alpha: 0.08),
            child: InkWell(
              onTap: onCollapseTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: slot.color.withValues(alpha: 0.22),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        slot.shortLabel,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: slot.color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        slot.label,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: slot.color,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_up_rounded,
                      color: slot.color,
                    ),
                  ],
                ),
              ),
            ),
          ),
          QuillSimpleToolbar(
            controller: slot.controller,
            config: const QuillSimpleToolbarConfig(
              multiRowsDisplay: true,
              showFontFamily: false,
              showFontSize: false,
              showSearchButton: false,
            ),
          ),
          Divider(
            height: 1,
            color: scheme.outlineVariant.withValues(alpha: 0.5),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: QuillEditor.basic(
                    controller: slot.controller,
                    focusNode: slot.focusNode,
                    scrollController: slot.scrollController,
                    config: const QuillEditorConfig(
                      padding: EdgeInsets.all(12),
                      scrollable: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddWardRoundNoteDialog extends StatefulWidget {
  const _AddWardRoundNoteDialog({
    required this.admissionId,
    required this.doctorId,
    required this.wardRoundNoteService,
    this.initialDraft,
  });

  final String admissionId;
  final String doctorId;
  final WardRoundNoteService wardRoundNoteService;
  final WardRoundNoteDraft? initialDraft;

  @override
  State<_AddWardRoundNoteDialog> createState() =>
      _AddWardRoundNoteDialogState();
}

class _AddWardRoundNoteDialogState extends State<_AddWardRoundNoteDialog> {
  late final QuillController _subjectiveCtrl;
  late final QuillController _objectiveCtrl;
  late final QuillController _assessmentCtrl;
  late final QuillController _planCtrl;

  final _subjectiveFocus = FocusNode();
  final _objectiveFocus = FocusNode();
  final _assessmentFocus = FocusNode();
  final _planFocus = FocusNode();

  final _subjectiveScroll = ScrollController();
  final _objectiveScroll = ScrollController();
  final _assessmentScroll = ScrollController();
  final _planScroll = ScrollController();

  late final List<_SoapEditorSlot> _slots;

  late int _expandedIndex;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final draft = widget.initialDraft;
    _subjectiveCtrl = quillControllerFromStoredContent(draft?.subjective);
    _objectiveCtrl = quillControllerFromStoredContent(draft?.objective);
    _assessmentCtrl = quillControllerFromStoredContent(draft?.assessment);
    _planCtrl = quillControllerFromStoredContent(draft?.plan);
    _expandedIndex = (draft?.expandedIndex ?? 0).clamp(0, 3);

    _slots = [
      _SoapEditorSlot(
        label: 'Subjective',
        shortLabel: 'S',
        color: DepartmentColors.radiology,
        controller: _subjectiveCtrl,
        focusNode: _subjectiveFocus,
        scrollController: _subjectiveScroll,
      ),
      _SoapEditorSlot(
        label: 'Objective',
        shortLabel: 'O',
        color: DepartmentColors.frontDesk,
        controller: _objectiveCtrl,
        focusNode: _objectiveFocus,
        scrollController: _objectiveScroll,
      ),
      _SoapEditorSlot(
        label: 'Assessment',
        shortLabel: 'A',
        color: DepartmentColors.billing,
        controller: _assessmentCtrl,
        focusNode: _assessmentFocus,
        scrollController: _assessmentScroll,
      ),
      _SoapEditorSlot(
        label: 'Plan',
        shortLabel: 'P',
        color: DepartmentColors.emergency,
        controller: _planCtrl,
        focusNode: _planFocus,
        scrollController: _planScroll,
      ),
    ];

    for (final slot in _slots) {
      slot.controller.addListener(_onEditorChanged);
    }
  }

  void _onEditorChanged() {
    if (mounted) setState(() {});
  }

  void _expandSection(int index) {
    if (_expandedIndex == index) return;
    setState(() => _expandedIndex = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _slots[index].focusNode.requestFocus();
    });
  }

  String? _previewFor(_SoapEditorSlot slot) {
    final plain =
        plainTextFromStoredContent(encodeQuillContent(slot.controller));
    if (plain.isEmpty) return null;
    return plain.replaceAll('\n', ' ');
  }

  bool _hasContent(_SoapEditorSlot slot) =>
      (_previewFor(slot)?.isNotEmpty ?? false);

  @override
  void dispose() {
    for (final slot in _slots) {
      slot.controller.removeListener(_onEditorChanged);
    }
    _subjectiveCtrl.dispose();
    _objectiveCtrl.dispose();
    _assessmentCtrl.dispose();
    _planCtrl.dispose();
    _subjectiveFocus.dispose();
    _objectiveFocus.dispose();
    _assessmentFocus.dispose();
    _planFocus.dispose();
    _subjectiveScroll.dispose();
    _objectiveScroll.dispose();
    _assessmentScroll.dispose();
    _planScroll.dispose();
    super.dispose();
  }

  String? _encodedField(QuillController controller) {
    final encoded = encodeQuillContent(controller);
    final plain = plainTextFromStoredContent(encoded);
    return plain.isEmpty ? null : encoded;
  }

  WardRoundNoteDraft _captureDraft() {
    return WardRoundNoteDraft(
      admissionId: widget.admissionId,
      subjective: _encodedField(_subjectiveCtrl),
      objective: _encodedField(_objectiveCtrl),
      assessment: _encodedField(_assessmentCtrl),
      plan: _encodedField(_planCtrl),
      expandedIndex: _expandedIndex,
    );
  }

  bool get _hasAnyContent => _slots.any(_hasContent);

  void _minimize() {
    Navigator.of(context).pop(
      WardRoundNoteDialogResult(
        outcome: WardRoundNoteDialogOutcome.minimized,
        draft: _captureDraft(),
      ),
    );
  }

  Future<void> _discardAndClose() async {
    if (_hasAnyContent) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard note?'),
          content: const Text(
            'You have unsaved ward round notes. Discard them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Keep editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    Navigator.of(context).pop(
      const WardRoundNoteDialogResult(
        outcome: WardRoundNoteDialogOutcome.discarded,
      ),
    );
  }

  Future<void> _save() async {
    final s = _encodedField(_subjectiveCtrl);
    final o = _encodedField(_objectiveCtrl);
    final a = _encodedField(_assessmentCtrl);
    final p = _encodedField(_planCtrl);
    if (s == null && o == null && a == null && p == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter at least one field.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.wardRoundNoteService.create(
        admissionId: widget.admissionId,
        doctorId: widget.doctorId,
        roundDate: DateTime.now(),
        subjective: s,
        objective: o,
        assessment: a,
        plan: p,
      );
      if (!mounted) return;
      Navigator.of(context).pop(
        const WardRoundNoteDialogResult(
          outcome: WardRoundNoteDialogOutcome.saved,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dialogWidth = _wardRoundDialogWidth(context);
    final dialogHeight = _wardRoundDialogHeight(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add ward round note',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Expand one SOAP section at a time — tap a header to switch.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Minimize — keep draft',
                    onPressed: _saving ? null : _minimize,
                    icon: const Icon(Icons.minimize),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: _saving ? null : _discardAndClose,
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < _slots.length; i++) ...[
                    if (_expandedIndex == i)
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: _SoapExpandedPanel(
                            key: ValueKey(_slots[i].label),
                            slot: _slots[i],
                            onCollapseTap: () {},
                          ),
                        ),
                      )
                    else
                      _SoapCollapsedHeader(
                        slot: _slots[i],
                        hasContent: _hasContent(_slots[i]),
                        preview: _previewFor(_slots[i]),
                        onTap: _saving ? () {} : () => _expandSection(i),
                      ),
                  ],
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final slot in _slots)
                        FilterChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(slot.shortLabel),
                          selected: _slots[_expandedIndex] == slot,
                          onSelected: _saving
                              ? null
                              : (_) => _expandSection(_slots.indexOf(slot)),
                          selectedColor:
                              slot.color.withValues(alpha: 0.22),
                          checkmarkColor: slot.color,
                        ),
                    ],
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _saving ? null : _discardAndClose,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save note'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
