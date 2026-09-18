import 'package:flutter/material.dart';

import '../../../nursing/models/nursing_models.dart';
import '../../../widgets/helty_surface.dart';
import '../nurse_dashboard_metrics.dart';

/// Compact unit-roster and shift-coverage cards under the KPI strip.
class NurseDashboardRoleStrip extends StatelessWidget {
  const NurseDashboardRoleStrip({
    super.key,
    this.unitRosterCounts = const [],
    this.shiftBreakdown = const [],
    this.onManageRoster,
    this.onAssignments,
  });

  final List<NursingUnitRosterCount> unitRosterCounts;
  final List<NursingShiftBreakdown> shiftBreakdown;
  final VoidCallback? onManageRoster;
  final VoidCallback? onAssignments;

  bool get isEmpty => unitRosterCounts.isEmpty && shiftBreakdown.isEmpty;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (unitRosterCounts.isNotEmpty)
          _UnitRosterRow(
            counts: unitRosterCounts,
            onManageRoster: onManageRoster,
            onAssignments: onAssignments,
          ),
        if (unitRosterCounts.isNotEmpty && shiftBreakdown.isNotEmpty)
          const SizedBox(height: 10),
        if (shiftBreakdown.isNotEmpty)
          _ShiftBreakdownRow(shifts: shiftBreakdown),
      ],
    );
  }
}

class _UnitRosterRow extends StatelessWidget {
  const _UnitRosterRow({
    required this.counts,
    this.onManageRoster,
    this.onAssignments,
  });

  final List<NursingUnitRosterCount> counts;
  final VoidCallback? onManageRoster;
  final VoidCallback? onAssignments;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const HeltySolidIcon(
              icon: Icons.apartment_outlined,
              color: NurseDashboardMetrics.iconPink,
              size: 22,
              iconSize: 12,
              radius: 6,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Unit roster & coverage',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (onManageRoster != null)
              TextButton(
                onPressed: onManageRoster,
                child: const Text('Roster'),
              ),
            if (onAssignments != null)
              TextButton(
                onPressed: onAssignments,
                child: const Text('Assignments'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 820;
            if (wide) {
              return Row(
                children: [
                  for (var i = 0; i < counts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _UnitCard(count: counts[i])),
                  ],
                ],
              );
            }
            return SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: counts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) =>
                    SizedBox(width: 200, child: _UnitCard(count: counts[i])),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _UnitCard extends StatelessWidget {
  const _UnitCard({required this.count});

  final NursingUnitRosterCount count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final label = NurseDashboardMetrics.unitLabel(count.nursingUnit);
    final gap = count.coverageGap > 0
        ? 'Coverage gap ${count.coverageGap}'
        : count.assignmentGap > 0
        ? 'Assignment gap ${count.assignmentGap}'
        : 'On duty ${count.onDuty}';
    final accent = count.coverageGap > 0
        ? NurseDashboardMetrics.waitRed
        : count.assignmentGap > 0
        ? NurseDashboardMetrics.waitAmber
        : NurseDashboardMetrics.iconBlue;

    return HeltySurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          HeltySolidIcon(
            icon: Icons.domain_outlined,
            color: NurseDashboardMetrics.colorForUnit(label, accent),
            size: 30,
            iconSize: 16,
            radius: 8,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HeltyEllipsisText(
                  text: label.isEmpty ? 'Unit' : label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                HeltyEllipsisText(
                  text: '${count.onDuty}/${count.scheduled}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                HeltyEllipsisText(
                  text: gap,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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

class _ShiftBreakdownRow extends StatelessWidget {
  const _ShiftBreakdownRow({required this.shifts});

  final List<NursingShiftBreakdown> shifts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const HeltySolidIcon(
              icon: Icons.nights_stay_outlined,
              color: NurseDashboardMetrics.iconIndigo,
              size: 22,
              iconSize: 12,
              radius: 6,
            ),
            const SizedBox(width: 8),
            Text(
              "Today's roster by shift",
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 820) {
              return Row(
                children: [
                  for (var i = 0; i < shifts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(child: _ShiftCard(shift: shifts[i])),
                  ],
                ],
              );
            }
            return SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: shifts.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) =>
                    SizedBox(width: 180, child: _ShiftCard(shift: shifts[i])),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ShiftCard extends StatelessWidget {
  const _ShiftCard({required this.shift});

  final NursingShiftBreakdown shift;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final label = NurseDashboardMetrics.shiftLabel(shift.shiftType);
    final short = shift.scheduled == 0
        ? '—'
        : '${((shift.onDuty / shift.scheduled) * 100).round()}% on duty';

    return HeltySurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          HeltySolidIcon(
            icon: Icons.schedule_outlined,
            color: NurseDashboardMetrics.iconIndigo,
            size: 30,
            iconSize: 16,
            radius: 8,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HeltyEllipsisText(
                  text: label.isEmpty ? 'Shift' : label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                HeltyEllipsisText(
                  text: '${shift.onDuty}/${shift.scheduled}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                HeltyEllipsisText(
                  text: short,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
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
