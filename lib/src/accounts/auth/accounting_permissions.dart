import 'package:helty/src/models/staff_model.dart';

String _role(Staff? staff) =>
    staff?.staffRole.trim().toUpperCase().replaceAll('-', '_') ?? '';

bool isCmd(Staff? staff) {
  if (staff == null) return false;
  if (staff.accountType == AccountType.cmd) return true;
  return _role(staff) == 'CMD';
}

bool isAccountHead(Staff? staff) {
  if (staff == null) return false;
  if (staff.accountType == AccountType.super_admin) return true;
  final r = _role(staff);
  return r == 'ACCOUNT_HEAD' || r == 'ACCOUNTING_HEAD' || r == 'SUPER_ADMIN';
}

bool isAccountingStaffRole(Staff? staff) {
  if (staff == null) return false;
  return _role(staff) == 'ACCOUNTING_STAFF';
}

/// Who may open Accounts & Audit screens (including CMD read-only access).
bool canAccessAccountsModule(Staff? staff) {
  if (staff == null) return false;
  if (staff.accountType == AccountType.super_admin) return true;
  if (isCmd(staff)) return true;
  final at = staff.accountType;
  return at == AccountType.accounting;
}

/// Head-level dashboards, KPIs, and financial reports (view only for CMD).
bool canViewAccountsHeadData(Staff? staff) =>
    isAccountHead(staff) || isCmd(staff);

bool canManageBanks(Staff? staff) => isAccountHead(staff);

bool canViewFullRevenueAnalytics(Staff? staff) =>
    canViewAccountsHeadData(staff) || staffCanAccessPrivilegedBilling(staff);

/// Billing analytics dashboard may be viewed by CMD without privileged mutation rights.
bool canViewBillingAnalyticsDashboard(Staff? staff) =>
    canViewFullRevenueAnalytics(staff);

bool canRefundOrChangePaymentDate(Staff? staff) =>
    staffCanAccessPrivilegedBilling(staff);

bool canApproveFinancialActions(Staff? staff) => isAccountHead(staff);

bool canClosePeriod(Staff? staff) => isAccountHead(staff);

bool canViewLeakDetection(Staff? staff) => canViewAccountsHeadData(staff);

bool canExportFullReports(Staff? staff) => isAccountHead(staff);

bool canManageChartOfAccounts(Staff? staff) => isAccountHead(staff);

bool canPostJournalEntries(Staff? staff) => isAccountHead(staff);

bool canAcknowledgeCompliance(Staff? staff) => isAccountHead(staff);

bool canPerformBankReconciliation(Staff? staff) => isAccountHead(staff);

/// Open bank reconciliation screen (list) — CMD and heads may view.
bool canViewBankReconciliation(Staff? staff) => canViewAccountsHeadData(staff);

bool canViewProfitLoss(Staff? staff) => canViewAccountsHeadData(staff);

bool canViewRevenueByService(Staff? staff) =>
    canViewProfitLoss(staff) || staffCanAccessPrivilegedBilling(staff);

bool canApproveItemRefundRequests(Staff? staff) =>
    canApproveFinancialActions(staff) || staffCanAccessPrivilegedBilling(staff);

bool canViewStaffFinancialActivity(Staff? staff) =>
    canViewAccountsHeadData(staff);

/// Submit daily cash recon — accounting roles only (not CMD).
bool canSubmitDailyCashRecon(Staff? staff) =>
    isAccountHead(staff) || isAccountingStaffRole(staff);

/// View pending financial approvals queue (mutations still need [canApproveFinancialActions]).
bool canViewFinancialApprovals(Staff? staff) => canViewAccountsHeadData(staff);

/// View refund-request queue (mutations still need [canApproveItemRefundRequests]).
bool canViewItemRefundRequests(Staff? staff) => canViewAccountsHeadData(staff);

/// View fiscal periods (mutations still need [canClosePeriod]).
bool canViewPeriodClose(Staff? staff) => canViewAccountsHeadData(staff);

/// View journal entries (mutations still need [canPostJournalEntries]).
bool canViewJournalEntries(Staff? staff) => canViewAccountsHeadData(staff);

/// View chart of accounts (mutations still need [canManageChartOfAccounts]).
bool canViewChartOfAccounts(Staff? staff) => canViewAccountsHeadData(staff);
