import 'package:flutter/material.dart';

import '../widgets/helty_surface.dart';
import 'models/ed_enums.dart';
import 'models/emergency_visit_model.dart';

/// Wait-time, ESI, and status helpers for the ED board UI.
abstract final class EdBoardMetrics {
  static const cardBreakpoint = 768.0;
  static const sidebarBreakpoint = 1100.0;
  static const int rowsPerPage = 20;

  static const Color waitGreen = Color(0xFF16A34A);
  static const Color waitYellow = Color(0xFFCA8A04);
  static const Color waitAmber = Color(0xFFEA580C);
  static const Color waitRed = Color(0xFFDC2626);

  static const Color iconBlue = Color(0xFF2563EB);
  static const Color iconTeal = Color(0xFF0D9488);
  static const Color iconPurple = Color(0xFF7C3AED);
  static const Color iconPink = Color(0xFFDB2777);
  static const Color iconIndigo = Color(0xFF4F46E5);

  static const List<Color> avatarPalette = [
    iconBlue,
    iconPurple,
    iconTeal,
    waitAmber,
    iconPink,
    waitGreen,
    Color(0xFF0891B2),
    iconIndigo,
  ];

  static String patientName(EmergencyVisitModel visit) {
    final name = visit.patientName?.trim() ?? '';
    if (name.isNotEmpty) return name;
    final id = visit.patientId.trim();
    return id.isEmpty ? 'Unknown' : id;
  }

  static String formatWaitMinutes(int minutes) {
    if (minutes <= 0) return '<1m';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (hours > 0) {
      if (rem == 0) return '${hours}h';
      return '${hours}h ${rem}m';
    }
    return '${minutes}m';
  }

  static Color esiStripeColor(int? esiLevel) {
    switch (esiLevel) {
      case 1:
        return waitRed;
      case 2:
        return waitAmber;
      case 3:
        return waitYellow;
      case 4:
        return iconBlue;
      case 5:
        return waitGreen;
      default:
        return const Color(0xFF94A3B8);
    }
  }

  static Color statusColor(EdWorkflowStatus status) {
    switch (status) {
      case EdWorkflowStatus.registered:
      case EdWorkflowStatus.triage:
        return iconIndigo;
      case EdWorkflowStatus.waitingDoctor:
        return waitAmber;
      case EdWorkflowStatus.inTreatment:
      case EdWorkflowStatus.dispositionPending:
        return iconTeal;
      case EdWorkflowStatus.admitted:
        return waitGreen;
      case EdWorkflowStatus.discharged:
      case EdWorkflowStatus.transferred:
        return const Color(0xFF64748B);
      case EdWorkflowStatus.lwbs:
      case EdWorkflowStatus.cancelled:
        return waitRed;
      case EdWorkflowStatus.deceased:
        return const Color(0xFF475569);
    }
  }

  static Color avatarBlockColor(EmergencyVisitModel visit) {
    final seed = visit.patientId.isNotEmpty ? visit.patientId : visit.id;
    if (seed.isEmpty) return avatarPalette.first;
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return avatarPalette[hash % avatarPalette.length];
  }

  static String? averageWaitLabel(List<EmergencyVisitModel> visits) {
    if (visits.isEmpty) return null;
    var total = 0;
    for (final v in visits) {
      total += v.computedWaitMinutes;
    }
    return formatWaitMinutes(total ~/ visits.length);
  }

  static int criticalEsiCount(List<EmergencyVisitModel> visits) {
    return visits.where((v) {
      final esi = v.esiLevel;
      return esi != null && esi <= 2;
    }).length;
  }

  static int waitingDoctorCount(List<EmergencyVisitModel> visits) {
    return visits
        .where((v) => v.workflowStatus == EdWorkflowStatus.waitingDoctor)
        .length;
  }

  static List<EmergencyVisitModel> applyClientSearch({
    required List<EmergencyVisitModel> visits,
    required String query,
  }) {
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return visits;
    return visits.where((v) {
      final name = patientName(v).toLowerCase();
      final complaint = (v.chiefComplaint ?? '').toLowerCase();
      final id = v.patientId.toLowerCase();
      return name.contains(needle) ||
          complaint.contains(needle) ||
          id.contains(needle);
    }).toList();
  }

  static List<EmergencyVisitModel> sortVisits(List<EmergencyVisitModel> visits) {
    final sorted = List<EmergencyVisitModel>.from(visits)
      ..sort((a, b) {
        final esiA = a.esiLevel ?? 99;
        final esiB = b.esiLevel ?? 99;
        if (esiA != esiB) return esiA.compareTo(esiB);
        return b.computedWaitMinutes.compareTo(a.computedWaitMinutes);
      });
    return sorted;
  }

  static Color zebraFill(ColorScheme cs, int index) {
    if (index.isEven) return Colors.transparent;
    return cs.onSurface.withValues(alpha: 0.035);
  }
}

typedef EdBoardSolidIcon = HeltySolidIcon;
