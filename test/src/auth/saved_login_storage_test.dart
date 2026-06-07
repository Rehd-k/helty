import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/core/storage/saved_login_storage.dart';
import 'package:helty/src/models/saved_login.dart';
import 'package:shared_preferences/shared_preferences.dart';

SavedLogin _entry(String email, String name, {int ms = 0}) => SavedLogin(
      emailOrPhone: email,
      displayName: name,
      roleLabel: 'nurse',
      lastUsedMs: ms,
    );

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SavedLogin', () {
    test('normalizes email keys case-insensitively', () {
      expect(
        SavedLogin.normalizeKey('John@Hospital.org'),
        SavedLogin.normalizeKey('john@hospital.org'),
      );
    });

    test('initials from full name', () {
      expect(
        _entry('a@b.com', 'Jane Doe').initials,
        'JD',
      );
    });

    test('round-trips through JSON', () {
      final original = _entry('nurse@imsh.org', 'Ada Lovelace', ms: 42);
      final decoded = SavedLogin.fromJson(original.toJson());
      expect(decoded.emailOrPhone, original.emailOrPhone);
      expect(decoded.displayName, original.displayName);
      expect(decoded.roleLabel, original.roleLabel);
      expect(decoded.lastUsedMs, original.lastUsedMs);
    });
  });

  group('SavedLoginStorage', () {
    test('upsert prepends and dedupes by normalized email', () async {
      await SavedLoginStorage.upsert(_entry('user@imsh.org', 'User One', ms: 1));
      await SavedLoginStorage.upsert(
        _entry('USER@imsh.org', 'User One Updated', ms: 2),
      );
      await SavedLoginStorage.upsert(
        _entry('other@imsh.org', 'Other User', ms: 3),
      );

      final logins = await SavedLoginStorage.load();
      expect(logins, hasLength(2));
      expect(logins.first.emailOrPhone, 'other@imsh.org');
      expect(logins.last.emailOrPhone, 'USER@imsh.org');
      expect(logins.last.displayName, 'User One Updated');
    });

    test('caps stored logins at five', () async {
      for (var i = 0; i < 6; i++) {
        await SavedLoginStorage.upsert(
          _entry('user$i@imsh.org', 'User $i', ms: i),
        );
      }

      final logins = await SavedLoginStorage.load();
      expect(logins, hasLength(5));
      expect(logins.first.emailOrPhone, 'user5@imsh.org');
      expect(logins.last.emailOrPhone, 'user1@imsh.org');
    });

    test('remove deletes matching entry', () async {
      await SavedLoginStorage.upsert(_entry('a@imsh.org', 'A'));
      await SavedLoginStorage.upsert(_entry('b@imsh.org', 'B'));
      await SavedLoginStorage.remove('A@imsh.org');

      final logins = await SavedLoginStorage.load();
      expect(logins, hasLength(1));
      expect(logins.first.emailOrPhone, 'b@imsh.org');
    });
  });
}
