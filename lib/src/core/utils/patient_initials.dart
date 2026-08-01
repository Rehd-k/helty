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

bool _isLoopbackHost(String host) {
  final h = host.toLowerCase();
  return h == 'localhost' || h == '127.0.0.1' || h == '::1';
}

String _stripTrailingSlash(String origin) =>
    origin.endsWith('/') ? origin.substring(0, origin.length - 1) : origin;

/// Turns a stored or API `avatarUrl` into an absolute URL for [Image.network].
///
/// Relative paths (e.g. `/uploads/patients/.../avatar.jpg`) are joined with
/// [baseUrl], which defaults to [ApiService.apiBaseUrl] so the origin follows
/// endpoint probing. Absolute URLs whose host is loopback (`localhost`,
/// `127.0.0.1`, `::1`) are rewritten onto the same probed origin. Other
/// absolute `http(s)` values are returned as-is.
String? resolvePatientAvatarUrl(String? avatarUrl, {String? baseUrl}) {
  final trimmed = avatarUrl?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;

  final origin = (baseUrl ?? ApiService().apiBaseUrl).trim();
  final base = origin.isEmpty ? '' : _stripTrailingSlash(origin);

  final lower = trimmed.toLowerCase();
  if (lower.startsWith('http://') || lower.startsWith('https://')) {
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !_isLoopbackHost(uri.host) || base.isEmpty) {
      return trimmed;
    }
    final baseUri = Uri.tryParse(base);
    if (baseUri == null || baseUri.host.isEmpty) return trimmed;

    // Build a new Uri so a missing base port is not inherited from localhost:3000.
    return Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: uri.path,
      query: uri.hasQuery ? uri.query : null,
      fragment: uri.hasFragment ? uri.fragment : null,
    ).toString();
  }

  if (base.isEmpty) return trimmed;

  final path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
  return '$base$path';
}
