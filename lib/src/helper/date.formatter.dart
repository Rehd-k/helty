import 'package:intl/intl.dart';

class DateFormatter {
  // 1. Just the date: 23/12/1990
  static String shortDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // 2. Full readable date: Monday, December 23, 1990
  static String fullDate(DateTime date) {
    return DateFormat('EEEE, MMMM d, yyyy').format(date);
  }

  // 3. Date with Time (24h): 23/12/1990 14:30
  static String dateTime(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  // 4. Time only: 02:30 PM
  static String timeOnly(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  // 5. Medical Style (e.g., for Patient records): 23 Dec 1990
  static String medicalDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Helper to parse backend string safely
  /// Returns "N/A" if the date is null or invalid
  static String formatFromBackend(
    String? dateStr,
    String Function(DateTime) formatType,
  ) {
    if (dateStr == null || dateStr.isEmpty) return 'N/A';
    try {
      DateTime dt = DateTime.parse(dateStr);
      return formatType(dt);
    } catch (e) {
      return 'Invalid Date';
    }
  }
}
