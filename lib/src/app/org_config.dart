import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Organization branding and contact details loaded from `.env`.
///
/// Multi-value fields (`ORG_ADDRESSES`, `ORG_PHONES`, `ORG_EMAILS`,
/// `ORG_TAGLINES`) are split on `;`. Use [contactLine] to join them for
/// display (e.g. PDF headers).
class OrgConfig {
  OrgConfig._({
    required this.name,
    required this.addresses,
    required this.phones,
    required this.emails,
    required this.website,
    required this.apiBaseUrl,
    required this.taglines,
  });

  static OrgConfig? _instance;

  /// Loaded config. Falls back to IMSH defaults if [load] was never called.
  static OrgConfig get instance => _instance ?? OrgConfig.defaults();

  final String name;
  final List<String> addresses;
  final List<String> phones;
  final List<String> emails;
  final String website;
  final String apiBaseUrl;
  final List<String> taglines;

  /// Joins non-empty values with `; ` for PDF / receipt display.
  static String contactLine(List<String> values) =>
      values.map((e) => e.trim()).where((e) => e.isNotEmpty).join('; ');

  String get addressesLine => contactLine(addresses);
  String get phonesLine => contactLine(phones);
  String get emailsLine => contactLine(emails);
  String get taglinesLine => contactLine(taglines);

  static OrgConfig defaults() => OrgConfig._(
        name: 'Ibom Multispecialty Hospital',
        addresses: const ['Ikot Ekpene - Uyo Rd, Uyo, Akwa Ibom'],
        phones: const ['0802 181 4674'],
        emails: const ['info@imsh.ng'],
        website: 'https://imsh.ng',
        apiBaseUrl: '',
        taglines: const [
          'Digital Mammography',
          'Digital X-ray',
          'Special X-ray Investigations',
          'Ultrasound Scan',
          'Automated Laboratory',
          'Comprehensive Health Check',
          'Pap Smear',
          'ECG',
        ],
      );

  /// Loads `.env` when present as an asset, otherwise `.env.example`.
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

  @visibleForTesting
  static void debugSet(OrgConfig config) {
    _instance = config;
  }

  @visibleForTesting
  static void debugReset() {
    _instance = null;
  }
}
