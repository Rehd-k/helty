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
}
