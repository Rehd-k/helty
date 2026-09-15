import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';

import '../../providers/patient_hub_providers.dart';
import '../../widgets/hub_empty_state.dart';
import '../../widgets/hub_list_row.dart';
import '../../widgets/patient_hub_scope.dart';
import '../../patient_hub_metrics.dart';
import '../../../helper/date.formatter.dart';

@RoutePage()
class HubDialysisScreen extends ConsumerWidget {
  const HubDialysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientUuid = PatientHubScope.requirePatientUuid(context);
    final range = ref.watch(patientHubDateRangeProvider);
    final async = ref.watch(
      patientHubDialysisHistoryProvider(
        HubModuleHistoryRequest(
          patientUuid: patientUuid,
          fromDate: range.from,
          toDate: range.to,
        ),
      ),
    );

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (response) {
        final sessions = response.sessions;
        if (sessions.isEmpty) {
          return const HubEmptyState(
            title: 'No dialysis sessions',
            icon: Icons.bloodtype_outlined,
          );
        }
        return ResponsiveBody(
          builder: (context, bp) => ListView.builder(
          padding: const EdgeInsets.only(top: 4),
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final s = sessions[index];
            final when = s.createdAt ?? s.startedAt;
            return HubListRow(
              title: 'Session ${s.id.substring(0, 8)}…',
              subtitle:
                  '${s.status.displayLabel} · ${when != null ? DateFormatter.dateTime(when) : '—'}',
              icon: Icons.bloodtype_outlined,
              iconColor: PatientHubMetrics.iconBlue,
              onTap: () => context.router.push(
                DialysisSessionDetailRoute(sessionId: s.id),
              ),
            );
          },
        ),
        );
      },
    );
  }
}
