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

    test('leaves absolute http(s) urls unchanged', () {
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
