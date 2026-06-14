import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';

/// Summary data for pregnancy list/detail at-a-glance UI.
class PregnancyAtAGlance {
  const PregnancyAtAGlance({
    this.gestationalWeeks,
    this.gestationalDays,
    this.daysUntilEdd,
    this.visitCount,
    this.deliveryCount,
    this.lastBp,
    this.lastFhr,
    this.lastPresentation,
    this.lastVisitDate,
  });

  final int? gestationalWeeks;
  final int? gestationalDays;
  final int? daysUntilEdd;
  final int? visitCount;
  final int? deliveryCount;
  final String? lastBp;
  final int? lastFhr;
  final String? lastPresentation;
  final String? lastVisitDate;
}

DateTime? _parseBackendDate(String? value) {
  if (value == null || value.isEmpty) return null;
  try {
    return DateTime.parse(value);
  } catch (_) {
    return null;
  }
}

String pregnancyStatusLabel(PregnancyStatus? status) {
  switch (status) {
    case PregnancyStatus.ONGOING:
      return 'Ongoing';
    case PregnancyStatus.DELIVERED:
      return 'Delivered';
    case PregnancyStatus.LOST:
      return 'Lost';
    case PregnancyStatus.TERMINATED:
      return 'Terminated';
    case null:
      return 'Unknown';
  }
}

Color pregnancyStatusColor(PregnancyStatus? status, ColorScheme scheme) {
  switch (status) {
    case PregnancyStatus.ONGOING:
      return scheme.primary;
    case PregnancyStatus.DELIVERED:
      return scheme.tertiary;
    case PregnancyStatus.LOST:
      return scheme.error;
    case PregnancyStatus.TERMINATED:
      return scheme.outline;
    case null:
      return scheme.onSurfaceVariant;
  }
}

Color pregnancyStatusContainerColor(PregnancyStatus? status, ColorScheme scheme) {
  switch (status) {
    case PregnancyStatus.ONGOING:
      return scheme.primaryContainer;
    case PregnancyStatus.DELIVERED:
      return scheme.tertiaryContainer;
    case PregnancyStatus.LOST:
      return scheme.errorContainer;
    case PregnancyStatus.TERMINATED:
      return scheme.surfaceContainerHighest;
    case null:
      return scheme.surfaceContainerHigh;
  }
}

/// Gestational age in whole weeks from LMP (280-day rule approximation).
int? gestationalWeeksFromLmp(String? lmp, [DateTime? now]) {
  final lmpDate = _parseBackendDate(lmp);
  if (lmpDate == null) return null;
  final clock = now ?? DateTime.now();
  final days = clock.difference(lmpDate).inDays;
  if (days < 0) return null;
  return days ~/ 7;
}

/// Days from today until EDD (negative = overdue).
int? daysUntilEdd(String? edd, [DateTime? now]) {
  final eddDate = _parseBackendDate(edd);
  if (eddDate == null) return null;
  final clock = now ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  final due = DateTime(eddDate.year, eddDate.month, eddDate.day);
  return due.difference(today).inDays;
}

String formatEddCountdown(int? days) {
  if (days == null) return 'EDD unknown';
  if (days == 0) return 'EDD today';
  if (days > 0) return 'EDD in $days day${days == 1 ? '' : 's'}';
  final overdue = -days;
  return '$overdue day${overdue == 1 ? '' : 's'} overdue';
}

AntenatalVisit? latestAntenatalVisit(Pregnancy pregnancy) {
  final visits = pregnancy.antenatalVisits;
  if (visits == null || visits.isEmpty) return null;
  final sorted = List<AntenatalVisit>.from(visits)
    ..sort((a, b) {
      final da = _parseBackendDate(a.visitDate);
      final db = _parseBackendDate(b.visitDate);
      if (da == null && db == null) return 0;
      if (da == null) return -1;
      if (db == null) return 1;
      return da.compareTo(db);
    });
  return sorted.last;
}

PregnancyAtAGlance pregnancyAtAGlance(Pregnancy pregnancy, [DateTime? now]) {
  final latest = latestAntenatalVisit(pregnancy);
  final gaFromLmp = gestationalWeeksFromLmp(pregnancy.lmp, now);
  final gaWeeks = latest?.gestationWeeks?.truncate() ?? gaFromLmp;
  final gaDays = latest?.gestationDays;

  String? lastBp;
  if (latest?.systolicBP != null && latest?.diastolicBP != null) {
    lastBp = '${latest!.systolicBP}/${latest.diastolicBP}';
  }

  return PregnancyAtAGlance(
    gestationalWeeks: gaWeeks,
    gestationalDays: gaDays,
    daysUntilEdd: daysUntilEdd(pregnancy.edd, now),
    visitCount: pregnancy.antenatalVisits?.length,
    deliveryCount: pregnancy.labourDeliveries?.length,
    lastBp: lastBp,
    lastFhr: latest?.fetalHeartRate,
    lastPresentation: latest?.presentation != null
        ? formatEnumLabel(latest!.presentation!.name)
        : null,
    lastVisitDate: latest?.visitDate,
  );
}

String formatEnumLabel(String raw) {
  if (raw.isEmpty) return raw;
  return raw
      .toLowerCase()
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String formatPresentation(FetalPresentation? p) =>
    p != null ? formatEnumLabel(p.name) : '—';

String formatDeliveryMode(DeliveryMode? m) =>
    m != null ? formatEnumLabel(m.name) : '—';

String formatDeliveryOutcome(DeliveryOutcome? o) =>
    o != null ? formatEnumLabel(o.name) : '—';

String formatPostnatalType(PostnatalVisitType? t) =>
    t != null ? formatEnumLabel(t.name) : '—';

String pregnancyGpLabel(Pregnancy p) => 'G${p.gravida}P${p.para}';

String pregnancyDateRangeLabel(Pregnancy p) =>
    '${DateFormatter.formatFromBackend(p.lmp, DateFormatter.shortDate)} – '
    '${DateFormatter.formatFromBackend(p.edd, DateFormatter.shortDate)}';

/// Non-empty booking summary lines for pregnancy overview display.
List<String> pregnancyBookingSummaryLines(Pregnancy p) {
  final lines = <String>[];

  if (p.respiratoryRate != null) lines.add('RR ${p.respiratoryRate}');
  if (p.heartRate != null) lines.add('HR ${p.heartRate}');
  if (p.systolicBP != null && p.diastolicBP != null) {
    lines.add('BP ${p.systolicBP}/${p.diastolicBP}');
  }
  if (p.spo2 != null) lines.add('SpO₂ ${p.spo2}%');
  if (p.genotype != null && p.genotype!.isNotEmpty) {
    lines.add('Genotype ${p.genotype}');
  }
  if (p.bloodGroup != null && p.bloodGroup!.isNotEmpty) {
    lines.add('Blood group ${p.bloodGroup}');
  }
  if (p.pcv != null) lines.add('PCV ${p.pcv}%');
  if (p.hcv != null && p.hcv!.isNotEmpty) lines.add('HCV ${p.hcv}');
  if (p.hbsAg != null && p.hbsAg!.isNotEmpty) lines.add('HBsAg ${p.hbsAg}');
  if (p.vdrl != null && p.vdrl!.isNotEmpty) lines.add('VDRL ${p.vdrl}');
  if (p.hiv12 != null && p.hiv12!.isNotEmpty) lines.add('HIV ${p.hiv12}');
  if (p.urinalysisProtein != null && p.urinalysisProtein!.isNotEmpty) {
    lines.add('Urine protein ${p.urinalysisProtein}');
  }
  if (p.urinalysisGlucose != null && p.urinalysisGlucose!.isNotEmpty) {
    lines.add('Urine glucose ${p.urinalysisGlucose}');
  }
  if (p.ttImmunization != null && p.ttImmunization!.isNotEmpty) {
    lines.add('T-T ${p.ttImmunization}');
  }

  return lines;
}

bool urineProteinPositive(String? urineProtein) =>
    urineDipstickPositive(urineProtein);

bool urineDipstickPositive(String? value) {
  if (value == null || value.isEmpty) return false;
  final v = value.toLowerCase();
  if (v == 'trace') return true;
  return v.contains('+') ||
      v.contains('positive') ||
      v == 'pos' ||
      v == '1' ||
      v == '2' ||
      v == '3';
}

String formatGestationalAge(int? weeks, int? days) {
  if (weeks == null && days == null) return '—';
  if (weeks != null && days != null && days > 0) {
    return '${weeks}w ${days}d';
  }
  if (weeks != null) return '${weeks}w';
  if (days != null) return '${days}d';
  return '—';
}

/// Formats visit date for display — includes time when present in ISO string.
String formatAntenatalVisitDate(String? visitDate) {
  if (visitDate == null || visitDate.isEmpty) return '—';
  try {
    final dt = DateTime.parse(visitDate);
    final hasTime = visitDate.contains('T') &&
        (dt.hour != 0 || dt.minute != 0 || visitDate.contains(':'));
    if (hasTime) {
      return DateFormatter.formatFromBackend(visitDate, DateFormatter.dateTime);
    }
    return DateFormatter.formatFromBackend(visitDate, DateFormatter.shortDate);
  } catch (_) {
    return visitDate;
  }
}

/// Resolves gestational weeks and days from a visit (handles legacy decimal weeks).
(int? weeks, int? days) gestationalAgeParts(AntenatalVisit visit) {
  int? weeks;
  int? days = visit.gestationDays;

  if (visit.gestationWeeks != null) {
    weeks = visit.gestationWeeks!.truncate();
    if (days == null) {
      final fractional = visit.gestationWeeks! - weeks;
      if (fractional > 0) {
        days = (fractional * 7).round();
      }
    }
  }

  return (weeks, days);
}
