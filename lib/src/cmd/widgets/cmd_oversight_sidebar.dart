import 'package:flutter/material.dart';

import '../../helper/theme.dart';
import '../../widgets/helty_surface.dart';
import '../cmd_oversight_metrics.dart';
import '../models/cmd_models.dart';

/// Quick actions, staffing alerts, and performance for the oversight rail.
class CmdOversightSidebar extends StatelessWidget {
  const CmdOversightSidebar({
    super.key,
    required this.alerts,
    required this.performance,
    required this.onRefresh,
    required this.onCommandCenter,
    required this.onAlerts,
    required this.onHospitalOverview,
    required this.onViewAllPerformance,
    this.fillHeight = false,
  });

  final List<CmdStaffingAlert> alerts;
  final List<CmdStaffPerformanceRow> performance;
  final VoidCallback onRefresh;
  final VoidCallback onCommandCenter;
  final VoidCallback onAlerts;
  final VoidCallback onHospitalOverview;
  final VoidCallback onViewAllPerformance;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final quick = _QuickActionsCard(
      onRefresh: onRefresh,
      onCommandCenter: onCommandCenter,
      onAlerts: onAlerts,
      onHospitalOverview: onHospitalOverview,
    );
    final alertsCard = _AlertsCard(alerts: alerts, expanded: fillHeight);
    final perfCard = _PerformanceCard(
      performance: performance,
      onViewAll: onViewAllPerformance,
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
          perfCard,
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
        Expanded(flex: 2, child: perfCard),
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onRefresh,
    required this.onCommandCenter,
    required this.onAlerts,
    required this.onHospitalOverview,
  });

  final VoidCallback onRefresh;
  final VoidCallback onCommandCenter;
  final VoidCallback onAlerts;
  final VoidCallback onHospitalOverview;

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
                color: CmdOversightMetrics.waitAmber,
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
            label: 'Refresh Roster',
            icon: Icons.refresh,
            colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.45)!],
            onPressed: onRefresh,
          ),
          const SizedBox(height: 10),
          _GradientActionButton(
            label: 'Command Center',
            icon: Icons.hub_outlined,
            colors: [
              CmdOversightMetrics.waitGreen,
              Color.lerp(CmdOversightMetrics.waitGreen, cs.primary, 0.25)!,
            ],
            onPressed: onCommandCenter,
          ),
          const SizedBox(height: 10),
          _GradientActionButton(
            label: 'Alerts & Incidents',
            icon: Icons.crisis_alert_outlined,
            colors: [
              CmdOversightMetrics.iconTeal,
              Color.lerp(CmdOversightMetrics.iconTeal, cs.primary, 0.25)!,
            ],
            onPressed: onAlerts,
          ),
          const SizedBox(height: 10),
          _GradientActionButton(
            label: 'Hospital Overview',
            icon: Icons.account_balance_outlined,
            colors: [cs.tertiary, Color.lerp(cs.tertiary, cs.primary, 0.4)!],
            onPressed: onHospitalOverview,
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

  final List<CmdStaffingAlert> alerts;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final list = alerts.isEmpty
        ? Text(
            'No staffing alerts.',
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
                        decoration: const BoxDecoration(
                          color: CmdOversightMetrics.waitRed,
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
              color: CmdOversightMetrics.waitRed,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Text(
              'Staffing Alerts',
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

class _PerformanceCard extends StatelessWidget {
  const _PerformanceCard({
    required this.performance,
    required this.onViewAll,
    this.expanded = false,
  });

  final List<CmdStaffPerformanceRow> performance;
  final VoidCallback onViewAll;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final preview = performance
        .take(expanded ? performance.length : 5)
        .toList();
    final feed = preview.isEmpty
        ? Text(
            'No performance rows.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          )
        : ListView(
            shrinkWrap: !expanded,
            physics: expanded ? null : const NeverScrollableScrollPhysics(),
            children: [
              for (final row in preview)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: HeltyEllipsisText(
                          text: CmdOversightMetrics.display(row.nameOrTeam),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${row.patientsHandled}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
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
              icon: Icons.insights_outlined,
              color: CmdOversightMetrics.iconTeal,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Performance',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: performance.isEmpty ? null : onViewAll,
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

Future<void> showCmdOversightPerformanceDialog(
  BuildContext context,
  List<CmdStaffPerformanceRow> performance,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final width = MediaQuery.sizeOf(ctx).width;
      return AlertDialog(
        title: const Text('Performance'),
        content: SizedBox(
          width: width < 592 ? width - 32 : 560,
          child: performance.isEmpty
              ? const Text('No performance rows.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: performance.length,
                  separatorBuilder: (_, _) => const Divider(height: 16),
                  itemBuilder: (context, i) {
                    final row = performance[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(CmdOversightMetrics.display(row.nameOrTeam)),
                      subtitle: Text(
                        '${CmdOversightMetrics.display(row.role)} · '
                        '${row.patientsHandled} patients · '
                        '${row.efficiencyScore.toStringAsFixed(2)} efficiency',
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
