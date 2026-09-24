import 'package:flutter/material.dart';

import '../../core/widgets/patient_avatar.dart';
import '../../helper/date.formatter.dart';
import '../../helper/theme.dart';
import '../../widgets/helty_surface.dart';
import '../ed_board_metrics.dart';
import '../models/emergency_visit_model.dart';
import '../utils/ed_role_helper.dart';
import '../utils/ed_workflow_helper.dart';
import '../../models/staff_model.dart';
import 'ed_status_chip.dart';
import 'esi_badge.dart';

class EdBoardRowActions extends StatelessWidget {
  const EdBoardRowActions({
    super.key,
    required this.visit,
    required this.accountType,
    required this.canTriage,
    required this.canDoctor,
    required this.onTriage,
    required this.onOpen,
    required this.onLwbs,
    required this.onDeceased,
  });

  final EmergencyVisitModel visit;
  final AccountType? accountType;
  final bool canTriage;
  final bool canDoctor;
  final VoidCallback onTriage;
  final VoidCallback onOpen;
  final VoidCallback onLwbs;
  final VoidCallback onDeceased;

  bool get showTriage =>
      canTriage && EdWorkflowHelper.canShowTriage(visit.workflowStatus);

  bool get showOpen =>
      canDoctor && EdWorkflowHelper.canShowOpenDoctor(visit.workflowStatus);

  bool get showLwbs {
    final terminal = EdWorkflowHelper.isTerminal(visit.workflowStatus);
    return !terminal &&
        EdWorkflowHelper.canMarkLwbs(visit.workflowStatus) &&
        (EdRoleHelper.isNurseOrFrontDesk(accountType) || canDoctor);
  }

  bool get showDeceased {
    final terminal = EdWorkflowHelper.isTerminal(visit.workflowStatus);
    return !terminal &&
        EdWorkflowHelper.canMarkDeceased(visit.workflowStatus) &&
        canDoctor;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Widget? primary;
    if (showTriage) {
      primary = FilledButton(
        onPressed: onTriage,
        style: FilledButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const StadiumBorder(),
        ),
        child: const Text('Triage'),
      );
    } else if (showOpen) {
      primary = OutlinedButton(
        onPressed: onOpen,
        style: OutlinedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: const StadiumBorder(),
        ),
        child: const Text('Open'),
      );
    }

    final menuItems = <PopupMenuEntry<String>>[
      if (showTriage)
        const PopupMenuItem(value: 'triage', child: Text('Open triage')),
      if (showOpen)
        const PopupMenuItem(value: 'open', child: Text('Open workspace')),
      if (showLwbs)
        const PopupMenuItem(value: 'lwbs', child: Text('Mark LWBS')),
      if (showDeceased)
        const PopupMenuItem(value: 'deceased', child: Text('Record deceased')),
    ];

    if (primary == null && menuItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ?primary,
        if (menuItems.isNotEmpty)
          PopupMenuButton<String>(
            tooltip: 'More actions',
            icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
            onSelected: (value) {
              switch (value) {
                case 'triage':
                  onTriage();
                case 'open':
                  onOpen();
                case 'lwbs':
                  onLwbs();
                case 'deceased':
                  onDeceased();
              }
            },
            itemBuilder: (context) => menuItems,
          ),
      ],
    );
  }
}

class EdBoardUrgencyStripe extends StatelessWidget {
  const EdBoardUrgencyStripe({
    super.key,
    required this.color,
    required this.child,
    this.clip = true,
  });

  final Color color;
  final Widget child;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(color: color, child: const SizedBox(width: 4)),
          Expanded(child: child),
        ],
      ),
    );
    if (!clip) return row;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      child: row,
    );
  }
}

class EdBoardPatientIdentity extends StatelessWidget {
  const EdBoardPatientIdentity({super.key, required this.visit});

  final EmergencyVisitModel visit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = EdBoardMetrics.patientName(visit);
    final avatarColor = EdBoardMetrics.avatarBlockColor(visit);

    return Row(
      children: [
        PatientAvatar(
          firstName: name,
          displayName: name,
          size: 36,
          backgroundColor: avatarColor,
          foregroundColor: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              HeltyEllipsisText(
                text: name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              HeltyEllipsisText(
                text: visit.patientId.isEmpty ? '—' : visit.patientId,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EdBoardPaginationFooter extends StatelessWidget {
  const EdBoardPaginationFooter({
    super.key,
    required this.skip,
    required this.pageSize,
    required this.shown,
    required this.total,
    required this.hasMore,
    required this.onPrev,
    required this.onNext,
  });

  final int skip;
  final int pageSize;
  final int shown;
  final int total;
  final bool hasMore;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final start = shown == 0 ? 0 : skip + 1;
    final end = skip + shown;
    final canPrev = skip > 0;
    final page = (skip ~/ pageSize) + 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              shown == 0
                  ? 'No visits to display'
                  : 'Showing $start–$end of $total visits',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          IconButton(
            tooltip: 'Previous page',
            onPressed: canPrev ? onPrev : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$page',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: hasMore ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }
}

class EdBoardTable extends StatelessWidget {
  const EdBoardTable({
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

  static const _colGap = 20.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final footer = EdBoardPaginationFooter(
      skip: skip,
      pageSize: pageSize,
      shown: visits.length,
      total: total,
      hasMore: hasMore,
      onPrev: onPrev,
      onNext: onNext,
    );

    Widget headerRow() {
      return Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 16, 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        ),
        child: Row(
          children: [
            const SizedBox(width: 4),
            _head(context, '#', flex: 1),
            const SizedBox(width: _colGap),
            _head(context, 'PATIENT', flex: 5),
            const SizedBox(width: _colGap),
            _head(context, 'ESI', flex: 2),
            const SizedBox(width: _colGap),
            _head(context, 'CHIEF COMPLAINT', flex: 4),
            const SizedBox(width: _colGap),
            _head(context, 'ARRIVAL', flex: 3),
            const SizedBox(width: _colGap),
            _head(context, 'WAIT', flex: 2),
            const SizedBox(width: _colGap),
            _head(context, 'DOCTOR', flex: 3),
            const SizedBox(width: _colGap),
            _head(context, 'STATUS', flex: 2),
            const SizedBox(width: _colGap),
            _head(context, 'ACTIONS', flex: 3, alignEnd: true),
          ],
        ),
      );
    }

    Widget body({required double width, required double height}) {
      return SizedBox(
        width: width,
        height: height,
        child: Column(
          children: [
            headerRow(),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : visits.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          emptyMessage,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: visits.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: cs.outline.withValues(alpha: 0.08),
                      ),
                      itemBuilder: (context, index) {
                        final visit = visits[index];
                        final stripe = EdBoardMetrics.esiStripeColor(
                          visit.esiLevel,
                        );
                        final arrival = visit.arrivalAt != null
                            ? DateFormatter.dateTime(visit.arrivalAt!)
                            : '—';
                        final doctor =
                            visit.assignedDoctor?.displayName ??
                            visit.encounter?.doctorLabel ??
                            '—';
                        return Material(
                          color: EdBoardMetrics.zebraFill(cs, index),
                          child: EdBoardUrgencyStripe(
                            color: stripe,
                            clip: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: HeltyEllipsisText(
                                      text: '${skip + index + 1}',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: _colGap),
                                  Expanded(
                                    flex: 5,
                                    child: EdBoardPatientIdentity(visit: visit),
                                  ),
                                  const SizedBox(width: _colGap),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: EsiBadge(
                                        esiLevel: visit.esiLevel,
                                        compact: true,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: _colGap),
                                  Expanded(
                                    flex: 4,
                                    child: HeltyEllipsisText(
                                      text: visit.chiefComplaint ?? '—',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  const SizedBox(width: _colGap),
                                  Expanded(
                                    flex: 3,
                                    child: HeltyEllipsisText(
                                      text: arrival,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  const SizedBox(width: _colGap),
                                  Expanded(
                                    flex: 2,
                                    child: HeltyEllipsisText(
                                      text: EdBoardMetrics.formatWaitMinutes(
                                        visit.computedWaitMinutes,
                                      ),
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: stripe,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: _colGap),
                                  Expanded(
                                    flex: 3,
                                    child: HeltyEllipsisText(
                                      text: doctor,
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ),
                                  const SizedBox(width: _colGap),
                                  Expanded(
                                    flex: 2,
                                    child: EdStatusChip(
                                      status: visit.workflowStatus,
                                      compact: true,
                                    ),
                                  ),
                                  const SizedBox(width: _colGap),
                                  Expanded(
                                    flex: 3,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerRight,
                                        child: EdBoardRowActions(
                                          visit: visit,
                                          accountType: accountType,
                                          canTriage: canTriage,
                                          canDoctor: canDoctor,
                                          onTriage: () => onTriage(visit),
                                          onOpen: () => onOpen(visit),
                                          onLwbs: () => onLwbs(visit),
                                          onDeceased: () => onDeceased(visit),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      );
    }

    return HeltySurfaceCard(
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, inner) {
                const minWidth = 1100.0;
                final tableWidth = inner.maxWidth < minWidth
                    ? minWidth
                    : inner.maxWidth;
                final sheet = body(width: tableWidth, height: inner.maxHeight);
                if (inner.maxWidth >= minWidth) return sheet;
                return Scrollbar(
                  thumbVisibility: true,
                  notificationPredicate: (n) =>
                      n.metrics.axis == Axis.horizontal,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: sheet,
                  ),
                );
              },
            ),
          ),
          footer,
        ],
      ),
    );
  }

  Widget _head(
    BuildContext context,
    String label, {
    required int flex,
    bool alignEnd = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}
