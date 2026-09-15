import 'package:flutter/material.dart';

import '../../helper/theme.dart';
import '../../widgets/helty_surface.dart';
import '../ed_board_metrics.dart';
import '../models/ed_enums.dart';
import '../models/emergency_visit_model.dart';

class EdBoardCountRow {
  const EdBoardCountRow({required this.label, required this.count, required this.color});

  final String label;
  final int count;
  final Color color;
}

/// Quick actions, ESI counts, and status counts.
class EdBoardSidebar extends StatelessWidget {
  const EdBoardSidebar({
    super.key,
    required this.esiCounts,
    required this.statusCounts,
    required this.onRegister,
    required this.onRefresh,
    this.canRegister = false,
    this.fillHeight = false,
  });

  final List<EdBoardCountRow> esiCounts;
  final List<EdBoardCountRow> statusCounts;
  final VoidCallback onRegister;
  final VoidCallback onRefresh;
  final bool canRegister;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final quick = _QuickActionsCard(
      onRegister: onRegister,
      onRefresh: onRefresh,
      canRegister: canRegister,
    );
    final esi = _CountsCard(
      title: 'By ESI',
      icon: Icons.priority_high_outlined,
      iconColor: EdBoardMetrics.waitRed,
      rows: esiCounts,
      emptyLabel: 'No ESI data on this page.',
      expanded: fillHeight,
    );
    final status = _CountsCard(
      title: 'By status',
      icon: Icons.flag_outlined,
      iconColor: EdBoardMetrics.iconTeal,
      rows: statusCounts,
      emptyLabel: 'No visits on this page.',
      expanded: fillHeight,
    );

    if (!fillHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          quick,
          const SizedBox(height: 12),
          esi,
          const SizedBox(height: 12),
          status,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        quick,
        const SizedBox(height: 12),
        Expanded(flex: 3, child: esi),
        const SizedBox(height: 12),
        Expanded(flex: 2, child: status),
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onRegister,
    required this.onRefresh,
    required this.canRegister,
  });

  final VoidCallback onRegister;
  final VoidCallback onRefresh;
  final bool canRegister;

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
              const EdBoardSolidIcon(
                icon: Icons.flash_on,
                color: EdBoardMetrics.waitAmber,
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
          if (canRegister) ...[
            _GradientActionButton(
              label: 'Register patient',
              icon: Icons.person_add_alt_1,
              colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.45)!],
              onPressed: onRegister,
            ),
            const SizedBox(height: 10),
          ],
          _GradientActionButton(
            label: 'Refresh board',
            icon: Icons.refresh,
            colors: [
              EdBoardMetrics.iconTeal,
              Color.lerp(EdBoardMetrics.iconTeal, cs.primary, 0.25)!,
            ],
            onPressed: onRefresh,
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

class _CountsCard extends StatelessWidget {
  const _CountsCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.rows,
    required this.emptyLabel,
    this.expanded = false,
  });

  final String title;
  final IconData icon;
  final Color iconColor;
  final List<EdBoardCountRow> rows;
  final String emptyLabel;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final visible = rows.where((r) => r.count > 0).toList();
    final list = visible.isEmpty
        ? Text(
            emptyLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          )
        : ListView(
            shrinkWrap: !expanded,
            physics: expanded ? null : const NeverScrollableScrollPhysics(),
            children: [
              for (final row in visible)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: row.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          row.label,
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
            EdBoardSolidIcon(
              icon: icon,
              color: iconColor,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Text(
              title,
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

List<EdBoardCountRow> edBoardEsiCounts(List<EmergencyVisitModel> visits) {
  final counts = <int, int>{};
  for (final v in visits) {
    final esi = v.esiLevel;
    if (esi == null) continue;
    counts[esi] = (counts[esi] ?? 0) + 1;
  }
  return [
    for (var level = 1; level <= 5; level++)
      EdBoardCountRow(
        label: 'ESI $level',
        count: counts[level] ?? 0,
        color: EdBoardMetrics.esiStripeColor(level),
      ),
  ];
}

List<EdBoardCountRow> edBoardStatusCounts(List<EmergencyVisitModel> visits) {
  final counts = <EdWorkflowStatus, int>{};
  for (final v in visits) {
    counts[v.workflowStatus] = (counts[v.workflowStatus] ?? 0) + 1;
  }
  return EdWorkflowStatus.values
      .map(
        (s) => EdBoardCountRow(
          label: s.label,
          count: counts[s] ?? 0,
          color: EdBoardMetrics.statusColor(s),
        ),
      )
      .toList();
}
