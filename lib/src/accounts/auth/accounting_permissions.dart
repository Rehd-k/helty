import 'package:helty/src/models/staff_model.dart';

String _role(Staff? staff) =>
    staff?.staffRole.trim().toUpperCase().replaceAll('-', '_') ?? '';

bool isAccountHead(Staff? staff) {
  if (staff == null) return false;
  if (staff.accountType == AccountType.super_admin) return true;
  final r = _role(staff);
  return r == 'ACCOUNT_HEAD' ||
      r == 'ACCOUNTING_HEAD' ||
      r == 'SUPER_ADMIN';
}

bool isAccountingStaffRole(Staff? staff) {
  if (staff == null) return false;
  return _role(staff) == 'ACCOUNTING_STAFF';
}

bool canAccessAccountsModule(Staff? staff) {
  if (staff == null) return false;
  if (staff.accountType == AccountType.super_admin) return true;
  final at = staff.accountType;
  return at == AccountType.accounting;
}

bool canManageBanks(Staff? staff) => isAccountHead(staff);

bool canViewFullRevenueAnalytics(Staff? staff) =>
    isAccountHead(staff) || staffCanAccessPrivilegedBilling(staff);

bool canRefundOrChangePaymentDate(Staff? staff) =>
    staffCanAccessPrivilegedBilling(staff);

bool canApproveFinancialActions(Staff? staff) => isAccountHead(staff);

bool canClosePeriod(Staff? staff) => isAccountHead(staff);

bool canViewLeakDetection(Staff? staff) => isAccountHead(staff);

bool canExportFullReports(Staff? staff) => isAccountHead(staff);

bool canManageChartOfAccounts(Staff? staff) => isAccountHead(staff);

bool canPostJournalEntries(Staff? staff) => isAccountHead(staff);

bool canAcknowledgeCompliance(Staff? staff) => isAccountHead(staff);

bool canPerformBankReconciliation(Staff? staff) => isAccountHead(staff);

bool canViewProfitLoss(Staff? staff) => isAccountHead(staff);

bool canViewStaffFinancialActivity(Staff? staff) => isAccountHead(staff);
