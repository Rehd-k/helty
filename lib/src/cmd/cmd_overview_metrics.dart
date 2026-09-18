import 'package:flutter/material.dart';

import 'cmd_command_metrics.dart';
import 'cmd_oversight_metrics.dart';
import 'models/cmd_models.dart';

/// Hospital-overview helpers in the Walk-in Queue visual language.
abstract final class CmdOverviewMetrics {
  static const cardBreakpoint = CmdOversightMetrics.cardBreakpoint;
  static const sidebarBreakpoint = CmdOversightMetrics.sidebarBreakpoint;
  static const pageSize = CmdOversightMetrics.pageSize;

  static const Color waitGreen = CmdOversightMetrics.waitGreen;
  static const Color waitAmber = CmdOversightMetrics.waitAmber;
  static const Color waitRed = CmdOversightMetrics.waitRed;
  static const Color iconBlue = CmdOversightMetrics.iconBlue;
  static const Color iconTeal = CmdOversightMetrics.iconTeal;
  static const Color iconPurple = CmdOversightMetrics.iconPurple;
  static const Color iconPink = CmdOversightMetrics.iconPink;
  static const Color iconIndigo = CmdOversightMetrics.iconIndigo;

  static String display(String value) => CmdOversightMetrics.display(value);

  static Color zebraFill(ColorScheme cs, int index) =>
      CmdOversightMetrics.zebraFill(cs, index);

  static Color colorForDepartment(String name, Color fallback) =>
      CmdOversightMetrics.colorForDepartment(name, fallback);

  static bool isOk(String status) => status.trim().toLowerCase() == 'ok';

  static Color statusColor(String status) {
    if (status.trim().isEmpty) return iconBlue;
    return isOk(status) ? waitGreen : waitRed;
  }

  static Color trendColor(String label) {
    final n = label.toLowerCase();
    if (n.contains('up') || n.contains('worse') || n.contains('↑')) {
      return waitRed;
    }
    if (n.contains('down') || n.contains('better') || n.contains('↓')) {
      return waitGreen;
    }
    return iconBlue;
  }

  static List<CmdCommandKpiItem> kpiItemsFor(CmdHospitalOverview data) {
    var patients = 0;
    var sla = 0;
    for (final row in data.departments) {
      patients += row.patientsSeen;
      sla += row.slaBreaches;
    }
    var inPipeline = 0;
    for (final stage in data.flow) {
      inPipeline += stage.patientsInStage;
    }
    return [
      CmdCommandKpiItem(
        label: 'Departments',
        value: '${data.departments.length}',
        caption: 'Scorecards loaded',
        icon: Icons.apartment_outlined,
        accent: iconBlue,
      ),
      CmdCommandKpiItem(
        label: 'Patients Seen',
        value: '$patients',
        caption: 'Across departments',
        icon: Icons.groups_outlined,
        accent: iconTeal,
      ),
      CmdCommandKpiItem(
        label: 'SLA Breaches',
        value: '$sla',
        caption: sla == 0 ? 'None reported' : 'Needs attention',
        icon: Icons.flag_outlined,
        accent: sla > 0 ? waitRed : waitGreen,
      ),
      CmdCommandKpiItem(
        label: 'In Pipeline',
        value: '$inPipeline',
        caption: data.flow.isEmpty ? 'No flow stages' : 'Patients in flow',
        icon: Icons.account_tree_outlined,
        accent: iconPurple,
      ),
    ];
  }

  static List<CmdDepartmentScorecard> applyClientFilters({
    required List<CmdDepartmentScorecard> rows,
    required String query,
    required String statusValue,
    required String sortValue,
  }) {
    final needle = query.trim().toLowerCase();
    var list = rows.where((row) {
      if (needle.isNotEmpty && !row.name.toLowerCase().contains(needle)) {
        return false;
      }
      switch (statusValue) {
        case 'ok':
          return isOk(row.status);
        case 'issue':
          return !isOk(row.status);
        default:
          return true;
      }
    }).toList();
    list.sort((a, b) {
      var cmp = 0;
      if (sortValue == 'sla') {
        cmp = b.slaBreaches.compareTo(a.slaBreaches);
      } else if (sortValue == 'patients') {
        cmp = b.patientsSeen.compareTo(a.patientsSeen);
      }
      if (cmp != 0) return cmp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return list;
  }
}
