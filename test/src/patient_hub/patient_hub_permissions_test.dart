import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/auth/dialysis_permissions.dart';
import 'package:helty/src/auth/nursing_permissions.dart';
import 'package:helty/src/auth/theatre_permissions.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/patient_chart/models/patient_chart_models.dart';
import 'package:helty/src/patient_hub/models/patient_hub_models.dart';
import 'package:helty/src/patient_hub/permissions/patient_hub_permissions.dart';

void main() {
  Staff staff({required String role, AccountType? accountType}) {
    return Staff(
      id: 's1',
      staffId: 'ST-1',
      firstName: 'Test',
      lastName: 'User',
      staffRole: role,
      accountType: accountType,
    );
  }

  group('filterClinicalChartIncludes', () {
    test('removes billing sections', () {
      final filtered = filterClinicalChartIncludes([
        PatientChartSectionKeys.encounters,
        PatientChartSectionKeys.invoices,
        PatientChartSectionKeys.payments,
        PatientChartSectionKeys.wallet,
        PatientChartSectionKeys.vitals,
      ]);
      expect(filtered, [
        PatientChartSectionKeys.encounters,
        PatientChartSectionKeys.vitals,
      ]);
    });

    test('patientHubClinicalSections excludes billing keys', () {
      for (final key in patientHubClinicalSections) {
        expect({
          PatientChartSectionKeys.invoices,
          PatientChartSectionKeys.payments,
          PatientChartSectionKeys.wallet,
          PatientChartSectionKeys.appointments,
        }, isNot(contains(key)));
      }
    });
  });

  group('canAccessPatientHub', () {
    test('allows nursing staff', () {
      final nurse = staff(role: 'CHARGE_NURSE', accountType: AccountType.nurse);
      expect(isNursingStaff(nurse), isTrue);
      expect(canAccessPatientHub(nurse), isTrue);
    });

    test('allows physician', () {
      final doctor = staff(role: 'doctor', accountType: AccountType.physician);
      expect(canAccessPatientHub(doctor), isTrue);
    });

    test('allows laboratory', () {
      final lab = staff(
        role: 'lab_scientist',
        accountType: AccountType.laboratory,
      );
      expect(canAccessPatientHub(lab), isTrue);
    });

    test('allows radiology account', () {
      final rad = staff(role: 'radiology', accountType: AccountType.radiology);
      expect(canAccessPatientHub(rad), isTrue);
    });

    test('allows pharmacy', () {
      final pharm = staff(
        role: 'pharmacy_dispensary',
        accountType: AccountType.pharmacy,
      );
      expect(canAccessPatientHub(pharm), isTrue);
    });

    test('allows dialysis module staff', () {
      final dialysis = staff(
        role: 'DIALYSIS_NURSE',
        accountType: AccountType.dialysis,
      );
      expect(canAccessDialysisModule(dialysis), isTrue);
      expect(canAccessPatientHub(dialysis), isTrue);
    });

    test('allows theatre module staff', () {
      final theatre = staff(
        role: 'THEATRE_HEAD',
        accountType: AccountType.theatre,
      );
      expect(canAccessTheatreModule(theatre), isTrue);
      expect(canAccessPatientHub(theatre), isTrue);
    });

    test('allows CMAC account', () {
      final cmac = staff(role: 'CMAC', accountType: AccountType.cmac);
      expect(canAccessPatientHub(cmac), isTrue);
    });

    test('allows CMD account', () {
      final cmd = staff(role: 'CMD', accountType: AccountType.cmd);
      expect(canAccessPatientHub(cmd), isTrue);
    });

    test('allows HMO desk staff', () {
      final hmo = staff(role: 'hmo_staff', accountType: AccountType.hmo);
      expect(canAccessPatientHub(hmo), isTrue);
    });

    test('denies billing staff', () {
      final billing = staff(
        role: 'billing_staff',
        accountType: AccountType.billing,
      );
      expect(canAccessPatientHub(billing), isFalse);
    });

    test('denies null staff', () {
      expect(canAccessPatientHub(null), isFalse);
    });
  });

  group('patientHubTabsForStaff', () {
    test('returns tabs for clinical staff', () {
      final doctor = staff(role: 'doctor', accountType: AccountType.physician);
      expect(patientHubTabsForStaff(doctor).length, patientHubTabDefs.length);
    });

    test('returns empty for denied staff', () {
      final billing = staff(
        role: 'billing_staff',
        accountType: AccountType.billing,
      );
      expect(patientHubTabsForStaff(billing), isEmpty);
    });
  });

  group('canUploadDocumentsInPatientHub', () {
    test('allows physician', () {
      final doctor = staff(role: 'doctor', accountType: AccountType.physician);
      expect(canUploadDocumentsInPatientHub(doctor), isTrue);
    });

    test('allows nursing staff', () {
      final nurse = staff(role: 'CHARGE_NURSE', accountType: AccountType.nurse);
      expect(canUploadDocumentsInPatientHub(nurse), isTrue);
    });

    test('allows laboratory', () {
      final lab = staff(
        role: 'lab_scientist',
        accountType: AccountType.laboratory,
      );
      expect(canUploadDocumentsInPatientHub(lab), isTrue);
    });

    test('allows pharmacy', () {
      final pharm = staff(
        role: 'pharmacy_dispensary',
        accountType: AccountType.pharmacy,
      );
      expect(canUploadDocumentsInPatientHub(pharm), isTrue);
    });

    test('denies billing staff', () {
      final billing = staff(
        role: 'billing_staff',
        accountType: AccountType.billing,
      );
      expect(canUploadDocumentsInPatientHub(billing), isFalse);
    });

    test('denies null staff', () {
      expect(canUploadDocumentsInPatientHub(null), isFalse);
    });
  });
}
