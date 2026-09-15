import 'package:flutter/material.dart';

import '../../widgets/helty_surface.dart';
import '../patient_hub_metrics.dart';

/// Dense list row used across hub tabs.
class HubListRow extends StatelessWidget {
  const HubListRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.folder_outlined,
    this.iconColor = PatientHubMetrics.iconBlue,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Color iconColor;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      margin: const EdgeInsets.only(bottom: 8),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          HubSolidIcon(
            icon: icon,
            color: iconColor,
            size: 30,
            iconSize: 16,
            radius: 8,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HeltyEllipsisText(
                  text: title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (subtitle != null && subtitle!.trim().isNotEmpty)
                  HeltyEllipsisText(
                    text: subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
          if (onTap != null)
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        ],
      ),
    );
  }
}
