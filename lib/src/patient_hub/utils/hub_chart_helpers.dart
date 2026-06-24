import 'package:intl/intl.dart';

import '../models/patient_hub_models.dart';

DateTime? hubParseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v.toString());
}

String? hubFormatDate(dynamic v) {
  final dt = hubParseDate(v);
  if (dt == null) return null;
  return DateFormat.yMMMd().add_jm().format(dt.toLocal());
}

List<Map<String, dynamic>> hubSortRows(
  List<Map<String, dynamic>> rows,
  HubSortOrder order, {
  List<String> dateKeys = const [
    'createdAt',
    'recordedAt',
    'encounterDate',
    'admissionDate',
    'orderedAt',
    'occurredAt',
  ],
}) {
  final copy = List<Map<String, dynamic>>.from(rows);
  copy.sort((a, b) {
    DateTime? da;
    DateTime? db;
    for (final k in dateKeys) {
      da ??= hubParseDate(a[k]);
      db ??= hubParseDate(b[k]);
    }
    da ??= DateTime.fromMillisecondsSinceEpoch(0);
    db ??= DateTime.fromMillisecondsSinceEpoch(0);
    return order == HubSortOrder.newestFirst
        ? db.compareTo(da)
        : da.compareTo(db);
  });
  return copy;
}

bool hubRowInDateRange(
  Map<String, dynamic> row,
  PatientHubDateRange range, {
  List<String> dateKeys = const [
    'createdAt',
    'recordedAt',
    'encounterDate',
    'admissionDate',
    'orderedAt',
    'occurredAt',
  ],
}) {
  if (range.from == null && range.to == null) return true;
  DateTime? dt;
  for (final k in dateKeys) {
    dt ??= hubParseDate(row[k]);
  }
  if (dt == null) return true;
  if (range.from != null && dt.isBefore(range.from!)) return false;
  if (range.to != null && dt.isAfter(range.to!)) return false;
  return true;
}

List<Map<String, dynamic>> hubFilterByDateRange(
  List<Map<String, dynamic>> rows,
  PatientHubDateRange range,
) {
  return rows.where((r) => hubRowInDateRange(r, range)).toList();
}

String hubRowTitle(String sectionKey, Map<String, dynamic> item) {
  switch (sectionKey) {
    case 'encounters':
      return item['chiefComplaint']?.toString() ??
          item['encounterType']?.toString() ??
          item['type']?.toString() ??
          'Encounter';
    case 'admissions':
      return item['ward'] is Map
          ? (item['ward'] as Map)['name']?.toString() ?? 'Admission'
          : 'Admission';
    case 'vitals':
      return hubFormatDate(item['recordedAt'] ?? item['createdAt']) ?? 'Vitals';
    case 'allergies':
      return item['name']?.toString() ??
          item['substance']?.toString() ??
          'Allergy';
    default:
      return item['title']?.toString() ??
          item['name']?.toString() ??
          item['drugName']?.toString() ??
          item['testName']?.toString() ??
          item['procedureName']?.toString() ??
          sectionKey;
  }
}

String? hubRowSubtitle(Map<String, dynamic> item) {
  final parts = <String>[];
  final date = hubFormatDate(
    item['createdAt'] ??
        item['encounterDate'] ??
        item['admissionDate'] ??
        item['orderedAt'] ??
        item['occurredAt'] ??
        item['recordedAt'],
  );
  if (date != null) parts.add(date);

  final status = item['status']?.toString();
  if (status != null && status.isNotEmpty) parts.add(status);

  final notes = item['notes']?.toString() ?? item['findings']?.toString();
  if (notes != null && notes.isNotEmpty) parts.add(notes);

  return parts.isEmpty ? null : parts.join(' · ');
}

double? hubParseDouble(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}
