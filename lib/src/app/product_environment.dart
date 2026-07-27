import 'package:flutter/foundation.dart';

import 'api_candidates.dart';
import 'org_config.dart';
import 'product_definition.dart';

export 'api_candidates.dart';

/// Compile-time and entry-point product / API configuration.
///
/// Prefer dedicated entry points ([main_pharmacy.dart], [main_diagnostics.dart])
/// which call [bind] so the product is selected without relying only on
/// `--dart-define=APP_PRODUCT=...`. Always pass `--dart-define=API_BASE_URL=...`
/// for non-hospital release builds.
class ProductEnvironment {
  ProductEnvironment._();

  static const String _productFromDefine = String.fromEnvironment(
    'APP_PRODUCT',
    defaultValue: 'hospital',
  );

  /// Explicit production API origin from `--dart-define=API_BASE_URL=...`.
  /// Empty means fall through to `.env` then [kApiCandidateBaseUrls].
  static const String apiBaseUrlFromDefine = String.fromEnvironment(
    'API_BASE_URL',
  );

  static AppProduct? _boundProduct;

  /// Optional runtime bind from a product entry point (e.g. pharmacy main).
  static void bind(AppProduct product) {
    _boundProduct = product;
  }

  /// Clears a runtime bind (tests only).
  @visibleForTesting
  static void debugResetBind() {
    _boundProduct = null;
  }

  static AppProduct get currentProduct =>
      _boundProduct ?? parseAppProduct(_productFromDefine);

  static ProductDefinition get definition =>
      productDefinitionFor(currentProduct);

  static String get displayName => definition.displayName;

  static Set<AppModule> get enabledModules => definition.enabledModules;

  static bool isModuleEnabled(AppModule module) =>
      definition.isModuleEnabled(module);

  /// Resolved API base URL: dart-define wins, then `.env`, else empty.
  static String get resolvedApiBaseUrl {
    final fromDefine = apiBaseUrlFromDefine.trim();
    if (fromDefine.isNotEmpty) return fromDefine;
    return OrgConfig.instance.apiBaseUrl.trim();
  }

  /// Candidate API origins for [ClockSyncGate] probing.
  ///
  /// Precedence: [apiBaseUrlOverride] → `--dart-define=API_BASE_URL` →
  /// `.env` `API_BASE_URL` → [kApiCandidateBaseUrls].
  static List<String> apiCandidateBaseUrls({
    String? apiBaseUrlOverride,
    List<String>? fallbackCandidates,
  }) {
    final explicit = (apiBaseUrlOverride ?? resolvedApiBaseUrl).trim();
    if (explicit.isNotEmpty) {
      return [_normalizeBaseUrl(explicit)];
    }
    return List<String>.unmodifiable(
      fallbackCandidates ?? kApiCandidateBaseUrls,
    );
  }

  /// Non-hospital release builds must pin an HTTPS (or explicit) API URL.
  static void validateReleaseConfig({
    bool? isRelease,
    String? apiBaseUrlOverride,
    AppProduct? productOverride,
  }) {
    final release = isRelease ?? kReleaseMode;
    if (!release) return;

    final product = productOverride ?? currentProduct;
    if (product == AppProduct.hospital) return;

    final url = (apiBaseUrlOverride ?? resolvedApiBaseUrl).trim();
    if (url.isEmpty) {
      throw StateError(
        'API_BASE_URL is required for ${product.name} release builds. '
        'Pass --dart-define=API_BASE_URL=https://api.customer.example '
        'or set API_BASE_URL in .env',
      );
    }
  }

  static String _normalizeBaseUrl(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
