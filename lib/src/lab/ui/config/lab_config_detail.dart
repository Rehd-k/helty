import 'package:flutter/material.dart';

import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/ui/config/lab_config_shared.dart';
import 'package:helty/src/lab/ui/widgets/lab_clinical_ui.dart';
import 'package:helty/src/widgets/helty_surface.dart';

class LabConfigDetailActions {
  const LabConfigDetailActions({
    required this.onBack,
    required this.onOpenCategory,
    required this.onSelectTest,
    required this.onSelectVersion,
    required this.onEditCategory,
    required this.onDeleteCategory,
    required this.onAddTest,
    required this.onEditTest,
    required this.onDeleteTest,
    required this.onCreateVersion,
    required this.onRetry,
    required this.onAddField,
    required this.onEditField,
    required this.onDeleteField,
    required this.onMoveField,
  });

  final VoidCallback onBack;
  final VoidCallback onOpenCategory;
  final ValueChanged<LabTest> onSelectTest;
  final ValueChanged<LabTestVersion> onSelectVersion;
  final VoidCallback onEditCategory;
  final VoidCallback onDeleteCategory;
  final VoidCallback onAddTest;
  final VoidCallback onEditTest;
  final VoidCallback onDeleteTest;
  final VoidCallback onCreateVersion;
  final VoidCallback onRetry;
  final VoidCallback onAddField;
  final ValueChanged<LabTestField> onEditField;
  final ValueChanged<LabTestField> onDeleteField;
  final void Function(LabTestField field, int delta) onMoveField;
}

class LabConfigDetail extends StatelessWidget {
  const LabConfigDetail({
    super.key,
    required this.category,
    required this.test,
    required this.categoryTests,
    required this.versions,
    required this.fields,
    required this.selectedVersionId,
    required this.loadingVersions,
    required this.loadingFields,
    required this.error,
    required this.useCards,
    required this.showBack,
    required this.actions,
  });

  final LabCategory? category;
  final LabTest? test;
  final List<LabTest> categoryTests;
  final List<LabTestVersion>? versions;
  final List<LabTestField>? fields;
  final String? selectedVersionId;
  final bool loadingVersions;
  final bool loadingFields;
  final String? error;
  final bool useCards;
  final bool showBack;
  final LabConfigDetailActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final body = test == null && category == null
        ? _EmptyDetail(theme: theme, cs: cs)
        : test != null
        ? _TestDetail(
            test: test!,
            category: category,
            versions: versions,
            fields: fields,
            selectedVersionId: selectedVersionId,
            loadingVersions: loadingVersions,
            loadingFields: loadingFields,
            error: error,
            useCards: useCards,
            showBack: showBack,
            actions: actions,
          )
        : _CategoryDetail(
            category: category!,
            tests: categoryTests,
            showBack: showBack,
            actions: actions,
          );
    return HeltySurfaceCard(child: SizedBox.expand(child: body));
  }
}

class _EmptyDetail extends StatelessWidget {
  const _EmptyDetail({required this.theme, required this.cs});

  final ThemeData theme;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HeltySolidIcon(
              icon: Icons.account_tree_outlined,
              color: LabClinicalUi.iconIndigo,
              size: 36,
              iconSize: 18,
            ),
            const SizedBox(height: 12),
            Text(
              'Select a category or test',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Categories hold tests. A test holds versions, and each version holds the result fields staff fill in.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryDetail extends StatelessWidget {
  const _CategoryDetail({
    required this.category,
    required this.tests,
    required this.showBack,
    required this.actions,
  });

  final LabCategory category;
  final List<LabTest> tests;
  final bool showBack;
  final LabConfigDetailActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailHeader(
          icon: Icons.folder_rounded,
          iconColor: LabClinicalUi.iconBlue,
          title: category.name,
          path: 'Category',
          meta: [
            '${tests.length} test${tests.length == 1 ? '' : 's'}',
            if (category.description != null &&
                category.description!.trim().isNotEmpty)
              category.description!.trim(),
          ].join(' · '),
          showBack: showBack,
          onBack: actions.onBack,
          actions: [
            _ActionButton(
              label: 'Add test',
              icon: Icons.add_rounded,
              onPressed: actions.onAddTest,
            ),
            _ActionButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              onPressed: actions.onEditCategory,
              tonal: true,
            ),
            _ActionButton(
              label: 'Delete',
              icon: Icons.delete_outline_rounded,
              onPressed: actions.onDeleteCategory,
              danger: true,
            ),
          ],
        ),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.7)),
        Expanded(
          child: tests.isEmpty
              ? Center(
                  child: Text(
                    'No tests under ${category.name} yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: tests.length,
                  itemBuilder: (context, index) {
                    final test = tests[index];
                    return _ChildTestTile(
                      test: test,
                      fill: LabClinicalUi.zebraFill(cs, index),
                      onTap: () => actions.onSelectTest(test),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _TestDetail extends StatelessWidget {
  const _TestDetail({
    required this.test,
    required this.category,
    required this.versions,
    required this.fields,
    required this.selectedVersionId,
    required this.loadingVersions,
    required this.loadingFields,
    required this.error,
    required this.useCards,
    required this.showBack,
    required this.actions,
  });

  final LabTest test;
  final LabCategory? category;
  final List<LabTestVersion>? versions;
  final List<LabTestField>? fields;
  final String? selectedVersionId;
  final bool loadingVersions;
  final bool loadingFields;
  final String? error;
  final bool useCards;
  final bool showBack;
  final LabConfigDetailActions actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selected = versions
        ?.where((version) => version.id == selectedVersionId)
        .firstOrNull;
    final sortedFields = [...?fields]
      ..sort((a, b) {
        final byPosition = a.position.compareTo(b.position);
        if (byPosition != 0) return byPosition;
        return compareLabText(a.label, b.label);
      });
    final meta = [
      test.sampleType,
      if (!test.isActive) 'Inactive',
      if (test.price != null) test.price!.toFinancial(isMoney: true),
      if (test.description != null && test.description!.trim().isNotEmpty)
        test.description!.trim(),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DetailHeader(
          icon: Icons.science_rounded,
          iconColor: test.isActive
              ? LabClinicalUi.iconTeal
              : LabClinicalUi.iconAmber,
          title: test.name,
          path: category?.name ?? 'Test',
          pathTappable: category != null,
          onPath: actions.onOpenCategory,
          meta: meta,
          showBack: showBack,
          onBack: actions.onBack,
          actions: [
            _ActionButton(
              label: 'New version',
              icon: Icons.add_rounded,
              onPressed: loadingVersions ? null : actions.onCreateVersion,
            ),
            _ActionButton(
              label: 'Edit',
              icon: Icons.edit_outlined,
              onPressed: actions.onEditTest,
              tonal: true,
            ),
            _ActionButton(
              label: 'Delete',
              icon: Icons.delete_outline_rounded,
              onPressed: actions.onDeleteTest,
              danger: true,
            ),
          ],
        ),
        if (category != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: HeltyEllipsisText(
              text:
                  '${category!.name}  ›  ${test.name}'
                  '${selected == null ? '' : '  ›  v${selected.versionNumber}'}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        Divider(height: 1, color: cs.outlineVariant.withValues(alpha: 0.7)),
        if (loadingVersions && (versions == null || versions!.isEmpty))
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else if (error != null && (versions == null))
          Expanded(
            child: _ErrorNote(message: error!, onRetry: actions.onRetry),
          )
        else ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: versions == null || versions!.isEmpty
                ? Text(
                    'No versions yet. Create one to add result fields.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  )
                : SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: versions!.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final version = versions![index];
                        final count = version.fieldCount;
                        final label =
                            'v${version.versionNumber}'
                            '${version.isActive ? ' · Active' : ''}'
                            '${count == null ? '' : ' · $count'}';
                        return ChoiceChip(
                          label: Text(label),
                          selected: version.id == selectedVersionId,
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => actions.onSelectVersion(version),
                        );
                      },
                    ),
                  ),
          ),
          if (selectedVersionId != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Result fields',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: actions.onAddField,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add field'),
                  ),
                ],
              ),
            ),
            if (!useCards)
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 0, 12, 4),
                child: _FieldHeader(),
              ),
            Expanded(
              child: loadingFields
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? _ErrorNote(message: error!, onRetry: actions.onRetry)
                  : sortedFields.isEmpty
                  ? Center(
                      child: Text(
                        'This version has no result fields yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: sortedFields.length,
                      itemBuilder: (context, index) {
                        final field = sortedFields[index];
                        return _FieldRow(
                          field: field,
                          index: index,
                          count: sortedFields.length,
                          useCards: useCards,
                          fill: LabClinicalUi.zebraFill(cs, index),
                          onEdit: () => actions.onEditField(field),
                          onDelete: () => actions.onDeleteField(field),
                          onMove: (delta) => actions.onMoveField(field, delta),
                        );
                      },
                    ),
            ),
          ] else
            const Spacer(),
        ],
      ],
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.path,
    required this.meta,
    required this.showBack,
    required this.onBack,
    required this.actions,
    this.pathTappable = false,
    this.onPath,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String path;
  final String meta;
  final bool showBack;
  final VoidCallback onBack;
  final List<Widget> actions;
  final bool pathTappable;
  final VoidCallback? onPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final pathStyle = theme.textTheme.labelMedium?.copyWith(
      color: pathTappable ? LabClinicalUi.iconBlue : cs.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showBack) ...[
                IconButton(
                  tooltip: 'Back to catalog',
                  visualDensity: VisualDensity.compact,
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 4),
              ],
              HeltySolidIcon(
                icon: icon,
                color: iconColor,
                size: 34,
                iconSize: 18,
                radius: AppTheme.radiusMd,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    pathTappable
                        ? InkWell(
                            onTap: onPath,
                            child: HeltyEllipsisText(
                              text: path,
                              style: pathStyle,
                            ),
                          )
                        : HeltyEllipsisText(text: path, style: pathStyle),
                    HeltyEllipsisText(
                      text: title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (meta.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            HeltyEllipsisText(
              text: meta,
              maxLines: 2,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: actions),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tonal = false,
    this.danger = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool tonal;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Icon(icon, size: 16);
    if (danger) {
      return TextButton.icon(
        onPressed: onPressed,
        icon: iconWidget,
        label: Text(label),
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          foregroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
    if (tonal) {
      return FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: iconWidget,
        label: Text(label),
        style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
      );
    }
    return FilledButton.icon(
      onPressed: onPressed,
      icon: iconWidget,
      label: Text(label),
      style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
    );
  }
}

class _ChildTestTile extends StatelessWidget {
  const _ChildTestTile({
    required this.test,
    required this.fill,
    required this.onTap,
  });

  final LabTest test;
  final Color fill;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Material(
      color: fill,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HeltyEllipsisText(
                      text: test.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    HeltyEllipsisText(
                      text: test.isActive
                          ? test.sampleType
                          : '${test.sampleType} · Inactive',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldHeader extends StatelessWidget {
  const _FieldHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w700,
    );
    return Row(
      children: [
        const SizedBox(width: 38),
        Expanded(flex: 4, child: Text('Field', style: style)),
        const SizedBox(width: 20),
        Expanded(flex: 2, child: Text('Type', style: style)),
        const SizedBox(width: 20),
        Expanded(flex: 2, child: Text('Unit', style: style)),
        const SizedBox(width: 20),
        Expanded(flex: 2, child: Text('Range', style: style)),
        const SizedBox(width: 88),
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({
    required this.field,
    required this.index,
    required this.count,
    required this.useCards,
    required this.fill,
    required this.onEdit,
    required this.onDelete,
    required this.onMove,
  });

  final LabTestField field;
  final int index;
  final int count;
  final bool useCards;
  final Color fill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<int> onMove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final typeLabel = labFieldTypeLabel(field.fieldType);
    final flags = [
      if (field.required) 'Required',
      if (field.options.isNotEmpty)
        '${field.options.length} option${field.options.length == 1 ? '' : 's'}',
    ].join(' · ');

    final menu = PopupMenuButton<String>(
      tooltip: 'Field actions',
      onSelected: (action) {
        switch (action) {
          case 'up':
            onMove(-1);
          case 'down':
            onMove(1);
          case 'edit':
            onEdit();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        if (index > 0) const PopupMenuItem(value: 'up', child: Text('Move up')),
        if (index < count - 1)
          const PopupMenuItem(value: 'down', child: Text('Move down')),
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );

    return Material(
      color: fill,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
          child: useCards
              ? Row(
                  children: [
                    HeltySolidIcon(
                      icon: labFieldTypeIcon(field.fieldType),
                      color: labFieldTypeColor(field.fieldType),
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
                            text: field.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          HeltyEllipsisText(
                            text: [
                              typeLabel,
                              if (field.unit != null && field.unit!.isNotEmpty)
                                field.unit!,
                              if (field.referenceRange != null &&
                                  field.referenceRange!.isNotEmpty)
                                field.referenceRange!,
                              if (flags.isNotEmpty) flags,
                            ].join(' · '),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    menu,
                  ],
                )
              : Row(
                  children: [
                    HeltySolidIcon(
                      icon: labFieldTypeIcon(field.fieldType),
                      color: labFieldTypeColor(field.fieldType),
                      size: 28,
                      iconSize: 15,
                      radius: 7,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HeltyEllipsisText(
                            text: field.label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (flags.isNotEmpty)
                            HeltyEllipsisText(
                              text: flags,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: HeltyEllipsisText(
                        text: typeLabel,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: HeltyEllipsisText(
                        text: field.unit?.trim().isNotEmpty == true
                            ? field.unit!
                            : '—',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      flex: 2,
                      child: HeltyEllipsisText(
                        text: field.referenceRange?.trim().isNotEmpty == true
                            ? field.referenceRange!
                            : '—',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    menu,
                  ],
                ),
        ),
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.error),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
