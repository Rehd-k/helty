import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cmac_palette.dart';
import '../providers/cmac_providers.dart';
import '../widgets/cmac_analytics_scaffold.dart';
import '../widgets/cmac_charts.dart';
import '../widgets/cmac_kpi_card.dart';

@RoutePage()
class CmacClinicalScreen extends ConsumerWidget {
  const CmacClinicalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmacClinicalProvider);
    void refresh() => ref.invalidate(cmacClinicalProvider);

    return CmacAnalyticsScaffold(
      title: 'Clinical performance',
      subtitle: 'Diagnoses, outcomes & readmissions (30-day window)',
      colors: CmacPalette.clinical,
      accent: CmacPalette.clinical.first,
      asyncValue: async,
      onRefresh: refresh,
      builder: (context, data) {
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CmacKpiGrid(kpis: data.kpis, accent: CmacPalette.clinical.first),
            if (data.readmissionsCurrent != null) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: Icon(
                    Icons.replay_rounded,
                    color: CmacPalette.clinical.first,
                  ),
                  title: const Text('Readmissions (current period)'),
                  subtitle: Text(
                    'Prior: ${data.readmissionsPrevious ?? '—'}',
                  ),
                  trailing: Text(
                    data.readmissionsCurrent.toString(),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: CmacPalette.clinical.first,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            CmacBarChartCard(
              title: 'Top diagnoses',
              points: data.topDiagnoses,
              horizontal: true,
            ),
            const SizedBox(height: 16),
            CmacDonutChartCard(
              title: 'Treatment outcomes',
              slices: data.treatmentOutcomes,
            ),
          ],
        );
      },
    );
  }
}
