import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/core/utils/patient_display_name.dart';

void main() {
  group('formatPatientDisplayName', () {
    test('joins first, other, and surname', () {
      expect(
        formatPatientDisplayName(
          firstName: 'John',
          otherName: 'Michael',
          surname: 'Doe',
        ),
        'John Michael Doe',
      );
    });

    test('prefixes title when present', () {
      expect(
        formatPatientDisplayName(
          title: 'Mrs',
          firstName: 'Ada',
          otherName: 'Grace',
          surname: 'Okafor',
        ),
        'Mrs Ada Grace Okafor',
      );
    });

    test('returns Unknown when all parts empty', () {
      expect(formatPatientDisplayName(), 'Unknown');
    });

    test('skips empty parts', () {
      expect(
        formatPatientDisplayName(firstName: 'Jane', surname: 'Smith'),
        'Jane Smith',
      );
    });
  });

  group('patientDisplayNameFromJson', () {
    test('prefers patientName from API', () {
      expect(
        patientDisplayNameFromJson({
          'firstName': 'John',
          'surname': 'Doe',
          'patientName': 'Mrs Ada Grace Okafor',
        }),
        'Mrs Ada Grace Okafor',
      );
    });

    test('falls back to structured fields', () {
      expect(
        patientDisplayNameFromJson({
          'title': null,
          'firstName': 'John',
          'otherName': 'Michael',
          'surname': 'Doe',
        }),
        'John Michael Doe',
      );
    });

    test('returns null variant for empty list rows', () {
      expect(patientDisplayNameFromJsonOrNull({}), isNull);
    });
  });
}
