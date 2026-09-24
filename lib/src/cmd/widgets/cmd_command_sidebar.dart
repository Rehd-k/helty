import 'package:flutter/material.dart';

import '../../helper/date.formatter.dart';
import '../../helper/theme.dart';
import '../../widgets/helty_surface.dart';
import '../cmd_command_metrics.dart';
import '../models/cmd_models.dart';

/// Quick actions, alerts, and live activity for the command-center rail.
class CmdCommandSidebar extends StatelessWidget {
  const CmdCommandSidebar({
    super.key,
    required this.alerts,
    required this.activity,
    required this.onRefresh,
    required this.onHospitalOverview,
    required this.onFinancialCommand,
    required this.onAlerts,
    required this.onViewAllActivity,
    this.fillHeight = false,
  });

  final List<CmdAlertChip> alerts;
  final List<CmdActivityFeedItem> activity;
  final VoidCallback onRefresh;
  final VoidCallback onHospitalOverview;
  final VoidCallback onFinancialCommand;
  final VoidCallback onAlerts;
  final VoidCallback onViewAllActivity;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final quick = _QuickActionsCard(
      onRefresh: onRefresh,
      onHospitalOverview: onHospitalOverview,
      onFinancialCommand: onFinancialCommand,
      onAlerts: onAlerts,
    );
    final alertsCard = _AlertsCard(alerts: alerts, expanded: fillHeight);
    final activityCard = _ActivityCard(
      activity: activity,
      onViewAll: onViewAllActivity,
      expanded: fillHeight,
    );

    if (!fillHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          quick,
          const SizedBox(height: 12),
          alertsCard,
          const SizedBox(height: 12),
          activityCard,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        quick,
        const SizedBox(height: 12),
        Expanded(flex: 3, child: alertsCard),
        const SizedBox(height: 12),
        Expanded(flex: 2, child: activityCard),
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onRefresh,
    required this.onHospitalOverview,
    required this.onFinancialCommand,
    required this.onAlerts,
  });

  final VoidCallback onRefresh;
  final VoidCallback onHospitalOverview;
  final VoidCallback onFinancialCommand;
  final VoidCallback onAlerts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HeltySolidIcon(
                icon: Icons.flash_on,
                color: CmdCommandMetrics.waitAmber,
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _GradientActionButton(
            label: 'Refresh Dashboard',
            icon: Icons.refresh,
            colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.45)!],
            onPressed: onRefresh,
          ),
          const SizedBox(height: 10),
          _GradientActionButton(
            label: 'Hospital Overview',
            icon: Icons.account_balance_outlined,
            colors: [
              CmdCommandMetrics.waitGreen,
              Color.lerp(CmdCommandMetrics.waitGreen, cs.primary, 0.25)!,
            ],
            onPressed: onHospitalOverview,
          ),
          const SizedBox(height: 10),
          _GradientActionButton(
            label: 'Financial Command',
            icon: Icons.payments_outlined,
            colors: [
              CmdCommandMetrics.iconTeal,
              Color.lerp(CmdCommandMetrics.iconTeal, cs.primary, 0.25)!,
            ],
            onPressed: onFinancialCommand,
          ),
          const SizedBox(height: 10),
          _GradientActionButton(
            label: 'Alerts & Incidents',
            icon: Icons.crisis_alert_outlined,
            colors: [cs.tertiary, Color.lerp(cs.tertiary, cs.primary, 0.4)!],
            onPressed: onAlerts,
          ),
        ],
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.colors,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final List<Color> colors;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: colors),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.alerts, this.expanded = false});

  final List<CmdAlertChip> alerts;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final list = alerts.isEmpty
        ? Text(
            'No active alerts.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          )
        : ListView(
            shrinkWrap: !expanded,
            physics: expanded ? null : const NeverScrollableScrollPhysics(),
            children: [
              for (final alert in alerts)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: CmdCommandMetrics.alertColor(alert.level),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: HeltyEllipsisText(
                          text: alert.message,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const HeltySolidIcon(
              icon: Icons.shield_outlined,
              color: CmdCommandMetrics.waitRed,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Text(
              'Alerts',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (expanded) Expanded(child: list) else list,
      ],
    );

    if (!expanded) {
      return HeltySurfaceCard(padding: const EdgeInsets.all(14), child: body);
    }
    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox.expand(
        child: Padding(padding: const EdgeInsets.all(14), child: body),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({
    required this.activity,
    required this.onViewAll,
    this.expanded = false,
  });

  final List<CmdActivityFeedItem> activity;
  final VoidCallback onViewAll;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final preview = activity.take(expanded ? activity.length : 5).toList();
    final feed = preview.isEmpty
        ? Text(
            'No recent activity.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          )
        : ListView(
            shrinkWrap: !expanded,
            physics: expanded ? null : const NeverScrollableScrollPhysics(),
            children: [
              for (final item in preview)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 52,
                        child: Text(
                          DateFormatter.timeOnly(item.at),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: HeltyEllipsisText(
                          text: item.message,
                          maxLines: 2,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const HeltySolidIcon(
              icon: Icons.notes_outlined,
              color: CmdCommandMetrics.iconTeal,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Activity',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: activity.isEmpty ? null : onViewAll,
              child: const Text('View all'),
            ),
          ],
        ),
        if (expanded) Expanded(child: feed) else feed,
      ],
    );

    if (!expanded) {
      return HeltySurfaceCard(padding: const EdgeInsets.all(14), child: body);
    }
    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox.expand(
        child: Padding(padding: const EdgeInsets.all(14), child: body),
      ),
    );
  }
}

Future<void> showCmdActivityDialog(
  BuildContext context,
  List<CmdActivityFeedItem> activity,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final width = MediaQuery.sizeOf(ctx).width;
      return AlertDialog(
        title: const Text('Activity'),
        content: SizedBox(
          width: width < 592 ? width - 32 : 560,
          child: activity.isEmpty
              ? const Text('No recent activity.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: activity.length,
                  separatorBuilder: (_, _) => const Divider(height: 16),
                  itemBuilder: (context, i) {
                    final item = activity[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.message),
                      subtitle: Text(
                        '${DateFormatter.dateTime(item.at)} · ${item.actorLabel} · ${item.category}',
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
