import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cmac_palette.dart';
import '../providers/cmac_providers.dart';
import '../widgets/cmac_analytics_scaffold.dart';
import '../widgets/cmac_charts.dart';
import '../widgets/cmac_kpi_card.dart';

@RoutePage()
class CmacPharmacyScreen extends ConsumerWidget {
  const CmacPharmacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmacPharmacyProvider);
    void refresh() => ref.invalidate(cmacPharmacyProvider);

    return CmacAnalyticsScaffold(
      title: 'Pharmacy',
      subtitle: 'Prescribing, antibiotics (J01) & inventory signals',
      colors: CmacPalette.pharmacy,
      accent: CmacPalette.pharmacy.first,
      asyncValue: async,
      onRefresh: refresh,
      builder: (context, data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CmacKpiGrid(kpis: data.kpis, accent: CmacPalette.pharmacy.first),
          const SizedBox(height: 20),
          CmacBarChartCard(
            title: 'Top prescribed',
            points: data.topPrescribed,
          ),
          const SizedBox(height: 16),
          CmacLineChartCard(
            title: 'Antibiotic trend (ATC J01)',
            series: data.antibioticTrend,
          ),
        ],
      ),
    );
  }
}
