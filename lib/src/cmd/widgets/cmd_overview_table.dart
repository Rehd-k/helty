import 'package:flutter/material.dart';

import '../../widgets/helty_surface.dart';
import '../cmd_money_format.dart';
import '../cmd_overview_metrics.dart';
import '../models/cmd_models.dart';

class CmdOverviewPaginationFooter extends StatelessWidget {
  const CmdOverviewPaginationFooter({
    super.key,
    required this.skip,
    required this.pageSize,
    required this.shown,
    required this.total,
    required this.hasMore,
    required this.onPrev,
    required this.onNext,
  });

  final int skip;
  final int pageSize;
  final int shown;
  final int total;
  final bool hasMore;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final start = shown == 0 ? 0 : skip + 1;
    final end = skip + shown;
    final canPrev = skip > 0;
    final page = (skip ~/ pageSize) + 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              shown == 0
                  ? 'No departments to display'
                  : 'Showing $start–$end of $total departments',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          IconButton(
            tooltip: 'Previous page',
            onPressed: canPrev ? onPrev : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$page',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: hasMore ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class CmdOverviewScorecardTable extends StatelessWidget {
  const CmdOverviewScorecardTable({
    super.key,
    required this.rows,
    required this.skip,
    required this.loading,
    required this.emptyMessage,
    required this.total,
    required this.hasMore,
    required this.pageSize,
    required this.onPrev,
    required this.onNext,
  });

  final List<CmdDepartmentScorecard> rows;
  final int skip;
  final bool loading;
  final String emptyMessage;
  final int total;
  final bool hasMore;
  final int pageSize;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  static const _colGap = 20.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fmt = cmdNairaFormat();
    final footer = CmdOverviewPaginationFooter(
      skip: skip,
      pageSize: pageSize,
      shown: rows.length,
      total: total,
      hasMore: hasMore,
      onPrev: onPrev,
      onNext: onNext,
    );

    Widget headerRow() {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        ),
        child: Row(
          children: [
            _head(context, '#', flex: 1),
            const SizedBox(width: _colGap),
            _head(context, 'DEPARTMENT', flex: 4),
            const SizedBox(width: _colGap),
            _head(context, 'PATIENTS', flex: 2),
            const SizedBox(width: _colGap),
            _head(context, 'REVENUE', flex: 3),
            const SizedBox(width: _colGap),
            _head(context, 'SLA', flex: 2),
            const SizedBox(width: _colGap),
            _head(context, 'STATUS', flex: 2),
          ],
        ),
      );
    }

    Widget body({required double width, required double height}) {
      return SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            headerRow(),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : rows.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          emptyMessage,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: rows.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: cs.outline.withValues(alpha: 0.08),
                      ),
                      itemBuilder: (context, index) {
                        final row = rows[index];
                        final deptColor = CmdOverviewMetrics.colorForDepartment(
                          row.name,
                          CmdOverviewMetrics.iconBlue,
                        );
                        final statusColor = CmdOverviewMetrics.statusColor(
                          row.status,
                        );
                        return ColoredBox(
                          color: CmdOverviewMetrics.zebraFill(cs, index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: HeltyEllipsisText(
                                    text: '${skip + index + 1}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: _colGap),
                                Expanded(
                                  flex: 4,
                                  child: HeltyEllipsisChip(
                                    label: CmdOverviewMetrics.display(row.name),
                                    color: deptColor,
                                  ),
                                ),
                                const SizedBox(width: _colGap),
                                Expanded(
                                  flex: 2,
                                  child: HeltyEllipsisText(
                                    text: '${row.patientsSeen}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: _colGap),
                                Expanded(
                                  flex: 3,
                                  child: HeltyEllipsisText(
                                    text: fmt.format(row.revenue),
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                const SizedBox(width: _colGap),
                                Expanded(
                                  flex: 2,
                                  child: HeltyEllipsisText(
                                    text: '${row.slaBreaches}',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: row.slaBreaches > 0
                                          ? CmdOverviewMetrics.waitRed
                                          : cs.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: _colGap),
                                Expanded(
                                  flex: 2,
                                  child: HeltyEllipsisChip(
                                    label: CmdOverviewMetrics.display(
                                      row.status,
                                    ),
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    }

    return HeltySurfaceCard(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, inner) {
                const minWidth = 720.0;
                final tableWidth = inner.maxWidth < minWidth
                    ? minWidth
                    : inner.maxWidth;
                final sheet = body(width: tableWidth, height: inner.maxHeight);
                if (inner.maxWidth >= minWidth) return sheet;
                return Scrollbar(
                  thumbVisibility: true,
                  notificationPredicate: (n) =>
                      n.metrics.axis == Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: sheet,
                  ),
                );
              },
            ),
          ),
          footer,
        ],
      ),
    );
  }

  Widget _head(BuildContext context, String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class CmdOverviewScorecardCard extends StatelessWidget {
  const CmdOverviewScorecardCard({
    super.key,
    required this.row,
    required this.indexLabel,
  });

  final CmdDepartmentScorecard row;
  final String indexLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final stripe = CmdOverviewMetrics.statusColor(row.status);
    final fmt = cmdNairaFormat();

    return HeltySurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(color: stripe, child: const SizedBox(width: 4)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            indexLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: HeltyEllipsisText(
                              text: CmdOverviewMetrics.display(row.name),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          HeltyStatusChip(
                            label: CmdOverviewMetrics.display(row.status),
                            color: stripe,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: HeltyEllipsisText(
                              text: 'Patients ${row.patientsSeen}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          HeltyEllipsisText(
                            text: fmt.format(row.revenue),
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      HeltyEllipsisText(
                        text: 'SLA breaches ${row.slaBreaches}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: row.slaBreaches > 0
                              ? CmdOverviewMetrics.waitRed
                              : cs.onSurfaceVariant,
                          fontWeight: row.slaBreaches > 0
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CmdOverviewScorecardCardList extends StatelessWidget {
  const CmdOverviewScorecardCardList({
    super.key,
    required this.rows,
    required this.skip,
    required this.loading,
    required this.emptyMessage,
    required this.total,
    required this.hasMore,
    required this.pageSize,
    required this.onPrev,
    required this.onNext,
  });

  final List<CmdDepartmentScorecard> rows;
  final int skip;
  final bool loading;
  final String emptyMessage;
  final int total;
  final bool hasMore;
  final int pageSize;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (rows.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) {
              final row = rows[index];
              return CmdOverviewScorecardCard(
                row: row,
                indexLabel: '${skip + index + 1}',
              );
            },
          ),
        ),
        CmdOverviewPaginationFooter(
          skip: skip,
          pageSize: pageSize,
          shown: rows.length,
          total: total,
          hasMore: hasMore,
          onPrev: onPrev,
          onNext: onNext,
        ),
      ],
    );
  }
}
