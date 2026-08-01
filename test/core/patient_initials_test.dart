import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/core/utils/patient_initials.dart';

void main() {
  group('patientInitials', () {
    test('uses first letters of firstName and surname', () {
      expect(
        patientInitials(firstName: 'Ada', surname: 'Okonkwo'),
        'AO',
      );
    });

    test('returns ? when both names empty', () {
      expect(patientInitials(), '?');
      expect(patientInitials(firstName: '  ', surname: null), '?');
    });

    test('handles single name part', () {
      expect(patientInitials(firstName: 'Ada'), 'A');
      expect(patientInitials(surname: 'Okonkwo'), 'O');
    });
  });

  group('avatarUrlFromJson', () {
    test('returns null for missing or empty avatarUrl', () {
      expect(avatarUrlFromJson(null), isNull);
      expect(avatarUrlFromJson({}), isNull);
      expect(avatarUrlFromJson({'avatarUrl': ''}), isNull);
      expect(avatarUrlFromJson({'avatarUrl': '  '}), isNull);
    });

    test('returns trimmed url when present', () {
      expect(
        avatarUrlFromJson({
          'avatarUrl': ' https://api.example.com/avatar.jpg ',
        }),
        'https://api.example.com/avatar.jpg',
      );
    });
  });

  group('resolvePatientAvatarUrl', () {
    const base = 'http://localhost:3000';

    test('returns null for missing or empty', () {
      expect(resolvePatientAvatarUrl(null, baseUrl: base), isNull);
      expect(resolvePatientAvatarUrl('', baseUrl: base), isNull);
      expect(resolvePatientAvatarUrl('  ', baseUrl: base), isNull);
    });

    test('leaves non-loopback absolute http(s) urls unchanged', () {
      expect(
        resolvePatientAvatarUrl(
          'https://api.example.com/uploads/patients/x/avatar.jpg',
          baseUrl: base,
        ),
        'https://api.example.com/uploads/patients/x/avatar.jpg',
      );
      expect(
        resolvePatientAvatarUrl(
          'http://api.example.com/avatar.jpg',
          baseUrl: base,
        ),
        'http://api.example.com/avatar.jpg',
      );
    });

    test('rewrites localhost absolute urls onto probed base', () {
      const probed = 'http://192.168.2.121:3000';
      expect(
        resolvePatientAvatarUrl(
          'http://localhost:3000/uploads/patients/66c33d2c/avatar.jpg',
          baseUrl: probed,
        ),
        'http://192.168.2.121:3000/uploads/patients/66c33d2c/avatar.jpg',
      );
    });

    test('rewrites 127.0.0.1 absolute urls onto probed base', () {
      const probed = 'http://192.168.2.121:3000';
      expect(
        resolvePatientAvatarUrl(
          'http://127.0.0.1:3000/uploads/patients/66c33d2c/avatar.jpg',
          baseUrl: probed,
        ),
        'http://192.168.2.121:3000/uploads/patients/66c33d2c/avatar.jpg',
      );
    });

    test('does not inherit localhost port onto host-only base', () {
      expect(
        resolvePatientAvatarUrl(
          'http://localhost:3000/uploads/patients/x/avatar.jpg',
          baseUrl: 'https://api.example.com',
        ),
        'https://api.example.com/uploads/patients/x/avatar.jpg',
      );
    });

    test('joins relative paths with api base', () {
      expect(
        resolvePatientAvatarUrl(
          '/uploads/patients/3245054a/avatar.jpg',
          baseUrl: base,
        ),
        'http://localhost:3000/uploads/patients/3245054a/avatar.jpg',
      );
      expect(
        resolvePatientAvatarUrl(
          'uploads/patients/3245054a/avatar.jpg',
          baseUrl: '$base/',
        ),
        'http://localhost:3000/uploads/patients/3245054a/avatar.jpg',
      );
    });
  });
}
