import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/helper/date.formatter.dart';

import 'cmd_providers.dart';
import 'models/cmd_models.dart';
import 'widgets/cmd_async_scaffold.dart';
import 'widgets/cmd_data_table_box.dart';

@RoutePage()
class CMDReportsAnalyticsScreen extends ConsumerWidget {
  const CMDReportsAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmdReportTemplatesProvider);
    return CmdAsyncScaffold<List<CmdReportTemplate>>(
      title: 'Reports & analytics',
      subtitle: 'Catalog — export wiring comes with backend jobs',
      asyncValue: async,
      builder: (context, data) {
        return SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Scheduled report templates',
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
                      DataColumn2(label: Text('Report'), size: ColumnSize.L),
                      DataColumn2(label: Text('Cadence'), size: ColumnSize.S),
                      DataColumn2(label: Text('Last generated'), size: ColumnSize.M),
                      DataColumn2(label: Text('Formats'), size: ColumnSize.L),
                      DataColumn2(label: Text('Actions'), size: ColumnSize.S),
                    ],
                    rows: [
                      for (final r in data)
                        DataRow2(
                          cells: [
                            DataCell(Text(r.name)),
                            DataCell(Text(r.cadence)),
                            DataCell(Text(
                              r.lastGeneratedAt != null
                                  ? DateFormatter.dateTime(r.lastGeneratedAt!)
                                  : '—',
                            )),
                            DataCell(Text(r.formatsSupported.join(', '))),
                            DataCell(
                              OutlinedButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Export stub — ${r.name}')),
                                  );
                                },
                                child: const Text('Export'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Custom builder (placeholder)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Card(
                child: ListTile(
                  title: Text('Drag-and-drop fields and filters will connect to /cmd/reports/builder'),
                  subtitle: Text('PDF / Excel export will enqueue server-side jobs.'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
