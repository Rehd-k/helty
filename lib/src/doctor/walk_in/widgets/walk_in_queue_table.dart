import 'package:flutter/material.dart';

import '../../../core/widgets/patient_avatar.dart';
import '../../../helper/theme.dart';
import '../../../models/waiting_patient_model.dart';
import '../../../widgets/helty_surface.dart';
import '../walk_in_queue_metrics.dart';

typedef WalkInEllipsisText = HeltyEllipsisText;
typedef WalkInEllipsisChip = HeltyEllipsisChip;

class WalkInQueueActions extends StatelessWidget {
  const WalkInQueueActions({
    super.key,
    required this.waiting,
    required this.onStart,
    required this.onView,
    required this.onAssignRoom,
  });

  final WaitingPatientModel waiting;
  final VoidCallback onStart;
  final VoidCallback onView;
  final VoidCallback onAssignRoom;

  bool get _canView =>
      waiting.seen &&
      waiting.encounterId != null &&
      waiting.encounterId!.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primary = _canView
        ? OutlinedButton(
            onPressed: onView,
            style: OutlinedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: const StadiumBorder(),
            ),
            child: const Text('View'),
          )
        : FilledButton(
            onPressed: onStart,
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: const StadiumBorder(),
            ),
            child: const Text('Start'),
          );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        primary,
        PopupMenuButton<String>(
          tooltip: 'More actions',
          icon: Icon(Icons.more_vert, color: cs.onSurfaceVariant),
          onSelected: (value) {
            switch (value) {
              case 'start':
                onStart();
              case 'view':
                onView();
              case 'assign':
                onAssignRoom();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: _canView ? 'view' : 'start',
              child: Text(_canView ? 'Open encounter' : 'Start consultation'),
            ),
            const PopupMenuItem(
              value: 'assign',
              child: Text('Assign consulting room'),
            ),
          ],
        ),
      ],
    );
  }
}

class WalkInUrgencyStripe extends StatelessWidget {
  const WalkInUrgencyStripe({
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

class WalkInPatientIdentity extends StatelessWidget {
  const WalkInPatientIdentity({super.key, required this.waiting});

  final WaitingPatientModel waiting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final name = WalkInQueueMetrics.patientName(waiting);
    final mrn = WalkInQueueMetrics.mrn(waiting);
    final phone = WalkInQueueMetrics.phone(waiting);
    final avatarColor = WalkInQueueMetrics.avatarBlockColor(waiting);
    final avatar = waiting.patient != null
        ? PatientAvatar.fromPatient(
            waiting.patient!,
            size: 36,
            backgroundColor: avatarColor,
            foregroundColor: Colors.white,
            fontWeight: FontWeight.bold,
          )
        : PatientAvatar(
            firstName: name,
            size: 36,
            backgroundColor: avatarColor,
            foregroundColor: Colors.white,
            fontWeight: FontWeight.bold,
          );

    return Row(
      children: [
        avatar,
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              WalkInEllipsisText(
                text: name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (mrn.isNotEmpty)
                WalkInEllipsisText(
                  text: 'MRN: $mrn',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              if (phone != null)
                Row(
                  children: [
                    Icon(
                      Icons.phone_outlined,
                      size: 12,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: WalkInEllipsisText(
                        text: phone,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class WalkInReasonCell extends StatelessWidget {
  const WalkInReasonCell({super.key, required this.waiting});

  final WaitingPatientModel waiting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reason = waiting.consultationName ?? '—';
    final extras = waiting.consultationNames.skip(1).toList();
    final text = extras.isEmpty ? reason : '$reason · ${extras.join(', ')}';
    return WalkInEllipsisText(text: text, style: theme.textTheme.bodyMedium);
  }
}

class WalkInRoomChip extends StatelessWidget {
  const WalkInRoomChip({super.key, required this.waiting});

  final WaitingPatientModel waiting;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = WalkInQueueMetrics.roomName(waiting);
    final color = WalkInQueueMetrics.colorForRoomName(name, cs.primary);
    final location = waiting.consultingRoom?.location?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        WalkInEllipsisChip(label: name, color: color),
        if (location != null && location.isNotEmpty) ...[
          const SizedBox(height: 4),
          WalkInEllipsisText(
            text: location,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ],
    );
  }
}

class WalkInWaitText extends StatelessWidget {
  const WalkInWaitText({super.key, required this.waiting, this.now});

  final WaitingPatientModel waiting;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final wait = WalkInQueueMetrics.waitDuration(waiting, now);
    final urgency = WalkInQueueMetrics.urgencyFor(wait);
    final color = WalkInQueueMetrics.urgencyColor(urgency);
    return Tooltip(
      message: WalkInQueueMetrics.formatWait(wait),
      waitDuration: const Duration(milliseconds: 350),
      child: Text(
        WalkInQueueMetrics.formatWait(wait),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class WalkInStatusChip extends StatelessWidget {
  const WalkInStatusChip({super.key, required this.waiting});

  final WaitingPatientModel waiting;

  @override
  Widget build(BuildContext context) {
    final status = WalkInQueueMetrics.statusOf(waiting);
    final inConsult = status == WalkInQueueStatus.inConsultation;
    final color = inConsult
        ? WalkInQueueMetrics.waitGreen
        : WalkInQueueMetrics.waitAmber;
    return WalkInEllipsisChip(
      label: WalkInQueueMetrics.statusLabel(status),
      color: color,
    );
  }
}

class WalkInPaginationFooter extends StatelessWidget {
  const WalkInPaginationFooter({
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
                  ? 'No patients to display'
                  : 'Showing $start–$end of $total patients',
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

class WalkInQueueTable extends StatelessWidget {
  const WalkInQueueTable({
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

  static const _colGap = 20.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final footer = WalkInPaginationFooter(
      skip: skip,
      pageSize: pageSize,
      shown: patients.length,
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
            _head(context, 'REASON FOR VISIT', flex: 4),
            const SizedBox(width: _colGap),
            _head(context, 'DEPARTMENT', flex: 3),
            const SizedBox(width: _colGap),
            _head(context, 'WAIT TIME', flex: 2),
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
                  : patients.isEmpty
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
                      itemCount: patients.length,
                      separatorBuilder: (_, _) => Divider(
                        height: 1,
                        color: cs.outline.withValues(alpha: 0.08),
                      ),
                      itemBuilder: (context, index) {
                        final waiting = patients[index];
                        final wait = WalkInQueueMetrics.waitDuration(waiting);
                        final stripe = WalkInQueueMetrics.urgencyColor(
                          WalkInQueueMetrics.urgencyFor(wait),
                        );
                        return Material(
                          color: WalkInQueueMetrics.zebraFill(cs, index),
                          child: InkWell(
                            onDoubleTap: () => onDoubleTap(waiting),
                            child: WalkInUrgencyStripe(
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
                                      child: WalkInEllipsisText(
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
                                      child: WalkInPatientIdentity(
                                        waiting: waiting,
                                      ),
                                    ),
                                    const SizedBox(width: _colGap),
                                    Expanded(
                                      flex: 4,
                                      child: WalkInReasonCell(waiting: waiting),
                                    ),
                                    const SizedBox(width: _colGap),
                                    Expanded(
                                      flex: 3,
                                      child: WalkInRoomChip(waiting: waiting),
                                    ),
                                    const SizedBox(width: _colGap),
                                    Expanded(
                                      flex: 2,
                                      child: WalkInWaitText(waiting: waiting),
                                    ),
                                    const SizedBox(width: _colGap),
                                    Expanded(
                                      flex: 2,
                                      child: WalkInStatusChip(waiting: waiting),
                                    ),
                                    const SizedBox(width: _colGap),
                                    Expanded(
                                      flex: 3,
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: WalkInQueueActions(
                                            waiting: waiting,
                                            onStart: () => onStart(waiting),
                                            onView: () => onView(waiting),
                                            onAssignRoom: () =>
                                                onAssignRoom(waiting),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
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
