import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/nurse_dashboard_models.dart';
import '../../nursing/models/nursing_models.dart';
import '../../shared/department_colors.dart';

class NurseDashboardKpiItem {
  const NurseDashboardKpiItem({
    required this.label,
    required this.value,
    required this.caption,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final String caption;
  final IconData icon;
  final Color accent;
}

/// Accents, breakpoints, and helpers for the nursing dashboard chrome.
abstract final class NurseDashboardMetrics {
  static const cardBreakpoint = 768.0;
  static const sidebarBreakpoint = 1100.0;

  static const Color waitGreen = Color(0xFF16A34A);
  static const Color waitAmber = Color(0xFFEA580C);
  static const Color waitRed = Color(0xFFDC2626);
  static const Color iconBlue = Color(0xFF2563EB);
  static const Color iconTeal = Color(0xFF0D9488);
  static const Color iconPurple = Color(0xFF7C3AED);
  static const Color iconPink = Color(0xFFDB2777);
  static const Color iconIndigo = Color(0xFF4F46E5);

  static const timeRanges = ['Today', 'Last 7 Days', 'This Month', 'This Year'];

  static const barPalette = <Color>[
    iconBlue,
    iconTeal,
    iconPurple,
    iconPink,
    iconIndigo,
    waitGreen,
    waitAmber,
  ];

  static Color zebraFill(ColorScheme cs, int index) {
    if (index.isEven) return Colors.transparent;
    return cs.onSurface.withValues(alpha: 0.035);
  }

  static String display(String? value) {
    if (value == null || value.trim().isEmpty) return '';
    return value
        .trim()
        .toLowerCase()
        .replaceAll('_', ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  static String unitLabel(String? value) {
    return NursingUnit.fromString(value)?.label ?? display(value);
  }

  static String shiftLabel(String? value) {
    return ShiftType.fromString(value)?.label ?? display(value);
  }

  static String resolvedSubtitle(NurseDashboardHeader header) {
    if (header.subtitle != null && header.subtitle!.trim().isNotEmpty) {
      return header.subtitle!;
    }
    final template =
        header.subtitleTemplate ??
        "Welcome back, {name}. Here's what's happening today.";
    final name = header.userDisplayName.trim().isNotEmpty
        ? header.userDisplayName.trim()
        : 'there';
    return template.replaceAll('{name}', name);
  }

  static Color statusToneColor(String? tone, ColorScheme scheme) {
    switch ((tone ?? 'neutral').toLowerCase()) {
      case 'success':
        return waitGreen;
      case 'warning':
        return waitAmber;
      case 'danger':
        return waitRed;
      case 'busy':
        return iconBlue;
      case 'break':
        return iconPurple;
      case 'neutral':
      default:
        return scheme.onSurfaceVariant;
    }
  }

  static Color alertAccent(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
      case 'error':
        return waitRed;
      case 'warning':
      default:
        return waitAmber;
    }
  }

  static List<NurseDashboardKpiItem> kpiItemsFor(
    NursingDashboardOverview data,
  ) {
    final kpis = data.base.kpis;
    final patientsCaption = data.opdQueueDepth != null
        ? 'OPD queue: ${data.opdQueueDepth}'
        : _caption(kpis.totalPatients.delta);
    final occupancyCaption = data.bedOccupancyPercent != null
        ? '${data.bedOccupancyPercent!.toStringAsFixed(0)}% occupied'
        : _caption(kpis.bedOccupancy.delta);

    return [
      NurseDashboardKpiItem(
        label: 'Total Patients',
        value: _value(kpis.totalPatients.valueFormatted),
        caption: patientsCaption,
        icon: Icons.groups_outlined,
        accent: iconBlue,
      ),
      NurseDashboardKpiItem(
        label: 'Bed Occupancy',
        value: _value(kpis.bedOccupancy.valueFormatted),
        caption: occupancyCaption,
        icon: Icons.hotel_outlined,
        accent: iconTeal,
      ),
      NurseDashboardKpiItem(
        label: 'Active Staff',
        value: _value(kpis.activeStaff.valueFormatted),
        caption: _caption(kpis.activeStaff.delta),
        icon: Icons.medical_information_outlined,
        accent: iconPurple,
      ),
      NurseDashboardKpiItem(
        label: 'Avg. Wait Time',
        value: _value(kpis.averageWaitTime.valueFormatted),
        caption: _caption(kpis.averageWaitTime.delta),
        icon: Icons.schedule_outlined,
        accent: waitAmber,
      ),
    ];
  }

  static String _value(String raw) {
    final v = raw.trim();
    return v.isEmpty ? '—' : v;
  }

  static String _caption(NurseKpiDelta delta) {
    final label = delta.label.trim();
    return label.isEmpty ? '—' : label;
  }

  static NurseAdmissionsDischargesSeries admissionsSeriesForChart({
    required String timeRange,
    required NurseAdmissionsDischargesSeries series,
  }) {
    if (timeRange != 'Today') return series;
    final aggregated = _aggregateAdmissionsToFourHourBuckets(series.points);
    if (aggregated == null) return series;
    return NurseAdmissionsDischargesSeries(points: aggregated, meta: null);
  }

  static List<NurseAdmissionDischargePoint>?
  _aggregateAdmissionsToFourHourBuckets(
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

  static int? _tryParseHourFromLabel(String label) {
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
      final isPm = m12.group(3)!.toUpperCase() == 'PM';
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

  static String _fourHourBucketLabel(int bucketIndex) {
    final h = bucketIndex * 4;
    return '${h.toString().padLeft(2, '0')}:00';
  }

  static double lineChartMaxY(
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

  static double niceInterval(double maxY) {
    if (maxY <= 0) return 20;
    final rough = maxY / 4;
    final exp = (math.log(rough) / math.ln10).floor();
    final frac = rough / math.pow(10, exp);
    late final double niceFrac;
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

  static Color colorForUnit(String name, Color fallback) {
    final n = name.toLowerCase();
    if (n.contains('emerg')) return DepartmentColors.emergency;
    if (n.contains('icu')) return DepartmentColors.icu;
    if (n.contains('opd') || n.contains('outpatient')) {
      return DepartmentColors.outpatientClinic;
    }
    if (n.contains('ward') || n.contains('inpatient')) {
      return DepartmentColors.frontDesk;
    }
    if (n.contains('ong') || n.contains('obg') || n.contains('gyn')) {
      return DepartmentColors.obgyn;
    }
    return fallback;
  }
}
