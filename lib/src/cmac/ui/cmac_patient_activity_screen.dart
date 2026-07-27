import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cmac_palette.dart';
import '../providers/cmac_providers.dart';
import '../widgets/cmac_analytics_scaffold.dart';
import '../widgets/cmac_charts.dart';
import '../widgets/cmac_kpi_card.dart';

@RoutePage()
class CmacPatientActivityScreen extends ConsumerWidget {
  const CmacPatientActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmacPatientActivityProvider);
    void refresh() => ref.invalidate(cmacPatientActivityProvider);

    return CmacAnalyticsScaffold(
      title: 'Patient activity',
      subtitle: 'Volume, OPD, admissions & referrals',
      colors: CmacPalette.patientActivity,
      accent: CmacPalette.patientActivity.first,
      asyncValue: async,
      onRefresh: refresh,
      builder: (context, data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CmacKpiGrid(
            kpis: data.kpis,
            accent: CmacPalette.patientActivity.first,
          ),
          const SizedBox(height: 24),
          CmacLineChartCard(
            title: 'New patients',
            series: data.newPatientsSeries,
          ),
          const SizedBox(height: 16),
          CmacLineChartCard(
            title: 'Referrals',
            series: data.referralsInSeries,
            secondSeries: data.referralsOutSeries,
            secondLabel: 'In vs out',
          ),
        ],
      ),
    );
  }
}
