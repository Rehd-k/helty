import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Hospital wall-clock timezone — always Africa/Lagos regardless of device TZ.
class AppTimezone {
  AppTimezone._();

  static const locationName = 'Africa/Lagos';

  static late final tz.Location _location;
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    _location = tz.getLocation(locationName);
    _initialized = true;
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError(
        'AppTimezone not initialized. Call AppTimezone.initialize() in main().',
      );
    }
  }

  /// Current instant as Lagos wall time.
  static tz.TZDateTime now() {
    _ensureInitialized();
    return tz.TZDateTime.now(_location);
  }

  /// Convert any [DateTime] instant to Lagos wall time.
  static tz.TZDateTime toLocal(DateTime dt) {
    _ensureInitialized();
    final utc = dt.isUtc ? dt : dt.toUtc();
    return tz.TZDateTime.from(utc, _location);
  }

  /// Lagos wall time → UTC [DateTime] for API payloads.
  static DateTime toUtc(DateTime lagosWall) {
    _ensureInitialized();
    if (lagosWall is tz.TZDateTime && lagosWall.location == _location) {
      return lagosWall.toUtc();
    }
    final tzDt = tz.TZDateTime(
      _location,
      lagosWall.year,
      lagosWall.month,
      lagosWall.day,
      lagosWall.hour,
      lagosWall.minute,
      lagosWall.second,
      lagosWall.millisecond,
      lagosWall.microsecond,
    );
    return tzDt.toUtc();
  }

  /// Lagos wall time → ISO-8601 UTC string for backend.
  static String toBackendIso(DateTime lagosWall) =>
      toUtc(lagosWall).toIso8601String();

  /// Start of calendar day in Lagos (00:00:00.000).
  static tz.TZDateTime startOfDay([DateTime? day]) {
    final d = day != null ? toLocal(day) : now();
    return tz.TZDateTime(_location, d.year, d.month, d.day);
  }

  /// End of calendar day in Lagos (23:59:59.999).
  static tz.TZDateTime endOfDay([DateTime? day]) {
    final d = day != null ? toLocal(day) : now();
    return tz.TZDateTime(
      _location,
      d.year,
      d.month,
      d.day,
      23,
      59,
      59,
      999,
    );
  }

  /// Lagos wall time from calendar components (e.g. date/time picker values).
  static tz.TZDateTime dateTime(
    int year,
    int month,
    int day, [
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
  ]) {
    _ensureInitialized();
    return tz.TZDateTime(
      _location,
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
    );
  }

  /// Combine a calendar [date] and [time] as Lagos wall time.
  static tz.TZDateTime combineDateAndTime(DateTime date, TimeOfDay time) {
    return dateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  /// `yyyy-MM-dd` in Lagos for API date-only fields.
  static String dateOnlyKey(DateTime dt) {
    final local = toLocal(dt);
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  /// Whether [instant] falls on today's calendar date in Lagos.
  static bool isToday(DateTime instant) {
    final local = toLocal(instant);
    final today = now();
    return local.year == today.year &&
        local.month == today.month &&
        local.day == today.day;
  }

  /// Parse user time input on a Lagos calendar date.
  ///
  /// Accepts `2:30 PM`, `02:30 pm`, `2:30PM`, or 24h `14:30`.
  /// Returns `null` when input is empty or invalid.
  static tz.TZDateTime? parseTimeOnDate(String text, tz.TZDateTime onDate) {
    _ensureInitialized();
    final t = text.trim();
    if (t.isEmpty) return null;

    final normalized = t.replaceAll(RegExp(r'\s+'), ' ');

    final match12 = RegExp(
      r'^(\d{1,2}):(\d{2})\s*(am|pm|a\.m\.|p\.m\.)$',
      caseSensitive: false,
    ).firstMatch(normalized);

    if (match12 != null) {
      var hour = int.parse(match12.group(1)!);
      final minute = int.parse(match12.group(2)!);
      final period = match12.group(3)!.toLowerCase().replaceAll('.', '');
      if (minute < 0 || minute > 59) return null;
      if (hour < 1 || hour > 12) return null;
      final isPm = period == 'pm';
      if (hour == 12) {
        hour = isPm ? 12 : 0;
      } else if (isPm) {
        hour += 12;
      }
      return tz.TZDateTime(
        _location,
        onDate.year,
        onDate.month,
        onDate.day,
        hour,
        minute,
      );
    }

    final match24 = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(normalized);
    if (match24 != null) {
      final hour = int.parse(match24.group(1)!);
      final minute = int.parse(match24.group(2)!);
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      return tz.TZDateTime(
        _location,
        onDate.year,
        onDate.month,
        onDate.day,
        hour,
        minute,
      );
    }

    return null;
  }
}
