import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/models/staff_model.dart';

bool _hasRole(Staff? staff, Set<String> roles) {
  if (staff == null) return false;
  final staffRole = staff.staffRole.trim().toUpperCase();
  return roles.contains(staffRole);
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
      'ACCOUNT_HEAD',
      'ACCOUNTING_HEAD',
      'ACCOUNTING_STAFF',
      'BILLING_HEAD',
      'BILLING_STAFF',
      'CMD',
      'CMAC',
      'SUPER_ADMIN',
      'HMO',
      'HMO_STAFF',
      'HMO_DESK',
    });

/// Create, edit, delete HMO plans and configure HMO service pricing.
bool canManageHmos(Staff? staff) {
  if (staff == null) return false;
  if (staffCanAccessPrivilegedBilling(staff)) return true;
  return _hasAccountType(staff, {AccountType.hmo}) ||
      _hasRole(staff, {'HMO', 'HMO_STAFF', 'HMO_DESK'});
}

bool canRecordRemittance(Staff? staff) =>
    _hasAccountType(staff, {AccountType.accounting, AccountType.super_admin}) ||
    _hasRole(staff, {
      'ACCOUNT_HEAD',
      'ACCOUNTING_HEAD',
      'ACCOUNTING_STAFF',
      'SUPER_ADMIN',
    });

/// Submit invoice line refund requests (billing / accounts staff).
bool canRequestInvoiceItemRefund(Staff? staff) {
  if (staff == null) return false;
  if (staff.accountType == AccountType.super_admin) return true;
  return _hasAccountType(staff, {
        AccountType.billing,
        AccountType.accounting,
      }) ||
      _hasRole(staff, {
        'BILLING_HEAD',
        'BILLING_STAFF',
        'BILLS',
        'ACCOUNT_HEAD',
        'ACCOUNTING_HEAD',
        'ACCOUNTING_STAFF',
        'ACCOUNTS',
        'SUPER_ADMIN',
      });
}

/// Delete an entire inpatient invoice and all of its line items.
bool canDeleteInpatientInvoice(Staff? staff) {
  if (staff == null) return false;
  if (staff.accountType == AccountType.super_admin) return true;
  final r = staff.staffRole.trim().toUpperCase().replaceAll('-', '_');
  if (r == 'SUPER_ADMIN') return true;
  return staff.accountType == AccountType.accounting;
}

/// Cancel a pending refund request (original requester or account head).
bool canCancelInvoiceItemRefundRequest(
  Staff? staff,
  BillingInvoiceItemActiveRefundRequest? activeRequest,
) {
  if (staff == null || activeRequest == null) return false;
  if (isAccountHead(staff)) return true;
  final requester = activeRequest.requestedBy?.trim().toLowerCase() ?? '';
  if (requester.isEmpty) return false;
  return staff.fullName.trim().toLowerCase() == requester;
}
