import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'cmd_providers.dart';
import 'models/cmd_models.dart';
import 'widgets/cmd_async_scaffold.dart';
import 'widgets/cmd_data_table_box.dart';

@RoutePage()
class CMDPatientExperienceScreen extends ConsumerWidget {
  const CMDPatientExperienceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmdPatientExperienceProvider);
    return CmdAsyncScaffold<CmdPatientExperienceOverview>(
      title: 'Patient experience',
      subtitle: 'Satisfaction, complaints, and wait-time insight',
      asyncValue: async,
      builder: (context, data) {
        final fmt = DateFormat('MMM d, yyyy');
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.insights_outlined, size: 32),
                      const SizedBox(width: 16),
                      Expanded(child: Text(data.waitTimeInsight, style: Theme.of(context).textTheme.bodyLarge)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Satisfaction metrics',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final m in data.metrics)
                    SizedBox(
                      width: 240,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(m.label, style: Theme.of(context).textTheme.labelMedium),
                              const SizedBox(height: 8),
                              Text(
                                m.label.contains('NPS') ? m.score.toStringAsFixed(0) : m.score.toStringAsFixed(1),
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text('vs bench ${m.benchmark.toStringAsFixed(1)} · ${m.trendLabel}', style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Complaints & feedback',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: CmdDataTableBox(
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 720,
                    columns: const [
                      DataColumn2(label: Text('Dept'), size: ColumnSize.S),
                      DataColumn2(label: Text('Summary'), size: ColumnSize.L),
                      DataColumn2(label: Text('Status'), size: ColumnSize.S),
                      DataColumn2(label: Text('Opened'), size: ColumnSize.M),
                    ],
                    rows: [
                      for (final c in data.complaints)
                        DataRow2(
                          cells: [
                            DataCell(Text(c.department)),
                            DataCell(Text(c.summary)),
                            DataCell(Text(c.status)),
                            DataCell(Text(fmt.format(c.openedAt))),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Department ratings (rolling)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: CmdDataTableBox(
                  heightFactor: 0.34,
                  minHeight: 220,
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 520,
                    columns: const [
                      DataColumn2(label: Text('Department'), size: ColumnSize.L),
                      DataColumn2(label: Text('Stars'), numeric: true),
                      DataColumn2(label: Text('Responses'), numeric: true),
                    ],
                    rows: [
                      for (final r in data.departmentRatings)
                        DataRow2(
                          cells: [
                            DataCell(Text(r.department)),
                            DataCell(Text(r.stars.toStringAsFixed(1))),
                            DataCell(Text('${r.responseCount}')),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
