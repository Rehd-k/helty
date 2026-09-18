import 'package:flutter/material.dart';

import 'cmd_money_format.dart';
import 'models/cmd_models.dart';

class CmdCommandKpiItem {
  const CmdCommandKpiItem({
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

/// Colors, icons, and KPI mapping for the CMD command center
/// (Walk-in Queue visual language).
abstract final class CmdCommandMetrics {
  static const cardBreakpoint = 768.0;
  static const sidebarBreakpoint = 1100.0;

  static const Color waitGreen = Color(0xFF16A34A);
  static const Color waitYellow = Color(0xFFCA8A04);
  static const Color waitAmber = Color(0xFFEA580C);
  static const Color waitRed = Color(0xFFDC2626);

  static const Color iconBlue = Color(0xFF2563EB);
  static const Color iconTeal = Color(0xFF0D9488);
  static const Color iconPurple = Color(0xFF7C3AED);
  static const Color iconPink = Color(0xFFDB2777);
  static const Color iconIndigo = Color(0xFF4F46E5);

  static const List<Color> accentPalette = [
    iconBlue,
    iconTeal,
    iconPurple,
    iconPink,
    iconIndigo,
    waitGreen,
    waitAmber,
  ];

  static String displayValue(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? '—' : trimmed;
  }

  static IconData iconForKey(String key) {
    switch (key) {
      case 'people':
        return Icons.groups_outlined;
      case 'login':
        return Icons.login;
      case 'bed':
        return Icons.bed_outlined;
      case 'money':
        return Icons.payments_outlined;
      case 'badge':
        return Icons.badge_outlined;
      case 'science':
        return Icons.science_outlined;
      case 'receipt':
        return Icons.receipt_long_outlined;
      case 'emergency':
        return Icons.local_hospital_outlined;
      default:
        return Icons.analytics_outlined;
    }
  }

  static Color accentForKey(String key, int index) {
    switch (key) {
      case 'people':
        return iconBlue;
      case 'login':
        return iconTeal;
      case 'bed':
        return iconPurple;
      case 'money':
        return waitGreen;
      case 'badge':
        return iconIndigo;
      case 'science':
        return iconPink;
      case 'receipt':
        return waitAmber;
      case 'emergency':
        return waitRed;
      default:
        return accentPalette[index % accentPalette.length];
    }
  }

  static Color trendColor(CmdTrendDirection direction, ColorScheme cs) {
    return switch (direction) {
      CmdTrendDirection.up => waitGreen,
      CmdTrendDirection.down => waitRed,
      CmdTrendDirection.flat => cs.onSurfaceVariant,
    };
  }

  static Color alertColor(String level) {
    switch (level.toLowerCase()) {
      case 'critical':
      case 'high':
        return waitRed;
      case 'medium':
      case 'warning':
        return waitAmber;
      default:
        return iconBlue;
    }
  }

  static List<CmdCommandKpiItem> kpiItemsFor(
    CmdExecutiveDashboardBundle bundle,
  ) {
    if (bundle.kpis.isNotEmpty) {
      return [
        for (var i = 0; i < bundle.kpis.length; i++)
          CmdCommandKpiItem(
            label: bundle.kpis[i].label,
            value: displayValue(bundle.kpis[i].value),
            caption: displayValue(bundle.kpis[i].trendLabel),
            icon: iconForKey(bundle.kpis[i].iconKey),
            accent: accentForKey(bundle.kpis[i].iconKey, i),
          ),
      ];
    }

    final fmt = cmdNairaFormat();
    return [
      CmdCommandKpiItem(
        label: 'OPD Today',
        value: '${bundle.patientsTodayOpd}',
        caption: 'Outpatient visits',
        icon: Icons.groups_outlined,
        accent: iconBlue,
      ),
      CmdCommandKpiItem(
        label: 'Admitted Today',
        value: '${bundle.patientsTodayAdmitted}',
        caption: 'Inpatient admissions',
        icon: Icons.bed_outlined,
        accent: iconPurple,
      ),
      CmdCommandKpiItem(
        label: 'Revenue Today',
        value: fmt.format(bundle.revenueToday),
        caption: 'Hospital collections',
        icon: Icons.payments_outlined,
        accent: waitGreen,
      ),
      CmdCommandKpiItem(
        label: 'Bed Occupancy',
        value: '${bundle.capacity.occupancyPercent.toStringAsFixed(0)}%',
        caption: 'Live capacity',
        icon: Icons.hotel_outlined,
        accent: iconTeal,
      ),
    ];
  }
}
