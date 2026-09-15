import 'package:flutter/material.dart';

import '../../../widgets/helty_surface.dart';
import '../ongoing_encounters_metrics.dart';

class OngoingKpiItem {
  const OngoingKpiItem({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;
}

/// Compact ongoing-encounter KPI cards with solid icon tiles.
class OngoingEncountersKpiStrip extends StatelessWidget {
  const OngoingEncountersKpiStrip({
    super.key,
    required this.totalInRange,
    required this.startedToday,
    required this.avgElapsedLabel,
    required this.longestElapsedLabel,
    this.useSnapStrip = false,
  });

  final int totalInRange;
  final int startedToday;
  final String avgElapsedLabel;
  final String longestElapsedLabel;
  final bool useSnapStrip;

  @override
  Widget build(BuildContext context) {
    final items = [
      OngoingKpiItem(
        label: 'Open Now',
        value: '$totalInRange',
        caption: 'Ongoing encounters loaded',
        icon: Icons.pending_actions_outlined,
        accent: OngoingEncountersMetrics.iconBlue,
      ),
      OngoingKpiItem(
        label: 'Started Today',
        value: '$startedToday',
        caption: 'Opened during this calendar day',
        icon: Icons.today_outlined,
        accent: OngoingEncountersMetrics.iconTeal,
      ),
      OngoingKpiItem(
        label: 'Avg. Elapsed',
        value: avgElapsedLabel,
        caption: 'Time since encounter start',
        icon: Icons.schedule_outlined,
        accent: OngoingEncountersMetrics.waitAmber,
      ),
      OngoingKpiItem(
        label: 'Longest Open',
        value: longestElapsedLabel,
        caption: 'Oldest still-open visit',
        icon: Icons.hourglass_top_outlined,
        accent: OngoingEncountersMetrics.iconPurple,
      ),
    ];

    if (useSnapStrip) {
      return SizedBox(
        height: 78,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const PageScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) =>
              SizedBox(width: 200, child: _KpiCard(item: items[i])),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 820;
        if (wide) {
          return Row(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _KpiCard(item: items[i])),
              ],
            ],
          );
        }
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            mainAxisExtent: 72,
          ),
          itemBuilder: (context, i) => _KpiCard(item: items[i]),
        );
      },
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({required this.item});

  final OngoingKpiItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          HeltySolidIcon(
            icon: item.icon,
            color: item.accent,
            size: 30,
            iconSize: 16,
            radius: 8,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  item.value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1.15,
                  ),
                ),
                Text(
                  item.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
