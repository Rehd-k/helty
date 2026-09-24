import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import '../../core/extensions/number.extention.dart';
import '../../lab/ui/widgets/lab_clinical_ui.dart';
import '../../widgets/helty_surface.dart';
import '../models/investigation_models.dart';
import '../models/investigation_query_params.dart';

export 'investigation_list_table.dart';

class InvestigationKpiCard extends StatelessWidget {
  const InvestigationKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = accent ?? theme.colorScheme.primary;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              foregroundColor: color,
              child: Icon(icon, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
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

typedef InvestigationTestDetailCallback =
    void Function(String testName, int count);

typedef InvestigationDepartmentDetailCallback =
    void Function(String departmentId, String departmentName, int count);

class InvestigationBreakdownTables extends StatelessWidget {
  const InvestigationBreakdownTables({
    super.key,
    required this.summary,
    this.onPrintSummaryByTest,
    this.onShareSummaryByTest,
    this.onPrintSummaryByDepartment,
    this.onShareSummaryByDepartment,
    this.onPrintTestDetails,
    this.onShareTestDetails,
    this.onPrintDepartmentDetails,
    this.onShareDepartmentDetails,
    this.exporting = false,
    this.fillHeight = false,
    this.shrinkWrap = false,
  });

  final InvestigationSummary summary;
  final VoidCallback? onPrintSummaryByTest;
  final VoidCallback? onShareSummaryByTest;
  final VoidCallback? onPrintSummaryByDepartment;
  final VoidCallback? onShareSummaryByDepartment;
  final InvestigationTestDetailCallback? onPrintTestDetails;
  final InvestigationTestDetailCallback? onShareTestDetails;
  final InvestigationDepartmentDetailCallback? onPrintDepartmentDetails;
  final InvestigationDepartmentDetailCallback? onShareDepartmentDetails;
  final bool exporting;
  final bool fillHeight;
  final bool shrinkWrap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked =
            constraints.maxWidth <
            ((fillHeight || shrinkWrap) ? LabClinicalUi.cardBreakpoint : 900);
        final testTable = _BreakdownTable(
          title: 'By test name',
          icon: Icons.science_outlined,
          iconColor: LabClinicalUi.iconPurple,
          columns: const ['Test', 'Count', 'Amount'],
          rows: summary.byTestName
              .map(
                (r) => [
                  r.testName,
                  '${r.count}',
                  r.amount.toFinancial(isMoney: true),
                ],
              )
              .toList(),
          onPrintSummary: onPrintSummaryByTest,
          onShareSummary: onShareSummaryByTest,
          exporting: exporting,
          fillHeight: fillHeight,
          shrinkWrap: shrinkWrap,
          rowActions: onPrintTestDetails == null && onShareTestDetails == null
              ? null
              : summary.byTestName
                    .map(
                      (r) => _BreakdownRowActions(
                        count: r.count,
                        onPrint: onPrintTestDetails == null
                            ? null
                            : () => onPrintTestDetails!(r.testName, r.count),
                        onShare: onShareTestDetails == null
                            ? null
                            : () => onShareTestDetails!(r.testName, r.count),
                        exporting: exporting,
                      ),
                    )
                    .toList(),
        );
        final deptTable = _BreakdownTable(
          title: 'By department',
          icon: Icons.apartment_outlined,
          iconColor: LabClinicalUi.iconTeal,
          columns: const ['Department', 'Count', 'Amount'],
          rows: summary.byDepartment
              .map(
                (r) => [
                  r.departmentName,
                  '${r.count}',
                  r.amount.toFinancial(isMoney: true),
                ],
              )
              .toList(),
          onPrintSummary: onPrintSummaryByDepartment,
          onShareSummary: onShareSummaryByDepartment,
          exporting: exporting,
          fillHeight: fillHeight,
          shrinkWrap: shrinkWrap,
          rowActions:
              onPrintDepartmentDetails == null &&
                  onShareDepartmentDetails == null
              ? null
              : summary.byDepartment
                    .map(
                      (r) => _BreakdownRowActions(
                        count: r.count,
                        onPrint: onPrintDepartmentDetails == null
                            ? null
                            : () => onPrintDepartmentDetails!(
                                r.departmentId,
                                r.departmentName,
                                r.count,
                              ),
                        onShare: onShareDepartmentDetails == null
                            ? null
                            : () => onShareDepartmentDetails!(
                                r.departmentId,
                                r.departmentName,
                                r.count,
                              ),
                        exporting: exporting,
                      ),
                    )
                    .toList(),
        );

        if (stacked) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (fillHeight && !shrinkWrap)
                Expanded(child: testTable)
              else
                testTable,
              SizedBox(height: fillHeight || shrinkWrap ? 10 : 16),
              if (fillHeight && !shrinkWrap)
                Expanded(child: deptTable)
              else
                deptTable,
            ],
          );
        }
        return Row(
          crossAxisAlignment: fillHeight && !shrinkWrap
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          children: [
            Expanded(child: testTable),
            SizedBox(width: fillHeight || shrinkWrap ? 10 : 16),
            Expanded(child: deptTable),
          ],
        );
      },
    );
  }
}

class _BreakdownRowActions {
  const _BreakdownRowActions({
    required this.count,
    this.onPrint,
    this.onShare,
    this.exporting = false,
  });

  final int count;
  final VoidCallback? onPrint;
  final VoidCallback? onShare;
  final bool exporting;
}

class _BreakdownTable extends StatelessWidget {
  const _BreakdownTable({
    required this.title,
    required this.columns,
    required this.rows,
    this.icon = Icons.table_chart_outlined,
    this.iconColor = LabClinicalUi.iconIndigo,
    this.onPrintSummary,
    this.onShareSummary,
    this.rowActions,
    this.exporting = false,
    this.fillHeight = false,
    this.shrinkWrap = false,
  });

  final String title;
  final List<String> columns;
  final List<List<String>> rows;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onPrintSummary;
  final VoidCallback? onShareSummary;
  final List<_BreakdownRowActions>? rowActions;
  final bool exporting;
  final bool fillHeight;
  final bool shrinkWrap;

  bool get _hasSummaryActions =>
      onPrintSummary != null || onShareSummary != null;

  bool get _hasRowActions =>
      rowActions != null &&
      rowActions!.any((a) => a.onPrint != null || a.onShare != null);

  @override
  Widget build(BuildContext context) {
    if (fillHeight || shrinkWrap) return _buildFilled(context);
    return _buildLegacy(context);
  }

  Widget _titleBar(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        fillHeight || shrinkWrap ? 12 : 0,
        fillHeight || shrinkWrap ? 10 : 0,
        8,
        6,
      ),
      child: Row(
        children: [
          HeltySolidIcon(
            icon: icon,
            color: iconColor,
            size: 26,
            iconSize: 14,
            radius: 7,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: HeltyEllipsisText(
              text: title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (_hasSummaryActions && rows.isNotEmpty) ...[
            _ExportIconButton(
              tooltip: 'Print summary',
              icon: Icons.print_rounded,
              onPressed: exporting ? null : onPrintSummary,
            ),
            _ExportIconButton(
              tooltip: 'Save summary as PDF',
              icon: Icons.ios_share_rounded,
              onPressed: exporting ? null : onShareSummary,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilled(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasActions = _hasRowActions;
    const colGap = 20.0;

    Widget head(String label, {int flex = 1, bool alignEnd = false}) {
      return Expanded(
        flex: flex,
        child: Text(
          label,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    final unbounded = shrinkWrap;
    final emptyState = Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          'No data for selected filters.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      ),
    );

    final list = ListView.separated(
      shrinkWrap: unbounded,
      physics: unbounded
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      itemCount: rows.length,
      separatorBuilder: (_, _) =>
          Divider(height: 1, color: cs.outline.withValues(alpha: 0.08)),
      itemBuilder: (context, i) {
        final row = rows[i];
        final actions = rowActions != null && i < rowActions!.length
            ? rowActions![i]
            : const _BreakdownRowActions(count: 0);
        return ColoredBox(
          color: LabClinicalUi.zebraFill(cs, i),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: HeltyEllipsisText(
                    text: row.isNotEmpty ? row[0] : '—',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: colGap),
                Expanded(
                  flex: 2,
                  child: HeltyEllipsisText(text: row.length > 1 ? row[1] : '—'),
                ),
                const SizedBox(width: colGap),
                Expanded(
                  flex: 2,
                  child: HeltyEllipsisText(
                    text: row.length > 2 ? row[2] : '—',
                    align: TextAlign.end,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (hasActions) ...[
                  const SizedBox(width: colGap),
                  SizedBox(
                    width: 72,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: _BreakdownRowActionButtons(actions: actions),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    final header = Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Row(
        children: [
          head(columns.isNotEmpty ? columns[0].toUpperCase() : 'NAME', flex: 5),
          const SizedBox(width: colGap),
          head(
            columns.length > 1 ? columns[1].toUpperCase() : 'COUNT',
            flex: 2,
          ),
          const SizedBox(width: colGap),
          head(
            columns.length > 2 ? columns[2].toUpperCase() : 'AMOUNT',
            flex: 2,
            alignEnd: true,
          ),
          if (hasActions) ...[
            const SizedBox(width: colGap),
            const SizedBox(width: 72),
          ],
        ],
      ),
    );

    return HeltySurfaceCard(
      child: Column(
        mainAxisSize: unbounded ? MainAxisSize.min : MainAxisSize.max,
        children: [
          _titleBar(context),
          if (rows.isEmpty)
            unbounded ? emptyState : Expanded(child: emptyState)
          else ...[
            header,
            if (unbounded) list else Expanded(child: list),
          ],
        ],
      ),
    );
  }

  Widget _buildLegacy(BuildContext context) {
    final theme = Theme.of(context);
    final hasActions = _hasSummaryActions || _hasRowActions;
    final actionColumnWidth = hasActions ? 88.0 : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_hasSummaryActions && rows.isNotEmpty) ...[
                  _ExportIconButton(
                    tooltip: 'Print summary',
                    icon: Icons.print_rounded,
                    onPressed: exporting ? null : onPrintSummary,
                  ),
                  _ExportIconButton(
                    tooltip: 'Save summary as PDF',
                    icon: Icons.ios_share_rounded,
                    onPressed: exporting ? null : onShareSummary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No data for selected filters.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: (rows.length.clamp(1, 8) * 48 + 56).toDouble(),
                child: DataTable2(
                  columnSpacing: 12,
                  horizontalMargin: 8,
                  minWidth: 280 + actionColumnWidth,
                  columns: [
                    for (final c in columns)
                      DataColumn2(label: Text(c), size: ColumnSize.L),
                    if (hasActions)
                      const DataColumn2(label: Text(''), fixedWidth: 88),
                  ],
                  rows: [
                    for (var i = 0; i < rows.length; i++)
                      DataRow2(
                        cells: [
                          for (final cell in rows[i]) DataCell(Text(cell)),
                          if (hasActions)
                            DataCell(
                              _BreakdownRowActionButtons(
                                actions:
                                    rowActions != null && i < rowActions!.length
                                    ? rowActions![i]
                                    : const _BreakdownRowActions(count: 0),
                              ),
                            ),
                        ],
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

class _BreakdownRowActionButtons extends StatelessWidget {
  const _BreakdownRowActionButtons({required this.actions});

  final _BreakdownRowActions actions;

  @override
  Widget build(BuildContext context) {
    if (actions.count <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ExportIconButton(
          tooltip: 'Print details',
          icon: Icons.print_outlined,
          iconSize: 18,
          onPressed: actions.exporting ? null : actions.onPrint,
        ),
        _ExportIconButton(
          tooltip: 'Save details as PDF',
          icon: Icons.ios_share_outlined,
          iconSize: 18,
          onPressed: actions.exporting ? null : actions.onShare,
        ),
      ],
    );
  }
}

class _ExportIconButton extends StatelessWidget {
  const _ExportIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.iconSize = 20,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      onPressed: onPressed,
      icon: Icon(icon, size: iconSize),
    );
  }
}

class InvestigationExportActions extends StatelessWidget {
  const InvestigationExportActions({
    super.key,
    required this.enabled,
    required this.exporting,
    this.onPrint,
    this.onShare,
  });

  final bool enabled;
  final bool exporting;
  final VoidCallback? onPrint;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    if (onPrint == null && onShare == null) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ExportIconButton(
          tooltip: 'Print',
          icon: Icons.print_rounded,
          onPressed: enabled && !exporting ? onPrint : null,
        ),
        _ExportIconButton(
          tooltip: 'Save as PDF',
          icon: Icons.ios_share_rounded,
          onPressed: enabled && !exporting ? onShare : null,
        ),
      ],
    );
  }
}

class InvestigationSortControls extends StatelessWidget {
  const InvestigationSortControls({
    super.key,
    required this.sortBy,
    required this.sortOrder,
    required this.onSortByChanged,
    required this.onSortOrderChanged,
  });

  final InvestigationSortBy sortBy;
  final InvestigationSortOrder sortOrder;
  final ValueChanged<InvestigationSortBy> onSortByChanged;
  final ValueChanged<InvestigationSortOrder> onSortOrderChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<InvestigationSortBy>(
          value: sortBy,
          hint: const Text('Sort by'),
          onChanged: (v) {
            if (v != null) onSortByChanged(v);
          },
          items: InvestigationSortBy.values
              .map(
                (e) => DropdownMenuItem(value: e, child: Text(_sortLabel(e))),
              )
              .toList(),
        ),
        DropdownButton<InvestigationSortOrder>(
          value: sortOrder,
          onChanged: (v) {
            if (v != null) onSortOrderChanged(v);
          },
          items: const [
            DropdownMenuItem(
              value: InvestigationSortOrder.asc,
              child: Text('Ascending'),
            ),
            DropdownMenuItem(
              value: InvestigationSortOrder.desc,
              child: Text('Descending'),
            ),
          ],
        ),
      ],
    );
  }

  String _sortLabel(InvestigationSortBy value) {
    switch (value) {
      case InvestigationSortBy.createdAt:
        return 'Created';
      case InvestigationSortBy.testName:
        return 'Test name';
      case InvestigationSortBy.amount:
        return 'Amount';
      case InvestigationSortBy.patientName:
        return 'Patient name';
      case InvestigationSortBy.status:
        return 'Status';
    }
  }
}

class InvestigationPaginationBar extends StatelessWidget {
  const InvestigationPaginationBar({
    super.key,
    required this.total,
    required this.skip,
    required this.take,
    required this.onPrevious,
    required this.onNext,
  });

  final int total;
  final int skip;
  final int take;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final from = total == 0 ? 0 : skip + 1;
    final to = (skip + take).clamp(0, total);
    return Row(
      children: [
        Text(
          'Showing $from–$to of $total',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'Previous page',
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          tooltip: 'Next page',
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class InvestigationErrorBanner extends StatelessWidget {
  const InvestigationErrorBanner({
    super.key,
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Material(
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
