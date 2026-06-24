enum DialysisEncounterStatusFilter { all, ongoing, completed, cancelled }

DateTime? encounterDateFromMap(Map<String, dynamic> item) {
  for (final key in ['closedAt', 'startedAt', 'encounterDate', 'createdAt']) {
    final dt = DateTime.tryParse(item[key]?.toString() ?? '');
    if (dt != null) return dt;
  }
  return null;
}

String encounterIdFromMap(Map<String, dynamic> item) =>
    item['id']?.toString() ?? item['encounterId']?.toString() ?? '';

List<Map<String, dynamic>> sortEncountersNewestFirst(
  List<Map<String, dynamic>> encounters,
) {
  final sorted = List<Map<String, dynamic>>.from(encounters);
  sorted.sort((a, b) {
    final da = encounterDateFromMap(a);
    final db = encounterDateFromMap(b);
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return db.compareTo(da);
  });
  return sorted;
}

List<Map<String, dynamic>> filterEncountersByStatus(
  List<Map<String, dynamic>> encounters,
  DialysisEncounterStatusFilter filter,
) {
  if (filter == DialysisEncounterStatusFilter.all) return encounters;
  return encounters.where((item) {
    final status = item['status']?.toString().toUpperCase() ?? '';
    switch (filter) {
      case DialysisEncounterStatusFilter.ongoing:
        return status == 'ONGOING';
      case DialysisEncounterStatusFilter.completed:
        return status == 'COMPLETED';
      case DialysisEncounterStatusFilter.cancelled:
        return status == 'CANCELLED';
      case DialysisEncounterStatusFilter.all:
        return true;
    }
  }).toList();
}

bool encounterInDateRange(
  Map<String, dynamic> item,
  DateTime rangeStart,
  DateTime rangeEnd,
) {
  final date = encounterDateFromMap(item);
  if (date == null) return true;
  final start = DateTime(rangeStart.year, rangeStart.month, rangeStart.day);
  final end = DateTime(
    rangeEnd.year,
    rangeEnd.month,
    rangeEnd.day,
    23,
    59,
    59,
    999,
  );
  return !date.isBefore(start) && !date.isAfter(end);
}

List<Map<String, dynamic>> filterEncountersByDateRange(
  List<Map<String, dynamic>> encounters,
  DateTime rangeStart,
  DateTime rangeEnd,
) {
  return encounters
      .where((item) => encounterInDateRange(item, rangeStart, rangeEnd))
      .toList();
}

String? encounterNotesPreviewFromMap(Map<String, dynamic> item) {
  final triage = item['triageNotes']?.toString().trim();
  if (triage != null && triage.isNotEmpty) return triage;
  return null;
}

(DateTime, DateTime) defaultDialysisEncounterDateRange() {
  final now = DateTime.now();
  final end = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
  final start = DateTime(now.year, now.month, now.day).subtract(
    const Duration(days: 90),
  );
  return (start, end);
}
