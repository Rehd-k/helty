import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../cmac_palette.dart';
import '../models/cmac_analytics_models.dart';
import 'cmac_kpi_card.dart';

class CmacSectionHeader extends StatelessWidget {
  const CmacSectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.accent,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [accent, accent.withValues(alpha: 0.6)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class CmacBarChartCard extends StatelessWidget {
  const CmacBarChartCard({
    super.key,
    required this.title,
    required this.points,
    this.horizontal = false,
    this.height = 220,
  });

  final String title;
  final List<CmacNamedValue> points;
  final bool horizontal;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return CmacEmptyHint(message: 'No data for $title.');
    }
    final theme = Theme.of(context);
    final maxV = points.map((e) => e.value.toDouble()).fold<double>(
          0,
          (a, b) => a > b ? a : b,
        );
    final maxY = maxV <= 0 ? 1.0 : maxV * 1.15;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            horizontal
                ? _RankedBarList(points: points, max: maxY)
                : SizedBox(
                    height: height,
                    child: _VerticalBars(points: points, maxY: maxY),
                  ),
          ],
        ),
      ),
    );
  }
}

class _VerticalBars extends StatelessWidget {
  const _VerticalBars({required this.points, required this.maxY});

  final List<CmacNamedValue> points;
  final double maxY;

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 36)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= points.length) return const SizedBox.shrink();
                final label = points[i].label;
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    label.length > 8 ? '${label.substring(0, 8)}…' : label,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
        ),
        barGroups: [
          for (var i = 0; i < points.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].value.toDouble(),
                  width: 14,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      CmacPalette.chartColors[i % CmacPalette.chartColors.length]
                          .withValues(alpha: 0.7),
                      CmacPalette.chartColors[i % CmacPalette.chartColors.length],
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RankedBarList extends StatelessWidget {
  const _RankedBarList({required this.points, required this.max});

  final List<CmacNamedValue> points;
  final double max;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < points.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        points[i].label,
                        style: theme.textTheme.labelMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      points[i].value.toString(),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: (points[i].value.toDouble() / max).clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    color: CmacPalette.chartColors[i % CmacPalette.chartColors.length],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class CmacLineChartCard extends StatelessWidget {
  const CmacLineChartCard({
    super.key,
    required this.title,
    required this.series,
    this.secondSeries,
    this.secondLabel,
    this.height = 220,
  });

  final String title;
  final List<CmacSeriesPoint> series;
  final List<CmacSeriesPoint>? secondSeries;
  final String? secondLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (series.isEmpty && (secondSeries == null || secondSeries!.isEmpty)) {
      return CmacEmptyHint(message: 'No data for $title.');
    }
    final all = [...series, ...?secondSeries];
    final maxV = all.map((e) => e.value.toDouble()).fold<double>(
          0,
          (a, b) => a > b ? a : b,
        );
    final maxY = maxV <= 0 ? 1.0 : maxV * 1.15;

    LineChartBarData line(List<CmacSeriesPoint> pts, Color color) {
      return LineChartBarData(
        spots: [
          for (var i = 0; i < pts.length; i++)
            FlSpot(i.toDouble(), pts[i].value.toDouble()),
        ],
        isCurved: true,
        color: color,
        barWidth: 3,
        dotData: const FlDotData(show: true),
        belowBarData: BarAreaData(
          show: true,
          color: color.withValues(alpha: 0.15),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (secondLabel != null)
              Text(
                secondLabel!,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            const SizedBox(height: 12),
            SizedBox(
              height: height,
              child: LineChart(
                LineChartData(
                  maxY: maxY,
                  gridData: const FlGridData(show: true),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= series.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            series[i].label,
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    if (series.isNotEmpty)
                      line(series, CmacPalette.chartColors[0]),
                    if (secondSeries != null && secondSeries!.isNotEmpty)
                      line(secondSeries!, CmacPalette.chartColors[2]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CmacDonutChartCard extends StatelessWidget {
  const CmacDonutChartCard({
    super.key,
    required this.title,
    required this.slices,
    this.height = 220,
  });

  final String title;
  final List<CmacNamedValue> slices;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) {
      return CmacEmptyHint(message: 'No data for $title.');
    }
    final total = slices.fold<num>(0, (a, b) => a + b.value);
    if (total == 0) {
      return CmacEmptyHint(message: 'No data for $title.');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: height,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          for (var i = 0; i < slices.length; i++)
                            PieChartSectionData(
                              value: slices[i].value.toDouble(),
                              color: CmacPalette.chartColors[
                                  i % CmacPalette.chartColors.length],
                              title:
                                  '${(100 * slices[i].value / total).toStringAsFixed(0)}%',
                              radius: 52,
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < slices.length; i++)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: CmacPalette.chartColors[
                                        i % CmacPalette.chartColors.length],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    slices[i].label,
                                    style: const TextStyle(fontSize: 11),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
