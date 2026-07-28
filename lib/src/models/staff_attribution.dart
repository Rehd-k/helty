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

  // Root-level person fields when [json] is already a staff/doctor object.
  final rootFirst = _str(json['firstName'] ?? json['first_name']);
  final rootLast = _str(
    json['surname'] ?? json['lastName'] ?? json['last_name'],
  );
  final rootCombined = [rootFirst, rootLast].where((s) => s.isNotEmpty).join(' ');
  if (rootCombined.isNotEmpty) return rootCombined;
  final rootDisplay = _str(json['displayName'] ?? json['name']);
  if (rootDisplay.isNotEmpty) return rootDisplay;

  return '';
}

/// Formats a nested staff / createdBy person map as `First Last`.
///
/// Returns null when [staff] is null or has no usable name fields.
String? formatStaffName(Map<String, dynamic>? staff) {
  if (staff == null) return null;
  final first = _str(staff['firstName'] ?? staff['first_name']).trim();
  final last = _str(
    staff['surname'] ?? staff['lastName'] ?? staff['last_name'],
  ).trim();
  final name = '$first $last'.trim();
  if (name.isNotEmpty) return name;
  final display = _str(staff['displayName'] ?? staff['name']).trim();
  return display.isEmpty ? null : display;
}

/// Label like `Created by: Jane Okonkwo` from a record that may contain nested
/// `createdBy`. Returns null when creator is missing or has no name.
String? createdByLabel(
  Map<String, dynamic>? record, {
  String prefix = 'Created by',
}) {
  return staffRefLabel(record, 'createdBy', prefix: prefix);
}

/// Label from an arbitrary nested staff ref field (`updatedBy`, `requestedBy`,
/// `reportedBy`, `uploadedBy`, etc.). Returns null when missing or empty.
String? staffRefLabel(
  Map<String, dynamic>? record,
  String field, {
  required String prefix,
}) {
  if (record == null) return null;
  final raw = record[field];
  if (raw is String) {
    final t = raw.trim();
    return t.isEmpty ? null : '$prefix: $t';
  }
  final name = formatStaffName(_asMap(raw));
  return name == null ? null : '$prefix: $name';
}

/// Muted caption for creator/updater text. Builds nothing when [label] is null.
class CreatedByCaption extends StatelessWidget {
  const CreatedByCaption({
    super.key,
    this.label,
    this.style,
  });

  final String? label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final text = label?.trim();
    if (text == null || text.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Text(
      text,
      style: style ??
          theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
    );
  }
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

/// Reads logged-in staff id from [InpatientViewScope] without side effects.
/// Safe to call during [build].
String? nurseIdFromScope(BuildContext context) {
  final id = InpatientViewScope.of(context)?.staffId?.trim();
  if (id != null && id.isNotEmpty) return id;
  return null;
}

/// Returns logged-in staff id from [InpatientViewScope], or null after showing a SnackBar.
///
/// Use only from user-action callbacks (not during [build]).
String? requireNurseIdFromScope(BuildContext context) {
  final id = nurseIdFromScope(context);
  if (id != null) return id;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please log in as staff to record documentation.'),
      ),
    );
  });
  return null;
}
