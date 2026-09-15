import 'package:flutter/material.dart';

import 'package:helty/src/widgets/empty.widget.dart';
import '../patient_hub_metrics.dart';

/// Patient-hub empty state — delegates to the shared [EmptyStateWidget].
class HubEmptyState extends StatelessWidget {
  const HubEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.action,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    if (action != null) {
      final cs = Theme.of(context).colorScheme;
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HubSolidIcon(
                  icon: icon,
                  color: PatientHubMetrics.iconIndigo,
                  size: 44,
                  iconSize: 22,
                  radius: 12,
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                  textAlign: TextAlign.center,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 16),
                action!,
              ],
            ),
          ),
        ),
      );
    }

    return EmptyStateWidget(
      icon: icon,
      title: title,
      message: subtitle ?? 'Nothing to show yet',
    );
  }
}
