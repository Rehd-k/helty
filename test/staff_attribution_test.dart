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
