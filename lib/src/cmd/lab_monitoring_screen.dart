import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cmd_providers.dart';
import 'models/cmd_models.dart';
import 'widgets/cmd_async_scaffold.dart';
import 'widgets/cmd_data_table_box.dart';

@RoutePage()
class CMDLabMonitoringScreen extends ConsumerWidget {
  const CMDLabMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmdLabMonitoringProvider);
    return CmdAsyncScaffold<CmdLabMonitoring>(
      title: 'Lab monitoring',
      subtitle: 'Pending load, TAT, and instrument health',
      asyncValue: async,
      builder: (context, data) {
        final theme = Theme.of(context);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _MiniTile(
                    label: 'Delayed samples',
                    value: '${data.delayedCount}',
                    color: theme.colorScheme.error,
                  ),
                  _MiniTile(
                    label: 'Avg TAT',
                    value: '${data.avgTatHours.toStringAsFixed(1)} h',
                    color: theme.colorScheme.primary,
                  ),
                  _MiniTile(
                    label: 'Redo / repeat rate',
                    value: '${data.redoPercent.toStringAsFixed(1)}%',
                    color: theme.colorScheme.tertiary,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Pending by test type',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _PendingTable(rows: data.pendingRows),
              const SizedBox(height: 28),
              Text(
                'Analyser / instrument stats',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _MachineTable(rows: data.machines),
            ],
          ),
        );
      },
    );
  }
}

class _MiniTile extends StatelessWidget {
  const _MiniTile({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 200,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text(value, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingTable extends StatelessWidget {
  const _PendingTable({required this.rows});

  final List<CmdLabPendingRow> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: CmdDataTableBox(
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 520,
          columns: const [
            DataColumn2(label: Text('Test'), size: ColumnSize.L),
            DataColumn2(label: Text('Pending #'), numeric: true),
            DataColumn2(label: Text('Oldest (h)'), numeric: true),
          ],
          rows: [
            for (final r in rows)
              DataRow2(
                cells: [
                  DataCell(Text(r.testCode)),
                  DataCell(Text('${r.count}')),
                  DataCell(Text(r.oldestHours.toStringAsFixed(1))),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _MachineTable extends StatelessWidget {
  const _MachineTable({required this.rows});

  final List<CmdLabMachineStat> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: CmdDataTableBox(
        heightFactor: 0.34,
        minHeight: 220,
        child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 560,
          columns: const [
            DataColumn2(label: Text('Instrument'), size: ColumnSize.L),
            DataColumn2(label: Text('Uptime %'), numeric: true),
            DataColumn2(label: Text('Backlog'), numeric: true),
          ],
          rows: [
            for (final r in rows)
              DataRow2(
                cells: [
                  DataCell(Text(r.name)),
                  DataCell(Text('${r.uptimePercent.toStringAsFixed(1)}%')),
                  DataCell(Text('${r.backlog}')),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
