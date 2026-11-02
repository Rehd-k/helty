import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Organization branding and contact details loaded from `.env`.
///
/// Multi-value fields (`ORG_ADDRESSES`, `ORG_PHONES`, `ORG_EMAILS`,
/// `ORG_TAGLINES`) are split on `;`. Use [contactLine] to join them for
/// display (e.g. PDF headers). Logo path is `ORG_LOGO` (Flutter asset).
/// Missing keys stay empty. There is no built-in hospital identity.
class OrgConfig {
  const OrgConfig._({
    required this.name,
    required this.addresses,
    required this.phones,
    required this.emails,
    required this.website,
    required this.apiBaseUrl,
    required this.taglines,
    required this.taglinesFromEnv,
    required this.logoAsset,
  });

  static OrgConfig? _instance;

  /// Loaded config. Empty until [load], and empty for any key `.env` omits.
  static OrgConfig get instance => _instance ?? OrgConfig.defaults();

  final String name;
  final List<String> addresses;
  final List<String> phones;
  final List<String> emails;
  final String website;
  final String apiBaseUrl;
  final List<String> taglines;

  /// True only when `.env` sets a non-empty `ORG_TAGLINES`.
  final bool taglinesFromEnv;

  /// Flutter asset path for the org logo on PDFs, receipts, and watermark.
  /// Set via `ORG_LOGO` in `.env`. Empty when unset.
  /// The Helty app chrome (login / sidebar) always uses `assets/logo.png`.
  final String logoAsset;

  /// Joins non-empty values with `; ` for PDF / receipt display.
  static String contactLine(List<String> values) =>
      values.map((e) => e.trim()).where((e) => e.isNotEmpty).join('; ');

  String get addressesLine => contactLine(addresses);
  String get phonesLine => contactLine(phones);
  String get emailsLine => contactLine(emails);
  String get taglinesLine => contactLine(taglines);

  static OrgConfig defaults() => const OrgConfig._(
        name: '',
        addresses: [],
        phones: [],
        emails: [],
        website: '',
        apiBaseUrl: '',
        taglines: [],
        taglinesFromEnv: false,
        logoAsset: '',
      );

  /// Loads `.env` when present as an asset, otherwise the blank `.env.example`.
  /// Missing keys stay empty.
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      try {
        await dotenv.load(fileName: '.env.example');
      } catch (_) {
        _instance = OrgConfig.defaults();
        return;
      }
    }
    _instance = OrgConfig.fromDotenv();
  }

  static OrgConfig fromDotenv() {
    final d = defaults();
    return OrgConfig._(
      name: _string('ORG_NAME', d.name),
      addresses: _list('ORG_ADDRESSES', d.addresses),
      phones: _list('ORG_PHONES', d.phones),
      emails: _list('ORG_EMAILS', d.emails),
      website: _string('ORG_WEBSITE', d.website),
      apiBaseUrl: _string('API_BASE_URL', d.apiBaseUrl),
      taglines: _list('ORG_TAGLINES', d.taglines),
      taglinesFromEnv: _envListIsSet('ORG_TAGLINES'),
      logoAsset: _string('ORG_LOGO', d.logoAsset),
    );
  }

  static String _string(String key, String fallback) {
    final raw = dotenv.maybeGet(key)?.trim();
    if (raw == null || raw.isEmpty) return fallback;
    return raw;
  }

  static List<String> _list(String key, List<String> fallback) {
    final raw = dotenv.maybeGet(key)?.trim();
    if (raw == null || raw.isEmpty) return fallback;
    final parts = raw
        .split(';')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.isEmpty ? fallback : parts;
  }

  /// Whether [key] is present in `.env` with at least one non-empty part.
  static bool _envListIsSet(String key) {
    final raw = dotenv.maybeGet(key)?.trim();
    if (raw == null || raw.isEmpty) return false;
    return raw.split(';').any((part) => part.trim().isNotEmpty);
  }

  @visibleForTesting
  static void debugSet(OrgConfig config) {
    _instance = config;
  }

  @visibleForTesting
  static void debugReset() {
    _instance = null;
  }
}
