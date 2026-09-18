import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/responsive.dart';
import '../../widgets/helty_surface.dart';
import '../cmd_command_metrics.dart';
import '../cmd_money_format.dart';
import '../models/cmd_models.dart';

class CmdPanelCard extends StatelessWidget {
  const CmdPanelCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return HeltySurfaceCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              HeltySolidIcon(
                icon: icon,
                color: accent,
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: HeltyEllipsisText(
                  text: title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class CmdFinancialOverviewPanel extends StatelessWidget {
  const CmdFinancialOverviewPanel({super.key, required this.bundle});

  final CmdExecutiveDashboardBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final series = bundle.revenueWeek;
    final nairaCompact = cmdNairaCompactFormat();

    Widget chart;
    if (series.isEmpty) {
      chart = SizedBox(
        height: 180,
        child: Center(
          child: Text(
            '—',
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    } else {
      var maxY =
          series
              .map(
                (e) => e.revenueInpatient > e.revenueOutpatient
                    ? e.revenueInpatient
                    : e.revenueOutpatient,
              )
              .reduce((a, b) => a > b ? a : b) *
          1.08 /
          1000;
      if (maxY < 8) maxY = 8;

      chart = SizedBox(
        height: 180,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => FlLine(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 44,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        nairaCompact.format(value * 1000),
                        style: theme.textTheme.labelSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    const days = [
                      'Mon',
                      'Tue',
                      'Wed',
                      'Thu',
                      'Fri',
                      'Sat',
                      'Sun',
                    ];
                    final i = value.toInt();
                    if (i >= 0 && i < days.length) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(days[i], style: theme.textTheme.labelSmall),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (final p in series)
                    FlSpot(p.dayIndex.toDouble(), p.revenueInpatient / 1000),
                ],
                isCurved: true,
                color: CmdCommandMetrics.iconBlue,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: CmdCommandMetrics.iconBlue.withValues(alpha: 0.16),
                ),
              ),
              LineChartBarData(
                spots: [
                  for (final p in series)
                    FlSpot(p.dayIndex.toDouble(), p.revenueOutpatient / 1000),
                ],
                isCurved: true,
                color: CmdCommandMetrics.iconTeal,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: CmdCommandMetrics.iconTeal.withValues(alpha: 0.14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return CmdPanelCard(
      title: 'Revenue this week',
      icon: Icons.show_chart_rounded,
      accent: CmdCommandMetrics.iconBlue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _LegendDot(color: CmdCommandMetrics.iconBlue, label: 'Inpatient'),
              const SizedBox(width: 12),
              _LegendDot(
                color: CmdCommandMetrics.iconTeal,
                label: 'Outpatient',
              ),
            ],
          ),
          const SizedBox(height: 8),
          chart,
        ],
      ),
    );
  }
}

class CmdCapacityPanel extends StatelessWidget {
  const CmdCapacityPanel({super.key, required this.capacity});

  final CmdCapacitySnapshot capacity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avail = capacity.totalBeds - capacity.occupiedBeds;
    final hasMix =
        capacity.generalWardPercent +
            capacity.icuPercent +
            capacity.maternityPercent >
        0;

    Widget pieFor({required bool compact}) {
      if (!hasMix) {
        return SizedBox(
          height: compact ? 140 : 180,
          child: Center(
            child: Text(
              '—',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        );
      }
      return SizedBox(
        height: compact ? 140 : 180,
        child: Stack(
          alignment: Alignment.center,
          children: [
            PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: compact ? 36 : 46,
                sections: [
                  PieChartSectionData(
                    color: CmdCommandMetrics.iconBlue,
                    value: capacity.generalWardPercent,
                    title: '',
                    radius: 18,
                  ),
                  PieChartSectionData(
                    color: CmdCommandMetrics.iconPink,
                    value: capacity.icuPercent,
                    title: '',
                    radius: 22,
                  ),
                  PieChartSectionData(
                    color: CmdCommandMetrics.iconPurple,
                    value: capacity.maternityPercent,
                    title: '',
                    radius: 18,
                  ),
                ],
              ),
            ),
            Text(
              '${capacity.occupancyPercent.toStringAsFixed(0)}%\nocc.',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      );
    }

    final legend = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CapacityRow(title: 'Total beds', value: '${capacity.totalBeds}'),
        const SizedBox(height: 8),
        _CapacityRow(title: 'Available', value: '$avail'),
        const SizedBox(height: 8),
        _CapacityRow(
          title: 'ICU load',
          value: '${capacity.icuLoadPercent.toStringAsFixed(0)}%',
          color: CmdCommandMetrics.iconPink,
        ),
        const SizedBox(height: 8),
        _CapacityRow(
          title: 'ER load',
          value: CmdCommandMetrics.displayValue(capacity.erLoadLabel),
          color: CmdCommandMetrics.waitAmber,
        ),
      ],
    );

    return CmdPanelCard(
      title: 'Capacity',
      icon: Icons.pie_chart_outline_rounded,
      accent: CmdCommandMetrics.iconTeal,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stackLegend = constraints.maxWidth < 360;
          final pie = pieFor(compact: stackLegend);
          if (stackLegend) {
            return Column(children: [pie, const SizedBox(height: 8), legend]);
          }
          return Row(
            children: [
              Expanded(child: pie),
              const SizedBox(width: 8),
              Expanded(child: legend),
            ],
          );
        },
      ),
    );
  }
}

class CmdClinicalPerformancePanel extends StatelessWidget {
  const CmdClinicalPerformancePanel({super.key, required this.clinical});

  final CmdClinicalPerformance clinical;

  @override
  Widget build(BuildContext context) {
    return CmdPanelCard(
      title: 'Clinical performance',
      icon: Icons.favorite_outline_rounded,
      accent: CmdCommandMetrics.iconPink,
      child: Column(
        children: [
          _PerformanceRow(
            label: 'Surgery success',
            percentage: clinical.surgerySuccessRate,
          ),
          const SizedBox(height: 10),
          _PerformanceRow(
            label: 'Readmission (30d)',
            percentage: clinical.readmission30d,
            isReversed: true,
          ),
          const SizedBox(height: 10),
          _PerformanceRow(
            label: 'Infection rate',
            percentage: clinical.infectionRate,
            isReversed: true,
          ),
          const SizedBox(height: 10),
          _PerformanceRow(
            label: 'Patient satisfaction',
            percentage: clinical.patientSatisfaction,
          ),
        ],
      ),
    );
  }
}

class CmdStaffOverviewPanel extends StatelessWidget {
  const CmdStaffOverviewPanel({super.key, required this.staff});

  final CmdStaffDutySnapshot staff;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CmdPanelCard(
      title: 'Staff on duty',
      icon: Icons.groups_2_rounded,
      accent: CmdCommandMetrics.iconIndigo,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.medical_services_outlined,
                  accent: CmdCommandMetrics.iconBlue,
                  value: '${staff.doctorsOnDuty}',
                  label: 'Doctors',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  icon: Icons.local_hospital_outlined,
                  accent: CmdCommandMetrics.iconTeal,
                  value: '${staff.nursesOnDuty}',
                  label: 'Nurses',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _KeyValueRow(
            label: 'Absenteeism',
            value: '${staff.absenteeismPercent.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 8),
          _KeyValueRow(
            label: 'Overtime (week)',
            value: '${staff.overtimeHoursWeek} hrs',
            valueStyle: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class CmdPharmacyPanel extends StatelessWidget {
  const CmdPharmacyPanel({super.key, required this.pharmacy});

  final CmdPharmacySnapshot pharmacy;

  @override
  Widget build(BuildContext context) {
    final top = pharmacy.topDispensed
        .where((e) => e.trim().isNotEmpty)
        .toList();
    return CmdPanelCard(
      title: 'Pharmacy snapshot',
      icon: Icons.medication_liquid_rounded,
      accent: CmdCommandMetrics.waitAmber,
      child: Column(
        children: [
          _IconMetricRow(
            icon: Icons.warning_amber_rounded,
            accent: CmdCommandMetrics.waitRed,
            label: 'Low stock',
            value: '${pharmacy.lowStockCount} items',
          ),
          const SizedBox(height: 8),
          _IconMetricRow(
            icon: Icons.event_outlined,
            accent: CmdCommandMetrics.waitAmber,
            label: 'Expiring in 30 days',
            value: '${pharmacy.expiringBatches} batches',
          ),
          const SizedBox(height: 8),
          _IconMetricRow(
            icon: Icons.trending_up_rounded,
            accent: CmdCommandMetrics.iconTeal,
            label: 'Top dispensed',
            value: top.isEmpty ? '—' : top.join(', '),
          ),
        ],
      ),
    );
  }
}

class CmdLabPanel extends StatelessWidget {
  const CmdLabPanel({super.key, required this.lab});

  final CmdLabSnapshot lab;

  @override
  Widget build(BuildContext context) {
    return CmdPanelCard(
      title: 'Lab & diagnostics',
      icon: Icons.biotech_rounded,
      accent: CmdCommandMetrics.iconPurple,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.science_outlined,
                  accent: CmdCommandMetrics.iconBlue,
                  value: '${lab.testsToday}',
                  label: 'Tests today',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  icon: Icons.hourglass_empty_outlined,
                  accent: CmdCommandMetrics.waitAmber,
                  value: '${lab.pendingCount}',
                  label: 'Pending',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MiniStat(
                  icon: Icons.timer_outlined,
                  accent: CmdCommandMetrics.iconTeal,
                  value: '${lab.avgTurnaroundHours.toStringAsFixed(1)}h',
                  label: 'Avg TAT',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _KeyValueRow(
            label: 'Machine uptime',
            value: '${lab.machineUptimePercent.toStringAsFixed(1)}%',
          ),
          const SizedBox(height: 8),
          _KeyValueRow(
            label: 'Repeated tests',
            value: '${lab.redoRatePercent.toStringAsFixed(1)}%',
          ),
        ],
      ),
    );
  }
}

class CmdCommandOverviewGrid extends StatelessWidget {
  const CmdCommandOverviewGrid({
    super.key,
    required this.bundle,
    required this.compact,
  });

  final CmdExecutiveDashboardBundle bundle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final gap = compact ? 10.0 : 12.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ResponsiveRowColumn(
          gap: gap,
          stackWhenWidthBelow: CmdCommandMetrics.cardBreakpoint,
          stackFill: false,
          first: CmdFinancialOverviewPanel(bundle: bundle),
          second: CmdCapacityPanel(capacity: bundle.capacity),
        ),
        SizedBox(height: gap),
        ResponsiveRowColumn(
          gap: gap,
          stackWhenWidthBelow: CmdCommandMetrics.cardBreakpoint,
          stackFill: false,
          first: CmdClinicalPerformancePanel(clinical: bundle.clinical),
          second: CmdStaffOverviewPanel(staff: bundle.staff),
        ),
        SizedBox(height: gap),
        ResponsiveRowColumn(
          gap: gap,
          stackWhenWidthBelow: CmdCommandMetrics.cardBreakpoint,
          stackFill: false,
          first: CmdPharmacyPanel(pharmacy: bundle.pharmacy),
          second: CmdLabPanel(lab: bundle.lab),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _CapacityRow extends StatelessWidget {
  const _CapacityRow({required this.title, required this.value, this.color});

  final String title;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color ?? theme.colorScheme.onSurfaceVariant,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: HeltyEllipsisText(
            text: title,
            style: theme.textTheme.bodySmall,
          ),
        ),
        HeltyEllipsisText(
          text: value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({
    required this.label,
    required this.percentage,
    this.isReversed = false,
  });

  final String label;
  final double percentage;
  final bool isReversed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ok = isReversed ? percentage <= 0.1 : percentage > 0.8;
    final color = ok
        ? CmdCommandMetrics.waitGreen
        : CmdCommandMetrics.waitAmber;
    final v = percentage.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: HeltyEllipsisText(
                text: label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${(percentage * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 8,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.85),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: v,
                    child: ColoredBox(color: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.accent,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color accent;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeltySolidIcon(
            icon: icon,
            color: accent,
            size: 24,
            iconSize: 13,
            radius: 6,
          ),
          const SizedBox(height: 8),
          HeltyEllipsisText(
            text: value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          HeltyEllipsisText(
            text: label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({
    required this.label,
    required this.value,
    this.valueStyle,
  });

  final String label;
  final String value;
  final TextStyle? valueStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: HeltyEllipsisText(
            text: label,
            style: theme.textTheme.bodySmall,
          ),
        ),
        HeltyEllipsisText(
          text: value,
          style:
              valueStyle ??
              theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: CmdCommandMetrics.iconTeal,
              ),
        ),
      ],
    );
  }
}

class _IconMetricRow extends StatelessWidget {
  const _IconMetricRow({
    required this.icon,
    required this.accent,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color accent;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        HeltySolidIcon(
          icon: icon,
          color: accent,
          size: 26,
          iconSize: 14,
          radius: 7,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: HeltyEllipsisText(
            text: label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: HeltyEllipsisText(
            text: value,
            align: TextAlign.end,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
