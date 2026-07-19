import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/notifications/custom_push_permissions.dart';

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

  group('canSendCustomPatientPush', () {
    test('allows CMAC by account type', () {
      expect(
        canSendCustomPatientPush(
          staff(role: 'staff', accountType: AccountType.cmac),
        ),
        isTrue,
      );
    });

    test('allows CMD by account type', () {
      expect(
        canSendCustomPatientPush(
          staff(role: 'staff', accountType: AccountType.cmd),
        ),
        isTrue,
      );
    });

    test('allows SUPER_ADMIN by account type', () {
      expect(
        canSendCustomPatientPush(
          staff(role: 'staff', accountType: AccountType.super_admin),
        ),
        isTrue,
      );
    });

    test('allows CMAC by role string', () {
      expect(canSendCustomPatientPush(staff(role: 'cmac')), isTrue);
    });

    test('allows CMD by role string', () {
      expect(canSendCustomPatientPush(staff(role: 'CMD')), isTrue);
    });

    test('allows SUPER_ADMIN by role string', () {
      expect(canSendCustomPatientPush(staff(role: 'super_admin')), isTrue);
    });

    test('denies null staff', () {
      expect(canSendCustomPatientPush(null), isFalse);
    });

    test('denies billing staff', () {
      expect(
        canSendCustomPatientPush(
          staff(role: 'billing_staff', accountType: AccountType.billing),
        ),
        isFalse,
      );
    });

    test('denies nursing staff', () {
      expect(
        canSendCustomPatientPush(
          staff(role: 'CHARGE_NURSE', accountType: AccountType.nurse),
        ),
        isFalse,
      );
    });

    test('denies physician', () {
      expect(
        canSendCustomPatientPush(
          staff(role: 'doctor', accountType: AccountType.physician),
        ),
        isFalse,
      );
    });
  });
}
