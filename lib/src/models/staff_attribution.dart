import 'package:flutter/material.dart';

import '../nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'staff_model.dart';

Map<String, dynamic>? _asMap(dynamic e) =>
    e is Map ? Map<String, dynamic>.from(e) : null;

String _str(dynamic v) => v?.toString() ?? '';

/// Resolves a staff display name from API JSON (nested nurse/staff or flat fields).
String staffDisplayNameFromJson(Map<String, dynamic> json) {
  final nurseMap =
      _asMap(json['nurse']) ??
      _asMap(json['orderedBy']) ??
      _asMap(json['ordered_by']) ??
      _asMap(json['doctor']) ??
      _asMap(json['recorder']) ??
      _asMap(json['recordedBy']) ??
      _asMap(json['recorded_by']) ??
      _asMap(json['author']) ??
      _asMap(json['createdBy']) ??
      _asMap(json['created_by']);

  Map<String, dynamic>? staff;
  if (nurseMap != null) {
    staff = _asMap(nurseMap['staff']) ?? nurseMap;
  }

  if (staff != null) {
    final first = _str(staff['firstName'] ?? staff['first_name']);
    final last = _str(
      staff['surname'] ?? staff['lastName'] ?? staff['last_name'],
    );
    final combined = [first, last].where((s) => s.isNotEmpty).join(' ');
    if (combined.isNotEmpty) return combined;
    final display = _str(staff['displayName'] ?? staff['name']);
    if (display.isNotEmpty) return display;
  }

  for (final key in [
    'nurseName',
    'doctorName',
    'recordedByName',
    'authorName',
    'recordedBy',
    'author',
    'createdByName',
  ]) {
    final flat = _str(json[key]);
    if (flat.isNotEmpty) return flat;
  }

  return '';
}

/// Display name with department title from a nested staff/createdBy person map.
///
/// [AccountType.physician] → `Dr. …`, [AccountType.pharmacy] → `Pharm. …`, else plain name.
String staffTitledDisplayNameFromPersonMap(Map<String, dynamic>? person) {
  if (person == null) return '';
  final first = _str(person['firstName'] ?? person['first_name']).trim();
  final last = _str(
    person['surname'] ?? person['lastName'] ?? person['last_name'],
  ).trim();
  final name = [first, last].where((s) => s.isNotEmpty).join(' ');
  if (name.isEmpty) {
    final display = _str(person['displayName'] ?? person['name']).trim();
    if (display.isEmpty) return '';
    return _titleForAccountType(
      AccountType.fromString(person['accountType'] as String?),
      display,
    );
  }
  return _titleForAccountType(
    AccountType.fromString(person['accountType'] as String?),
    name,
  );
}

String _titleForAccountType(AccountType accountType, String name) {
  switch (accountType) {
    case AccountType.physician:
      return 'Dr. $name';
    case AccountType.pharmacy:
      return 'Pharm. $name';
    default:
      return name;
  }
}

/// Returns logged-in staff id from [InpatientViewScope], or null after showing a SnackBar.
String? requireNurseIdFromScope(BuildContext context) {
  final id = InpatientViewScope.of(context)?.staffId?.trim();
  if (id != null && id.isNotEmpty) return id;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Please log in as staff to record documentation.'),
    ),
  );
  return null;
}
