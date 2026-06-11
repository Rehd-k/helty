import 'package:intl/intl.dart';

import 'app_timezone.dart';

class DateFormatter {
  static DateTime _asLagos(DateTime date) => AppTimezone.toLocal(date);

  // 1. Just the date: 23/12/1990
  static String shortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(_asLagos(date));
  }

  // 2. Full readable date: Monday, December 23, 1990
  static String fullDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(_asLagos(date));
  }

  // 3. Date with Time (12h): 23/12/1990 02:30 PM
  static String dateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy hh:mm a').format(_asLagos(date));
  }

  /// Date with time including seconds (12h): 23/12/1990 02:30:05 PM
  static String dateTimeWithSeconds(DateTime date) {
    return DateFormat('dd/MM/yyyy hh:mm:ss a').format(_asLagos(date));
  }

  // 4. Time only: 02:30 PM
  static String timeOnly(DateTime date) {
    return DateFormat('hh:mm a').format(_asLagos(date));
  }

  // 5. Medical Style (e.g., for Patient records): 23 Dec 1990
  static String medicalDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(_asLagos(date));
  }

  /// US-style short date: 4/5/2026 (month/day/year, no leading zeros).
  static String shortNumericUs(DateTime date) {
    return DateFormat('M/d/yyyy').format(_asLagos(date));
  }

  /// Human-readable elapsed time from [past] until [now] (e.g. "3 days ago").
  static String relativeTimeAgo(DateTime past, [DateTime? now]) {
    final clock = now ?? AppTimezone.now();
    if (!past.isBefore(clock)) return 'just now';

    var years = clock.year - past.year;
    if (clock.month < past.month ||
        (clock.month == past.month && clock.day < past.day)) {
      years--;
    }
    if (years >= 1) {
      return years == 1 ? '1 year ago' : '$years years ago';
    }

    var months = (clock.year - past.year) * 12 + clock.month - past.month;
    if (clock.day < past.day) months--;
    if (months >= 1) {
      return months == 1 ? '1 month ago' : '$months months ago';
    }

    final days = clock.difference(past).inDays;
    if (days >= 7) {
      final w = days ~/ 7;
      return w == 1 ? '1 week ago' : '$w weeks ago';
    }
    if (days >= 1) {
      return days == 1 ? '1 day ago' : '$days days ago';
    }

    final hours = clock.difference(past).inHours;
    if (hours >= 1) {
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    }

    final minutes = clock.difference(past).inMinutes;
    if (minutes >= 1) {
      return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
    }

    final seconds = clock.difference(past).inSeconds;
    if (seconds >= 1) {
      return seconds == 1 ? '1 second ago' : '$seconds seconds ago';
    }
    return 'just now';
  }

  /// Helper to parse backend string safely
  /// Returns "N/A" if the date is null or invalid
  static String formatFromBackend(
    String? dateStr,
    String Function(DateTime) formatType,
  ) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr);
      return formatType(dt);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  /// Age for bedside display: years if 1y+, months if under 1y, weeks/days for newborns.
  static String patientAgeFromDob(DateTime dob, [DateTime? now]) {
    final clock = now != null ? AppTimezone.toLocal(now) : AppTimezone.now();
    final lagosDob = _asLagos(dob);
    if (lagosDob.isAfter(clock)) return '0 d';

    var years = clock.year - lagosDob.year;
    if (clock.month < lagosDob.month ||
        (clock.month == lagosDob.month && clock.day < lagosDob.day)) {
      years--;
    }
    if (years >= 1) {
      return years == 1 ? '1 yr' : '$years yrs';
    }

    var months = (clock.year - lagosDob.year) * 12 + clock.month - lagosDob.month;
    if (clock.day < lagosDob.day) months--;
    if (months >= 1) {
      return months == 1 ? '1 mo' : '$months mo';
    }

    final startDay = AppTimezone.startOfDay(lagosDob);
    final today = AppTimezone.startOfDay(clock);
    final days = today.difference(startDay).inDays;
    if (days >= 7) {
      final w = days ~/ 7;
      return w == 1 ? '1 wk' : '$w wks';
    }
    return days <= 0 ? '0 d' : '$days d';
  }

  /// Calendar days from [admissionDate] to today (same calendar day → 0).
  static int calendarDaysSince(DateTime admissionInstant, [DateTime? now]) {
    final clock = now != null ? AppTimezone.toLocal(now) : AppTimezone.now();
    final a = AppTimezone.startOfDay(_asLagos(admissionInstant));
    final n = AppTimezone.startOfDay(clock);
    return n.difference(a).inDays;
  }
}
