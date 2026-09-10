import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/auth/department_head_permissions.dart';
import 'package:helty/src/models/staff_model.dart';

Staff _staff({required AccountType accountType, required String staffRole}) {
  return Staff(
    id: '1',
    staffId: 'S1',
    firstName: 'A',
    lastName: 'B',
    staffRole: staffRole,
    accountType: accountType,
  );
}

void main() {
  test('existing heads stay heads', () {
    expect(
      isAccountTypeHead(
        _staff(accountType: AccountType.laboratory, staffRole: 'LAB_HEAD'),
      ),
      isTrue,
    );
    expect(
      isAccountTypeHead(
        _staff(accountType: AccountType.nurse, staffRole: 'MATRON'),
      ),
      isTrue,
    );
  });

  test('lab scientist can view own department inventory', () {
    expect(
      canViewOwnDepartmentInventory(
        _staff(accountType: AccountType.laboratory, staffRole: 'LAB_SCIENTIST'),
      ),
      isTrue,
    );
    expect(
      isHospitalWideInventoryViewer(
        _staff(accountType: AccountType.laboratory, staffRole: 'LAB_SCIENTIST'),
      ),
      isFalse,
    );
  });

  test('Director of Admin is hospital-wide inventory (coming soon)', () {
    expect(
      isHospitalWideInventoryViewer(
        _staff(accountType: AccountType.staff, staffRole: 'DA'),
      ),
      isTrue,
    );
    expect(
      isHospitalWideInventoryViewer(
        _staff(accountType: AccountType.staff, staffRole: 'DIRECTOR_OF_ADMIN'),
      ),
      isTrue,
    );
  });

  test('CMD is not a department head', () {
    expect(
      isAccountTypeHead(_staff(accountType: AccountType.cmd, staffRole: 'CMD')),
      isFalse,
    );
    expect(
      isHospitalWideInventoryViewer(
        _staff(accountType: AccountType.cmd, staffRole: 'CMD'),
      ),
      isTrue,
    );
  });

  test('nursing and janitor skip generic roster', () {
    expect(
      usesGenericDepartmentRoster(
        _staff(accountType: AccountType.nurse, staffRole: 'MATRON'),
      ),
      isFalse,
    );
    expect(
      usesGenericDepartmentRoster(
        _staff(accountType: AccountType.janitor, staffRole: 'JANITOR_HEAD'),
      ),
      isFalse,
    );
    expect(
      usesGenericDepartmentRoster(
        _staff(accountType: AccountType.physician, staffRole: 'PHYSICIAN_HEAD'),
      ),
      isTrue,
    );
  });
}
