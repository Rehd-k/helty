import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cmac_palette.dart';
import '../providers/cmac_providers.dart';
import '../widgets/cmac_analytics_scaffold.dart';
import '../widgets/cmac_charts.dart';
import '../widgets/cmac_kpi_card.dart';

@RoutePage()
class CmacOperationsScreen extends ConsumerWidget {
  const CmacOperationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmacOperationsProvider);
    void refresh() => ref.invalidate(cmacOperationsProvider);

    return CmacAnalyticsScaffold(
      title: 'Operations',
      subtitle: 'No-shows, wait times & peak hours',
      colors: CmacPalette.operations,
      accent: CmacPalette.operations.first,
      asyncValue: async,
      onRefresh: refresh,
      builder: (context, data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CmacKpiGrid(kpis: data.kpis, accent: CmacPalette.operations.first),
          const SizedBox(height: 20),
          CmacBarChartCard(
            title: 'Doctor workload',
            points: data.doctorWorkload,
          ),
          const SizedBox(height: 16),
          CmacBarChartCard(
            title: 'Department utilization',
            points: data.departmentUtilization,
          ),
          const SizedBox(height: 16),
          CmacLineChartCard(
            title: 'Peak visiting hours',
            series: data.peakVisitingHours,
            height: 260,
          ),
        ],
      ),
    );
  }
}
