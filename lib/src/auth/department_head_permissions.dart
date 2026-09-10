import '../models/staff_model.dart';

String _normRole(Staff? staff) =>
    (staff?.staffRole ?? '').trim().toUpperCase().replaceAll('-', '_');

const kDepartmentHeadRoles = {
  'BILLING_HEAD',
  'ACCOUNT_HEAD',
  'ACCOUNTING_HEAD',
  'PHARMACY_HEAD',
  'MATRON',
  'HEAD_NURSE',
  'PHYSICIAN_HEAD',
  'LAB_HEAD',
  'RADIOLOGY_HEAD',
  'HEAD_OF_STORE',
  'MEDICAL_RECORDS_HEAD',
  'FRONT_DESK_HEAD',
  'ICT_HEAD',
  'HMO_HEAD',
  'PURCHASES_HEAD',
  'DIALYSIS_HEAD',
  'THEATRE_HEAD',
  'JANITOR_HEAD',
};

const kHospitalWideInventoryRoles = {
  'CMD',
  'CMAC',
  'SUPER_ADMIN',
  // Director of Admin — coming soon.
  'DA',
  'DIRECTOR_OF_ADMIN',
  'DIRECTOR_ADMIN',
};

bool isAccountTypeHead(Staff? staff) {
  if (staff == null) return false;
  return kDepartmentHeadRoles.contains(_normRole(staff));
}

bool isHospitalWideInventoryViewer(Staff? staff) {
  if (staff == null) return false;
  if (staff.accountType == AccountType.cmd ||
      staff.accountType == AccountType.cmac ||
      staff.accountType == AccountType.super_admin) {
    return true;
  }
  final at = staff.accountType?.apiValue;
  if (at != null && kHospitalWideInventoryRoles.contains(at)) return true;
  return kHospitalWideInventoryRoles.contains(_normRole(staff));
}

/// Operational departments that keep their own physical-asset inventory.
List<AccountType> get kInventoryDepartments => AccountType.departmentTypes
    .where(
      (t) =>
          t != AccountType.cmd &&
          t != AccountType.cmac &&
          t != AccountType.super_admin,
    )
    .toList();

bool isInventoryDepartment(AccountType? accountType) {
  return accountType != null && kInventoryDepartments.contains(accountType);
}

/// Staff in an operational department may view that department's inventory only.
bool canViewOwnDepartmentInventory(Staff? staff) {
  if (staff == null) return false;
  if (isHospitalWideInventoryViewer(staff)) return true;
  return isInventoryDepartment(staff.accountType);
}

bool usesGenericDepartmentRoster(Staff? staff) {
  if (!isAccountTypeHead(staff)) return false;
  final at = staff!.accountType;
  return at != AccountType.nurse && at != AccountType.janitor;
}

bool isHousekeepingHead(Staff? staff) {
  if (staff == null) return false;
  return staff.accountType == AccountType.janitor ||
      _normRole(staff) == 'JANITOR_HEAD';
}

bool canManageDepartmentStaff(Staff? staff) => isAccountTypeHead(staff);

bool canManageDepartmentRoster(Staff? staff) =>
    usesGenericDepartmentRoster(staff);
