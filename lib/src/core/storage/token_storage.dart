import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Handles secure persistence of JWT access & refresh tokens.
class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  // ── Access Token ────────────────────────────────────────────────────────────

  static Future<void> saveAccessToken(String token) =>
      _storage.write(key: _accessTokenKey, value: token);

  static Future<String?> getAccessToken() =>
      _storage.read(key: _accessTokenKey);

  static Future<void> deleteAccessToken() =>
      _storage.delete(key: _accessTokenKey);

  // ── Refresh Token ───────────────────────────────────────────────────────────

  static Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _refreshTokenKey, value: token);

  static Future<String?> getRefreshToken() =>
      _storage.read(key: _refreshTokenKey);

  static Future<void> deleteRefreshToken() =>
      _storage.delete(key: _refreshTokenKey);

  // ── Convenience ─────────────────────────────────────────────────────────────

  /// Returns true if an access token is currently stored.
  static Future<bool> hasToken() async {
    final t = await getAccessToken();
    return t != null && t.isNotEmpty;
  }

  /// Wipes both tokens (call on logout).
  static Future<void> clearAll() async {
    await Future.wait([deleteAccessToken(), deleteRefreshToken()]);
  }
}
