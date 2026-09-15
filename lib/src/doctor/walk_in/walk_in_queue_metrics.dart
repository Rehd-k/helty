import 'package:flutter/material.dart';

import '../../helper/app_timezone.dart';
import '../../models/waiting_patient_model.dart';
import '../../shared/department_colors.dart';
import '../../widgets/helty_surface.dart';

enum WalkInUrgency { recent, moderate, elevated, critical }

enum WalkInQueueStatus { waiting, inConsultation }

class WalkInActivityNote {
  const WalkInActivityNote({required this.at, required this.message});

  final DateTime at;
  final String message;
}

/// Wait-time, status, and department-color helpers for the walk-in queue UI.
abstract final class WalkInQueueMetrics {
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

  static WalkInQueueStatus statusOf(WaitingPatientModel waiting) => waiting.seen
      ? WalkInQueueStatus.inConsultation
      : WalkInQueueStatus.waiting;

  static String statusLabel(WalkInQueueStatus status) => switch (status) {
    WalkInQueueStatus.waiting => 'Waiting',
    WalkInQueueStatus.inConsultation => 'In Consultation',
  };

  static String patientName(WaitingPatientModel waiting) {
    final name = waiting.patient?.displayName.trim() ?? '';
    return name.isEmpty ? 'Unknown' : name;
  }

  static String mrn(WaitingPatientModel waiting) {
    final card = waiting.patient?.cardNo.trim() ?? '';
    if (card.isNotEmpty) return card;
    final id = waiting.patient?.patientId.trim() ?? '';
    return id;
  }

  static String? phone(WaitingPatientModel waiting) {
    final value = waiting.patient?.phoneNumber?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static String roomName(WaitingPatientModel waiting) {
    final name = waiting.consultingRoom?.name.trim() ?? '';
    if (name.isNotEmpty) return name;
    return 'Unassigned';
  }

  static Duration waitDuration(WaitingPatientModel waiting, [DateTime? now]) {
    final clock = now ?? AppTimezone.now();
    final created = waiting.createdAt.isUtc
        ? waiting.createdAt.toLocal()
        : waiting.createdAt;
    final diff = clock.difference(created);
    return diff.isNegative ? Duration.zero : diff;
  }

  static String formatWait(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      if (minutes == 0) return '${hours}h';
      return '${hours}h ${minutes}m';
    }
    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    return '<1m';
  }

  static WalkInUrgency urgencyFor(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 15) return WalkInUrgency.recent;
    if (minutes < 30) return WalkInUrgency.moderate;
    if (minutes < 60) return WalkInUrgency.elevated;
    return WalkInUrgency.critical;
  }

  static Color urgencyColor(WalkInUrgency urgency) => switch (urgency) {
    WalkInUrgency.recent => waitGreen,
    WalkInUrgency.moderate => waitYellow,
    WalkInUrgency.elevated => waitAmber,
    WalkInUrgency.critical => waitRed,
  };

  static Duration? averageWait(
    List<WaitingPatientModel> patients, [
    DateTime? now,
  ]) {
    final unseen = patients.where((p) => !p.seen).toList();
    if (unseen.isEmpty) return null;
    var totalMs = 0;
    for (final patient in unseen) {
      totalMs += waitDuration(patient, now).inMilliseconds;
    }
    return Duration(milliseconds: totalMs ~/ unseen.length);
  }

  static Color colorForRoomName(String name, Color fallback) {
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
    return fallback;
  }

  static List<WaitingPatientModel> applyClientFilters({
    required List<WaitingPatientModel> patients,
    String? departmentName,
    required bool longestWaitFirst,
  }) {
    var list = List<WaitingPatientModel>.from(patients);
    final needle = departmentName?.trim().toLowerCase() ?? '';
    if (needle.isNotEmpty) {
      list = list.where((p) {
        final room = p.consultingRoom?.name.toLowerCase() ?? '';
        return room.contains(needle);
      }).toList();
    }
    list.sort((a, b) {
      final cmp = a.createdAt.compareTo(b.createdAt);
      return longestWaitFirst ? cmp : -cmp;
    });
    return list;
  }

  static Color avatarBlockColor(WaitingPatientModel waiting) {
    final seed = waiting.patientId.isNotEmpty ? waiting.patientId : waiting.id;
    if (seed.isEmpty) return avatarPalette.first;
    var hash = 0;
    for (final code in seed.codeUnits) {
      hash = (hash * 31 + code) & 0x7fffffff;
    }
    return avatarPalette[hash % avatarPalette.length];
  }

  static Color zebraFill(ColorScheme cs, int index) {
    if (index.isEven) return Colors.transparent;
    return cs.onSurface.withValues(alpha: 0.035);
  }
}

/// Walk-in alias for the shared solid icon tile.
typedef WalkInSolidIcon = HeltySolidIcon;
