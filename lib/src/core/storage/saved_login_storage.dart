import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/saved_login.dart';

const _kSavedLoginsKey = 'saved_logins';
const _kMaxSavedLogins = 5;

/// Persists recent staff login identifiers (never passwords).
abstract final class SavedLoginStorage {
  static Future<List<SavedLogin>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kSavedLoginsKey);
    if (raw == null || raw.isEmpty) return [];

    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SavedLogin.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> upsert(SavedLogin entry) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await load();
    final key = entry.normalizedKey;

    final updated = [
      entry,
      ...existing.where((e) => e.normalizedKey != key),
    ].take(_kMaxSavedLogins).toList();

    await prefs.setString(
      _kSavedLoginsKey,
      jsonEncode(updated.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> remove(String emailOrPhone) async {
    final prefs = await SharedPreferences.getInstance();
    final key = SavedLogin.normalizeKey(emailOrPhone);
    final updated =
        (await load()).where((e) => e.normalizedKey != key).toList();

    if (updated.isEmpty) {
      await prefs.remove(_kSavedLoginsKey);
    } else {
      await prefs.setString(
        _kSavedLoginsKey,
        jsonEncode(updated.map((e) => e.toJson()).toList()),
      );
    }
  }
}
