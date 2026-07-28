import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/models/medication_request_model.dart';
import 'package:helty/src/models/staff_attribution.dart';

void main() {
  group('staffDisplayNameFromJson', () {
    test('resolves flat firstName/lastName on root person object', () {
      expect(
        staffDisplayNameFromJson({
          'id': '49e6edef-2349-482f-8bdc-f05bd114abb1',
          'firstName': 'doctor',
          'lastName': 'test',
          'staffId': '123456',
        }),
        'doctor test',
      );
    });

    test('still resolves nested doctor object on parent record', () {
      expect(
        staffDisplayNameFromJson({
          'id': 'enc-1',
          'doctor': {
            'id': 'doc-1',
            'firstName': 'Ada',
            'lastName': 'Lovelace',
          },
        }),
        'Ada Lovelace',
      );
    });
  });

  group('formatStaffName', () {
    test('returns First Last from nested map', () {
      expect(
        formatStaffName({'firstName': 'Jane', 'lastName': 'Okonkwo'}),
        'Jane Okonkwo',
      );
    });

    test('returns null for null or empty', () {
      expect(formatStaffName(null), isNull);
      expect(formatStaffName({}), isNull);
      expect(formatStaffName({'firstName': '  ', 'lastName': ''}), isNull);
    });

    test('falls back to displayName', () {
      expect(formatStaffName({'displayName': 'Desk Staff'}), 'Desk Staff');
    });
  });

  group('createdByLabel / staffRefLabel', () {
    test('formats createdBy label', () {
      expect(
        createdByLabel({
          'createdBy': {'firstName': 'Jane', 'lastName': 'Okonkwo'},
        }),
        'Created by: Jane Okonkwo',
      );
    });

    test('returns null when createdBy missing', () {
      expect(createdByLabel({}), isNull);
      expect(createdByLabel({'createdBy': null}), isNull);
    });

    test('formats updatedBy / requestedBy / reportedBy', () {
      expect(
        staffRefLabel(
          {
            'updatedBy': {'firstName': 'Ada', 'lastName': 'Okoro'},
          },
          'updatedBy',
          prefix: 'Last updated by',
        ),
        'Last updated by: Ada Okoro',
      );
      expect(
        staffRefLabel(
          {
            'requestedBy': {'firstName': 'Pat', 'lastName': 'Lee'},
          },
          'requestedBy',
          prefix: 'Requested by',
        ),
        'Requested by: Pat Lee',
      );
      expect(
        staffRefLabel(
          {
            'reportedBy': {'firstName': 'Sam', 'lastName': 'Ng'},
          },
          'reportedBy',
          prefix: 'Reported by',
        ),
        'Reported by: Sam Ng',
      );
    });

    test('accepts preformatted string staff refs', () {
      expect(
        staffRefLabel(
          {'uploadedBy': 'Nurse A'},
          'uploadedBy',
          prefix: 'By',
        ),
        'By: Nurse A',
      );
    });
  });

  group('MedicationRequestStaffRef.fromJson', () {
    test('parses prescribing doctor from flat medicationOrder.doctor shape', () {
      final ref = MedicationRequestStaffRef.fromJson({
        'id': '49e6edef-2349-482f-8bdc-f05bd114abb1',
        'firstName': 'doctor',
        'lastName': 'test',
        'staffId': '123456',
      });

      expect(ref.id, '49e6edef-2349-482f-8bdc-f05bd114abb1');
      expect(ref.displayName, 'doctor test');
    });

    test('parses requested nurse from flat requestedByNurse shape', () {
      final ref = MedicationRequestStaffRef.fromJson({
        'id': 'c82b6c29-3d33-4549-ab53-cd42c394637e',
        'firstName': 'nurse',
        'lastName': 'name',
        'staffId': '87565',
      });

      expect(ref.displayName, 'nurse name');
    });
  });
}
