import 'package:flutter/material.dart';

import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/ui/config/lab_config_shared.dart';
import 'package:helty/src/lab/ui/widgets/lab_clinical_ui.dart';
import 'package:helty/src/widgets/helty_surface.dart';

class LabConfigTree extends StatelessWidget {
  const LabConfigTree({
    super.key,
    required this.groups,
    required this.expandedIds,
    required this.selectedCategoryId,
    required this.selectedTestId,
    required this.useCards,
    required this.footerLabel,
    required this.expansionLocked,
    required this.onToggle,
    required this.onSelectCategory,
    required this.onSelectTest,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onAddTest,
    required this.onEditTest,
    required this.onDeleteTest,
  });

  final List<LabConfigGroup> groups;
  final Set<String> expandedIds;
  final String? selectedCategoryId;
  final String? selectedTestId;
  final bool useCards;
  final String footerLabel;
  final bool expansionLocked;
  final ValueChanged<String> onToggle;
  final ValueChanged<LabConfigGroup> onSelectCategory;
  final void Function(LabTest test, String groupId) onSelectTest;
  final ValueChanged<LabCategory> onEditCategory;
  final ValueChanged<LabCategory> onDeleteCategory;
  final ValueChanged<LabCategory> onAddTest;
  final ValueChanged<LabTest> onEditTest;
  final ValueChanged<LabTest> onDeleteTest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final rows = _flatten();

    return HeltySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 8),
            child: useCards
                ? HeltyEllipsisText(
                    text: 'Category, then the tests under it',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : _TableHeader(theme: theme, cs: cs),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.7)),
          Expanded(
            child: rows.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Nothing matches this search.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (context, index) {
                      final row = rows[index];
                      if (row.group != null) {
                        return _CategoryHeader(
                          group: row.group!,
                          expanded: expandedIds.contains(row.group!.id),
                          expansionLocked: expansionLocked,
                          selected:
                              selectedTestId == null &&
                              selectedCategoryId == row.group!.id,
                          onToggle: () => onToggle(row.group!.id),
                          onSelect: () => onSelectCategory(row.group!),
                          onEdit: row.group!.category == null
                              ? null
                              : () => onEditCategory(row.group!.category!),
                          onDelete: row.group!.category == null
                              ? null
                              : () => onDeleteCategory(row.group!.category!),
                          onAddTest: row.group!.category == null
                              ? null
                              : () => onAddTest(row.group!.category!),
                        );
                      }
                      if (row.empty) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(44, 8, 12, 10),
                          child: Text(
                            'No tests under this category.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        );
                      }
                      final test = row.test!;
                      return _TestRow(
                        test: test,
                        useCards: useCards,
                        selected: test.id == selectedTestId,
                        fill: test.id == selectedTestId
                            ? cs.primaryContainer
                            : LabClinicalUi.zebraFill(cs, row.zebra),
                        onSelect: () => onSelectTest(test, row.groupId!),
                        onEdit: () => onEditTest(test),
                        onDelete: () => onDeleteTest(test),
                      );
                    },
                  ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.7)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: HeltyEllipsisText(
              text: footerLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_TreeRow> _flatten() {
    final rows = <_TreeRow>[];
    var zebra = 0;
    for (final group in groups) {
      rows.add(_TreeRow.header(group));
      if (!expandedIds.contains(group.id)) continue;
      if (group.tests.isEmpty) {
        rows.add(_TreeRow.empty(group.id));
        continue;
      }
      for (final test in group.tests) {
        rows.add(_TreeRow.test(group.id, test, zebra));
        zebra++;
      }
    }
    return rows;
  }
}

class _TreeRow {
  const _TreeRow.header(this.group)
    : test = null,
      groupId = null,
      zebra = 0,
      empty = false;

  const _TreeRow.test(this.groupId, this.test, this.zebra)
    : group = null,
      empty = false;

  const _TreeRow.empty(this.groupId)
    : group = null,
      test = null,
      zebra = 0,
      empty = true;

  final LabConfigGroup? group;
  final String? groupId;
  final LabTest? test;
  final int zebra;
  final bool empty;
}

class _TableHeader extends StatelessWidget {
  const _TableHeader({required this.theme, required this.cs});

  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final style = theme.textTheme.labelSmall?.copyWith(
      color: cs.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    return Row(
      children: [
        const SizedBox(width: 36),
        Expanded(flex: 5, child: Text('Name', style: style)),
        const SizedBox(width: 20),
        Expanded(flex: 3, child: Text('Sample', style: style)),
        const SizedBox(width: 20),
        SizedBox(width: 72, child: Text('Status', style: style)),
        const SizedBox(width: 36),
      ],
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  const _CategoryHeader({
    required this.group,
    required this.expanded,
    required this.expansionLocked,
    required this.selected,
    required this.onToggle,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onAddTest,
  });

  final LabConfigGroup group;
  final bool expanded;
  final bool expansionLocked;
  final bool selected;
  final VoidCallback onToggle;
  final VoidCallback onSelect;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onAddTest;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final countLabel = group.tests.length == group.totalTests
        ? '${group.totalTests} test${group.totalTests == 1 ? '' : 's'}'
        : '${group.tests.length} of ${group.totalTests}';
    final subtitle = [
      countLabel,
      if (group.description != null && group.description!.trim().isNotEmpty)
        group.description!.trim(),
    ].join(' · ');

    return Material(
      color: selected ? cs.primaryContainer : cs.surfaceContainerHighest,
      child: InkWell(
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
          child: Row(
            children: [
              IconButton(
                tooltip: expansionLocked
                    ? 'Showing matches'
                    : (expanded ? 'Collapse' : 'Expand'),
                visualDensity: VisualDensity.compact,
                onPressed: expansionLocked ? null : onToggle,
                icon: Icon(
                  expanded
                      ? Icons.expand_more_rounded
                      : Icons.chevron_right_rounded,
                ),
              ),
              HeltySolidIcon(
                icon: Icons.folder_rounded,
                color: LabClinicalUi.iconBlue,
                size: 28,
                iconSize: 15,
                radius: 7,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeltyEllipsisText(
                      text: group.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    HeltyEllipsisText(
                      text: subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                PopupMenuButton<String>(
                  tooltip: 'Category actions',
                  onSelected: (action) {
                    switch (action) {
                      case 'add':
                        onAddTest?.call();
                      case 'edit':
                        onEdit?.call();
                      case 'delete':
                        onDelete?.call();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'add', child: Text('Add test')),
                    PopupMenuItem(value: 'edit', child: Text('Edit category')),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete category'),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TestRow extends StatelessWidget {
  const _TestRow({
    required this.test,
    required this.useCards,
    required this.selected,
    required this.fill,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
  });

  final LabTest test;
  final bool useCards;
  final bool selected;
  final Color fill;
  final VoidCallback onSelect;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final nameStyle = theme.textTheme.bodyMedium?.copyWith(
      fontWeight: FontWeight.w600,
      color: test.isActive ? cs.onSurface : cs.onSurfaceVariant,
    );

    return Material(
      color: fill,
      child: InkWell(
        onTap: onSelect,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
          child: Row(
            children: [
              const SizedBox(width: 28),
              Container(width: 2, height: 28, color: LabClinicalUi.iconTeal),
              const SizedBox(width: 10),
              HeltySolidIcon(
                icon: Icons.science_rounded,
                color: test.isActive
                    ? LabClinicalUi.iconTeal
                    : LabClinicalUi.iconAmber,
                size: 28,
                iconSize: 15,
                radius: 7,
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: useCards
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HeltyEllipsisText(text: test.name, style: nameStyle),
                          HeltyEllipsisText(
                            text: test.isActive
                                ? test.sampleType
                                : '${test.sampleType} · Inactive',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      )
                    : HeltyEllipsisText(text: test.name, style: nameStyle),
              ),
              if (!useCards) ...[
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: HeltyEllipsisText(
                    text: test.sampleType,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: 72,
                  child: test.isActive
                      ? const SizedBox.shrink()
                      : const HeltyStatusChip(
                          label: 'Inactive',
                          color: LabClinicalUi.iconAmber,
                        ),
                ),
              ],
              PopupMenuButton<String>(
                tooltip: 'Test actions',
                onSelected: (action) {
                  if (action == 'edit') onEdit();
                  if (action == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit test')),
                  PopupMenuItem(value: 'delete', child: Text('Delete test')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
