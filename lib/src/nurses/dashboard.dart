import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../cmd/cmd_breakpoints.dart';
import '../models/nurse_dashboard_models.dart';
import '../services/nurse_dashboard_service.dart';

@RoutePage()
class NursesDashboardScreen extends StatefulWidget {
  const NursesDashboardScreen({super.key});

  @override
  State<NursesDashboardScreen> createState() => _NursesDashboardScreenState();
}

class _NursesDashboardScreenState extends State<NursesDashboardScreen> {
  static const _timeRanges = [
    'Today',
    'Last 7 Days',
    'This Month',
    'This Year',
  ];

  final NurseDashboardService _service = NurseDashboardService();

  String _timeRange = 'Today';
  NurseDashboardOverview? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overview = await _service.getOverview(timeRange: _timeRange);
      if (!mounted) return;
      setState(() {
        _data = overview;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(_error!)));
    }
  }

  String _resolvedSubtitle(NurseDashboardHeader h) {
    if (h.subtitle != null && h.subtitle!.trim().isNotEmpty) {
      return h.subtitle!;
    }
    final template =
        h.subtitleTemplate ??
        "Welcome back, {name}. Here's what's happening today.";
    final name = h.userDisplayName.trim().isNotEmpty
        ? h.userDisplayName.trim()
        : 'there';
    return template.replaceAll('{name}', name);
  }

  Color _statusToneColor(String? tone, ColorScheme scheme) {
    switch ((tone ?? 'neutral').toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'danger':
        return Colors.red;
      case 'busy':
        return scheme.primary;
      case 'break':
        return Colors.orange;
      case 'neutral':
      default:
        return scheme.onSurface.withValues(alpha: 0.6);
    }
  }

  Color _alertAccent(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'error':
        return Colors.red;
      case 'warning':
      default:
        return Colors.orange;
    }
  }

  double _lineChartMaxY(
    List<NurseAdmissionDischargePoint> points,
    NurseSeriesMeta? meta,
  ) {
    if (points.isEmpty) return 100;
    if (meta?.yAxisSuggested == true && meta?.yAxisMax != null) {
      return meta!.yAxisMax! > 0 ? meta.yAxisMax! : 100;
    }
    if (meta?.yAxisMax != null && meta!.yAxisMax! > 0) {
      return meta.yAxisMax!;
    }
    var maxV = 0.0;
    for (final p in points) {
      maxV = math.max(maxV, p.admissions);
      maxV = math.max(maxV, p.discharges);
    }
    if (maxV <= 0) return 100;
    return (maxV * 1.15).ceilToDouble().clamp(1, double.infinity);
  }

  /// When [timeRange] is Today, combine hourly (or sub-day) points into 4-hour buckets
  /// (00–04, 04–08, …) so the x-axis shows 00:00, 04:00, 08:00, … instead of hourly ticks.
  NurseAdmissionsDischargesSeries _admissionsSeriesForChart(
    NurseDashboardOverview overview,
  ) {
    final series = overview.admissionsDischargesSeries;
    if (_timeRange != 'Today') return series;

    final aggregated = _aggregateAdmissionsToFourHourBuckets(series.points);
    if (aggregated == null) return series;

    return NurseAdmissionsDischargesSeries(points: aggregated, meta: null);
  }

  /// Returns `null` if the series should be shown as-is (already bucketed or unknown shape).
  List<NurseAdmissionDischargePoint>? _aggregateAdmissionsToFourHourBuckets(
    List<NurseAdmissionDischargePoint> points,
  ) {
    if (points.length < 4) return null;

    final parsedHours = [
      for (final p in points) _tryParseHourFromLabel(p.label),
    ];
    final allHoursKnown = parsedHours.every((h) => h != null);

    if (allHoursKnown) {
      final admissions = List<double>.filled(6, 0);
      final discharges = List<double>.filled(6, 0);
      for (var i = 0; i < points.length; i++) {
        final h = parsedHours[i]!;
        final b = (h ~/ 4).clamp(0, 5);
        admissions[b] += points[i].admissions;
        discharges[b] += points[i].discharges;
      }
      return [
        for (var b = 0; b < 6; b++)
          NurseAdmissionDischargePoint(
            label: _fourHourBucketLabel(b),
            admissions: admissions[b],
            discharges: discharges[b],
          ),
      ];
    }

    // Assume points are consecutive hours starting at midnight (e.g. 24 hourly samples).
    if (points.length % 4 != 0) return null;

    final out = <NurseAdmissionDischargePoint>[];
    for (var start = 0; start < points.length; start += 4) {
      var a = 0.0;
      var d = 0.0;
      for (var i = start; i < start + 4; i++) {
        a += points[i].admissions;
        d += points[i].discharges;
      }
      out.add(
        NurseAdmissionDischargePoint(
          label: _fourHourBucketLabel(start ~/ 4),
          admissions: a,
          discharges: d,
        ),
      );
    }
    return out;
  }

  static final RegExp _label24h = RegExp(r'^(\d{1,2})(?::(\d{2}))?$');
  static final RegExp _label12h = RegExp(
    r'^(\d{1,2})(?::(\d{2}))?\s*(AM|PM)$',
    caseSensitive: false,
  );

  /// Parses hour 0–23 from common dashboard labels; returns null if unknown.
  int? _tryParseHourFromLabel(String label) {
    final s = label.trim();
    if (s.isEmpty) return null;

    final m24 = _label24h.firstMatch(s);
    if (m24 != null) {
      final h = int.tryParse(m24.group(1)!);
      final min = int.tryParse(m24.group(2) ?? '0') ?? 0;
      if (h != null && h >= 0 && h <= 23 && min >= 0 && min < 60) return h;
    }

    final m12 = _label12h.firstMatch(s);
    if (m12 != null) {
      var h = int.tryParse(m12.group(1)!);
      if (h == null) return null;
      final isPm = (m12.group(3)!.toUpperCase() == 'PM');
      if (h == 12) {
        h = isPm ? 12 : 0;
      } else if (isPm) {
        h += 12;
      }
      if (h >= 0 && h <= 23) return h;
    }

    if (RegExp(r'^\d{1,2}$').hasMatch(s)) {
      final h = int.tryParse(s);
      if (h != null && h >= 0 && h <= 23) return h;
    }

    return null;
  }

  String _fourHourBucketLabel(int bucketIndex) {
    final h = bucketIndex * 4;
    return '${h.toString().padLeft(2, '0')}:00';
  }

  double _niceInterval(double maxY) {
    if (maxY <= 0) return 20;
    final rough = maxY / 4;
    final exp = (math.log(rough) / math.ln10).floor();
    final frac = rough / math.pow(10, exp);
    double niceFrac;
    if (frac <= 1) {
      niceFrac = 1;
    } else if (frac <= 2) {
      niceFrac = 2;
    } else if (frac <= 5) {
      niceFrac = 5;
    } else {
      niceFrac = 10;
    }
    return niceFrac * math.pow(10, exp).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_loading && _data == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      );
    }

    final data = _data;
    if (data == null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'No dashboard data', textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final kpis = data.kpis;
    final header = data.header;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bp = CmdBreakpoints.fromWidth(constraints.maxWidth);
                final admitH = bp.isMobile
                    ? 280.0
                    : bp.isTablet
                    ? 340.0
                    : 400.0;
                final deptH = bp.isMobile
                    ? 230.0
                    : bp.isTablet
                    ? 270.0
                    : 300.0;
                final chartPad = bp.isMobile ? 16.0 : 24.0;
                final pad = EdgeInsets.symmetric(
                  horizontal: bp.paddingH,
                  vertical: bp.paddingV,
                );

                return SingleChildScrollView(
                  padding: pad,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: math.min(
                          constraints.maxWidth,
                          CmdBreakpoints.maxContentWidth,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _nurseDashboardHeader(
                            bp: bp,
                            header: header,
                            colorScheme: colorScheme,
                          ),
                          SizedBox(height: bp.isMobile ? 24 : 32),
                          _nurseKpiGrid(bp, kpis, colorScheme),
                          const SizedBox(height: 24),
                          _nurseChartsAndSidebar(
                            bp: bp,
                            data: data,
                            colorScheme: colorScheme,
                            admissionsHeight: admitH,
                            departmentHeight: deptH,
                            chartInnerPadding: chartPad,
                            stackChartTitleRow: !bp.isDesktop,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeRangeDropdown(ColorScheme colorScheme) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: _timeRange,
          icon: Icon(
            Icons.calendar_today,
            size: 16,
            color: colorScheme.primary,
          ),
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          items: _timeRanges
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(e),
                  ),
                ),
              )
              .toList(),
          onChanged: (val) {
            if (val == null) return;
            setState(() => _timeRange = val);
            _load();
          },
        ),
      ),
    );
  }

  Widget _nurseDashboardHeader({
    required CmdBreakpoints bp,
    required NurseDashboardHeader header,
    required ColorScheme colorScheme,
  }) {
    final titleStyle = TextStyle(
      fontSize: bp.isMobile ? 20 : 24,
      fontWeight: FontWeight.bold,
      color: colorScheme.onSurface,
    );
    final subtitleStyle = TextStyle(
      fontSize: bp.isMobile ? 13 : 14,
      color: colorScheme.onSurface.withValues(alpha: 0.6),
    );
    final timeDropdown = _timeRangeDropdown(colorScheme);
    final avatar = CircleAvatar(
      radius: 20,
      backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
      child: Icon(Icons.person, color: colorScheme.primary),
    );

    if (bp.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(header.title ?? 'Hospital Overview', style: titleStyle),
          const SizedBox(height: 4),
          Text(_resolvedSubtitle(header), style: subtitleStyle),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: timeDropdown),
              const SizedBox(width: 12),
              avatar,
            ],
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(header.title ?? 'Hospital Overview', style: titleStyle),
              const SizedBox(height: 4),
              Text(_resolvedSubtitle(header), style: subtitleStyle),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 160, maxWidth: 240),
              child: timeDropdown,
            ),
            const SizedBox(width: 16),
            avatar,
          ],
        ),
      ],
    );
  }

  int _nurseKpiCrossAxisCount(CmdBreakpoints bp) => bp.isDesktop ? 4 : 2;

  double _nurseKpiChildAspectRatio(CmdBreakpoints bp) {
    if (bp.isDesktop) return 1.65;
    if (bp.isTablet) return 1.48;
    return bp.maxWidth < 360 ? 1.2 : 1.36;
  }

  Widget _nurseKpiGrid(
    CmdBreakpoints bp,
    NurseDashboardKpis kpis,
    ColorScheme colorScheme,
  ) {
    return GridView.count(
      crossAxisCount: _nurseKpiCrossAxisCount(bp),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: _nurseKpiChildAspectRatio(bp),
      children: [
        _buildMetricCard(
          'Total Patients',
          kpis.totalPatients.valueFormatted,
          kpis.totalPatients.delta.label,
          Icons.people_alt,
          Colors.blue,
          colorScheme,
          trendPositive: kpis.totalPatients.delta.isPositive,
          trendDirection: kpis.totalPatients.delta.direction,
          showTrendArrow: kpis.totalPatients.delta.kind != 'text',
        ),
        _buildMetricCard(
          'Bed Occupancy',
          kpis.bedOccupancy.valueFormatted,
          kpis.bedOccupancy.delta.label,
          Icons.bed,
          Colors.orange,
          colorScheme,
          isProgress: true,
          progressValue: kpis.bedOccupancy.ratio.clamp(0.0, 1.0),
          trendPositive: kpis.bedOccupancy.delta.isPositive,
          trendDirection: kpis.bedOccupancy.delta.direction,
          showTrendArrow: kpis.bedOccupancy.delta.kind != 'text',
        ),
        _buildMetricCard(
          'Active Staff',
          kpis.activeStaff.valueFormatted,
          kpis.activeStaff.delta.label,
          Icons.medical_information,
          Colors.green,
          colorScheme,
          trendPositive: kpis.activeStaff.delta.isPositive,
          trendDirection: kpis.activeStaff.delta.direction,
          showTrendArrow: kpis.activeStaff.delta.kind != 'text',
        ),
        _buildMetricCard(
          'Avg. Wait Time',
          kpis.averageWaitTime.valueFormatted,
          kpis.averageWaitTime.delta.label,
          Icons.timer,
          Colors.purple,
          colorScheme,
          trendPositive: kpis.averageWaitTime.delta.isPositive,
          trendDirection: kpis.averageWaitTime.delta.direction,
          showTrendArrow: kpis.averageWaitTime.delta.kind != 'text',
        ),
      ],
    );
  }

  Widget _nurseChartsColumn({
    required NurseDashboardOverview data,
    required ColorScheme colorScheme,
    required double admissionsHeight,
    required double departmentHeight,
    required double chartInnerPadding,
    required bool stackChartTitleRow,
  }) {
    final titleRow = stackChartTitleRow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Patient Admissions vs Discharges',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildLegendIndicator(colorScheme.primary, 'Admissions'),
                  _buildLegendIndicator(Colors.orange, 'Discharges'),
                ],
              ),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Patient Admissions vs Discharges',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Row(
                children: [
                  _buildLegendIndicator(colorScheme.primary, 'Admissions'),
                  const SizedBox(width: 16),
                  _buildLegendIndicator(Colors.orange, 'Discharges'),
                ],
              ),
            ],
          );

    return Column(
      children: [
        Container(
          height: admissionsHeight,
          padding: EdgeInsets.all(chartInnerPadding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleRow,
              SizedBox(height: stackChartTitleRow ? 20 : 32),
              Expanded(
                child: _buildPatientInfluxChart(
                  colorScheme,
                  _admissionsSeriesForChart(data),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          height: departmentHeight,
          padding: EdgeInsets.all(chartInnerPadding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Department Load (Patients)',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              SizedBox(height: stackChartTitleRow ? 16 : 24),
              Expanded(
                child: _buildDepartmentBarChart(
                  colorScheme,
                  data.departmentLoad,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nurseSidebarColumn({
    required NurseDashboardOverview data,
    required ColorScheme colorScheme,
    required double chartInnerPadding,
  }) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(chartInnerPadding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Staff on Duty',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (data.staffOnDuty.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No staff on duty',
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                )
              else
                ...data.staffOnDuty.map(
                  (staff) => Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: _staffRow(staff, colorScheme),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.assignment_ind, size: 16),
                  label: const Text('Manage Roster'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(chartInnerPadding),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_rounded, color: Colors.red[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Critical Alerts',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (data.criticalAlerts.isEmpty)
                Text(
                  'No critical alerts',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red[700]?.withValues(alpha: 0.8),
                  ),
                )
              else
                ..._alertTiles(data.criticalAlerts),
            ],
          ),
        ),
      ],
    );
  }

  Widget _nurseChartsAndSidebar({
    required CmdBreakpoints bp,
    required NurseDashboardOverview data,
    required ColorScheme colorScheme,
    required double admissionsHeight,
    required double departmentHeight,
    required double chartInnerPadding,
    required bool stackChartTitleRow,
  }) {
    final charts = _nurseChartsColumn(
      data: data,
      colorScheme: colorScheme,
      admissionsHeight: admissionsHeight,
      departmentHeight: departmentHeight,
      chartInnerPadding: chartInnerPadding,
      stackChartTitleRow: stackChartTitleRow,
    );
    final aside = _nurseSidebarColumn(
      data: data,
      colorScheme: colorScheme,
      chartInnerPadding: chartInnerPadding,
    );

    if (bp.isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: charts),
          const SizedBox(width: 24),
          Expanded(flex: 2, child: aside),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        charts,
        SizedBox(height: bp.isMobile ? 20 : 24),
        aside,
      ],
    );
  }

  Widget _staffRow(NurseStaffOnDuty staff, ColorScheme colorScheme) {
    final toneColor = _statusToneColor(staff.statusTone, colorScheme);
    final nameTrim = staff.name.trim();
    final initial = nameTrim.isNotEmpty
        ? nameTrim.substring(0, 1).toUpperCase()
        : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
          child: Text(
            initial,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                staff.name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                staff.role,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: toneColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            staff.status,
            style: TextStyle(
              fontSize: 10,
              color: toneColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _alertTiles(List<NurseCriticalAlert> alerts) {
    final widgets = <Widget>[];
    for (var i = 0; i < alerts.length; i++) {
      final a = alerts[i];
      final accent = _alertAccent(a.severity);
      widgets.add(
        _buildAlertItem(
          a.location,
          a.message,
          a.relativeLabel ?? _formatAlertTime(a.occurredAt),
          accent,
        ),
      );
      if (i < alerts.length - 1) {
        widgets.add(const Divider(height: 24));
      }
    }
    return widgets;
  }

  String _formatAlertTime(DateTime t) {
    // Fallback when API omits relativeLabel
    return MaterialLocalizations.of(context).formatShortDate(t.toLocal());
  }

  IconData _trendArrowIcon({
    required bool trendPositive,
    String? trendDirection,
  }) {
    final d = trendDirection?.toLowerCase();
    if (d == 'up') return Icons.arrow_upward;
    if (d == 'down') return Icons.arrow_downward;
    return trendPositive ? Icons.arrow_upward : Icons.arrow_downward;
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String trendLabel,
    IconData icon,
    Color color,
    ColorScheme colorScheme, {
    bool isProgress = false,
    double progressValue = 0,
    bool trendPositive = true,
    String? trendDirection,
    bool showTrendArrow = true,
  }) {
    final trendColor = trendPositive ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (isProgress)
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CircularProgressIndicator(
                        value: progressValue,
                        backgroundColor: colorScheme.outline.withValues(
                          alpha: 0.1,
                        ),
                        color: color,
                        strokeWidth: 4,
                      ),
                      Center(
                        child: Text(
                          '${(progressValue * 100).round()}%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: trendColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      if (showTrendArrow)
                        Icon(
                          _trendArrowIcon(
                            trendPositive: trendPositive,
                            trendDirection: trendDirection,
                          ),
                          size: 12,
                          color: trendColor,
                        ),
                      if (showTrendArrow) const SizedBox(width: 4),
                      Text(
                        trendLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: trendColor,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 0),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildAlertItem(
    String location,
    String message,
    String time,
    Color color,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    location,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    time,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.red[700]?.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                message,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[700]?.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPatientInfluxChart(
    ColorScheme colorScheme,
    NurseAdmissionsDischargesSeries series,
  ) {
    final points = series.points;
    if (points.isEmpty) {
      return Center(
        child: Text(
          'No admissions or discharge data for this period',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      );
    }

    final maxY = _lineChartMaxY(points, series.meta);
    final interval = _niceInterval(maxY);
    final maxX = (points.length - 1).toDouble();

    final admissionSpots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].admissions),
    ];
    final dischargeSpots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].discharges),
    ];

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: colorScheme.outline.withValues(alpha: 0.1),
            strokeWidth: 1,
          ),
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
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final i = value.round();
                if (i < 0 || i >= points.length) {
                  return const SizedBox.shrink();
                }
                final label = points[i].label;
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 11),
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
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                if (value == 0 && maxY > 0) {
                  return const SizedBox.shrink();
                }
                if (value > maxY) return const SizedBox.shrink();
                return Text(
                  '${value.toInt()}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: maxX,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: admissionSpots,
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.1),
            ),
          ),
          LineChartBarData(
            spots: dischargeSpots,
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
          ),
        ],
      ),
    );
  }

  static const _barPalette = <Color>[
    Colors.blue,
    Colors.teal,
    Colors.red,
    Colors.deepOrange,
    Colors.purple,
    Colors.indigo,
    Colors.cyan,
  ];

  Widget _buildDepartmentBarChart(
    ColorScheme colorScheme,
    NurseDepartmentLoadBundle bundle,
  ) {
    final bars = bundle.bars;
    final chartMax = bundle.chartMax > 0 ? bundle.chartMax : 100.0;

    if (bars.isEmpty) {
      return Center(
        child: Text(
          'No department load data',
          style: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
        ),
      );
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: chartMax,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final i = value.toInt();
                if (i < 0 || i >= bars.length) {
                  return const SizedBox.shrink();
                }
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    bars[i].shortLabel,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
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
            _makeBarGroup(
              i,
              bars[i].load.clamp(0, chartMax),
              _barPalette[i % _barPalette.length],
              chartMax,
            ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(
    int x,
    double y,
    Color color,
    double chartMax,
  ) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: color,
          width: 22,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: chartMax,
            color: color.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }
}
