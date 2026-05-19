import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_service.dart';

/// Builds URLs for `/helty-desktop/*` on the **same host** as the REST API ([ApiService.apiBaseUrl]),
/// ignoring any path prefix on that base (e.g. `/api`). See `docs/flutter-helty-desktop-updater.md`.
Uri heltyDesktopBaseUri() {
  final raw = ApiService().apiBaseUrl.trim();
  final api = Uri.parse(
    raw.isEmpty ? kApiCandidateBaseUrls.first : raw,
  );
  return Uri(
    scheme: api.scheme,
    host: api.host,
    port: api.hasPort ? api.port : null,
    path: '/helty-desktop/',
  );
}

/// Public desktop-update endpoints (no auth); do not use [ApiService.dio] (interceptors).
class HeltyDesktopUpdateService {
  HeltyDesktopUpdateService._();

  /// Last failure for UI (version check). Cleared on successful check start.
  static String? lastVersionCheckMessage;

  /// Called from [HeltyDesktopUpdateLayer] so the title bar can trigger a re-check.
  static void Function()? checkForUpdate;

  static Uri _uri(String relativePath) => heltyDesktopBaseUri().resolve(
    relativePath.replaceFirst(RegExp(r'^/+'), ''),
  );

  static const _fetchTimeout = Duration(seconds: 30);
  static final _semverCorePattern = RegExp(r'^\d+\.\d+\.\d+$');

  static String _toSemverCore(String raw) => raw.split('+').first.trim();

  /// Latest semver from `GET /helty-desktop/update/latest`, or `null` if **404** (no release yet).
  static Future<String?> fetchLatestVersion() async {
    lastVersionCheckMessage = null;
    final uri = _uri('update/latest');
    try {
      final r = await http
          .get(uri)
          .timeout(
            _fetchTimeout,
            onTimeout: () => throw TimeoutException('Request timed out'),
          );
      if (r.statusCode == 404) {
        return null;
      }
      if (r.statusCode != 200) {
        lastVersionCheckMessage =
            'Update server returned HTTP ${r.statusCode} for ${uri.path}. '
            'Ask your administrator that a desktop build is published, or try again later.';
        throw Exception(lastVersionCheckMessage);
      }
      Map<String, dynamic> map;
      try {
        final decoded = jsonDecode(r.body);
        if (decoded is! Map<String, dynamic>) {
          throw FormatException('Expected a JSON object');
        }
        map = decoded;
      } on FormatException catch (e) {
        lastVersionCheckMessage =
            'Update server sent invalid JSON (${e.message}). The API base URL may point at the wrong server.';
        throw Exception(lastVersionCheckMessage);
      }
      final v = map['version'];
      if (v is! String || v.isEmpty) {
        lastVersionCheckMessage =
            'Update server response is missing a "version" field. Check the Helty desktop API configuration.';
        throw Exception(lastVersionCheckMessage);
      }
      return v;
    } on TimeoutException {
      lastVersionCheckMessage =
          'Connection to the update server timed out after ${_fetchTimeout.inSeconds}s. '
          'Check that the machine can reach ${uri.host}${uri.hasPort ? ':${uri.port}' : ''} '
          'and that the API address in the app matches your server.';
      throw Exception(lastVersionCheckMessage);
    } on SocketException catch (e) {
      lastVersionCheckMessage =
          'No network route to the update server (${uri.host}). '
          'Verify Wi‑Fi or Ethernet, firewall rules, and that the API URL in the app is correct. '
          '(${e.message})';
      throw Exception(lastVersionCheckMessage);
    } on HandshakeException catch (e) {
      lastVersionCheckMessage =
          'Secure connection to ${uri.host} failed (TLS). '
          'If you use HTTPS, ensure the certificate is valid. (${e.message})';
      throw Exception(lastVersionCheckMessage);
    } on http.ClientException catch (e) {
      lastVersionCheckMessage =
          'Could not reach ${uri.origin}${uri.path} — ${e.message}';
      throw Exception(lastVersionCheckMessage);
    } catch (e) {
      lastVersionCheckMessage ??=
          'Unexpected error while checking for updates: $e';
      throw Exception(lastVersionCheckMessage);
    }
  }

  /// [updat] must not receive a permanently null latest string (would leave UI stuck on "checking").
  static Future<String?> getLatestVersionForUpdat(String currentVersion) async {
    try {
      final latest = await fetchLatestVersion();
      final currentCore = _toSemverCore(currentVersion);
      if (!_semverCorePattern.hasMatch(currentCore)) {
        lastVersionCheckMessage =
            'Installed app version "$currentVersion" is not a supported semantic version. '
            'Expected format like 1.0.0.';
        throw Exception(lastVersionCheckMessage);
      }
      if (latest == null) return currentCore;
      final latestCore = _toSemverCore(latest);
      if (!_semverCorePattern.hasMatch(latestCore)) {
        lastVersionCheckMessage =
            'Update server returned an unsupported version "$latest". '
            'Expected format like 1.0.0 (optional +build is allowed).';
        throw Exception(lastVersionCheckMessage);
      }

      return latestCore;
    } catch (e) {
      lastVersionCheckMessage ??=
          'Unexpected error while preparing version info: $e';
      throw Exception(lastVersionCheckMessage);
    }
  }

  static Future<String> getBinaryDownloadUrl(String? latestVersion) async {
    return _uri('download/latest').toString();
  }

  static void triggerCheckFromUi() => checkForUpdate?.call();
}
