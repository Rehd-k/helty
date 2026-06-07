/// REST paths for the Accounts & Audit module (relative to [ApiService] base).
abstract final class AccountsEndpoints {
  static const dashboard = '/accounts/dashboard';

  static const auditLogs = '/accounts/audit/logs';
  static const complianceChecklist = '/accounts/audit/compliance-checklist';
  static const invoiceChanges = '/accounts/audit/invoice-changes';
  static const leakDetection = '/accounts/audit/leak-detection';
  static const staffActivity = '/accounts/audit/staff-activity';

  static const dailyCollections = '/accounts/reports/daily-collections';
  static const aging = '/accounts/reports/aging';
  static const profitLoss = '/accounts/reports/profit-loss';
  static const cashFlow = '/accounts/reports/cash-flow';
  static const revenueByService = '/accounts/reports/revenue-by-service';
  static const expenseVsBudget = '/accounts/reports/expense-vs-budget';
  static const collectionEfficiency = '/accounts/reports/collection-efficiency';
  static const periodComparison = '/accounts/reports/period-comparison';

  static const walletsSummary = '/accounts/wallets/summary';
  static const dailyCashRecon = '/accounts/reconciliation/daily-cash';
  static const bankRecon = '/accounts/reconciliation/bank';

  static const approvalsPending = '/accounts/approvals/pending';
  static String approveApproval(String id) => '/accounts/approvals/$id/approve';
  static String rejectApproval(String id) => '/accounts/approvals/$id/reject';

  static const refundRequestsPending = '/accounts/refund-requests/pending';
  static String approveRefundRequest(String id) =>
      '/accounts/refund-requests/$id/approve';
  static String rejectRefundRequest(String id) =>
      '/accounts/refund-requests/$id/reject';

  static const periods = '/accounts/periods';
  static String closePeriod(String id) => '/accounts/periods/$id/close';

  static const journalEntries = '/accounts/journal-entries';
  static const chartOfAccounts = '/accounts/chart-of-accounts';
  static String chartOfAccount(String id) => '/accounts/chart-of-accounts/$id';
}
