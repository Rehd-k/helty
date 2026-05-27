import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cmac_palette.dart';
import '../models/cmac_analytics_models.dart';
import '../providers/cmac_providers.dart';
import '../widgets/cmac_alerts_insights.dart';
import '../widgets/cmac_analytics_scaffold.dart';

@RoutePage()
class CmacInsightsScreen extends ConsumerWidget {
  const CmacInsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmacInsightsProvider);
    void refresh() => ref.invalidate(cmacInsightsProvider);

    return CmacAnalyticsScaffold(
      title: 'System insights',
      subtitle: 'Auto-generated oversight signals',
      colors: CmacPalette.insights,
      accent: CmacPalette.insights.first,
      asyncValue: async,
      onRefresh: refresh,
      pollInterval: const Duration(seconds: 60),
      builder: (context, raw) {
        final data = raw as CmacInsightsResponse;
        return CmacInsightList(insights: data.insights);
      },
    );
  }
}
