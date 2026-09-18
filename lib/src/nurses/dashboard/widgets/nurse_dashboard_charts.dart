import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../helper/theme.dart';
import '../../../models/nurse_dashboard_models.dart';
import '../../../widgets/helty_surface.dart';
import '../nurse_dashboard_metrics.dart';

/// Admissions vs discharges and department load charts.
class NurseDashboardCharts extends StatelessWidget {
  const NurseDashboardCharts({
    super.key,
    required this.overview,
    required this.timeRange,
  });

  final NurseDashboardOverview overview;
  final String timeRange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 5,
          child: _AdmissionsChart(
            series: NurseDashboardMetrics.admissionsSeriesForChart(
              timeRange: timeRange,
              series: overview.admissionsDischargesSeries,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          flex: 4,
          child: _DepartmentLoadChart(bundle: overview.departmentLoad),
        ),
      ],
    );
  }
}

class _AdmissionsChart extends StatelessWidget {
  const _AdmissionsChart({required this.series});

  final NurseAdmissionsDischargesSeries series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final points = series.points;

    return HeltySurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HeltySolidIcon(
                icon: Icons.show_chart,
                color: NurseDashboardMetrics.iconBlue,
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: HeltyEllipsisText(
                  text: 'Admissions vs Discharges',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _LegendDot(color: cs.primary, label: 'Admissions'),
                    const SizedBox(width: 10),
                    const _LegendDot(
                      color: NurseDashboardMetrics.waitAmber,
                      label: 'Discharges',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: points.isEmpty
                ? Center(
                    child: Text(
                      'No admissions or discharge data for this period',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                : _LineChart(points: points, meta: series.meta),
          ),
        ],
      ),
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
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LineChart extends StatelessWidget {
  const _LineChart({required this.points, this.meta});

  final List<NurseAdmissionDischargePoint> points;
  final NurseSeriesMeta? meta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final maxY = NurseDashboardMetrics.lineChartMaxY(points, meta);
    final interval = NurseDashboardMetrics.niceInterval(maxY);
    final maxX = (points.length - 1).toDouble();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: cs.outline.withValues(alpha: 0.1), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, titleMeta) {
                final i = value.round();
                if (i < 0 || i >= points.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: titleMeta,
                  child: Text(
                    points[i].label,
                    style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: interval,
              reservedSize: 32,
              getTitlesWidget: (value, titleMeta) {
                if (value == 0 && maxY > 0) return const SizedBox.shrink();
                if (value > maxY) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()}',
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 10),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: maxX < 0 ? 0 : maxX,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].admissions),
            ],
            isCurved: true,
            color: cs.primary,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: cs.primary.withValues(alpha: 0.1),
            ),
          ),
          LineChartBarData(
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i].discharges),
            ],
            isCurved: true,
            color: NurseDashboardMetrics.waitAmber,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}

class _DepartmentLoadChart extends StatelessWidget {
  const _DepartmentLoadChart({required this.bundle});

  final NurseDepartmentLoadBundle bundle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final bars = bundle.bars;
    final chartMax = bundle.chartMax > 0 ? bundle.chartMax : 100.0;

    return HeltySurfaceCard(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const HeltySolidIcon(
                icon: Icons.bar_chart,
                color: NurseDashboardMetrics.iconTeal,
                size: 26,
                iconSize: 14,
                radius: 7,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: HeltyEllipsisText(
                  text: 'Department Load',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: bars.isEmpty
                ? Center(
                    child: Text(
                      'No department load data',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMax,
                      barTouchData: BarTouchData(enabled: false),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= bars.length) {
                                return const SizedBox.shrink();
                              }
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  bars[i].shortLabel,
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: const FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        for (var i = 0; i < bars.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: bars[i].load.clamp(0, chartMax),
                                color:
                                    NurseDashboardMetrics.barPalette[i %
                                        NurseDashboardMetrics
                                            .barPalette
                                            .length],
                                width: 18,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(AppTheme.radiusSm),
                                ),
                                backDrawRodData: BackgroundBarChartRodData(
                                  show: true,
                                  toY: chartMax,
                                  color: NurseDashboardMetrics
                                      .barPalette[i %
                                          NurseDashboardMetrics
                                              .barPalette
                                              .length]
                                      .withValues(alpha: 0.12),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
