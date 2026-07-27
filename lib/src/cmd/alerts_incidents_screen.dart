import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/cmac/cmac_palette.dart';
import 'package:helty/src/helper/date.formatter.dart';

import 'cmd_providers.dart';
import 'models/cmd_models.dart';
import 'widgets/cmd_async_scaffold.dart';

Color _cmdIncidentSeverityColor(CmdIncidentSeverity s) {
  switch (s) {
    case CmdIncidentSeverity.critical:
      return CmacPalette.severityColor('critical');
    case CmdIncidentSeverity.high:
      return CmacPalette.severityColor('high');
    case CmdIncidentSeverity.medium:
      return CmacPalette.severityColor('medium');
    case CmdIncidentSeverity.low:
      return CmacPalette.severityColor('low');
  }
}

@RoutePage()
class CMDAlertsIncidentsScreen extends ConsumerWidget {
  const CMDAlertsIncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmdIncidentsProvider);
    final theme = Theme.of(context);
    return CmdAsyncScaffold<List<CmdIncident>>(
      title: 'Alerts & incidents',
      subtitle: 'Problem radar — clinical, ops, and experience',
      asyncValue: async,
      builder: (context, data) {
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: data.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final e = data[i];
            final severity = _cmdIncidentSeverityColor(e.severity);
            return Card(
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                leading: Icon(Icons.flag_outlined, color: severity),
                title: Text(
                  e.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  '${e.category} · ${DateFormatter.dateTime(e.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.detail, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(label: Text('Owner: ${e.owner}')),
                            Chip(label: Text('Status: ${e.status}')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
