/// Builds patient initials from structured name fields (see docs/patient-avatar-frontend.md).
String patientInitials({
  String? firstName,
  String? surname,
}) {
  final a = firstName?.trim().isNotEmpty == true
      ? firstName!.trim()[0].toUpperCase()
      : '';
  final b = surname?.trim().isNotEmpty == true
      ? surname!.trim()[0].toUpperCase()
      : '';
  final initials = '$a$b';
  return initials.isEmpty ? '?' : initials;
}

/// Parses optional `avatarUrl` from API JSON (`null` when absent or empty).
String? avatarUrlFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  final url = json['avatarUrl']?.toString().trim();
  if (url == null || url.isEmpty) return null;
  return url;
}
