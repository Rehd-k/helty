import 'package:flutter/material.dart';

import '../../../models/waiting_patient_model.dart';
import '../../../widgets/helty_surface.dart';
import '../walk_in_queue_metrics.dart';
import 'walk_in_queue_table.dart';

/// Mobile queue row: urgency stripe, identity, room, wait, and actions.
class WalkInPatientCard extends StatelessWidget {
  const WalkInPatientCard({
    super.key,
    required this.waiting,
    required this.indexLabel,
    required this.onStart,
    required this.onView,
    required this.onAssignRoom,
    required this.onDoubleTap,
  });

  final WaitingPatientModel waiting;
  final String indexLabel;
  final VoidCallback onStart;
  final VoidCallback onView;
  final VoidCallback onAssignRoom;
  final VoidCallback onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final wait = WalkInQueueMetrics.waitDuration(waiting);
    final stripe = WalkInQueueMetrics.urgencyColor(
      WalkInQueueMetrics.urgencyFor(wait),
    );

    return HeltySurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onDoubleTap: onDoubleTap,
        child: WalkInUrgencyStripe(
          color: stripe,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      indexLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: WalkInPatientIdentity(waiting: waiting)),
                    WalkInWaitText(waiting: waiting),
                  ],
                ),
                const SizedBox(height: 10),
                WalkInReasonCell(waiting: waiting),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    WalkInRoomChip(waiting: waiting),
                    WalkInStatusChip(waiting: waiting),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: WalkInQueueActions(
                    waiting: waiting,
                    onStart: onStart,
                    onView: onView,
                    onAssignRoom: onAssignRoom,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class WalkInPatientCardList extends StatelessWidget {
  const WalkInPatientCardList({
    super.key,
    required this.patients,
    required this.skip,
    required this.loading,
    required this.emptyMessage,
    required this.total,
    required this.hasMore,
    required this.pageSize,
    required this.onPrev,
    required this.onNext,
    required this.onStart,
    required this.onView,
    required this.onAssignRoom,
    required this.onDoubleTap,
  });

  final List<WaitingPatientModel> patients;
  final int skip;
  final bool loading;
  final String emptyMessage;
  final int total;
  final bool hasMore;
  final int pageSize;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<WaitingPatientModel> onStart;
  final ValueChanged<WaitingPatientModel> onView;
  final ValueChanged<WaitingPatientModel> onAssignRoom;
  final ValueChanged<WaitingPatientModel> onDoubleTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (patients.isEmpty) {
      return Center(
        child: Text(
          emptyMessage,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final waiting = patients[index];
              return WalkInPatientCard(
                waiting: waiting,
                indexLabel: '${skip + index + 1}',
                onStart: () => onStart(waiting),
                onView: () => onView(waiting),
                onAssignRoom: () => onAssignRoom(waiting),
                onDoubleTap: () => onDoubleTap(waiting),
              );
            },
          ),
        ),
        WalkInPaginationFooter(
          skip: skip,
          pageSize: pageSize,
          shown: patients.length,
          total: total,
          hasMore: hasMore,
          onPrev: onPrev,
          onNext: onNext,
        ),
      ],
    );
  }
}
