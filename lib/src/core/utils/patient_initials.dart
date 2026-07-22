import '../../services/api_service.dart';

/// Builds patient initials from structured name fields (see docs/frontend-patient-avatar.md).
String patientInitials({
  String? firstName,
  String? surname,
  String? displayName,
}) {
  final a = firstName?.trim().isNotEmpty == true
      ? firstName!.trim()[0].toUpperCase()
      : '';
  final b = surname?.trim().isNotEmpty == true
      ? surname!.trim()[0].toUpperCase()
      : '';
  if (a.isNotEmpty || b.isNotEmpty) return '$a$b';

  final parts =
      (displayName ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  if (parts.isNotEmpty) {
    return parts.first[0].toUpperCase();
  }
  return '?';
}

/// Parses optional `avatarUrl` from API JSON (`null` when absent or empty).
String? avatarUrlFromJson(Map<String, dynamic>? json) {
  if (json == null) return null;
  final url = json['avatarUrl']?.toString().trim();
  if (url == null || url.isEmpty) return null;
  return url;
}

/// Turns a stored or API `avatarUrl` into an absolute URL for [Image.network].
///
/// Absolute `http(s)` values are returned as-is. Relative paths (e.g.
/// `/uploads/patients/.../avatar.jpg`) are joined with [baseUrl], which defaults
/// to [ApiService.apiBaseUrl] so the origin follows endpoint probing.
String? resolvePatientAvatarUrl(String? avatarUrl, {String? baseUrl}) {
  final trimmed = avatarUrl?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  final lower = trimmed.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    return trimmed;
  }

  final origin = (baseUrl ?? ApiService().apiBaseUrl).trim();
  if (origin.isEmpty) return trimmed;

  final base = origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin;
  final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return '$base$path';
}
