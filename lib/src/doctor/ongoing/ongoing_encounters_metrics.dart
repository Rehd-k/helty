import 'package:flutter/material.dart';

import '../../helper/app_timezone.dart';
import '../../models/encounter_model.dart';
import '../../paitients/patient_model.dart';
import '../../shared/department_colors.dart';

class OngoingActivityNote {
  const OngoingActivityNote({required this.at, required this.message});

  final DateTime at;
  final String message;
}

class OngoingDoctorCount {
  const OngoingDoctorCount({required this.name, required this.count});

  final String name;
  final int count;
}

enum OngoingElapsedUrgency { recent, moderate, elevated, critical }

/// Helpers for the ongoing-encounters list (Walk-in Queue visual language).
abstract final class OngoingEncountersMetrics {
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

  static String patientName(EncounterModel encounter, Patient? patient) {
    final name = patient?.displayName.trim() ?? '';
    if (name.isNotEmpty) return name;
    final id = encounter.patientId.trim();
    return id.isEmpty ? 'Unknown' : 'Patient $id';
  }

  static String mrn(Patient? patient) {
    final card = patient?.cardNo.trim() ?? '';
    if (card.isNotEmpty) return card;
    return patient?.patientId.trim() ?? '';
  }

  static String? phone(Patient? patient) {
    final value = patient?.phoneNumber?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  static String complaint(EncounterModel encounter) {
    final value = encounter.chiefComplaint?.trim() ?? '';
    return value.isEmpty ? 'No chief complaint recorded' : value;
  }

  static String visitTypeLabel(EncounterModel encounter) {
    final visit = encounter.visitType?.trim() ?? '';
    if (visit.isNotEmpty) return visit;
    final type = encounter.encounterType?.trim() ?? '';
    if (type.isNotEmpty) return type;
    return 'OPD';
  }

  static String statusLabel(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'ONGOING':
        return 'Ongoing';
      case 'WAITING':
        return 'Waiting';
      case 'IN_CONSULTATION':
        return 'In Consultation';
      default:
        return status.trim().isEmpty ? 'Ongoing' : status;
    }
  }

  static Color statusColor(String status) {
    final s = status.toUpperCase();
    switch (s) {
      case 'WAITING':
        return waitAmber;
      case 'IN_CONSULTATION':
        return iconBlue;
      case 'ONGOING':
        return iconTeal;
      default:
        return iconTeal;
    }
  }

  static Duration elapsed(EncounterModel encounter, [DateTime? now]) {
    final clock = now ?? AppTimezone.now();
    final started = encounter.startedAt.isUtc
        ? encounter.startedAt.toLocal()
        : encounter.startedAt;
    final diff = clock.difference(started);
    return diff.isNegative ? Duration.zero : diff;
  }

  static String formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      if (minutes == 0) return '${hours}h';
      return '${hours}h ${minutes}m';
    }
    if (duration.inMinutes > 0) return '${duration.inMinutes}m';
    return '<1m';
  }

  static OngoingElapsedUrgency urgencyFor(Duration duration) {
    final minutes = duration.inMinutes;
    if (minutes < 15) return OngoingElapsedUrgency.recent;
    if (minutes < 30) return OngoingElapsedUrgency.moderate;
    if (minutes < 60) return OngoingElapsedUrgency.elevated;
    return OngoingElapsedUrgency.critical;
  }

  static Color urgencyColor(OngoingElapsedUrgency urgency) => switch (urgency) {
    OngoingElapsedUrgency.recent => waitGreen,
    OngoingElapsedUrgency.moderate => waitYellow,
    OngoingElapsedUrgency.elevated => waitAmber,
    OngoingElapsedUrgency.critical => waitRed,
  };

  static Color stripeColor(EncounterModel encounter, [DateTime? now]) {
    return urgencyColor(urgencyFor(elapsed(encounter, now)));
  }

  static String? averageElapsedLabel(
    List<EncounterModel> encounters, [
    DateTime? now,
  ]) {
    if (encounters.isEmpty) return null;
    var totalMs = 0;
    for (final e in encounters) {
      totalMs += elapsed(e, now).inMilliseconds;
    }
    return formatDuration(Duration(milliseconds: totalMs ~/ encounters.length));
  }

  static String? longestElapsedLabel(
    List<EncounterModel> encounters, [
    DateTime? now,
  ]) {
    if (encounters.isEmpty) return null;
    var max = Duration.zero;
    for (final e in encounters) {
      final d = elapsed(e, now);
      if (d > max) max = d;
    }
    return formatDuration(max);
  }

  static bool isStartedToday(EncounterModel encounter) {
    final started = AppTimezone.toLocal(encounter.startedAt);
    final today = AppTimezone.now();
    return started.year == today.year &&
        started.month == today.month &&
        started.day == today.day;
  }

  static int startedTodayCount(List<EncounterModel> encounters) {
    var n = 0;
    for (final e in encounters) {
      if (isStartedToday(e)) n++;
    }
    return n;
  }

  static Color colorForVisitType(String label, Color fallback) {
    final n = label.toLowerCase();
    if (n.contains('emerg')) return DepartmentColors.emergency;
    if (n.contains('inpatient') || n.contains('admit')) {
      return DepartmentColors.icu;
    }
    if (n.contains('follow')) return iconIndigo;
    if (n.contains('walk')) return iconBlue;
    if (n.contains('appoint') || n.contains('schedul')) {
      return DepartmentColors.outpatientClinic;
    }
    if (n.contains('review')) return iconTeal;
    return fallback;
  }

  static Color avatarBlockColor(String seed) {
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

  static List<OngoingDoctorCount> doctorCounts({
    required List<EncounterModel> encounters,
    required String Function(EncounterModel) doctorLabel,
  }) {
    final counts = <String, int>{};
    for (final e in encounters) {
      final name = doctorLabel(e);
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final rows = counts.entries
        .map((e) => OngoingDoctorCount(name: e.key, count: e.value))
        .toList();
    rows.sort((a, b) => b.count.compareTo(a.count));
    return rows;
  }

  static List<String> uniqueVisitTypes(List<EncounterModel> encounters) {
    final seen = <String>{};
    final out = <String>[];
    for (final e in encounters) {
      final label = visitTypeLabel(e);
      if (seen.add(label)) out.add(label);
    }
    out.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return out;
  }
}
