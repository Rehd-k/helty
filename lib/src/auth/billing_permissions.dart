import 'package:helty/src/models/staff_model.dart';

bool _hasRole(Staff? staff, Set<String> roles) {
  if (staff == null) return false;
  final role = staff.role.trim().toUpperCase();
  return roles.contains(role);
}

bool _hasAccountType(Staff? staff, Set<AccountType> allowed) {
  if (staff == null) return false;
  final at = staff.accountType;
  return at != null && allowed.contains(at);
}

bool canSplitWithHmo(Staff? staff) =>
    _hasAccountType(staff, {AccountType.hmo, AccountType.super_admin}) ||
    _hasRole(staff, {'HMO', 'HMO_STAFF', 'SUPER_ADMIN'});

bool canApplyDiscount(Staff? staff) =>
    _hasAccountType(staff, {
      AccountType.billing,
      AccountType.cmd,
      AccountType.cmac,
      AccountType.super_admin,
    }) ||
    _hasRole(staff, {
      'BILLING_HEAD',
      'BILLING_STAFF',
      'CMD',
      'CMAC',
      'SUPER_ADMIN',
      'BILLS',
    });

bool canReverseCoverage(Staff? staff) => canSplitWithHmo(staff) || canApplyDiscount(staff);

bool canManageDiscountPolicies(Staff? staff) =>
    _hasAccountType(staff, {AccountType.cmd, AccountType.cmac, AccountType.super_admin}) ||
    _hasRole(staff, {'CMD', 'CMAC', 'SUPER_ADMIN'});

bool canViewReceivables(Staff? staff) =>
    _hasAccountType(staff, {
      AccountType.accounting,
      AccountType.billing,
      AccountType.cmd,
      AccountType.cmac,
      AccountType.super_admin,
      AccountType.hmo,
    }) ||
    _hasRole(staff, {
      'ACCOUNTING_HEAD',
      'ACCOUNTING_STAFF',
      'BILLING_HEAD',
      'BILLING_STAFF',
      'CMD',
      'CMAC',
      'SUPER_ADMIN',
      'HMO',
      'HMO_STAFF',
    });

bool canRecordRemittance(Staff? staff) =>
    _hasAccountType(staff, {AccountType.accounting, AccountType.super_admin}) ||
    _hasRole(staff, {'ACCOUNTING_HEAD', 'ACCOUNTING_STAFF', 'SUPER_ADMIN'});
