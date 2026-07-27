import 'package:flutter/material.dart';

import 'package:helty/src/widgets/helty_surface.dart';

import '../cmac_palette.dart';
import '../models/cmac_analytics_models.dart';
import 'cmac_kpi_card.dart';

class CmacAlertBanner extends StatelessWidget {
  const CmacAlertBanner({super.key, required this.alerts});

  final List<CmacAlert> alerts;

  @override
  Widget build(BuildContext context) {
    if (alerts.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: alerts.map((a) {
        final color = CmacPalette.severityColor(a.severity);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Card(
            color: color.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: color),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          a.message,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        if (a.metric != null)
                          Text(
                            a.metric!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  HeltyStatusChip(label: a.severity.toUpperCase(), color: color),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class CmacInsightList extends StatelessWidget {
  const CmacInsightList({super.key, required this.insights});

  final List<CmacInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return const CmacEmptyHint(message: 'No system insights for this period.');
    }
    final sorted = [...insights]
      ..sort((a, b) {
        int rank(String s) {
          switch (s.toLowerCase()) {
            case 'critical':
              return 0;
            case 'warning':
              return 1;
            default:
              return 2;
          }
        }

        return rank(a.severity).compareTo(rank(b.severity));
      });

    return Column(
      children: sorted
          .map((i) => CmacInsightCard(insight: i))
          .toList(),
    );
  }
}

class CmacInsightCard extends StatelessWidget {
  const CmacInsightCard({super.key, required this.insight});

  final CmacInsight insight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final color = CmacPalette.severityColor(insight.severity);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(
                color: color,
                child: const SizedBox(width: 4),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_rounded, color: color, size: 22),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              insight.message,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                              ),
                            ),
                            if (insight.category != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                insight.category!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
