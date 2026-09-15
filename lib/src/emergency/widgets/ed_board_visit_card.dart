import 'package:flutter/material.dart';

import '../../helper/date.formatter.dart';
import '../../models/staff_model.dart';
import '../../widgets/helty_surface.dart';
import '../ed_board_metrics.dart';
import '../models/emergency_visit_model.dart';
import 'ed_board_table.dart';
import 'ed_status_chip.dart';
import 'esi_badge.dart';

/// Mobile ED row: ESI stripe, identity, complaint, wait, and actions.
class EdBoardVisitCard extends StatelessWidget {
  const EdBoardVisitCard({
    super.key,
    required this.visit,
    required this.indexLabel,
    required this.accountType,
    required this.canTriage,
    required this.canDoctor,
    required this.onTriage,
    required this.onOpen,
    required this.onLwbs,
    required this.onDeceased,
  });

  final EmergencyVisitModel visit;
  final String indexLabel;
  final AccountType? accountType;
  final bool canTriage;
  final bool canDoctor;
  final VoidCallback onTriage;
  final VoidCallback onOpen;
  final VoidCallback onLwbs;
  final VoidCallback onDeceased;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stripe = EdBoardMetrics.esiStripeColor(visit.esiLevel);
    final arrival = visit.arrivalAt != null
        ? DateFormatter.dateTime(visit.arrivalAt!)
        : '—';
    final doctor =
        visit.assignedDoctor?.displayName ??
        visit.encounter?.doctorLabel ??
        '—';

    return HeltySurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: EdBoardUrgencyStripe(
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
                  Expanded(child: EdBoardPatientIdentity(visit: visit)),
                  HeltyEllipsisText(
                    text: EdBoardMetrics.formatWaitMinutes(
                      visit.computedWaitMinutes,
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: stripe,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              HeltyEllipsisText(
                text: visit.chiefComplaint ?? '—',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              HeltyEllipsisText(
                text: arrival,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  EsiBadge(esiLevel: visit.esiLevel, compact: true),
                  SizedBox(
                    width: 140,
                    child: EdStatusChip(
                      status: visit.workflowStatus,
                      compact: true,
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: HeltyEllipsisText(
                      text: doctor,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: EdBoardRowActions(
                  visit: visit,
                  accountType: accountType,
                  canTriage: canTriage,
                  canDoctor: canDoctor,
                  onTriage: onTriage,
                  onOpen: onOpen,
                  onLwbs: onLwbs,
                  onDeceased: onDeceased,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class EdBoardVisitCardList extends StatelessWidget {
  const EdBoardVisitCardList({
    super.key,
    required this.visits,
    required this.skip,
    required this.loading,
    required this.emptyMessage,
    required this.total,
    required this.hasMore,
    required this.pageSize,
    required this.onPrev,
    required this.onNext,
    required this.accountType,
    required this.canTriage,
    required this.canDoctor,
    required this.onTriage,
    required this.onOpen,
    required this.onLwbs,
    required this.onDeceased,
  });

  final List<EmergencyVisitModel> visits;
  final int skip;
  final bool loading;
  final String emptyMessage;
  final int total;
  final bool hasMore;
  final int pageSize;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final AccountType? accountType;
  final bool canTriage;
  final bool canDoctor;
  final ValueChanged<EmergencyVisitModel> onTriage;
  final ValueChanged<EmergencyVisitModel> onOpen;
  final ValueChanged<EmergencyVisitModel> onLwbs;
  final ValueChanged<EmergencyVisitModel> onDeceased;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (visits.isEmpty) {
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
            itemCount: visits.length,
            itemBuilder: (context, index) {
              final visit = visits[index];
              return EdBoardVisitCard(
                visit: visit,
                indexLabel: '${skip + index + 1}',
                accountType: accountType,
                canTriage: canTriage,
                canDoctor: canDoctor,
                onTriage: () => onTriage(visit),
                onOpen: () => onOpen(visit),
                onLwbs: () => onLwbs(visit),
                onDeceased: () => onDeceased(visit),
              );
            },
          ),
        ),
        EdBoardPaginationFooter(
          skip: skip,
          pageSize: pageSize,
          shown: visits.length,
          total: total,
          hasMore: hasMore,
          onPrev: onPrev,
          onNext: onNext,
        ),
      ],
    );
  }
}
