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
class CMDBedsFacilitiesScreen extends ConsumerWidget {
  const CMDBedsFacilitiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmdBedsSnapshotProvider);
    return CmdAsyncScaffold<CmdBedsSnapshot>(
      title: 'Beds & facilities',
      subtitle: 'Ward occupancy and admission / discharge pulse',
      asyncValue: async,
      builder: (context, data) {
        return SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (data.overcrowdingMessages.isNotEmpty) ...[
                Text(
                  'Overcrowding',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...data.overcrowdingMessages.map(
                  (m) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.4),
                    child: ListTile(
                      leading: const Icon(Icons.warning_amber_rounded),
                      title: Text(m),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Text(
                'Ward snapshot',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _WardTable(wards: data.wards),
              const SizedBox(height: 28),
              Text(
                'Recent admissions / discharges / transfers',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < data.recentEvents.length; i++) ...[
                      ListTile(
                        leading: Icon(
                          data.recentEvents[i].type == 'Admission'
                              ? Icons.login
                              : data.recentEvents[i].type == 'Discharge'
                                  ? Icons.logout
                                  : Icons.swap_horiz,
                        ),
                        title: Text('${data.recentEvents[i].type} — ${data.recentEvents[i].ward}'),
                        subtitle: Text(data.recentEvents[i].patientRef),
                        trailing: Text(DateFormatter.dateTime(data.recentEvents[i].at)),
                      ),
                      if (i < data.recentEvents.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WardTable extends StatelessWidget {
  const _WardTable({required this.wards});

  final List<CmdWardBedStats> wards;

  @override
  Widget build(BuildContext context) {
    return CmdDataTableBox(
      child: DataTable2(
          columnSpacing: 12,
          horizontalMargin: 12,
          minWidth: 640,
          columns: const [
            DataColumn2(label: Text('Ward'), size: ColumnSize.L),
            DataColumn2(label: Text('Beds'), numeric: true),
            DataColumn2(label: Text('Occupied'), numeric: true),
            DataColumn2(label: Text('Occ. %'), numeric: true),
            DataColumn2(label: Text('Acuity / notes'), size: ColumnSize.L),
          ],
          rows: [
            for (final w in wards)
              DataRow2(
                cells: [
                  DataCell(Text(w.wardName)),
                  DataCell(Text('${w.totalBeds}')),
                  DataCell(Text('${w.occupied}')),
                  DataCell(Text('${((w.occupied / w.totalBeds) * 100).toStringAsFixed(0)}%')),
                  DataCell(Text(w.acuityMix)),
                ],
              ),
          ],
        ),
    );
  }
}
