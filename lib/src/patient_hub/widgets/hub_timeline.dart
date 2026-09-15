import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';

import '../../widgets/helty_surface.dart';
import '../patient_hub_metrics.dart';

class HubTimelineEntry {
  const HubTimelineEntry({
    required this.title,
    required this.subtitle,
    required this.date,
    this.icon,
    this.iconColor,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final DateTime? date;
  final IconData? icon;
  final Color? iconColor;
  final VoidCallback? onTap;
}

class HubTimeline extends StatelessWidget {
  const HubTimeline({super.key, required this.entries});

  final List<HubTimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const SizedBox.shrink();
    }
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            InkWell(
              onTap: entries[i].onTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    HubSolidIcon(
                      icon: entries[i].icon ?? Icons.circle,
                      color: entries[i].iconColor ?? PatientHubMetrics.iconBlue,
                      size: 28,
                      iconSize: 14,
                      radius: 7,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          HeltyEllipsisText(
                            text: entries[i].title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (entries[i].subtitle.trim().isNotEmpty)
                            HeltyEllipsisText(
                              text: entries[i].subtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          if (entries[i].date != null)
                            HeltyEllipsisText(
                              text: DateFormatter.dateTime(entries[i].date!),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.outline,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i < entries.length - 1)
              Divider(height: 8, color: cs.outline.withValues(alpha: 0.12)),
          ],
        ],
      ),
    );
  }
}
