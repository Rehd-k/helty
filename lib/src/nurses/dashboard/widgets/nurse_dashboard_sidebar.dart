import 'package:flutter/material.dart';

import '../../../helper/date.formatter.dart';
import '../../../helper/theme.dart';
import '../../../models/nurse_dashboard_models.dart';
import '../../../nursing/models/nursing_models.dart';
import '../../../widgets/helty_surface.dart';
import '../nurse_dashboard_metrics.dart';

/// Quick actions, staff/shifts, and critical alerts for the dashboard rail.
class NurseDashboardSidebar extends StatelessWidget {
  const NurseDashboardSidebar({
    super.key,
    required this.staffOnDuty,
    required this.alerts,
    required this.myShifts,
    required this.onRefresh,
    required this.onWardCensus,
    required this.onWaitingPatients,
    required this.onViewAlerts,
    this.onManageRoster,
    this.onAssignments,
    this.fillHeight = false,
  });

  final List<NurseStaffOnDuty> staffOnDuty;
  final List<NurseCriticalAlert> alerts;
  final List<NursingMyRosterShift> myShifts;
  final VoidCallback onRefresh;
  final VoidCallback onWardCensus;
  final VoidCallback onWaitingPatients;
  final VoidCallback onViewAlerts;
  final VoidCallback? onManageRoster;
  final VoidCallback? onAssignments;
  final bool fillHeight;

  @override
  Widget build(BuildContext context) {
    final quick = _QuickActionsCard(
      onRefresh: onRefresh,
      onWardCensus: onWardCensus,
      onWaitingPatients: onWaitingPatients,
      onManageRoster: onManageRoster,
      onAssignments: onAssignments,
    );
    final roster = myShifts.isNotEmpty
        ? _MyShiftsCard(shifts: myShifts, expanded: fillHeight)
        : _StaffCard(staff: staffOnDuty, expanded: fillHeight);
    final alertsCard = _AlertsCard(
      alerts: alerts,
      onViewAll: onViewAlerts,
      expanded: fillHeight,
    );

    if (!fillHeight) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          quick,
          const SizedBox(height: 12),
          roster,
          const SizedBox(height: 12),
          alertsCard,
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        quick,
        const SizedBox(height: 12),
        Expanded(flex: 3, child: roster),
        const SizedBox(height: 12),
        Expanded(flex: 2, child: alertsCard),
      ],
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onRefresh,
    required this.onWardCensus,
    required this.onWaitingPatients,
    this.onManageRoster,
    this.onAssignments,
  });

  final VoidCallback onRefresh;
  final VoidCallback onWardCensus;
  final VoidCallback onWaitingPatients;
  final VoidCallback? onManageRoster;
  final VoidCallback? onAssignments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final fourth = onManageRoster != null
        ? _GradientActionButton(
            label: 'Manage Roster',
            icon: Icons.calendar_month_outlined,
            colors: [cs.tertiary, Color.lerp(cs.tertiary, cs.primary, 0.4)!],
            onPressed: onManageRoster!,
          )
        : onAssignments != null
        ? _GradientActionButton(
            label: 'Assignments',
            icon: Icons.assignment_ind_outlined,
            colors: [cs.tertiary, Color.lerp(cs.tertiary, cs.primary, 0.4)!],
            onPressed: onAssignments!,
          )
        : null;

    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HeltySolidIcon(
                icon: Icons.flash_on,
                color: NurseDashboardMetrics.waitAmber,
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
            label: 'Ward Census',
            icon: Icons.hotel_outlined,
            colors: [
              NurseDashboardMetrics.iconTeal,
              Color.lerp(NurseDashboardMetrics.iconTeal, cs.primary, 0.25)!,
            ],
            onPressed: onWardCensus,
          ),
          const SizedBox(height: 10),
          _GradientActionButton(
            label: 'Waiting Patients',
            icon: Icons.groups_outlined,
            colors: [
              NurseDashboardMetrics.waitAmber,
              Color.lerp(NurseDashboardMetrics.waitAmber, cs.error, 0.15)!,
            ],
            onPressed: onWaitingPatients,
          ),
          if (fourth != null) ...[const SizedBox(height: 10), fourth],
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

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.staff, this.expanded = false});

  final List<NurseStaffOnDuty> staff;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final list = staff.isEmpty
        ? Text(
            'No staff on duty.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          )
        : ListView.separated(
            shrinkWrap: !expanded,
            physics: expanded ? null : const NeverScrollableScrollPhysics(),
            itemCount: staff.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final row = staff[i];
              final tone = NurseDashboardMetrics.statusToneColor(
                row.statusTone,
                cs,
              );
              final initial = row.name.trim().isNotEmpty
                  ? row.name.trim().substring(0, 1).toUpperCase()
                  : '?';
              return Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: NurseDashboardMetrics.iconBlue,
                    foregroundColor: Colors.white,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        HeltyEllipsisText(
                          text: row.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        HeltyEllipsisText(
                          text: row.role,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  HeltyStatusChip(label: row.status, color: tone),
                ],
              );
            },
          );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const HeltySolidIcon(
              icon: Icons.badge_outlined,
              color: NurseDashboardMetrics.iconBlue,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Staff on Duty',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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

class _MyShiftsCard extends StatelessWidget {
  const _MyShiftsCard({required this.shifts, this.expanded = false});

  final List<NursingMyRosterShift> shifts;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final list = ListView.separated(
      shrinkWrap: !expanded,
      physics: expanded ? null : const NeverScrollableScrollPhysics(),
      itemCount: shifts.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final s = shifts[i];
        final shift = NurseDashboardMetrics.shiftLabel(s.shiftType);
        final unit = NurseDashboardMetrics.unitLabel(s.nursingUnit);
        final ward = s.wardName?.trim() ?? '';
        final subtitle = [
          if (ward.isNotEmpty) ward,
          if (unit.isNotEmpty && ward.isEmpty) unit,
          DateFormatter.medicalDate(s.shiftDate),
        ].join(' · ');
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HeltySolidIcon(
              icon: Icons.schedule_outlined,
              color: NurseDashboardMetrics.iconIndigo,
              size: 22,
              iconSize: 12,
              radius: 6,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeltyEllipsisText(
                    text: shift.isNotEmpty ? '$shift shift' : 'Shift',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  HeltyEllipsisText(
                    text: subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const HeltySolidIcon(
              icon: Icons.schedule_outlined,
              color: NurseDashboardMetrics.iconIndigo,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'My Shifts Today',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
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

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({
    required this.alerts,
    required this.onViewAll,
    this.expanded = false,
  });

  final List<NurseCriticalAlert> alerts;
  final VoidCallback onViewAll;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final preview = alerts.take(expanded ? alerts.length : 5).toList();
    final feed = preview.isEmpty
        ? Text(
            'No critical alerts.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          )
        : ListView.separated(
            shrinkWrap: !expanded,
            physics: expanded ? null : const NeverScrollableScrollPhysics(),
            itemCount: preview.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final a = preview[i];
              final accent = NurseDashboardMetrics.alertAccent(a.severity);
              final when = a.relativeLabel?.trim().isNotEmpty == true
                  ? a.relativeLabel!
                  : DateFormatter.shortDate(a.occurredAt);
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: HeltyEllipsisText(
                                text: a.location,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              when,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        HeltyEllipsisText(
                          text: a.message,
                          maxLines: 2,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const HeltySolidIcon(
              icon: Icons.warning_amber_rounded,
              color: NurseDashboardMetrics.waitRed,
              size: 26,
              iconSize: 14,
              radius: 7,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Critical Alerts',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            TextButton(
              onPressed: alerts.isEmpty ? null : onViewAll,
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

Future<void> showNurseDashboardAlertsDialog(
  BuildContext context,
  List<NurseCriticalAlert> alerts,
) {
  return showDialog<void>(
    context: context,
    builder: (ctx) {
      return AlertDialog(
        title: const Text('Critical alerts'),
        content: SizedBox(
          width: 420,
          child: alerts.isEmpty
              ? const Text('No critical alerts.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: alerts.length,
                  separatorBuilder: (_, _) => const Divider(height: 16),
                  itemBuilder: (context, i) {
                    final a = alerts[i];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(a.location),
                      subtitle: Text(
                        [
                          a.message,
                          a.relativeLabel ??
                              DateFormatter.dateTime(a.occurredAt),
                        ].join('\n'),
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
