import 'package:flutter/material.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: alerts.map((a) {
        final color = CmacPalette.severityColor(a.severity);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1.5),
            color: color.withValues(alpha: 0.08),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      a.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (a.metric != null)
                      Text(
                        a.metric!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Chip(
                label: Text(a.severity.toUpperCase()),
                backgroundColor: color.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
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
    final color = CmacPalette.severityColor(insight.severity);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.12),
            theme.colorScheme.surface.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_rounded, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (insight.category != null)
                  Text(
                    insight.category!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
