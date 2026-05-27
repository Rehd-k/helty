import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';

import '../../cmd/widgets/cmd_data_table_box.dart';
import '../cmac_palette.dart';
import '../models/cmac_analytics_models.dart';
import '../providers/cmac_providers.dart';
import '../widgets/cmac_analytics_scaffold.dart';
import '../widgets/cmac_charts.dart';
import '../widgets/cmac_kpi_card.dart';

@RoutePage()
class CmacStaffScreen extends ConsumerWidget {
  const CmacStaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmacStaffProvider);
    void refresh() => ref.invalidate(cmacStaffProvider);

    return CmacAnalyticsScaffold(
      title: 'Staff performance',
      subtitle: 'Patients per doctor · lab workload · efficiency scores',
      colors: CmacPalette.staff,
      accent: CmacPalette.staff.first,
      asyncValue: async,
      onRefresh: refresh,
      pollInterval: const Duration(seconds: 120),
      builder: (context, raw) {
        final data = raw as CmacStaffResponse;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CmacBarChartCard(
              title: 'Patients per doctor',
              points: data.patientsPerDoctor,
            ),
            const SizedBox(height: 16),
            CmacBarChartCard(
              title: 'Lab workload per technician',
              points: data.labWorkloadPerTechnician,
            ),
            const SizedBox(height: 20),
            Text(
              'Department efficiency',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            if (data.departmentEfficiency.isEmpty)
              const CmacEmptyHint(
                message: 'No department efficiency data for this period.',
              )
            else
              Card(
                clipBehavior: Clip.antiAlias,
                child: CmdDataTableBox(
                  heightFactor: 0.34,
                  minHeight: 220,
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 480,
                    columns: const [
                      DataColumn2(label: Text('Department'), size: ColumnSize.L),
                      DataColumn2(label: Text('Score'), numeric: true),
                      DataColumn2(label: Text('Volume'), numeric: true),
                      DataColumn2(label: Text('Complaints'), numeric: true),
                      DataColumn2(label: Text('Wait (min)'), numeric: true),
                    ],
                    rows: [
                      for (final d in data.departmentEfficiency)
                        DataRow2(
                          cells: [
                            DataCell(Text(d.department)),
                            DataCell(Text(d.score.toStringAsFixed(1))),
                            DataCell(Text(d.volume?.toString() ?? '—')),
                            DataCell(Text(d.complaints?.toString() ?? '—')),
                            DataCell(Text(d.waitMinutes?.toString() ?? '—')),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
