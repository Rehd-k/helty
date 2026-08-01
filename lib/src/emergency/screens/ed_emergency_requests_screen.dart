import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/emergency/models/emergency_request_model.dart';
import 'package:helty/src/emergency/providers/emergency_request_providers.dart';
import 'package:helty/src/helper/date.formatter.dart';

@RoutePage()
class EdEmergencyRequestsScreen extends ConsumerStatefulWidget {
  const EdEmergencyRequestsScreen({super.key});

  @override
  ConsumerState<EdEmergencyRequestsScreen> createState() =>
      _EdEmergencyRequestsScreenState();
}

class _EdEmergencyRequestsScreenState
    extends ConsumerState<EdEmergencyRequestsScreen> {
  @override
  void initState() {
    super.initState();
    // Start inbox polling / local alerts while this screen (or app) is open.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(emergencyRequestPollProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final status = ref.watch(emergencyRequestStatusFilterProvider);
    final inboxAsync = ref.watch(emergencyRequestInboxProvider);
    // Keep poll alive while inbox is mounted.
    ref.watch(emergencyRequestPollProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency requests'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(emergencyRequestInboxProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                for (final option in <(EmergencyRequestStatus?, String)>[
                  (null, 'All'),
                  (EmergencyRequestStatus.submitted, 'Submitted'),
                  (EmergencyRequestStatus.acknowledged, 'Acknowledged'),
                  (EmergencyRequestStatus.dispatched, 'Dispatched'),
                  (EmergencyRequestStatus.closed, 'Closed'),
                  (EmergencyRequestStatus.cancelled, 'Cancelled'),
                ]) ...[
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(option.$2),
                      selected: status == option.$1,
                      onSelected: (_) {
                        ref
                                .read(
                                  emergencyRequestStatusFilterProvider.notifier,
                                )
                                .state =
                            option.$1;
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: inboxAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed to load: $e'),
                    const Gap(12),
                    FilledButton(
                      onPressed: () =>
                          ref.invalidate(emergencyRequestInboxProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (response) {
                if (response.data.isEmpty) {
                  return const Center(
                    child: Text('No emergency requests in this filter.'),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(emergencyRequestInboxProvider);
                    await ref.read(emergencyRequestInboxProvider.future);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: response.data.length,
                    separatorBuilder: (_, __) => const Gap(8),
                    itemBuilder: (context, index) {
                      final item = response.data[index];
                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _statusColor(item.status)
                                .withValues(alpha: 0.15),
                            child: Icon(
                              Icons.emergency_outlined,
                              color: _statusColor(item.status),
                            ),
                          ),
                          title: Text(
                            item.patient?.displayName ?? 'Unknown patient',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            [
                              item.status.label,
                              if (item.description?.isNotEmpty == true)
                                item.description!,
                              if (item.createdAt != null)
                                DateFormatter.dateTime(item.createdAt!),
                            ].join(' · '),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.router.push(
                            EdEmergencyRequestDetailRoute(id: item.id),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(EmergencyRequestStatus status) {
    return switch (status) {
      EmergencyRequestStatus.submitted => Colors.red,
      EmergencyRequestStatus.acknowledged => Colors.orange,
      EmergencyRequestStatus.dispatched => Colors.blue,
      EmergencyRequestStatus.closed => Colors.green,
      EmergencyRequestStatus.cancelled => Colors.grey,
    };
  }
}
