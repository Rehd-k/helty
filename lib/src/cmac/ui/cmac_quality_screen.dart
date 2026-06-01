import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';

import '../cmac_palette.dart';
import '../models/cmac_analytics_models.dart';
import '../providers/cmac_providers.dart';
import '../widgets/cmac_analytics_scaffold.dart';
import '../widgets/cmac_charts.dart';
import '../widgets/cmac_kpi_card.dart';

@RoutePage()
class CmacQualityScreen extends ConsumerWidget {
  const CmacQualityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmacQualityProvider);
    void refresh() => ref.invalidate(cmacQualityProvider);

    return CmacAnalyticsScaffold(
      title: 'Quality & safety',
      subtitle: 'Incidents, complaints & chart audit flags',
      colors: CmacPalette.quality,
      accent: CmacPalette.quality.first,
      asyncValue: async,
      onRefresh: refresh,
      builder: (context, data) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CmacKpiGrid(kpis: data.kpis, accent: CmacPalette.quality.first),
          const SizedBox(height: 20),
          CmacBarChartCard(
            title: 'Incidents by type',
            points: data.incidentsByType,
          ),
          const SizedBox(height: 16),
          CmacBarChartCard(
            title: 'Complaints by category',
            points: data.complaintsByCategory,
          ),
          const SizedBox(height: 20),
          Text(
            'Audit flags',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          _AuditTable(flags: data.auditFlags),
        ],
      ),
    );
  }
}

class _AuditTable extends StatelessWidget {
  const _AuditTable({required this.flags});

  final List<CmacAuditFlag> flags;

  @override
  Widget build(BuildContext context) {
    if (flags.isEmpty) {
      return const CmacEmptyHint(message: 'No audit flags in this period.');
    }
    return Card(
      child: Column(
        children: flags.map((f) {
          return ListTile(
            leading: Icon(
              Icons.flag_rounded,
              color: CmacPalette.severityColor(f.severity),
            ),
            title: Text(f.rule),
            subtitle: Text('${f.entityType} · ${f.severity}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              if (f.patientId.isEmpty) return;
              context.router.push(
                PatientChartRoute(patientUuid: f.patientId),
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
