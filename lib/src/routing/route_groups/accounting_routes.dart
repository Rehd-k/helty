import 'package:auto_route/auto_route.dart';
import 'package:helty/app_router.gr.dart';

import '../product_module_guard.dart';

/// Accounts screens. Registered for any product that enables [AppModule.accounting].
List<AutoRoute> accountingRoutes() => [
  AutoRoute(
    page: AccountsDashboardRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ConsultationPaymentReportRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsRevenueSummaryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsDailyCollectionsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsAgingReportRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsFinancialReportsHubRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsProfitLossRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsCashFlowRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  // Revenue-by-service + refund requests live in billingRoutes (diagnostics too).
  AutoRoute(
    page: AccountsExpenseVsBudgetRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsCollectionEfficiencyRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsPeriodComparisonRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsPaymentMixRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsAuditLogRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsComplianceRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsInvoiceChangesRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsLeakDetectionRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsStaffActivityRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsRefundHistoryRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsWalletsOverviewRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsDailyCashReconRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsBankReconRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsApprovalsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsPeriodCloseRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsJournalEntriesRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsChartOfAccountsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: AccountsBanksRoute.page,
    guards: const [ProductModuleGuard()],
  ),
  AutoRoute(
    page: ReceivablesAnalyticsRoute.page,
    guards: const [ProductModuleGuard()],
  ),
];
