import 'package:flutter/foundation.dart';
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
      _write(_accessTokenKey, token);

  static Future<String?> getAccessToken() => _read(_accessTokenKey);

  static Future<void> deleteAccessToken() => _delete(_accessTokenKey);

  // ── Refresh Token ───────────────────────────────────────────────────────────

  static Future<void> saveRefreshToken(String token) =>
      _write(_refreshTokenKey, token);

  static Future<String?> getRefreshToken() => _read(_refreshTokenKey);

  static Future<void> deleteRefreshToken() => _delete(_refreshTokenKey);

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

  /// Windows DPAPI files created while elevated (or by another user) can throw
  /// on read/write/delete. Never let that abort app startup.
  static Future<String?> _read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('TokenStorage read failed for $key: $e');
      return null;
    }
  }

  static Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('TokenStorage write failed for $key: $e');
      rethrow;
    }
  }

  static Future<void> _delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('TokenStorage delete failed for $key: $e');
    }
  }
}
