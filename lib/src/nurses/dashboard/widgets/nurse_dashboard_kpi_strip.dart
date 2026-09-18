import 'package:flutter/material.dart';

import '../../../widgets/helty_surface.dart';
import '../nurse_dashboard_metrics.dart';

/// Compact nursing KPI cards with solid icon tiles.
class NurseDashboardKpiStrip extends StatelessWidget {
  const NurseDashboardKpiStrip({
    super.key,
    required this.items,
    this.useSnapStrip = false,
  });

  final List<NurseDashboardKpiItem> items;
  final bool useSnapStrip;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

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

  final NurseDashboardKpiItem item;

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
                HeltyEllipsisText(
                  text: item.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                HeltyEllipsisText(
                  text: item.value,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                    height: 1.15,
                  ),
                ),
                HeltyEllipsisText(
                  text: item.caption,
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
