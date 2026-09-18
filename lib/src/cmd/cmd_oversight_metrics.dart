import 'package:flutter/material.dart';

import '../shared/department_colors.dart';
import 'cmd_command_metrics.dart';
import 'models/cmd_models.dart';

/// Staff-oversight helpers in the Walk-in Queue visual language.
abstract final class CmdOversightMetrics {
  static const cardBreakpoint = CmdCommandMetrics.cardBreakpoint;
  static const sidebarBreakpoint = CmdCommandMetrics.sidebarBreakpoint;
  static const pageSize = 20;

  static const Color waitGreen = CmdCommandMetrics.waitGreen;
  static const Color waitAmber = CmdCommandMetrics.waitAmber;
  static const Color waitRed = CmdCommandMetrics.waitRed;
  static const Color iconBlue = CmdCommandMetrics.iconBlue;
  static const Color iconTeal = CmdCommandMetrics.iconTeal;
  static const Color iconPurple = CmdCommandMetrics.iconPurple;
  static const Color iconPink = CmdCommandMetrics.iconPink;
  static const Color iconIndigo = CmdCommandMetrics.iconIndigo;

  static String display(String value) => CmdCommandMetrics.displayValue(value);

  static Color zebraFill(ColorScheme cs, int index) {
    if (index.isEven) return Colors.transparent;
    return cs.onSurface.withValues(alpha: 0.035);
  }

  static Color gapColor(int gap) => gap > 0 ? waitRed : waitGreen;

  static String gapStatus(int gap) => gap > 0 ? 'Short' : 'Covered';

  static Color colorForDepartment(String name, Color fallback) {
    final n = name.toLowerCase();
    if (n.contains('emerg')) return DepartmentColors.emergency;
    if (n.contains('icu')) return DepartmentColors.icu;
    if (n.contains('theatre') ||
        n.contains('theater') ||
        n.contains('surgery')) {
      return DepartmentColors.theatre;
    }
    if (n.contains('obg') || n.contains('gyn') || n.contains('women')) {
      return DepartmentColors.obgyn;
    }
    if (n.contains('mater')) return DepartmentColors.maternity;
    if (n.contains('derma')) return DepartmentColors.dermatology;
    if (n.contains('ortho')) return DepartmentColors.orthopedics;
    if (n.contains('ophthal') || n.contains('eye')) {
      return DepartmentColors.eyeClinic;
    }
    if (n.contains('pedia') || n.contains('paed')) {
      return DepartmentColors.pediatrics;
    }
    if (n.contains('cardio')) return DepartmentColors.cardiology;
    if (n.contains('dental')) return DepartmentColors.dental;
    if (n.contains('ent')) return DepartmentColors.ent;
    if (n.contains('lab')) return DepartmentColors.laboratory;
    if (n.contains('radio')) return DepartmentColors.radiology;
    if (n.contains('pharma')) return DepartmentColors.pharmacy;
    if (n.contains('neuro')) return DepartmentColors.icu;
    if (n.contains('outpatient') ||
        n.contains('opd') ||
        n.contains('general')) {
      return DepartmentColors.outpatientClinic;
    }
    if (n.contains('admin')) return DepartmentColors.administration;
    if (n.contains('nurs')) return DepartmentColors.icu;
    return fallback;
  }

  static List<CmdCommandKpiItem> kpiItemsFor(CmdStaffOversight data) {
    final a = data.attendance;
    final shortCount = data.byDepartment.where((r) => r.gap > 0).length;
    return [
      CmdCommandKpiItem(
        label: 'On Duty',
        value: '${a.onDuty}',
        caption: a.scheduled == 0
            ? 'Present now'
            : 'of ${a.scheduled} scheduled',
        icon: Icons.badge_outlined,
        accent: iconBlue,
      ),
      CmdCommandKpiItem(
        label: 'Scheduled',
        value: '${a.scheduled}',
        caption: 'Rostered today',
        icon: Icons.calendar_today_outlined,
        accent: iconTeal,
      ),
      CmdCommandKpiItem(
        label: 'Late',
        value: '${a.late}',
        caption: 'Clocked in late',
        icon: Icons.schedule_outlined,
        accent: waitAmber,
      ),
      CmdCommandKpiItem(
        label: 'Absent',
        value: '${a.absent}',
        caption: shortCount == 0
            ? 'Not present'
            : '$shortCount dept${shortCount == 1 ? '' : 's'} short',
        icon: Icons.person_off_outlined,
        accent: waitRed,
      ),
    ];
  }

  static List<CmdDepartmentStaffing> applyClientFilters({
    required List<CmdDepartmentStaffing> rows,
    required String query,
    required String statusValue,
    required bool largestGapFirst,
  }) {
    final needle = query.trim().toLowerCase();
    var list = rows.where((row) {
      if (needle.isNotEmpty && !row.department.toLowerCase().contains(needle)) {
        return false;
      }
      switch (statusValue) {
        case 'short':
          return row.gap > 0;
        case 'covered':
          return row.gap <= 0;
        default:
          return true;
      }
    }).toList();
    list.sort((a, b) {
      if (largestGapFirst) {
        final gapCmp = b.gap.compareTo(a.gap);
        if (gapCmp != 0) return gapCmp;
      }
      return a.department.toLowerCase().compareTo(b.department.toLowerCase());
    });
    return list;
  }
}
