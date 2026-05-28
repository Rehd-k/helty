import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/helper/date.formatter.dart';

import 'cmd_money_format.dart';
import 'cmd_providers.dart';
import 'models/cmd_models.dart';
import 'widgets/cmd_async_scaffold.dart';
import 'widgets/cmd_data_table_box.dart';

@RoutePage()
class CMDSystemControlScreen extends ConsumerWidget {
  const CMDSystemControlScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmdSystemControlProvider);
    return CmdAsyncScaffold<(List<CmdApprovalRequest>, CmdSettingsOverview)>(
      title: 'System control',
      subtitle: 'Approvals queue and integration health',
      asyncValue: async,
      builder: (context, data) {
        final approvals = data.$1;
        final settings = data.$2;
        final money = cmdNairaFormat();
        return SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pending CMD approvals',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: CmdDataTableBox(
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 800,
                    columns: const [
                      DataColumn2(label: Text('Type'), size: ColumnSize.S),
                      DataColumn2(label: Text('Requester'), size: ColumnSize.M),
                      DataColumn2(label: Text('Amount'), numeric: true),
                      DataColumn2(label: Text('Status'), size: ColumnSize.S),
                      DataColumn2(label: Text('Submitted'), size: ColumnSize.M),
                      DataColumn2(label: Text(''), size: ColumnSize.S),
                    ],
                    rows: [
                      for (final a in approvals)
                        DataRow2(
                          cells: [
                            DataCell(Text(a.type)),
                            DataCell(Text(a.requester)),
                            DataCell(Text(money.format(a.amount))),
                            DataCell(Text(a.status)),
                            DataCell(Text(DateFormatter.dateTime(a.submittedAt))),
                            DataCell(
                              TextButton(
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Review action pending backend workflow — ${a.id}')),
                                  );
                                },
                                child: const Text('Review'),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Integrations',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...settings.integrations.map(
                (i) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(i.name),
                    subtitle: Text(
                      i.lastSyncAt != null
                          ? 'Last sync ${DateFormatter.dateTime(i.lastSyncAt!)}'
                          : 'Never synced',
                    ),
                    trailing: Chip(
                      label: Text(i.status),
                      backgroundColor: i.status == 'Connected'
                          ? Colors.green.shade100
                          : i.status == 'Degraded'
                              ? Colors.orange.shade100
                              : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Card(
                child: ListTile(
                  title: const Text('Roles & permissions'),
                  subtitle: Text(settings.rolesSummary),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ),
              Card(
                child: ListTile(
                  title: const Text('Hospital-wide banner draft'),
                  subtitle: Text(settings.bannerDraft),
                  trailing: FilledButton(
                    onPressed: () {},
                    child: const Text('Publish'),
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
