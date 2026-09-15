import 'package:flutter/material.dart';

import '../../helper/app_timezone.dart';
import '../../models/encounter_model.dart';
import '../../paitients/patient_model.dart';
import '../../shared/department_colors.dart';

class CompletedActivityNote {
  const CompletedActivityNote({required this.at, required this.message});

  final DateTime at;
  final String message;
}

class CompletedDoctorCount {
  const CompletedDoctorCount({required this.name, required this.count});

  final String name;
  final int count;
}

/// Helpers for the completed-encounters list (Walk-in Queue visual language).
abstract final class CompletedEncountersMetrics {
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

  static DateTime closedAt(EncounterModel encounter) =>
      encounter.closedAt ?? encounter.startedAt;

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

  static String diagnosis(EncounterModel encounter) {
    final desc = encounter.primaryIcdDescription?.trim() ?? '';
    if (desc.isNotEmpty) return desc;
    final code = encounter.primaryIcdCode?.trim() ?? '';
    if (code.isNotEmpty) return code;
    return '—';
  }

  static String visitTypeLabel(EncounterModel encounter) {
    final visit = encounter.visitType?.trim() ?? '';
    if (visit.isNotEmpty) return visit;
    final type = encounter.encounterType?.trim() ?? '';
    if (type.isNotEmpty) return type;
    return 'Unspecified';
  }

  static Duration? duration(EncounterModel encounter) {
    final closed = encounter.closedAt;
    if (closed == null) return null;
    final diff = closed.difference(encounter.startedAt);
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

  static String? averageDurationLabel(List<EncounterModel> encounters) {
    final durs = <Duration>[];
    for (final e in encounters) {
      final d = duration(e);
      if (d != null) durs.add(d);
    }
    if (durs.isEmpty) return null;
    var totalMs = 0;
    for (final d in durs) {
      totalMs += d.inMilliseconds;
    }
    return formatDuration(Duration(milliseconds: totalMs ~/ durs.length));
  }

  static bool isClosedToday(EncounterModel encounter) {
    final closed = AppTimezone.toLocal(closedAt(encounter));
    final today = AppTimezone.now();
    return closed.year == today.year &&
        closed.month == today.month &&
        closed.day == today.day;
  }

  static int completedTodayCount(List<EncounterModel> encounters) {
    var n = 0;
    for (final e in encounters) {
      if (isClosedToday(e)) n++;
    }
    return n;
  }

  /// `null` when the list endpoint did not return edit metadata.
  static int? editedCount(List<EncounterModel> encounters) {
    var sawMeta = false;
    var n = 0;
    for (final e in encounters) {
      if (e.editMeta == null) continue;
      sawMeta = true;
      if (e.editMeta!.hasEdits) n++;
    }
    return sawMeta ? n : null;
  }

  static Color stripeColor(EncounterModel encounter) {
    if (encounter.editMeta?.hasEdits == true) return waitAmber;
    if (isClosedToday(encounter)) return waitGreen;
    return iconTeal;
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

  static List<CompletedDoctorCount> doctorCounts({
    required List<EncounterModel> encounters,
    required String Function(EncounterModel) doctorLabel,
  }) {
    final counts = <String, int>{};
    for (final e in encounters) {
      final name = doctorLabel(e);
      counts[name] = (counts[name] ?? 0) + 1;
    }
    final rows = counts.entries
        .map((e) => CompletedDoctorCount(name: e.key, count: e.value))
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
