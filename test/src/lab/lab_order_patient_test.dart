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

    test('parses gender and dob from API shape', () {
      final patient = LabOrderPatient.fromJson({
        'id': '4ca42274-b366-4d82-bbac-3072535cdc2a',
        'patientId': 'KF0VFMFY',
        'firstName': 'Denis',
        'surname': 'Kalu',
        'gender': 'Male',
        'dob': '2026-03-24T05:49:40.569Z',
      });

      expect(patient.gender, 'Male');
      expect(patient.dob, DateTime.parse('2026-03-24T05:49:40.569Z'));
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

    test('isPhysician is true when accountType is PHYSICIAN', () {
      final doctor = LabOrderStaff.fromJson({
        'id': '49e6edef-2349-482f-8bdc-f05bd114abb1',
        'firstName': 'doctor',
        'lastName': 'test',
        'staffId': '123456',
        'accountType': 'PHYSICIAN',
      });

      expect(doctor.isPhysician, isTrue);
    });

    test('isPhysician is false when accountType is not PHYSICIAN', () {
      final doctor = LabOrderStaff.fromJson({
        'id': '49e6edef-2349-482f-8bdc-f05bd114abb1',
        'firstName': 'lab',
        'lastName': 'tech',
        'accountType': 'LABORATORY',
      });

      expect(doctor.isPhysician, isFalse);
    });

    test('isPhysician is false when accountType is absent', () {
      final doctor = LabOrderStaff.fromJson({
        'id': '49e6edef-2349-482f-8bdc-f05bd114abb1',
        'firstName': 'doctor',
        'lastName': 'test',
      });

      expect(doctor.accountType, isNull);
      expect(doctor.isPhysician, isFalse);
    });
  });
}
