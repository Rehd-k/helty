import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/utils/lab_reference_evaluation.dart';
import 'package:helty/src/models/lab_order_model.dart';

/// Read-only review dialog for a single operational lab order item (head of lab).
void showLabOrderItemReviewDialog(
  BuildContext context, {
  required LabOrderItem item,
}) {
  final theme = Theme.of(context);
  final testName = item.testVersion?.test?.name ?? 'Test';
  final sampleType = item.testVersion?.test?.sampleType ?? '';
  final fields = item.fields ?? item.testVersion?.fields ?? [];
  final fieldMap = {for (final f in fields) f.id: f};

  final lines = item.results.map((result) {
    final field = result.field ?? fieldMap[result.fieldId];
    return (
      line: LabOrderResultLine(
        label: field?.label ?? result.fieldId,
        value: result.value,
        unit: field?.unit,
        referenceRange: field?.referenceRange,
        referenceEvaluation: result.referenceEvaluation,
        position: field?.position ?? 0,
      ),
      hiddenFromReport: result.hiddenFromReport,
    );
  }).toList()
    ..sort((a, b) => a.line.position.compareTo(b.line.position));

  showDialog<void>(
    context: context,
    builder: (ctx) => _LabResultsDialogShell(
      title: testName,
      subtitle: sampleType.isNotEmpty ? sampleType : null,
      statusLabel: item.results.isNotEmpty ? 'Results available' : 'Pending',
      statusTone: item.results.isNotEmpty
          ? _LabStatusTone.success
          : _LabStatusTone.pending,
      metaChips: [
        if (sampleType.isNotEmpty)
          _LabMetaChip(icon: Icons.water_drop_outlined, label: sampleType),
        if (item.sample != null)
          _LabMetaChip(
            icon: Icons.schedule_outlined,
            label: DateFormatter.formatFromBackend(
              item.sample!.collectionTime.toIso8601String(),
              DateFormatter.dateTime,
            ),
          ),
        if (item.astRequested)
          _LabMetaChip(icon: Icons.biotech_outlined, label: 'AST requested'),
      ],
      resultsSection: _LabResultsPanel(
        theme: theme,
        lines: lines.map((e) => e.line).toList(),
        hiddenFlags: lines.map((e) => e.hiddenFromReport).toList(),
        emptyMessage: 'No results yet.',
      ),
      trailingSection: item.astRequested
          ? _LabOrderItemAstSection(item: item, theme: theme)
          : null,
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

/// Full lab result dialog shared by nurses, doctors, and completed-encounter review.
void showLabOrderResultsDialog(
  BuildContext context, {
  required LabOrderModel order,
  Future<void> Function()? onDelete,
  bool showEncounterId = true,
}) {
  final theme = Theme.of(context);
  final lines = order.resultLines;
  final hasLegacyMap =
      order.resultValues != null && order.resultValues!.isNotEmpty;
  final hasResults =
      (lines != null && lines.isNotEmpty) ||
      hasLegacyMap;

  final metaChips = <_LabMetaChip>[
    _LabMetaChip(
      icon: Icons.schedule_outlined,
      label: DateFormatter.formatFromBackend(
        order.createdAt,
        DateFormatter.dateTime,
      ),
    ),
    _LabMetaChip(
      icon: Icons.flag_outlined,
      label: order.priority ?? 'Routine',
    ),
    if (order.clinicalNotes != null && order.clinicalNotes!.isNotEmpty)
      _LabMetaChip(icon: Icons.notes_outlined, label: order.clinicalNotes!),
    if (showEncounterId && order.encounterId.isNotEmpty)
      _LabMetaChip(icon: Icons.tag_outlined, label: order.encounterId),
  ];

  Widget resultsSection;
  if (lines != null && lines.isNotEmpty) {
    resultsSection = _LabResultsPanel(
      theme: theme,
      lines: lines,
      emptyMessage: 'No results yet.',
    );
  } else if (hasLegacyMap) {
    resultsSection = _LabLegacyResultsPanel(
      theme: theme,
      values: order.resultValues!,
    );
  } else {
    resultsSection = _LabResultsEmptyState(theme: theme);
  }

  showDialog<void>(
    context: context,
    builder: (ctx) => _LabResultsDialogShell(
      title: order.testType,
      statusLabel: order.status,
      statusTone: _labStatusToneFromLabel(order.status, hasResults: hasResults),
      metaChips: metaChips,
      resultsSection: resultsSection,
      actions: [
        if (onDelete != null)
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await onDelete();
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            child: const Text('Delete request'),
          ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

enum _LabStatusTone { pending, inProgress, success, error, neutral }

_LabStatusTone _labStatusToneFromLabel(String status, {required bool hasResults}) {
  final s = status.toLowerCase();
  if (s.contains('cancel') || s.contains('reject')) return _LabStatusTone.error;
  if (hasResults ||
      s.contains('complete') ||
      s.contains('verified') ||
      s.contains('reported')) {
    return _LabStatusTone.success;
  }
  if (s.contains('process') ||
      s.contains('sample') ||
      s.contains('progress') ||
      s.contains('collect')) {
    return _LabStatusTone.inProgress;
  }
  if (s.contains('pending') || s.contains('ordered')) {
    return _LabStatusTone.pending;
  }
  return _LabStatusTone.neutral;
}

(Color, Color) _labStatusBadgeColors(ThemeData theme, _LabStatusTone tone) {
  final cs = theme.colorScheme;
  return switch (tone) {
    _LabStatusTone.success => (cs.primaryContainer, cs.onPrimaryContainer),
    _LabStatusTone.inProgress => (cs.tertiaryContainer, cs.onTertiaryContainer),
    _LabStatusTone.pending => (cs.secondaryContainer, cs.onSecondaryContainer),
    _LabStatusTone.error => (cs.errorContainer, cs.onErrorContainer),
    _LabStatusTone.neutral => (cs.surfaceContainerHighest, cs.onSurfaceVariant),
  };
}

class _LabMetaChip {
  const _LabMetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _LabResultsDialogShell extends StatelessWidget {
  const _LabResultsDialogShell({
    required this.title,
    required this.statusLabel,
    required this.statusTone,
    required this.metaChips,
    required this.resultsSection,
    required this.actions,
    this.subtitle,
    this.trailingSection,
  });

  final String title;
  final String? subtitle;
  final String statusLabel;
  final _LabStatusTone statusTone;
  final List<_LabMetaChip> metaChips;
  final Widget resultsSection;
  final Widget? trailingSection;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final (badgeBg, badgeFg) = _labStatusBadgeColors(theme, statusTone);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                border: Border(
                  bottom: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.biotech_rounded,
                      color: cs.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            statusLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: badgeFg,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (metaChips.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: metaChips
                            .map((chip) => _MetaChipWidget(chip: chip, theme: theme))
                            .toList(),
                      ),
                      const SizedBox(height: 18),
                    ],
                    resultsSection,
                    if (trailingSection != null) ...[
                      const SizedBox(height: 18),
                      trailingSection!,
                    ],
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                border: Border(
                  top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.45)),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    actions[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChipWidget extends StatelessWidget {
  const _MetaChipWidget({required this.chip, required this.theme});

  final _LabMetaChip chip;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chip.icon, size: 15, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              chip.label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurface,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabResultsPanel extends StatelessWidget {
  const _LabResultsPanel({
    required this.theme,
    required this.lines,
    required this.emptyMessage,
    this.hiddenFlags = const [],
  });

  final ThemeData theme;
  final List<LabOrderResultLine> lines;
  final String emptyMessage;
  final List<bool> hiddenFlags;

  @override
  Widget build(BuildContext context) {
    if (lines.isEmpty) {
      return _LabResultsEmptyState(theme: theme, message: emptyMessage);
    }

    final abnormalCount = lines.where((line) {
      final eval = resolveLabReferenceEvaluation(
        value: line.value,
        referenceRange: line.referenceRange,
        serverEvaluation: line.referenceEvaluation,
      );
      return labResultIsAbnormal(eval);
    }).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Results',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${lines.length} parameter${lines.length == 1 ? '' : 's'}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (abnormalCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$abnormalCount abnormal',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: Text(
                        'Analyte',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Result',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        'Reference',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
              ...lines.asMap().entries.map((entry) {
                final isLast = entry.key == lines.length - 1;
                final hidden = entry.key < hiddenFlags.length
                    ? hiddenFlags[entry.key]
                    : false;
                return _LabOrderResultLineRow(
                  line: entry.value,
                  theme: theme,
                  hiddenFromReport: hidden,
                  showDivider: !isLast,
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _LabLegacyResultsPanel extends StatelessWidget {
  const _LabLegacyResultsPanel({
    required this.theme,
    required this.values,
  });

  final ThemeData theme;
  final Map<String, String> values;

  @override
  Widget build(BuildContext context) {
    final entries = values.entries.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Results',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Column(
            children: entries.asMap().entries.map((entry) {
              final isLast = entry.key == entries.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: Text(
                            entry.value.key,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text(
                            entry.value.value,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _LabResultsEmptyState extends StatelessWidget {
  const _LabResultsEmptyState({required this.theme, this.message});

  final ThemeData theme;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 32,
            color: cs.onSurfaceVariant.withValues(alpha: 0.7),
          ),
          const SizedBox(height: 10),
          Text(
            message ?? 'No results yet.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Results will appear here once the lab completes testing.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LabOrderResultLineRow extends StatelessWidget {
  const _LabOrderResultLineRow({
    required this.line,
    required this.theme,
    this.hiddenFromReport = false,
    this.showDivider = true,
  });

  final LabOrderResultLine line;
  final ThemeData theme;
  final bool hiddenFromReport;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final eval = resolveLabReferenceEvaluation(
      value: line.value,
      referenceRange: line.referenceRange,
      serverEvaluation: line.referenceEvaluation,
    );
    final abnormal = labResultIsAbnormal(eval);
    final flagLabel = labReferenceFlagShortLabel(eval);
    final valueColor = labReferenceValueColor(theme, eval);
    final refText = line.referenceRange?.trim().isNotEmpty == true
        ? line.referenceRange!
        : eval?.referenceRange?.trim().isNotEmpty == true
        ? eval!.referenceRange!
        : null;
    final accentColor = abnormal
        ? theme.colorScheme.error
        : theme.colorScheme.primary.withValues(alpha: 0.55);

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(14),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.label,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (hiddenFromReport) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Hidden from report',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              line.valueWithUnit,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: valueColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            if (flagLabel != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.errorContainer,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  flagLabel,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          refText ?? '—',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
      ],
    );
  }
}

class _LabOrderItemAstSection extends StatelessWidget {
  const _LabOrderItemAstSection({
    required this.item,
    required this.theme,
  });

  final LabOrderItem item;
  final ThemeData theme;

  List<LabAstResult> get _sortedResults {
    final list = List<LabAstResult>.from(item.astResults)
      ..sort((a, b) {
        final pc = a.antibiotic.position.compareTo(b.antibiotic.position);
        return pc != 0 ? pc : a.antibiotic.name.compareTo(b.antibiotic.name);
      });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final results = _sortedResults;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.biotech_outlined,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Antibiotic Susceptibility',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (results.isEmpty)
            Text(
              'AST pending',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Antibiotic',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Result',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ...results.map((r) {
              final abxName = r.antibiotic.code != null &&
                      r.antibiotic.code!.isNotEmpty
                  ? '${r.antibiotic.name} (${r.antibiotic.code})'
                  : r.antibiotic.name;
              final resultLabel = r.resultOption.code != null &&
                      r.resultOption.code!.isNotEmpty
                  ? '${r.resultOption.label} (${r.resultOption.code})'
                  : r.resultOption.label;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(abxName, style: theme.textTheme.bodyMedium),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          resultLabel,
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}
