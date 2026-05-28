import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'cmd_money_format.dart';
import 'cmd_providers.dart';
import 'models/cmd_models.dart';
import 'widgets/cmd_async_scaffold.dart';
import 'widgets/cmd_data_table_box.dart';

@RoutePage()
class CMDFinancialCommandScreen extends ConsumerWidget {
  const CMDFinancialCommandScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmdFinancialOverviewProvider);
    return CmdAsyncScaffold<CmdFinancialOverview>(
      title: 'Financial command center',
      subtitle: 'All figures in Nigerian Naira (₦) · live billing overview',
      asyncValue: async,
      builder: (context, data) {
        final fmt = cmdNairaFormat();
        final compact = cmdNairaCompactFormat();
        final size = MediaQuery.sizeOf(context);
        final chartH = size.height < 640 ? 200.0 : 240.0;
        final narrow = size.width < 600;

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _KpiGrid(
                outstanding: fmt.format(data.outstandingPayments),
                marginLabel: '${data.profitMarginPercent.toStringAsFixed(1)}%',
                forecast: fmt.format(data.forecastNextMonth),
              ),
              SizedBox(height: narrow ? 20 : 28),
              _SectionHeader(
                icon: Icons.pie_chart_outline_rounded,
                title: 'Revenue by department',
                subtitle: 'Live split by contribution',
              ),
              SizedBox(height: narrow ? 10 : 14),
              SizedBox(
                height: chartH,
                child: _RevenueBarChart(
                  rows: data.byDepartment,
                  compactFmt: compact,
                ),
              ),
              SizedBox(height: narrow ? 10 : 14),
              _RevenueTable(rows: data.byDepartment, fmt: fmt),
              SizedBox(height: narrow ? 20 : 28),
              _SectionHeader(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Payment mix',
                subtitle: 'Cash, insurance & corporate',
              ),
              SizedBox(height: narrow ? 10 : 14),
              _PaymentMixCard(mix: data.paymentMix, fmt: fmt),
              SizedBox(height: narrow ? 20 : 28),
              _SectionHeader(
                icon: Icons.receipt_long_outlined,
                title: 'Expense lines vs budget',
                subtitle: 'Variance highlights overspend',
              ),
              SizedBox(height: narrow ? 10 : 14),
              _ExpenseTable(rows: data.expenses, fmt: fmt),
              SizedBox(height: narrow ? 20 : 28),
              _SectionHeader(
                icon: Icons.shield_outlined,
                title: 'Leak detection',
                subtitle: 'Estimated exposure — review with finance',
              ),
              SizedBox(height: narrow ? 10 : 14),
              _LeakList(leaks: data.leaks, fmt: fmt),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: cs.onPrimaryContainer, size: 22),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({
    required this.outstanding,
    required this.marginLabel,
    required this.forecast,
  });

  final String outstanding;
  final String marginLabel;
  final String forecast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final maxExtent = w >= 1100
            ? 400.0
            : w >= 720
                ? 360.0
                : 560.0;
        const spacing = 16.0;
        const mainExtent = 118.0;

        return GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: maxExtent,
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            mainAxisExtent: mainExtent,
          ),
          children: [
            _MoneyTile(
              title: 'Outstanding AR',
              value: outstanding,
              accent: cs.tertiary,
              icon: Icons.request_quote_outlined,
            ),
            _MoneyTile(
              title: 'Profit margin',
              value: marginLabel,
              accent: cs.secondary,
              icon: Icons.trending_up_rounded,
            ),
            _MoneyTile(
              title: 'Forecast next month',
              value: forecast,
              accent: cs.primary,
              icon: Icons.calendar_month_outlined,
            ),
          ],
        );
      },
    );
  }
}

class _MoneyTile extends StatelessWidget {
  const _MoneyTile({
    required this.title,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final dark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: cs.outlineVariant.withValues(alpha: dark ? 0.45 : 0.55),
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withValues(alpha: dark ? 0.14 : 0.10),
                    cs.surface.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: dark ? 0.35 : 0.22),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          value,
                          maxLines: 1,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(16),
                ),
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  const _RevenueBarChart({
    required this.rows,
    required this.compactFmt,
  });

  final List<CmdRevenueByDepartment> rows;
  final NumberFormat compactFmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (rows.isEmpty) {
      return Center(
        child: Text(
          'No department revenue data',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    final maxY =
        rows.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 1.15;
    if (maxY <= 0) {
      return Center(
        child: Text(
          'No amounts to chart',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: cs.onSurfaceVariant,
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 12, 8),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: maxY / 4,
              getDrawingHorizontalLine: (v) => FlLine(
                color: cs.outlineVariant.withValues(alpha: 0.45),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  interval: maxY / 4,
                  getTitlesWidget: (value, meta) {
                    if (value <= 0 || value > maxY * 1.01) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Text(
                        compactFmt.format(value),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= rows.length) {
                      return const SizedBox.shrink();
                    }
                    final raw = rows[i].department;
                    final label =
                        raw.length > 12 ? '${raw.substring(0, 10)}…' : raw;
                    return Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: [
              for (var i = 0; i < rows.length; i++)
                BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: rows[i].amount,
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          cs.primary.withValues(alpha: 0.75),
                          cs.primary,
                        ],
                      ),
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

class _RevenueTable extends StatelessWidget {
  const _RevenueTable({required this.rows, required this.fmt});

  final List<CmdRevenueByDepartment> rows;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: CmdDataTableBox(
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 520,
          headingRowColor: WidgetStatePropertyAll(
            cs.surfaceContainerHighest.withValues(alpha: 0.55),
          ),
          columns: const [
            DataColumn2(label: Text('Department'), size: ColumnSize.L),
            DataColumn2(label: Text('Amount (₦)'), numeric: true),
            DataColumn2(label: Text('% of total'), numeric: true),
          ],
          rows: [
            for (final r in rows)
              DataRow2(
                cells: [
                  DataCell(Text(r.department)),
                  DataCell(Text(fmt.format(r.amount))),
                  DataCell(Text('${r.percentOfTotal.toStringAsFixed(1)}%')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMixCard extends StatelessWidget {
  const _PaymentMixCard({required this.mix, required this.fmt});

  final CmdPaymentMix mix;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final total = mix.insuranceAmount + mix.cashAmount + mix.corporateAmount;
    final safeTotal = total > 0 ? total : 1.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Total inflow',
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              fmt.format(total),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 18),
            _mixRow(
              theme,
              'Insurance',
              mix.insuranceAmount / safeTotal,
              fmt.format(mix.insuranceAmount),
              cs.primary,
            ),
            const SizedBox(height: 14),
            _mixRow(
              theme,
              'Cash',
              mix.cashAmount / safeTotal,
              fmt.format(mix.cashAmount),
              cs.tertiary,
            ),
            const SizedBox(height: 14),
            _mixRow(
              theme,
              'Corporate',
              mix.corporateAmount / safeTotal,
              fmt.format(mix.corporateAmount),
              cs.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _mixRow(
    ThemeData theme,
    String label,
    double pct,
    String amount,
    Color color,
  ) {
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              amount,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 10,
            color: color,
            backgroundColor: cs.surfaceContainerHighest.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class _ExpenseTable extends StatelessWidget {
  const _ExpenseTable({required this.rows, required this.fmt});

  final List<CmdExpenseLine> rows;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: CmdDataTableBox(
        heightFactor: 0.36,
        minHeight: 240,
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 640,
          headingRowColor: WidgetStatePropertyAll(
            cs.surfaceContainerHighest.withValues(alpha: 0.55),
          ),
          columns: const [
            DataColumn2(label: Text('Category'), size: ColumnSize.L),
            DataColumn2(label: Text('Actual (₦)'), numeric: true),
            DataColumn2(label: Text('Budget (₦)'), numeric: true),
            DataColumn2(label: Text('Variance'), numeric: true),
          ],
          rows: [
            for (final r in rows)
              DataRow2(
                cells: [
                  DataCell(Text(r.category)),
                  DataCell(Text(fmt.format(r.amount))),
                  DataCell(Text(fmt.format(r.budget))),
                  DataCell(
                    Text(
                      '${r.variancePercent.toStringAsFixed(1)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: r.variancePercent > 0
                            ? cs.error
                            : cs.tertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _LeakList extends StatelessWidget {
  const _LeakList({required this.leaks, required this.fmt});

  final List<CmdLeakFlag> leaks;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (leaks.isEmpty) {
      return Text(
        'No exposure flags',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: cs.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: [
        for (final l in leaks)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: cs.surfaceContainerLow,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: cs.outlineVariant.withValues(alpha: 0.65),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                leading: CircleAvatar(
                  backgroundColor: cs.errorContainer.withValues(alpha: 0.65),
                  foregroundColor: cs.onErrorContainer,
                  child: const Icon(Icons.warning_amber_rounded, size: 22),
                ),
                title: Text(
                  l.description,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Status: ${l.status}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Exposure',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      fmt.format(l.estimatedExposure),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: cs.error,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
