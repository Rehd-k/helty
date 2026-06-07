import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/auth/dialysis_permissions.dart';
import 'package:helty/src/models/staff_model.dart';

Staff _staff({
  AccountType? accountType,
  String staffRole = '',
}) {
  return Staff(
    id: '1',
    staffId: 'S1',
    firstName: 'Test',
    lastName: 'User',
    staffRole: staffRole,
    accountType: accountType,
  );
}

void main() {
  group('dialysis permissions', () {
    test('all dialysis roles can access module menu', () {
      for (final role in [
        'DIALYSIS_HEAD',
        'DIALYSIS_NURSE',
        'DIALYSIS_TECH',
        'DIALYSIS_RECEPTIONIST',
      ]) {
        expect(canAccessDialysisModule(_staff(staffRole: role)), isTrue);
      }
    });

    test('receptionist cannot perform clinical actions', () {
      final receptionist = _staff(staffRole: 'DIALYSIS_RECEPTIONIST');
      expect(canAccessDialysisModule(receptionist), isTrue);
      expect(canPerformDialysisClinical(receptionist), isFalse);
      expect(canCancelDialysisSession(receptionist), isFalse);
    });

    test('nurse and tech can perform clinical but not cancel', () {
      for (final role in ['DIALYSIS_NURSE', 'DIALYSIS_TECH']) {
        final s = _staff(staffRole: role);
        expect(canPerformDialysisClinical(s), isTrue);
        expect(canCancelDialysisSession(s), isFalse);
      }
    });

    test('head can cancel sessions', () {
      final head = _staff(staffRole: 'DIALYSIS_HEAD');
      expect(canPerformDialysisClinical(head), isTrue);
      expect(canCancelDialysisSession(head), isTrue);
    });

    test('dialysis account type grants module access', () {
      expect(
        canAccessDialysisModule(_staff(accountType: AccountType.dialysis)),
        isTrue,
      );
    });
  });
}
