import 'package:flutter/material.dart';

import '../../helper/theme.dart';
import '../../widgets/helty_surface.dart';
import '../cmd_overview_metrics.dart';
import '../models/cmd_models.dart';

/// Quick actions, patient flow, and wait times for the overview rail.
class CmdOverviewSidebar extends StatelessWidget {
  const CmdOverviewSidebar({
    super.key,
    required this.flow,
    required this.waitTimes,
    required this.dailySummary,
    required this.weeklySummary,
    required this.onRefresh,
    required this.onCommandCenter,
    required this.onStaffOversight,
    required this.onAlerts,
    required this.onViewSummaries,
    this.fillHeight = false,
  });

  final List<CmdFlowStageMetric> flow;
  final List<CmdWaitTimeRow> waitTimes;
  final String dailySummary;
  final String weeklySummary;
  final VoidCallback onRefresh;
  final VoidCallback onCommandCenter;
  final VoidCallback onStaffOversight;
  final VoidCallback onAlerts;
  final VoidCallback onViewSummaries;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final quick = _QuickActionsCard(
      onRefresh: onRefresh,
      onCommandCenter: onCommandCenter,
      onStaffOversight: onStaffOversight,
      onAlerts: onAlerts,
    );
    final flowCard = _FlowCard(flow: flow, expanded: fillHeight);
    final waitCard = _WaitCard(
      waitTimes: waitTimes,
      dailySummary: dailySummary,
      weeklySummary: weeklySummary,
      onViewAll: onViewSummaries,
      expanded: fillHeight,
    );

    if (!fillHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          quick,
          const SizedBox(height: 12),
          flowCard,
          const SizedBox(height: 12),
          waitCard,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        quick,
        const SizedBox(height: 12),
        Expanded(flex: 3, child: flowCard),
        const SizedBox(height: 12),
        Expanded(flex: 2, child: waitCard),
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onRefresh,
    required this.onCommandCenter,
    required this.onStaffOversight,
    required this.onAlerts,
  });

  final VoidCallback onRefresh;
  final VoidCallback onCommandCenter;
  final VoidCallback onStaffOversight;
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
                color: CmdOverviewMetrics.waitAmber,
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
            label: 'Refresh Overview',
            icon: Icons.refresh,
            colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.45)!],
            onPressed: onRefresh,
          ),
          const SizedBox(height: 10),
          _GradientActionButton(
            label: 'Command Center',
            icon: Icons.hub_outlined,
            colors: [
              CmdOverviewMetrics.waitGreen,
              Color.lerp(CmdOverviewMetrics.waitGreen, cs.primary, 0.25)!,
            ],
            onPressed: onCommandCenter,
          ),
          const SizedBox(height: 10),
          _GradientActionButton(
            label: 'Staff Oversight',
            icon: Icons.groups_outlined,
            colors: [
              CmdOverviewMetrics.iconTeal,
              Color.lerp(CmdOverviewMetrics.iconTeal, cs.primary, 0.25)!,
            ],
            onPressed: onStaffOversight,
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

class _FlowCard extends StatelessWidget {
  const _FlowCard({required this.flow, this.expanded = false});

  final List<CmdFlowStageMetric> flow;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final list = flow.isEmpty
        ? Text(
            'No patient-flow stages.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          )
        : ListView(
            shrinkWrap: !expanded,
            physics: expanded ? null : const NeverScrollableScrollPhysics(),
            children: [
              for (final stage in flow)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: CmdOverviewMetrics.colorForDepartment(
                            stage.stage,
                            CmdOverviewMetrics.iconBlue,
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            HeltyEllipsisText(
                              text: CmdOverviewMetrics.display(stage.stage),
                              style: theme.textTheme.bodyMedium,
                            ),
                            HeltyEllipsisText(
                              text: 'Avg ${stage.avgMinutes} min',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${stage.patientsInStage}',
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
              icon: Icons.account_tree_outlined,
              color: CmdOverviewMetrics.iconBlue,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Text(
              'Patient Flow',
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

class _WaitCard extends StatelessWidget {
  const _WaitCard({
    required this.waitTimes,
    required this.dailySummary,
    required this.weeklySummary,
    required this.onViewAll,
    this.expanded = false,
  });

  final List<CmdWaitTimeRow> waitTimes;
  final String dailySummary;
  final String weeklySummary;
  final VoidCallback onViewAll;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final preview = waitTimes.take(expanded ? waitTimes.length : 5).toList();
    final feed = preview.isEmpty
        ? Text(
            CmdOverviewMetrics.display(dailySummary),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
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
                          text: CmdOverviewMetrics.display(row.area),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'P50 ${row.p50Minutes}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        CmdOverviewMetrics.display(row.trendLabel),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: CmdOverviewMetrics.trendColor(row.trendLabel),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );

    final hasDetail =
        waitTimes.isNotEmpty ||
        dailySummary.trim().isNotEmpty ||
        weeklySummary.trim().isNotEmpty;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const HeltySolidIcon(
              icon: Icons.schedule_outlined,
              color: CmdOverviewMetrics.iconTeal,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Wait Times',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: hasDetail ? onViewAll : null,
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

Future<void> showCmdOverviewSummariesDialog({
  required BuildContext context,
  required String dailySummary,
  required String weeklySummary,
  required List<CmdWaitTimeRow> waitTimes,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      final width = MediaQuery.sizeOf(ctx).width;
      return AlertDialog(
        title: const Text('Overview detail'),
        content: SizedBox(
          width: width < 592 ? width - 32 : 560,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily',
                  style: Theme.of(
                    ctx,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(CmdOverviewMetrics.display(dailySummary)),
                const SizedBox(height: 16),
                Text(
                  'Weekly',
                  style: Theme.of(
                    ctx,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 4),
                Text(CmdOverviewMetrics.display(weeklySummary)),
                if (waitTimes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Wait times',
                    style: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final row in waitTimes)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${CmdOverviewMetrics.display(row.area)} · '
                        'P50 ${row.p50Minutes} min · '
                        'P90 ${row.p90Minutes} min · '
                        '${CmdOverviewMetrics.display(row.trendLabel)}',
                      ),
                    ),
                ],
              ],
            ),
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
