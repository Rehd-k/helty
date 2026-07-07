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

bool isBillingHead(Staff? staff) {
  if (staff == null) return false;
  if (staff.accountType == AccountType.super_admin) return true;
  final r = staff.staffRole.trim().toUpperCase().replaceAll('-', '_');
  return r == 'BILLING_HEAD' || r == 'SUPER_ADMIN';
}

/// Billing department staff who may edit recurring line start dates.
bool canEditRecurringInvoiceItemStartDateForStaff(Staff? staff) {
  if (staff == null) return false;
  if (canDeleteInpatientInvoice(staff)) return true;
  return _hasAccountType(staff, {AccountType.billing}) ||
      _hasRole(staff, {'BILLING_STAFF', 'BILLS'});
}

/// Delete an entire inpatient invoice and all of its line items.
///
/// Allowed: super admin, account head, billing head.
bool canDeleteInpatientInvoice(Staff? staff) {
  if (staff == null) return false;
  if (staff.accountType == AccountType.super_admin) return true;
  final r = staff.staffRole.trim().toUpperCase().replaceAll('-', '_');
  if (r == 'SUPER_ADMIN') return true;
  return isAccountHead(staff) || isBillingHead(staff);
}

/// Whether a recurring daily line's start date may be edited (delete + re-add).
bool canEditRecurringInvoiceItemStartDate(Staff? staff, BillingInvoiceItem line) {
  if (!canEditRecurringInvoiceItemStartDateForStaff(staff)) return false;
  if (!line.isRecurringDaily) return false;
  if (line.serviceId.trim().isEmpty) return false;
  if (line.lineItemAmountPaid > 0.001) return false;
  if (line.refundPending) return false;
  return true;
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
