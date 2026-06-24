import 'dart:math' as math;

/// Shared prescribing / MAR scheduling helpers.
/// Frequency → doses/day, duration → days, next-dose computation.

class RxFrequency {
  const RxFrequency(this.label, this.dosesPerDay, {this.intervalHours});
  final String label;

  /// Average doses per 24h period (weekly frequencies use fractions).
  final double dosesPerDay;

  /// Fixed interval for Q4H/Q6H/Q8H/Q12H; null for spread-daily dosing.
  final double? intervalHours;
}

const List<RxFrequency> kRxFrequencies = <RxFrequency>[
  RxFrequency('Once daily (OD)', 1, intervalHours: 24),
  RxFrequency('Twice daily (BD / BID)', 2, intervalHours: 12),
  RxFrequency('Three times daily (TDS / TID)', 3, intervalHours: 8),
  RxFrequency('Four times daily (QID)', 4, intervalHours: 6),
  RxFrequency('Five times daily', 5, intervalHours: 24 / 5),
  RxFrequency('Every 12 hours (Q12H)', 2, intervalHours: 12),
  RxFrequency('Every 8 hours (Q8H)', 3, intervalHours: 8),
  RxFrequency('Every 6 hours (Q6H)', 4, intervalHours: 6),
  RxFrequency('Every 4 hours (Q4H)', 6, intervalHours: 4),
  RxFrequency('At bedtime (HS)', 1, intervalHours: 24),
  RxFrequency('Morning only (OM)', 1, intervalHours: 24),
  RxFrequency('Once weekly', 1 / 7, intervalHours: 168),
  RxFrequency('Twice weekly', 2 / 7, intervalHours: 84),
  RxFrequency('Three times weekly', 3 / 7, intervalHours: 56),
  RxFrequency('As needed (PRN) — estimate 1/day', 1, intervalHours: 24),
];

enum RxDurationUnit {
  days('Days'),
  weeks('Weeks'),
  months('Months'),
  years('Years'),
  hours('Hours');

  const RxDurationUnit(this.label);
  final String label;

  /// API enum value (matches backend `RxDurationUnit`).
  String get apiValue => name.toUpperCase();

  static RxDurationUnit? fromApi(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    switch (raw.toUpperCase()) {
      case 'DAYS':
        return RxDurationUnit.days;
      case 'WEEKS':
        return RxDurationUnit.weeks;
      case 'MONTHS':
        return RxDurationUnit.months;
      case 'YEARS':
        return RxDurationUnit.years;
      case 'HOURS':
        return RxDurationUnit.hours;
      default:
        return null;
    }
  }
}

enum MedicationScheduleStatus {
  notStarted,
  active,
  dueSoon,
  overdue,
  expired,
  stopped;

  static MedicationScheduleStatus fromApi(String? raw) {
    if (raw == null || raw.isEmpty) return MedicationScheduleStatus.notStarted;
    switch (raw.toUpperCase()) {
      case 'ACTIVE':
        return MedicationScheduleStatus.active;
      case 'DUE_SOON':
        return MedicationScheduleStatus.dueSoon;
      case 'OVERDUE':
        return MedicationScheduleStatus.overdue;
      case 'EXPIRED':
        return MedicationScheduleStatus.expired;
      case 'STOPPED':
        return MedicationScheduleStatus.stopped;
      case 'NOT_STARTED':
      default:
        return MedicationScheduleStatus.notStarted;
    }
  }

  String get apiValue => switch (this) {
        MedicationScheduleStatus.notStarted => 'NOT_STARTED',
        MedicationScheduleStatus.active => 'ACTIVE',
        MedicationScheduleStatus.dueSoon => 'DUE_SOON',
        MedicationScheduleStatus.overdue => 'OVERDUE',
        MedicationScheduleStatus.expired => 'EXPIRED',
        MedicationScheduleStatus.stopped => 'STOPPED',
      };

  String get label => switch (this) {
        MedicationScheduleStatus.notStarted => 'Not started',
        MedicationScheduleStatus.active => 'Active',
        MedicationScheduleStatus.dueSoon => 'Due soon',
        MedicationScheduleStatus.overdue => 'Overdue',
        MedicationScheduleStatus.expired => 'Course expired',
        MedicationScheduleStatus.stopped => 'Stopped',
      };

  bool get isDueAttention =>
      this == MedicationScheduleStatus.dueSoon ||
      this == MedicationScheduleStatus.overdue;
}

/// Default window before [nextDueAt] when status becomes DUE_SOON.
const Duration kDueSoonWindow = Duration(minutes: 30);

double rxDurationToDays(int value, RxDurationUnit unit) {
  switch (unit) {
    case RxDurationUnit.days:
      return value.toDouble();
    case RxDurationUnit.weeks:
      return value * 7.0;
    case RxDurationUnit.months:
      return value * 30.0;
    case RxDurationUnit.years:
      return value * 365.0;
    case RxDurationUnit.hours:
      return value / 24.0;
  }
}

Duration rxDurationToDuration(int value, RxDurationUnit unit) {
  switch (unit) {
    case RxDurationUnit.days:
      return Duration(days: value);
    case RxDurationUnit.weeks:
      return Duration(days: value * 7);
    case RxDurationUnit.months:
      return Duration(days: value * 30);
    case RxDurationUnit.years:
      return Duration(days: value * 365);
    case RxDurationUnit.hours:
      return Duration(hours: value);
  }
}

String formatRxDurationPhrase(int value, RxDurationUnit unit) {
  if (value <= 0) return '';
  String noun(RxDurationUnit u) {
    switch (u) {
      case RxDurationUnit.days:
        return value == 1 ? 'day' : 'days';
      case RxDurationUnit.weeks:
        return value == 1 ? 'week' : 'weeks';
      case RxDurationUnit.months:
        return value == 1 ? 'month' : 'months';
      case RxDurationUnit.years:
        return value == 1 ? 'year' : 'years';
      case RxDurationUnit.hours:
        return value == 1 ? 'hour' : 'hours';
    }
  }

  return '$value ${noun(unit)}';
}

int computedPrescriptionQuantity({
  required RxFrequency frequency,
  required int durationValue,
  required RxDurationUnit durationUnit,
}) {
  if (durationValue <= 0) return 0;
  final days = rxDurationToDays(durationValue, durationUnit);
  if (days <= 0) return 0;
  final raw = frequency.dosesPerDay * days;
  if (raw <= 0) return 1;
  return math.max(1, raw.ceil());
}

({int value, RxDurationUnit unit})? parseRxDurationPhrase(String raw) {
  final s = raw.trim();
  if (s.isEmpty || s == '—') return null;
  final m = RegExp(
    r'^(\d+)\s*(day|days|week|weeks|month|months|year|years|hour|hours)$',
    caseSensitive: false,
  ).firstMatch(s);
  if (m == null) return null;
  final value = int.tryParse(m.group(1)!);
  if (value == null || value <= 0) return null;
  final unitWord = m.group(2)!.toLowerCase();
  final unit = switch (unitWord) {
    'day' || 'days' => RxDurationUnit.days,
    'week' || 'weeks' => RxDurationUnit.weeks,
    'month' || 'months' => RxDurationUnit.months,
    'year' || 'years' => RxDurationUnit.years,
    'hour' || 'hours' => RxDurationUnit.hours,
    _ => null,
  };
  if (unit == null) return null;
  return (value: value, unit: unit);
}

RxFrequency matchRxFrequency(String raw) {
  final t = raw.trim();
  if (t.isEmpty || t == '—') return kRxFrequencies[1];
  for (final f in kRxFrequencies) {
    if (f.label == t) return f;
  }
  final lower = t.toLowerCase();
  for (final f in kRxFrequencies) {
    if (f.label.toLowerCase() == lower) return f;
  }
  if (lower.contains('q4h') || lower.contains('every 4 hour')) {
    return kRxFrequencies[8];
  }
  if (lower.contains('q6h') || lower.contains('every 6 hour')) {
    return kRxFrequencies[7];
  }
  if (lower.contains('q8h') || lower.contains('every 8 hour')) {
    return kRxFrequencies[6];
  }
  if (lower.contains('q12h') || lower.contains('every 12 hour')) {
    return kRxFrequencies[5];
  }
  if (lower.contains('qid') || lower.contains('four times')) {
    return kRxFrequencies[3];
  }
  if (lower.contains('tds') ||
      lower.contains('tid') ||
      lower.contains('three times')) {
    return kRxFrequencies[2];
  }
  if (lower.contains('bd') ||
      lower.contains('bid') ||
      lower.contains('twice')) {
    return kRxFrequencies[1];
  }
  if (lower.contains('od') || lower.contains('once daily')) {
    return kRxFrequencies[0];
  }
  if (lower.contains('once weekly')) return kRxFrequencies[11];
  if (lower.contains('twice weekly')) return kRxFrequencies[12];
  if (lower.contains('three times weekly')) return kRxFrequencies[13];
  if (lower.contains('prn')) return kRxFrequencies.last;
  return kRxFrequencies[1];
}

/// Hours between doses for [frequency].
double resolveIntervalHours(RxFrequency frequency) {
  if (frequency.intervalHours != null) return frequency.intervalHours!;
  if (frequency.dosesPerDay >= 1) return 24 / frequency.dosesPerDay;
  // Weekly: interval in hours = 168 / doses per week
  return 168 / (frequency.dosesPerDay * 7);
}

/// Next dose time after [lastGivenAt] based on [frequency].
DateTime computeNextDueAt({
  required DateTime lastGivenAt,
  required RxFrequency frequency,
}) {
  final hours = resolveIntervalHours(frequency);
  final wholeHours = hours.floor();
  final fractionalMinutes = ((hours - wholeHours) * 60).round();
  return lastGivenAt.add(
    Duration(hours: wholeHours, minutes: fractionalMinutes),
  );
}

/// Course end from first dose + duration phrase on order.
DateTime? computeCourseEndsAt({
  required DateTime scheduleStartedAt,
  String? durationPhrase,
  int? durationValue,
  RxDurationUnit? durationUnit,
}) {
  int? value = durationValue;
  RxDurationUnit? unit = durationUnit;
  if (value == null || unit == null) {
    final parsed = parseRxDurationPhrase(durationPhrase ?? '');
    if (parsed == null) return null;
    value = parsed.value;
    unit = parsed.unit;
  }
  return scheduleStartedAt.add(rxDurationToDuration(value, unit));
}

/// Client-side schedule status (mirrors backend when API unavailable).
MedicationScheduleStatus computeScheduleStatus({
  required DateTime now,
  DateTime? scheduleStartedAt,
  DateTime? courseEndsAt,
  DateTime? nextDueAt,
  bool administrationStopped = false,
  bool hasBeyondDurationConsent = false,
  Duration dueSoonWindow = kDueSoonWindow,
}) {
  if (administrationStopped) return MedicationScheduleStatus.stopped;
  if (courseEndsAt != null &&
      now.isAfter(courseEndsAt) &&
      !hasBeyondDurationConsent) {
    return MedicationScheduleStatus.expired;
  }
  if (scheduleStartedAt == null) return MedicationScheduleStatus.notStarted;
  if (nextDueAt != null) {
    if (now.isAfter(nextDueAt)) return MedicationScheduleStatus.overdue;
    if (nextDueAt.difference(now) <= dueSoonWindow) {
      return MedicationScheduleStatus.dueSoon;
    }
  }
  return MedicationScheduleStatus.active;
}

/// Optimistic schedule update after recording a GIVEN dose.
({
  DateTime scheduleStartedAt,
  DateTime? courseEndsAt,
  DateTime nextDueAt,
  int doseSequenceNumber,
  MedicationScheduleStatus scheduleStatus,
}) applyGivenDoseToSchedule({
  required DateTime actualTime,
  required String frequencyRaw,
  String? durationPhrase,
  int? durationValue,
  RxDurationUnit? durationUnit,
  DateTime? existingScheduleStartedAt,
  int existingDoseSequenceNumber = 0,
  bool administrationStopped = false,
  bool hasBeyondDurationConsent = false,
  DateTime? now,
}) {
  final frequency = matchRxFrequency(frequencyRaw);
  final started = existingScheduleStartedAt ?? actualTime;
  final isFirst = existingScheduleStartedAt == null;
  final sequence = isFirst ? 1 : existingDoseSequenceNumber + 1;
  final courseEnd = computeCourseEndsAt(
    scheduleStartedAt: started,
    durationPhrase: durationPhrase,
    durationValue: durationValue,
    durationUnit: durationUnit,
  );
  final nextDue = computeNextDueAt(lastGivenAt: actualTime, frequency: frequency);
  final status = computeScheduleStatus(
    now: now ?? actualTime,
    scheduleStartedAt: started,
    courseEndsAt: courseEnd,
    nextDueAt: nextDue,
    administrationStopped: administrationStopped,
    hasBeyondDurationConsent: hasBeyondDurationConsent,
  );
  return (
    scheduleStartedAt: started,
    courseEndsAt: courseEnd,
    nextDueAt: nextDue,
    doseSequenceNumber: sequence,
    scheduleStatus: status,
  );
}
