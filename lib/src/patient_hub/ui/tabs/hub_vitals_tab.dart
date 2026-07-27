import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:helty/src/widgets/empty.widget.dart';

import '../../models/patient_hub_models.dart';
import '../../../patient_chart/models/patient_chart_models.dart';
import '../../providers/patient_hub_providers.dart';
import '../../utils/hub_chart_helpers.dart';
import '../../widgets/hub_empty_state.dart';
import '../../widgets/hub_section_scaffold.dart';
import '../../widgets/patient_hub_scope.dart';

enum _VitalsMetric { temperature, pulse, spo2, respRate, bpSys, bpDia }

@RoutePage()
class HubVitalsScreen extends ConsumerStatefulWidget {
  const HubVitalsScreen({super.key});

  @override
  ConsumerState<HubVitalsScreen> createState() => _HubVitalsScreenState();
}

class _HubVitalsScreenState extends ConsumerState<HubVitalsScreen> {
  _VitalsMetric _metric = _VitalsMetric.temperature;
  HubSortOrder _sort = HubSortOrder.newestFirst;

  @override
  Widget build(BuildContext context) {
    final patientUuid = PatientHubScope.requirePatientUuid(context);
    final range = ref.watch(patientHubDateRangeProvider);
    final sectionAsync = ref.watch(
      patientHubSectionProvider(
        HubSectionRequest(
          patientUuid: patientUuid,
          includeKeys: const [PatientChartSectionKeys.vitals],
          limit: patientHubMaxTake,
          fromDate: range.from,
          toDate: range.to,
        ),
      ),
    );

    return sectionAsync.when(
      loading: () => const HubSectionScaffold(loading: true, child: SizedBox()),
      error: (e, _) => HubSectionScaffold(
        error: '$e',
        onRetry: () => ref.invalidate(patientHubSectionProvider),
        child: const SizedBox(),
      ),
      data: (response) {
        var vitals = response.section(PatientChartSectionKeys.vitals);
        vitals = hubFilterByDateRange(vitals, range);
        vitals = hubSortRows(vitals, _sort);

        if (vitals.isEmpty) {
          return const HubEmptyState(
            title: 'No vitals recorded',
            icon: Icons.monitor_heart_outlined,
          );
        }

        return ResponsiveBody(
          builder: (context, bp) => HubSectionScaffold(
          filterRow: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _VitalsMetric.values
                  .map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                        label: Text(_metricLabel(m)),
                        selected: _metric == m,
                        onSelected: (_) => setState(() => _metric = m),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          sortDropdown: DropdownButton<HubSortOrder>(
            value: _sort,
            items: const [
              DropdownMenuItem(
                value: HubSortOrder.newestFirst,
                child: Text('Newest'),
              ),
              DropdownMenuItem(
                value: HubSortOrder.oldestFirst,
                child: Text('Oldest'),
              ),
            ],
            onChanged: (v) {
              if (v != null) setState(() => _sort = v);
            },
          ),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              SizedBox(
                height: 220,
                child: _VitalsChart(vitals: vitals, metric: _metric),
              ),
              const SizedBox(height: 16),
              ...vitals.map(
                (v) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      hubFormatDate(v['recordedAt'] ?? v['createdAt']) ??
                          'Vitals',
                    ),
                    subtitle: Text(_vitalsSummary(v)),
                  ),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  String _metricLabel(_VitalsMetric m) => switch (m) {
        _VitalsMetric.temperature => 'Temp',
        _VitalsMetric.pulse => 'Pulse',
        _VitalsMetric.spo2 => 'SpO₂',
        _VitalsMetric.respRate => 'RR',
        _VitalsMetric.bpSys => 'BP Sys',
        _VitalsMetric.bpDia => 'BP Dia',
      };

  String _vitalsSummary(Map<String, dynamic> v) {
    final parts = <String>[];
    void add(String label, dynamic val) {
      if (val != null) parts.add('$label: $val');
    }
    add('T', v['temperature']);
    add('P', v['pulse']);
    add('SpO₂', v['spo2'] ?? v['spO2']);
    add('RR', v['respiratoryRate'] ?? v['respRate']);
    add('BP', v['bloodPressure'] ?? '${v['systolic']}/${v['diastolic']}');
    return parts.join(' · ');
  }
}

class _VitalsChart extends StatelessWidget {
  const _VitalsChart({required this.vitals, required this.metric});

  final List<Map<String, dynamic>> vitals;
  final _VitalsMetric metric;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final points = <FlSpot>[];
    final chronological = hubSortRows(vitals, HubSortOrder.oldestFirst);
    for (var i = 0; i < chronological.length; i++) {
      final v = _valueFor(chronological[i]);
      if (v != null) points.add(FlSpot(i.toDouble(), v));
    }

    if (points.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.show_chart_outlined,
        title: 'No data for this metric',
        message: 'Try another vital sign or widen the date range.',
      );
    }

    final minY = points.map((p) => p.y).reduce(math.min);
    final maxY = points.map((p) => p.y).reduce(math.max);
    final pad = (maxY - minY).abs() < 1 ? 1.0 : (maxY - minY) * 0.1;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: LineChart(
          LineChartData(
            minY: minY - pad,
            maxY: maxY + pad,
            gridData: const FlGridData(show: true),
            titlesData: const FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 36),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: points,
                isCurved: true,
                color: cs.primary,
                barWidth: 3,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: cs.primary.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double? _valueFor(Map<String, dynamic> v) {
    return switch (metric) {
      _VitalsMetric.temperature => hubParseDouble(v['temperature']),
      _VitalsMetric.pulse => hubParseDouble(v['pulse']),
      _VitalsMetric.spo2 => hubParseDouble(v['spo2'] ?? v['spO2']),
      _VitalsMetric.respRate =>
        hubParseDouble(v['respiratoryRate'] ?? v['respRate']),
      _VitalsMetric.bpSys => hubParseDouble(v['systolic']),
      _VitalsMetric.bpDia => hubParseDouble(v['diastolic']),
    };
  }
}
