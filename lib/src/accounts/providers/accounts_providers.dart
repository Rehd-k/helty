import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/providers/auth_provider.dart';

import '../models/accounts_models.dart';
import '../services/accounts_audit_service.dart';
import '../services/accounts_dashboard_service.dart';
import '../services/accounts_refund_requests_service.dart';
import '../services/accounts_reports_service.dart';

final accountsDashboardServiceProvider = Provider<AccountsDashboardService>(
  (ref) => AccountsDashboardService(),
);

final accountsAuditServiceProvider = Provider<AccountsAuditService>(
  (ref) => AccountsAuditService(),
);

final accountsReportsServiceProvider = Provider<AccountsReportsService>(
  (ref) => AccountsReportsService(),
);

final accountsRefundRequestsServiceProvider =
    Provider<AccountsRefundRequestsService>(
      (ref) => AccountsRefundRequestsService(),
    );

final accountsPeriodProvider = StateProvider<AccountsPeriodFilter>((ref) {
  return const AccountsPeriodFilter(period: 'today');
});

final accountsRevenueFilterProvider = StateProvider<AccountsRevenueFilter>((
  ref,
) {
  return const AccountsRevenueFilter(period: 'today');
});

final accountsDashboardProvider =
    FutureProvider.autoDispose<AccountsDashboardBundle>((ref) async {
      final period = ref.watch(accountsPeriodProvider);
      final staff = ref.watch(authProvider).staff;
      final svc = ref.watch(accountsDashboardServiceProvider);
      return svc.fetchDashboard(
        period: period.period,
        asOf: period.asOf,
        isHead: canViewAccountsHeadData(staff),
      );
    });

final accountsRefundHistoryProvider =
    FutureProvider.autoDispose<List<AccountsAuditLogEntry>>((ref) async {
      final svc = ref.watch(accountsAuditServiceProvider);
      final now = DateTime.now();
      return svc.fetchRefundHistory(
        from: now.subtract(const Duration(days: 90)),
        to: now,
      );
    });

final accountsAuditLogsProvider =
    FutureProvider.autoDispose<AccountsAuditComplianceBundle>((ref) async {
      final svc = ref.watch(accountsAuditServiceProvider);
      return svc.fetchAuditLogs(take: 100);
    });

final accountsComplianceProvider =
    FutureProvider.autoDispose<List<AccountsComplianceItem>>((ref) async {
      final svc = ref.watch(accountsAuditServiceProvider);
      return svc.fetchComplianceChecklist();
    });

final accountsLeakDetectionProvider =
    FutureProvider.autoDispose<List<AccountsLeakFlag>>((ref) async {
      final svc = ref.watch(accountsAuditServiceProvider);
      return svc.fetchLeakDetection();
    });

final accountsInvoiceChangesProvider =
    FutureProvider.autoDispose<List<AccountsInvoiceChangeEntry>>((ref) async {
      final svc = ref.watch(accountsAuditServiceProvider);
      return svc.fetchInvoiceChanges(take: 100);
    });

final accountsStaffActivityProvider =
    FutureProvider.autoDispose<List<AccountsStaffActivityRow>>((ref) async {
      final period = ref.watch(accountsPeriodProvider);
      final svc = ref.watch(accountsAuditServiceProvider);
      return svc.fetchStaffActivity(period: period.period, asOf: period.asOf);
    });

final accountsAgingReportProvider =
    FutureProvider.autoDispose<AccountsAgingReport>((ref) async {
      final svc = ref.watch(accountsReportsServiceProvider);
      return svc.fetchAgingReport();
    });

final accountsProfitLossProvider =
    FutureProvider.autoDispose<AccountsProfitLossReport>((ref) async {
      final period = ref.watch(accountsPeriodProvider);
      final svc = ref.watch(accountsReportsServiceProvider);
      return svc.fetchProfitLoss(period: period.period, asOf: period.asOf);
    });

final accountsCashFlowProvider =
    FutureProvider.autoDispose<AccountsCashFlowReport>((ref) async {
      final period = ref.watch(accountsPeriodProvider);
      final svc = ref.watch(accountsReportsServiceProvider);
      return svc.fetchCashFlow(period: period.period, asOf: period.asOf);
    });

final accountsDailyCollectionsProvider =
    FutureProvider.autoDispose<List<AccountsDailyCollectionRow>>((ref) async {
      final svc = ref.watch(accountsReportsServiceProvider);
      final now = DateTime.now();
      final from = now.subtract(const Duration(days: 30));
      return svc.fetchDailyCollections(from: from, to: now);
    });

final accountsRevenueByServiceProvider =
    FutureProvider.autoDispose<List<AccountsServiceRevenueRow>>((ref) async {
      final filter = ref.watch(accountsRevenueFilterProvider);
      final svc = ref.watch(accountsReportsServiceProvider);
      return svc.fetchRevenueByService(
        period: filter.period,
        asOf: filter.asOf,
        from: filter.from,
        to: filter.to,
      );
    });

class AccountsRevenueByServiceDetailsParams {
  const AccountsRevenueByServiceDetailsParams({
    required this.period,
    required this.serviceCategory,
    this.asOf,
    this.from,
    this.to,
    this.skip = 0,
    this.take = 50,
    this.q,
  });

  final String period;
  final String serviceCategory;
  final DateTime? asOf;
  final DateTime? from;
  final DateTime? to;
  final int skip;
  final int take;
  final String? q;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccountsRevenueByServiceDetailsParams &&
          runtimeType == other.runtimeType &&
          period == other.period &&
          serviceCategory == other.serviceCategory &&
          asOf == other.asOf &&
          from == other.from &&
          to == other.to &&
          skip == other.skip &&
          take == other.take &&
          q == other.q;

  @override
  int get hashCode =>
      Object.hash(period, serviceCategory, asOf, from, to, skip, take, q);
}

final accountsRevenueByServiceDetailsProvider = FutureProvider.autoDispose
    .family<
      AccountsRevenueByServiceDetailsResponse,
      AccountsRevenueByServiceDetailsParams
    >((ref, params) async {
      final svc = ref.watch(accountsReportsServiceProvider);
      return svc.fetchRevenueByServiceDetails(
        period: params.period,
        asOf: params.asOf,
        from: params.from,
        to: params.to,
        serviceCategory: params.serviceCategory,
        skip: params.skip,
        take: params.take,
        q: params.q,
      );
    });

final accountsExpenseVsBudgetProvider =
    FutureProvider.autoDispose<List<AccountsExpenseBudgetRow>>((ref) async {
      final period = ref.watch(accountsPeriodProvider);
      final svc = ref.watch(accountsReportsServiceProvider);
      return svc.fetchExpenseVsBudget(period: period.period, asOf: period.asOf);
    });

final accountsCollectionEfficiencyProvider =
    FutureProvider.autoDispose<AccountsCollectionEfficiencyReport>((ref) async {
      final period = ref.watch(accountsPeriodProvider);
      final svc = ref.watch(accountsReportsServiceProvider);
      return svc.fetchCollectionEfficiency(
        period: period.period,
        asOf: period.asOf,
      );
    });

final accountsPeriodComparisonProvider =
    FutureProvider.autoDispose<List<AccountsPeriodComparisonPoint>>((
      ref,
    ) async {
      final period = ref.watch(accountsPeriodProvider);
      final svc = ref.watch(accountsReportsServiceProvider);
      return svc.fetchPeriodComparison(
        period: period.period,
        asOf: period.asOf,
      );
    });

final accountsWalletsSummaryProvider =
    FutureProvider.autoDispose<AccountsWalletsSummary>((ref) async {
      final svc = ref.watch(accountsReportsServiceProvider);
      return svc.fetchWalletsSummary();
    });

final accountsDailyCashReconProvider =
    FutureProvider.autoDispose<List<AccountsDailyCashRecon>>((ref) async {
      final svc = ref.watch(accountsReportsServiceProvider);
      final now = DateTime.now();
      return svc.fetchDailyCashRecons(
        from: now.subtract(const Duration(days: 30)),
        to: now,
      );
    });

final accountsBankReconProvider =
    FutureProvider.autoDispose<List<AccountsBankReconRow>>((ref) async {
      final svc = ref.watch(accountsReportsServiceProvider);
      return svc.fetchBankRecons();
    });

final accountsPendingApprovalsProvider =
    FutureProvider.autoDispose<List<AccountsApprovalRequest>>((ref) async {
      final svc = ref.watch(accountsReportsServiceProvider);
      return svc.fetchPendingApprovals();
    });

final accountsPendingRefundRequestsProvider =
    FutureProvider.autoDispose<List<AccountsPendingRefundRequest>>((ref) async {
      final svc = ref.watch(accountsRefundRequestsServiceProvider);
      return svc.fetchPending();
    });

final accountsFiscalPeriodsProvider =
    FutureProvider.autoDispose<List<AccountsFiscalPeriod>>((ref) async {
      final svc = ref.watch(accountsReportsServiceProvider);
      return svc.fetchPeriods();
    });

final accountsJournalEntriesProvider =
    FutureProvider.autoDispose<List<AccountsJournalEntry>>((ref) async {
      final svc = ref.watch(accountsReportsServiceProvider);
      return svc.fetchJournalEntries(take: 100);
    });

final accountsChartOfAccountsProvider =
    FutureProvider.autoDispose<List<AccountsChartAccount>>((ref) async {
      final svc = ref.watch(accountsReportsServiceProvider);
      return svc.fetchChartOfAccounts();
    });
