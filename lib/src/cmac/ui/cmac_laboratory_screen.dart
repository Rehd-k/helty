import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cmac_palette.dart';
import '../providers/cmac_providers.dart';
import '../widgets/cmac_analytics_scaffold.dart';
import '../widgets/cmac_charts.dart';
import '../widgets/cmac_kpi_card.dart';

@RoutePage()
class CmacLaboratoryScreen extends ConsumerWidget {
  const CmacLaboratoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmacLaboratoryProvider);
    void refresh() => ref.invalidate(cmacLaboratoryProvider);

    return CmacAnalyticsScaffold(
      title: 'Laboratory',
      subtitle: 'LabOrder pipeline · turnaround & critical flags',
      colors: CmacPalette.laboratory,
      accent: CmacPalette.laboratory.first,
      asyncValue: async,
      onRefresh: refresh,
      builder: (context, data) {
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CmacKpiGrid(
              kpis: data.kpis,
              accent: CmacPalette.laboratory.first,
            ),
            if (data.pendingCount != null || data.completedCount != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatChip(
                      label: 'Pending',
                      value: '${data.pendingCount ?? 0}',
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatChip(
                      label: 'Completed',
                      value: '${data.completedCount ?? 0}',
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            CmacDonutChartCard(
              title: 'Status breakdown',
              slices: data.statusBreakdown,
            ),
            const SizedBox(height: 16),
            CmacBarChartCard(title: 'Top tests', points: data.topTests),
            if (data.criticalAlerts.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Critical alerts',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ...data.criticalAlerts.map((row) {
                final msg = row['message']?.toString() ??
                    row['patientName']?.toString() ??
                    'Critical result';
                return Card(
                  color: Colors.red.withValues(alpha: 0.08),
                  child: ListTile(
                    leading: const Icon(Icons.warning_rounded, color: Colors.red),
                    title: Text(msg),
                    subtitle: Text(row.toString()),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
