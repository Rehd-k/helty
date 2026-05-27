import 'package:flutter/material.dart';

import '../cmac_palette.dart';
import '../models/cmac_analytics_models.dart';

class CmacKpiGrid extends StatelessWidget {
  const CmacKpiGrid({
    super.key,
    required this.kpis,
    required this.accent,
  });

  final List<CmacKpiMetric> kpis;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    if (kpis.isEmpty) {
      return const CmacEmptyHint(message: 'No KPIs for this period.');
    }
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        final cols = w >= 1200 ? 4 : w >= 800 ? 3 : w >= 500 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: cols == 1 ? 2.8 : 1.55,
          ),
          itemCount: kpis.length,
          itemBuilder: (_, i) => CmacKpiCard(kpi: kpis[i], accent: accent),
        );
      },
    );
  }
}

class CmacKpiCard extends StatelessWidget {
  const CmacKpiCard({
    super.key,
    required this.kpi,
    required this.accent,
  });

  final CmacKpiMetric kpi;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final cmp = kpi.comparison;
    final trendColor = cmp == null
        ? cs.onSurfaceVariant
        : CmacPalette.trendColor(isPositive: cmp.isPositive);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: cs.surface.withValues(alpha: 0.95),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [accent, accent.withValues(alpha: 0.5)],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kpi.label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatValue(kpi.value, kpi.unit),
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                    ),
                  ),
                  if (cmp != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: trendColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            cmp.direction == 'down'
                                ? Icons.south_east_rounded
                                : cmp.direction == 'up'
                                ? Icons.north_east_rounded
                                : Icons.remove_rounded,
                            size: 14,
                            color: trendColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            cmp.percentChange != null
                                ? '${cmp.percentChange!.toStringAsFixed(1)}% vs prior'
                                : 'vs prior',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: trendColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatValue(num value, String? unit) {
    final v = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
    if (unit == null || unit.isEmpty) return v;
    return '$v $unit';
  }
}

class CmacEmptyHint extends StatelessWidget {
  const CmacEmptyHint({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
