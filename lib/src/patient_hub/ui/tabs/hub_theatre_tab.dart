import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';

import '../../providers/patient_hub_providers.dart';
import '../../widgets/hub_empty_state.dart';
import '../../widgets/patient_hub_scope.dart';

@RoutePage()
class HubTheatreScreen extends ConsumerWidget {
  const HubTheatreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientUuid = PatientHubScope.requirePatientUuid(context);
    final range = ref.watch(patientHubDateRangeProvider);
    final async = ref.watch(
      patientHubTheatreHistoryProvider(
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
        final requests = response.requests;
        if (requests.isEmpty) {
          return const HubEmptyState(
            title: 'No theatre or surgery records',
            icon: Icons.medical_services_outlined,
          );
        }
        return ResponsiveBody(
          builder: (context, bp) => ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final r = requests[index];
            final serviceName = r.service?.name ?? 'Surgery request';
            return Card(
              elevation: 0,
              child: ListTile(
                leading: const Icon(Icons.medical_services_outlined),
                title: Text(serviceName),
                subtitle: Text(
                  '${r.status.displayLabel} · ${r.priority?.displayLabel ?? 'Routine'} · ${r.createdAt?.toLocal() ?? '—'}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.router.push(
                  TheatreCaseDetailRoute(surgeryRequestId: r.id),
                ),
              ),
            );
          },
        ),
        );
      },
    );
  }
}
