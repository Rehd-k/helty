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
class CMDAuditComplianceScreen extends ConsumerWidget {
  const CMDAuditComplianceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmdAuditComplianceProvider);
    return CmdAsyncScaffold<CmdAuditComplianceBundle>(
      title: 'Audit & compliance',
      subtitle: 'Activity trail and checklist status',
      asyncValue: async,
      builder: (context, data) {
        return SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Compliance checklist',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final c in data.compliance)
                    Chip(
                      avatar: Icon(
                        c.status.startsWith('Compliant') ? Icons.check_circle : Icons.warning_amber,
                        size: 18,
                      ),
                      label: Text('${c.code}: ${c.description} (${c.status})'),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Recent audit log (sample)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: CmdDataTableBox(
                  child: DataTable2(
                    columnSpacing: 10,
                    horizontalMargin: 10,
                    minWidth: 900,
                    columns: const [
                      DataColumn2(label: Text('Time'), size: ColumnSize.S),
                      DataColumn2(label: Text('User'), size: ColumnSize.S),
                      DataColumn2(label: Text('Action'), size: ColumnSize.S),
                      DataColumn2(label: Text('Entity'), size: ColumnSize.M),
                      DataColumn2(label: Text('Detail'), size: ColumnSize.L),
                    ],
                    rows: [
                      for (final l in data.logs)
                        DataRow2(
                          cells: [
                            DataCell(Text(DateFormatter.dateTimeWithSeconds(l.at))),
                            DataCell(Text(l.user)),
                            DataCell(Text(l.action)),
                            DataCell(Text(l.entity)),
                            DataCell(Text(l.metadata)),
                          ],
                        ),
                    ],
                  ),
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
