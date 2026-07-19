import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/frontdesk/patient_access_permissions.dart';
import 'package:helty/src/models/staff_model.dart';

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

  group('canManagePatientAppAccess', () {
    test('allows front desk by account type', () {
      expect(
        canManagePatientAppAccess(
          staff(role: 'staff', accountType: AccountType.front_desk),
        ),
        isTrue,
      );
    });

    test('allows medical records by account type', () {
      expect(
        canManagePatientAppAccess(
          staff(role: 'staff', accountType: AccountType.medical_records),
        ),
        isTrue,
      );
    });

    test('allows CMD by account type', () {
      expect(
        canManagePatientAppAccess(
          staff(role: 'staff', accountType: AccountType.cmd),
        ),
        isTrue,
      );
    });

    test('allows SUPER_ADMIN by account type', () {
      expect(
        canManagePatientAppAccess(
          staff(role: 'staff', accountType: AccountType.super_admin),
        ),
        isTrue,
      );
    });

    test('allows FRONT_DESK by role string', () {
      expect(canManagePatientAppAccess(staff(role: 'FRONT_DESK')), isTrue);
    });

    test('allows FRONTDESK by role string', () {
      expect(canManagePatientAppAccess(staff(role: 'frontdesk')), isTrue);
    });

    test('allows MEDICAL_RECORDS by role string', () {
      expect(
        canManagePatientAppAccess(staff(role: 'medical_records')),
        isTrue,
      );
    });

    test('allows CMD by role string', () {
      expect(canManagePatientAppAccess(staff(role: 'CMD')), isTrue);
    });

    test('allows SUPER_ADMIN by role string', () {
      expect(canManagePatientAppAccess(staff(role: 'super_admin')), isTrue);
    });

    test('denies null staff', () {
      expect(canManagePatientAppAccess(null), isFalse);
    });

    test('denies billing staff', () {
      expect(
        canManagePatientAppAccess(
          staff(role: 'billing_staff', accountType: AccountType.billing),
        ),
        isFalse,
      );
    });

    test('denies nursing staff', () {
      expect(
        canManagePatientAppAccess(
          staff(role: 'CHARGE_NURSE', accountType: AccountType.nurse),
        ),
        isFalse,
      );
    });

    test('denies physician', () {
      expect(
        canManagePatientAppAccess(
          staff(role: 'doctor', accountType: AccountType.physician),
        ),
        isFalse,
      );
    });
  });
}
