import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cmd_breakpoints.dart';
import 'cmd_money_format.dart';
import 'cmd_providers.dart';
import 'models/cmd_models.dart';
import 'widgets/cmd_async_scaffold.dart';
import 'widgets/cmd_data_table_box.dart';

@RoutePage()
class CMDHospitalOverviewScreen extends ConsumerWidget {
  const CMDHospitalOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmdHospitalOverviewProvider);
    return CmdAsyncScaffold<CmdHospitalOverview>(
      title: 'Hospital overview',
      subtitle: 'Departments, patient flow, and wait times',
      asyncValue: async,
      builder: (context, data) {
        return LayoutBuilder(
          builder: (context, c) {
            final bp = CmdBreakpoints.fromWidth(c.maxWidth);
            return SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow(
                    daily: data.dailySummary,
                    weekly: data.weeklySummary,
                    stack: bp.isMobile,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Department scorecards',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _DeptTable(rows: data.departments),
                  const SizedBox(height: 28),
                  Text(
                    'Patient flow (pipeline)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _FlowList(flow: data.flow),
                  const SizedBox(height: 28),
                  Text(
                    'Waiting times',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _WaitTable(rows: data.waitTimes),
                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.daily,
    required this.weekly,
    required this.stack,
  });

  final String daily;
  final String weekly;
  final bool stack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dailyCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily summary',
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(daily, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
    final weeklyCard = Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Weekly summary',
              style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 8),
            Text(weekly, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
    if (stack) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          dailyCard,
          const SizedBox(height: 12),
          weeklyCard,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: dailyCard),
        const SizedBox(width: 16),
        Expanded(child: weeklyCard),
      ],
    );
  }
}

class _DeptTable extends StatelessWidget {
  const _DeptTable({required this.rows});

  final List<CmdDepartmentScorecard> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = cmdNairaFormat();
    return Card(
      clipBehavior: Clip.antiAlias,
      child: CmdDataTableBox(
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 720,
          columns: const [
            DataColumn2(label: Text('Department'), size: ColumnSize.L),
            DataColumn2(label: Text('Patients seen'), numeric: true),
            DataColumn2(label: Text('Revenue'), numeric: true),
            DataColumn2(label: Text('SLA breaches'), numeric: true),
            DataColumn2(label: Text('Status'), size: ColumnSize.S),
          ],
          rows: [
          for (final r in rows)
            DataRow2(
              cells: [
                DataCell(Text(r.name)),
                DataCell(Text('${r.patientsSeen}')),
                DataCell(Text(fmt.format(r.revenue))),
                DataCell(Text('${r.slaBreaches}')),
                DataCell(
                  Text(
                    r.status,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: r.status == 'OK' ? Colors.green.shade700 : theme.colorScheme.error,
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

class _FlowList extends StatelessWidget {
  const _FlowList({required this.flow});

  final List<CmdFlowStageMetric> flow;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < flow.length; i++) ...[
            ListTile(
              title: Text(flow[i].stage),
              subtitle: Text('Avg ${flow[i].avgMinutes} min in stage'),
              trailing: Chip(
                label: Text('${flow[i].patientsInStage} patients'),
              ),
            ),
            if (i < flow.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

class _WaitTable extends StatelessWidget {
  const _WaitTable({required this.rows});

  final List<CmdWaitTimeRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: CmdDataTableBox(
        heightFactor: 0.35,
        minHeight: 220,
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 560,
          columns: const [
            DataColumn2(label: Text('Area'), size: ColumnSize.L),
            DataColumn2(label: Text('P50 (min)'), numeric: true),
            DataColumn2(label: Text('P90 (min)'), numeric: true),
            DataColumn2(label: Text('Trend'), size: ColumnSize.S),
          ],
          rows: [
            for (final r in rows)
              DataRow2(
                cells: [
                  DataCell(Text(r.area)),
                  DataCell(Text('${r.p50Minutes}')),
                  DataCell(Text('${r.p90Minutes}')),
                  DataCell(Text(r.trendLabel)),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
