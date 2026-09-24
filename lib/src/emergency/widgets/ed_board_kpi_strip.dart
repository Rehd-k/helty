import 'package:flutter/material.dart';

import '../../widgets/helty_surface.dart';
import '../ed_board_metrics.dart';

class EdBoardKpiItem {
  const EdBoardKpiItem({
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

/// Compact ED KPI cards with solid icon tiles.
class EdBoardKpiStrip extends StatelessWidget {
  const EdBoardKpiStrip({
    super.key,
    required this.inEd,
    required this.criticalEsi,
    required this.waitingDoctor,
    required this.avgWaitLabel,
    this.useSnapStrip = false,
  });

  final int? inEd;
  final int? criticalEsi;
  final int? waitingDoctor;
  final String avgWaitLabel;
  final bool useSnapStrip;

  @override
  Widget build(BuildContext context) {
    final items = [
      EdBoardKpiItem(
        label: 'In ED',
        value: inEd == null ? '—' : '$inEd',
        caption: 'Active visits',
        icon: Icons.emergency_outlined,
        accent: EdBoardMetrics.iconBlue,
      ),
      EdBoardKpiItem(
        label: 'ESI 1–2',
        value: criticalEsi == null ? '—' : '$criticalEsi',
        caption: 'Critical acuity',
        icon: Icons.priority_high_outlined,
        accent: EdBoardMetrics.waitRed,
      ),
      EdBoardKpiItem(
        label: 'Waiting doctor',
        value: waitingDoctor == null ? '—' : '$waitingDoctor',
        caption: 'Ready for physician',
        icon: Icons.medical_services_outlined,
        accent: EdBoardMetrics.iconTeal,
      ),
      EdBoardKpiItem(
        label: 'Avg. wait',
        value: avgWaitLabel,
        caption: 'From arrival',
        icon: Icons.schedule_outlined,
        accent: EdBoardMetrics.waitAmber,
      ),
    ];

    if (useSnapStrip) {
      return SizedBox(
        height: 78,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const PageScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (_, _) => const SizedBox(width: 8),
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

  final EdBoardKpiItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          EdBoardSolidIcon(
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
