import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';

import '../../providers/patient_hub_providers.dart';
import '../../widgets/hub_empty_state.dart';
import '../../widgets/patient_hub_scope.dart';

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
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: sessions.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final s = sessions[index];
            return Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.bloodtype_outlined),
                title: Text('Session ${s.id.substring(0, 8)}…'),
                subtitle: Text(
                  '${s.status.displayLabel} · ${(s.createdAt ?? s.startedAt)?.toLocal() ?? '—'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.router.push(
                  DialysisSessionDetailRoute(sessionId: s.id),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
