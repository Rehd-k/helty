import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HubTimelineEntry {
  const HubTimelineEntry({
    required this.title,
    required this.subtitle,
    required this.date,
    this.icon,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final DateTime? date;
  final IconData? icon;
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
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          InkWell(
            onTap: entries[i].onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: cs.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          entries[i].icon ?? Icons.circle,
                          size: 16,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      if (i < entries.length - 1)
                        Container(
                          width: 2,
                          height: 24,
                          color: cs.outlineVariant,
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries[i].title,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          entries[i].subtitle,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                        ),
                        if (entries[i].date != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              DateFormat.yMMMd().add_jm().format(
                                    entries[i].date!.toLocal(),
                                  ),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: cs.outline,
                                  ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
