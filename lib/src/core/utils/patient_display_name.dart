/// Canonical patient display-name formatting (see docs/patient-names.md).
library;

String? _trimOrNull(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

/// Prefer API pre-formatted labels when present (list rows, nested patient).
String? preferPatientFormattedName({
  String? patientName,
  String? name,
  String? displayName,
}) {
  for (final candidate in [patientName, name, displayName]) {
    final trimmed = candidate?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  }
  return null;
}

/// Builds a display label from structured patient name fields.
///
/// Joins [firstName], [otherName], [surname]; prefixes [title] when set.
/// Returns [unknownFallback] when nothing remains (default `"Unknown"`).
String formatPatientDisplayName({
  String? title,
  String? firstName,
  String? otherName,
  String? surname,
  String unknownFallback = 'Unknown',
}) {
  final parts = [
    firstName,
    otherName,
    surname,
  ].map(_trimOrNull).whereType<String>().toList();
  var name = parts.join(' ').trim();
  final titleTrimmed = title?.trim();
  if (titleTrimmed != null && titleTrimmed.isNotEmpty) {
    name = '$titleTrimmed $name'.trim();
  }
  if (name.isEmpty) return unknownFallback;
  return name;
}

/// Like [formatPatientDisplayName] but returns `null` when no name parts exist
/// (matches list endpoints where `patientName` may be null).
String? formatPatientDisplayNameOrNull({
  String? title,
  String? firstName,
  String? otherName,
  String? surname,
}) {
  final parts = [
    firstName,
    otherName,
    surname,
  ].map(_trimOrNull).whereType<String>().toList();
  var name = parts.join(' ').trim();
  final titleTrimmed = title?.trim();
  if (titleTrimmed != null && titleTrimmed.isNotEmpty) {
    name = '$titleTrimmed $name'.trim();
  }
  return name.isEmpty ? null : name;
}

/// Resolves a patient label from a JSON map (flat row or nested `patient`).
String patientDisplayNameFromJson(
  Map<String, dynamic>? json, {
  String unknownFallback = 'Unknown',
}) {
  if (json == null) return unknownFallback;

  final preferred = preferPatientFormattedName(
    patientName: json['patientName']?.toString(),
    name: json['name']?.toString(),
    displayName: json['displayName']?.toString(),
  );
  if (preferred != null) return preferred;

  return formatPatientDisplayName(
    title: json['title']?.toString(),
    firstName: json['firstName']?.toString(),
    otherName: json['otherName']?.toString(),
    surname: (json['surname'] ?? json['lastName'] ?? json['last_name'])
        ?.toString(),
    unknownFallback: unknownFallback,
  );
}

/// Nullable variant for list rows where absent names stay null.
String? patientDisplayNameFromJsonOrNull(Map<String, dynamic>? json) {
  if (json == null) return null;

  final preferred = preferPatientFormattedName(
    patientName: json['patientName']?.toString(),
    name: json['name']?.toString(),
    displayName: json['displayName']?.toString(),
  );
  if (preferred != null) return preferred;

  return formatPatientDisplayNameOrNull(
    title: json['title']?.toString(),
    firstName: json['firstName']?.toString(),
    otherName: json['otherName']?.toString(),
    surname: (json['surname'] ?? json['lastName'] ?? json['last_name'])
        ?.toString(),
  );
}
