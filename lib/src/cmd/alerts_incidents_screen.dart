import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/helper/date.formatter.dart';

import 'cmd_providers.dart';
import 'models/cmd_models.dart';
import 'widgets/cmd_async_scaffold.dart';

Color _cmdIncidentSeverityColor(CmdIncidentSeverity s) {
  switch (s) {
    case CmdIncidentSeverity.critical:
      return Colors.red.shade900;
    case CmdIncidentSeverity.high:
      return Colors.deepOrange.shade700;
    case CmdIncidentSeverity.medium:
      return Colors.amber.shade800;
    case CmdIncidentSeverity.low:
      return Colors.blueGrey;
  }
}

@RoutePage()
class CMDAlertsIncidentsScreen extends ConsumerWidget {
  const CMDAlertsIncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cmdIncidentsProvider);
    return CmdAsyncScaffold<List<CmdIncident>>(
      title: 'Alerts & incidents',
      subtitle: 'Problem radar — clinical, ops, and experience',
      asyncValue: async,
      builder: (context, data) {
        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 24),
          itemCount: data.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final e = data[i];
            return Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _cmdIncidentSeverityColor(e.severity).withValues(alpha: 0.5)),
              ),
              child: ExpansionTile(
                leading: Icon(Icons.flag, color: _cmdIncidentSeverityColor(e.severity)),
                title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${e.category} · ${DateFormatter.dateTime(e.createdAt)}'),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.detail),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Chip(label: Text('Owner: ${e.owner}')),
                            const SizedBox(width: 8),
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
