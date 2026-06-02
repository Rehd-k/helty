import 'package:flutter/material.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';

/// Summary data for pregnancy list/detail at-a-glance UI.
class PregnancyAtAGlance {
  const PregnancyAtAGlance({
    this.gestationalWeeks,
    this.daysUntilEdd,
    this.visitCount,
    this.deliveryCount,
    this.lastBp,
    this.lastFhr,
    this.lastPresentation,
    this.lastVisitDate,
  });

  final int? gestationalWeeks;
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
  final gaWeeks = latest?.gestationWeeks?.round() ?? gaFromLmp;

  String? lastBp;
  if (latest?.systolicBP != null && latest?.diastolicBP != null) {
    lastBp = '${latest!.systolicBP}/${latest.diastolicBP}';
  }

  return PregnancyAtAGlance(
    gestationalWeeks: gaWeeks,
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

bool urineProteinPositive(String? urineProtein) {
  if (urineProtein == null || urineProtein.isEmpty) return false;
  final v = urineProtein.toLowerCase();
  return v.contains('+') ||
      v.contains('positive') ||
      v == 'pos' ||
      v == '1' ||
      v == '2' ||
      v == '3';
}
