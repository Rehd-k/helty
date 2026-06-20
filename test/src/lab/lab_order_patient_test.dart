import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/lab/models/lab_models.dart';

void main() {
  group('LabOrderPatient', () {
    test('parses API shape with surname and patientId', () {
      final patient = LabOrderPatient.fromJson({
        'id': '41b92cfe-f200-404e-af2a-78539329967d',
        'firstName': 'Kelvin',
        'surname': 'Ikenna',
        'patientId': '5ZA3QP87',
      });

      expect(patient.id, '41b92cfe-f200-404e-af2a-78539329967d');
      expect(patient.firstName, 'Kelvin');
      expect(patient.surname, 'Ikenna');
      expect(patient.patientId, '5ZA3QP87');
      expect(patient.displayName, 'Kelvin Ikenna');
      expect(patient.capitalizedDisplayName, 'Kelvin Ikenna');
    });

    test('patientId is null when absent', () {
      final patient = LabOrderPatient.fromJson({
        'id': '41b92cfe-f200-404e-af2a-78539329967d',
        'firstName': 'Kelvin',
        'surname': 'Ikenna',
      });

      expect(patient.patientId, isNull);
    });

    test('falls back to lastName when surname is absent', () {
      final patient = LabOrderPatient.fromJson({
        'id': 'patient-1',
        'firstName': 'Jane',
        'lastName': 'Doe',
      });

      expect(patient.surname, 'Doe');
      expect(patient.displayName, 'Jane Doe');
      expect(patient.capitalizedDisplayName, 'Jane Doe');
    });

    test('capitalizes mixed-case names', () {
      final patient = LabOrderPatient.fromJson({
        'id': 'patient-1',
        'firstName': 'kELVIN',
        'surname': 'iKENNA',
      });

      expect(patient.capitalizedDisplayName, 'Kelvin Ikenna');
    });
  });

  group('LabOrderStaff', () {
    test('capitalizes doctor name from API shape', () {
      final doctor = LabOrderStaff.fromJson({
        'id': '49e6edef-2349-482f-8bdc-f05bd114abb1',
        'firstName': 'doctor',
        'lastName': 'test',
      });

      expect(doctor.displayName, 'doctor test');
      expect(doctor.capitalizedDisplayName, 'Doctor Test');
    });
  });
}
