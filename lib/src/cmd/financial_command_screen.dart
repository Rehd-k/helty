import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
      subtitle: 'Dummy figures — replace with live billing when integrated',
      asyncValue: async,
      builder: (context, data) {
        final fmt = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _MoneyTile(title: 'Outstanding AR', value: fmt.format(data.outstandingPayments), color: Colors.orange.shade800),
                  _MoneyTile(
                    title: 'Profit margin (dummy)',
                    value: '${data.profitMarginPercent.toStringAsFixed(1)}%',
                    color: Colors.green.shade800,
                  ),
                  _MoneyTile(
                    title: 'Forecast next month',
                    value: fmt.format(data.forecastNextMonthDummy),
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Revenue by department (dummy)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 220,
                child: _RevenueBarChart(rows: data.byDepartment),
              ),
              const SizedBox(height: 12),
              _RevenueTable(rows: data.byDepartment),
              const SizedBox(height: 28),
              Text(
                'Payment mix',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _PaymentMixCard(mix: data.paymentMix, fmt: fmt),
              const SizedBox(height: 28),
              Text(
                'Expense lines vs budget',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _ExpenseTable(rows: data.expenses, fmt: fmt),
              const SizedBox(height: 28),
              Text(
                'Leak detection (dummy exposure)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _LeakList(leaks: data.leaks, fmt: fmt),
            ],
          ),
        );
      },
    );
  }
}

class _MoneyTile extends StatelessWidget {
  const _MoneyTile({required this.title, required this.value, required this.color});

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueBarChart extends StatelessWidget {
  const _RevenueBarChart({required this.rows});

  final List<CmdRevenueByDepartment> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxY = rows.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 1.15;
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= rows.length) return const SizedBox.shrink();
                final label = rows[i].department.length > 10
                    ? '${rows[i].department.substring(0, 8)}…'
                    : rows[i].department;
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(label, style: theme.textTheme.labelSmall),
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
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RevenueTable extends StatelessWidget {
  const _RevenueTable({required this.rows});

  final List<CmdRevenueByDepartment> rows;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(symbol: r'$', decimalDigits: 0);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: CmdDataTableBox(
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 520,
          columns: const [
            DataColumn2(label: Text('Department'), size: ColumnSize.L),
            DataColumn2(label: Text('Amount'), numeric: true),
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
    final total = mix.insuranceAmount + mix.cashAmount + mix.corporateAmount;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _mixRow(theme, 'Insurance', mix.insuranceAmount / total, fmt.format(mix.insuranceAmount), theme.colorScheme.primary),
            const SizedBox(height: 8),
            _mixRow(theme, 'Cash', mix.cashAmount / total, fmt.format(mix.cashAmount), theme.colorScheme.tertiary),
            const SizedBox(height: 8),
            _mixRow(theme, 'Corporate', mix.corporateAmount / total, fmt.format(mix.corporateAmount), theme.colorScheme.secondary),
          ],
        ),
      ),
    );
  }

  Widget _mixRow(ThemeData theme, String label, double pct, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            Text(amount, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: pct,
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
          color: color,
          backgroundColor: theme.colorScheme.surfaceBright,
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
    return Card(
      clipBehavior: Clip.antiAlias,
      child: CmdDataTableBox(
        heightFactor: 0.36,
        minHeight: 240,
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 640,
          columns: const [
            DataColumn2(label: Text('Category'), size: ColumnSize.L),
            DataColumn2(label: Text('Actual'), numeric: true),
            DataColumn2(label: Text('Budget'), numeric: true),
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
                        color: r.variancePercent > 0 ? theme.colorScheme.error : Colors.green.shade700,
                        fontWeight: FontWeight.w600,
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
    return Column(
      children: [
        for (final l in leaks)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(l.description),
              subtitle: Text('Status: ${l.status}'),
              trailing: Text(
                fmt.format(l.estimatedExposureDummy),
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}
