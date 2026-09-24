import 'package:flutter/material.dart';

import '../../../helper/date.formatter.dart';
import '../../../helper/theme.dart';
import '../../../widgets/helty_surface.dart';
import '../walk_in_queue_metrics.dart';

class WalkInRoomCount {
  const WalkInRoomCount({required this.name, required this.count});

  final String name;
  final int count;
}

/// Quick actions, room counts, and in-session activity notes.
class WalkInSidebar extends StatelessWidget {
  const WalkInSidebar({
    super.key,
    required this.roomCounts,
    required this.notes,
    required this.onNewWalkIn,
    required this.onCheckIn,
    required this.onAssignDepartment,
    required this.onViewQueue,
    required this.onViewAllNotes,
    this.fillHeight = false,
  });

  final List<WalkInRoomCount> roomCounts;
  final List<WalkInActivityNote> notes;
  final VoidCallback onNewWalkIn;
  final VoidCallback onCheckIn;
  final VoidCallback onAssignDepartment;
  final VoidCallback onViewQueue;
  final VoidCallback onViewAllNotes;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final quick = _QuickActionsCard(
      onNewWalkIn: onNewWalkIn,
      onCheckIn: onCheckIn,
      onAssignDepartment: onAssignDepartment,
      onViewQueue: onViewQueue,
    );
    final rooms = _RoomCountsCard(roomCounts: roomCounts, expanded: fillHeight);
    final notesCard = _NotesCard(
      notes: notes,
      onViewAll: onViewAllNotes,
      expanded: fillHeight,
    );

    if (!fillHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          quick,
          const SizedBox(height: 12),
          rooms,
          const SizedBox(height: 12),
          notesCard,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        quick,
        const SizedBox(height: 12),
        Expanded(flex: 3, child: rooms),
        const SizedBox(height: 12),
        Expanded(flex: 2, child: notesCard),
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onNewWalkIn,
    required this.onCheckIn,
    required this.onAssignDepartment,
    required this.onViewQueue,
  });

  final VoidCallback onNewWalkIn;
  final VoidCallback onCheckIn;
  final VoidCallback onAssignDepartment;
  final VoidCallback onViewQueue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const WalkInSolidIcon(
                icon: Icons.flash_on,
                color: WalkInQueueMetrics.waitAmber,
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _GradientActionButton(
            label: 'New Walk-in Patient',
            icon: Icons.person_add_alt_1,
            colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.45)!],
            onPressed: onNewWalkIn,
          ),
          const SizedBox(height: 10),
          _GradientActionButton(
            label: 'Check Patient In',
            icon: Icons.login,
            colors: [
              WalkInQueueMetrics.waitGreen,
              Color.lerp(WalkInQueueMetrics.waitGreen, cs.primary, 0.25)!,
            ],
            onPressed: onCheckIn,
          ),
          const SizedBox(height: 10),
          _GradientActionButton(
            label: 'Assign Department',
            icon: Icons.apartment_outlined,
            colors: [
              WalkInQueueMetrics.waitAmber,
              Color.lerp(WalkInQueueMetrics.waitAmber, cs.error, 0.15)!,
            ],
            onPressed: onAssignDepartment,
          ),
          const SizedBox(height: 10),
          _GradientActionButton(
            label: 'View Queue',
            icon: Icons.queue_outlined,
            colors: [cs.tertiary, Color.lerp(cs.tertiary, cs.primary, 0.4)!],
            onPressed: onViewQueue,
          ),
        ],
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
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

class _RoomCountsCard extends StatelessWidget {
  const _RoomCountsCard({required this.roomCounts, this.expanded = false});

  final List<WalkInRoomCount> roomCounts;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final list = roomCounts.isEmpty
        ? Text(
            'No rooms in the current page.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          )
        : ListView(
            shrinkWrap: !expanded,
            physics: expanded ? null : const NeverScrollableScrollPhysics(),
            children: [
              for (final row in roomCounts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: WalkInQueueMetrics.colorForRoomName(
                            row.name,
                            cs.primary,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          row.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        '${row.count}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const WalkInSolidIcon(
              icon: Icons.apartment_outlined,
              color: WalkInQueueMetrics.iconBlue,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Text(
              'Queue by Department',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (expanded) Expanded(child: list) else list,
      ],
    );

    if (!expanded) {
      return HeltySurfaceCard(padding: const EdgeInsets.all(14), child: body);
    }
    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox.expand(
        child: Padding(padding: const EdgeInsets.all(14), child: body),
      ),
    );
  }
}

class _NotesCard extends StatelessWidget {
  const _NotesCard({
    required this.notes,
    required this.onViewAll,
    this.expanded = false,
  });

  final List<WalkInActivityNote> notes;
  final VoidCallback onViewAll;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final preview = notes.take(expanded ? notes.length : 5).toList();
    final feed = preview.isEmpty
        ? Text(
            'No recent activity this session.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          )
        : ListView(
            shrinkWrap: !expanded,
            physics: expanded ? null : const NeverScrollableScrollPhysics(),
            children: [
              for (final note in preview)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 52,
                        child: Text(
                          DateFormatter.timeOnly(note.at),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          note.message,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const WalkInSolidIcon(
              icon: Icons.notes_outlined,
              color: WalkInQueueMetrics.iconTeal,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Notes',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: notes.isEmpty ? null : onViewAll,
              child: const Text('View all'),
            ),
          ],
        ),
        if (expanded) Expanded(child: feed) else feed,
      ],
    );

    if (!expanded) {
      return HeltySurfaceCard(padding: const EdgeInsets.all(14), child: body);
    }
    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox.expand(
        child: Padding(padding: const EdgeInsets.all(14), child: body),
      ),
    );
  }
}

Future<void> showWalkInNotesDialog(
  BuildContext context,
  List<WalkInActivityNote> notes,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Activity'),
        content: SizedBox(
          width: 420,
          child: notes.isEmpty
              ? const Text('No recent activity this session.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: notes.length,
                  separatorBuilder: (_, _) => const Divider(height: 16),
                  itemBuilder: (context, i) {
                    final note = notes[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(note.message),
                      subtitle: Text(DateFormatter.dateTime(note.at)),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
