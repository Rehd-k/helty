import 'package:dio/dio.dart';

import '../models/accounts_models.dart';
import 'accounts_base_service.dart';
import 'accounts_endpoints.dart';

class AccountsReportsService extends AccountsBaseService {
  AccountsReportsService({super.dio});

  Future<List<AccountsDailyCollectionRow>> fetchDailyCollections({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        AccountsEndpoints.dailyCollections,
        queryParameters: {
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
        },
      );
      return asList(response.data, key: 'rows')
          .whereType<Map>()
          .map(
            (e) =>
                AccountsDailyCollectionRow.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      throwApi(e, 'Daily collections');
    }
  }

  Future<AccountsAgingReport> fetchAgingReport({String? type}) async {
    try {
      final response = await dio.get<dynamic>(
        AccountsEndpoints.aging,
        queryParameters: {if (type != null) 'type': type},
      );
      return AccountsAgingReport.fromJson(asMap(response.data));
    } on DioException catch (e) {
      throwApi(e, 'Aging report');
    }
  }

  Future<AccountsProfitLossReport> fetchProfitLoss({
    required String period,
    DateTime? asOf,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        AccountsEndpoints.profitLoss,
        queryParameters: {
          'period': period,
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
        },
      );
      return AccountsProfitLossReport.fromJson(asMap(response.data));
    } on DioException catch (e) {
      throwApi(e, 'Profit & loss');
    }
  }

  Future<AccountsCashFlowReport> fetchCashFlow({
    required String period,
    DateTime? asOf,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        AccountsEndpoints.cashFlow,
        queryParameters: {
          'period': period,
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
        },
      );
      return AccountsCashFlowReport.fromJson(asMap(response.data));
    } on DioException catch (e) {
      throwApi(e, 'Cash flow');
    }
  }

  Future<List<AccountsServiceRevenueRow>> fetchRevenueByService({
    required String period,
    DateTime? asOf,
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        AccountsEndpoints.revenueByService,
        queryParameters: {
          'period': period,
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
        },
      );
      return asList(response.data, key: 'rows')
          .whereType<Map>()
          .map(
            (e) => AccountsServiceRevenueRow.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throwApi(e, 'Revenue by service');
    }
  }

  Future<AccountsRevenueByServiceDetailsResponse> fetchRevenueByServiceDetails({
    required String period,
    DateTime? asOf,
    DateTime? from,
    DateTime? to,
    required String serviceCategory,
    int skip = 0,
    int take = 50,
    String? q,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        AccountsEndpoints.revenueByServiceDetails,
        queryParameters: {
          'period': period,
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
          'serviceCategory': serviceCategory,
          'skip': skip,
          'take': take,
          if (q != null && q.trim().isNotEmpty) 'q': q.trim(),
        },
      );
      return AccountsRevenueByServiceDetailsResponse.fromJson(
        asMap(response.data),
      );
    } on DioException catch (e) {
      throwApi(e, 'Revenue by service details');
    }
  }

  Future<List<AccountsExpenseBudgetRow>> fetchExpenseVsBudget({
    required String period,
    DateTime? asOf,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        AccountsEndpoints.expenseVsBudget,
        queryParameters: {
          'period': period,
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
        },
      );
      return asList(response.data, key: 'rows')
          .whereType<Map>()
          .map(
            (e) => AccountsExpenseBudgetRow.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throwApi(e, 'Expense vs budget');
    }
  }

  Future<AccountsCollectionEfficiencyReport> fetchCollectionEfficiency({
    required String period,
    DateTime? asOf,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        AccountsEndpoints.collectionEfficiency,
        queryParameters: {
          'period': period,
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
        },
      );
      return AccountsCollectionEfficiencyReport.fromJson(asMap(response.data));
    } on DioException catch (e) {
      throwApi(e, 'Collection efficiency');
    }
  }

  Future<List<AccountsPeriodComparisonPoint>> fetchPeriodComparison({
    required String period,
    DateTime? asOf,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        AccountsEndpoints.periodComparison,
        queryParameters: {
          'period': period,
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
        },
      );
      return asList(response.data, key: 'points')
          .whereType<Map>()
          .map(
            (e) => AccountsPeriodComparisonPoint.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throwApi(e, 'Period comparison');
    }
  }

  Future<AccountsWalletsSummary> fetchWalletsSummary() async {
    try {
      final response = await dio.get<dynamic>(AccountsEndpoints.walletsSummary);
      return AccountsWalletsSummary.fromJson(asMap(response.data));
    } on DioException catch (e) {
      throwApi(e, 'Wallets summary');
    }
  }

  Future<List<AccountsDailyCashRecon>> fetchDailyCashRecons({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        AccountsEndpoints.dailyCashRecon,
        queryParameters: {
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
        },
      );
      return asList(response.data, key: 'rows')
          .whereType<Map>()
          .map(
            (e) =>
                AccountsDailyCashRecon.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      throwApi(e, 'Daily cash recon');
    }
  }

  Future<AccountsDailyCashRecon> submitDailyCashRecon({
    required DateTime date,
    required double countedCash,
    String? notes,
  }) async {
    final response = await dio.post<dynamic>(
      AccountsEndpoints.dailyCashRecon,
      data: {
        'date': date.toUtc().toIso8601String(),
        'countedCash': countedCash,
        if (notes != null) 'notes': notes,
      },
    );
    return AccountsDailyCashRecon.fromJson(asMap(response.data));
  }

  Future<List<AccountsBankReconRow>> fetchBankRecons() async {
    try {
      final response = await dio.get<dynamic>(AccountsEndpoints.bankRecon);
      return asList(response.data, key: 'rows')
          .whereType<Map>()
          .map(
            (e) => AccountsBankReconRow.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      throwApi(e, 'Bank recon');
    }
  }

  Future<List<AccountsApprovalRequest>> fetchPendingApprovals() async {
    try {
      final response =
          await dio.get<dynamic>(AccountsEndpoints.approvalsPending);
      return asList(response.data, key: 'approvals')
          .whereType<Map>()
          .map(
            (e) =>
                AccountsApprovalRequest.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      throwApi(e, 'Approvals');
    }
  }

  Future<void> approveRequest(String id, {String? note}) async {
    await dio.post<void>(
      AccountsEndpoints.approveApproval(id),
      data: {if (note != null) 'note': note},
    );
  }

  Future<void> rejectRequest(String id, {required String reason}) async {
    await dio.post<void>(
      AccountsEndpoints.rejectApproval(id),
      data: {'reason': reason},
    );
  }

  Future<List<AccountsFiscalPeriod>> fetchPeriods() async {
    try {
      final response = await dio.get<dynamic>(AccountsEndpoints.periods);
      return asList(response.data, key: 'periods')
          .whereType<Map>()
          .map(
            (e) => AccountsFiscalPeriod.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      throwApi(e, 'Fiscal periods');
    }
  }

  Future<void> closePeriod(String id) async {
    await dio.post<void>(AccountsEndpoints.closePeriod(id));
  }

  Future<List<AccountsJournalEntry>> fetchJournalEntries({
    DateTime? from,
    DateTime? to,
    int? skip,
    int? take,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        AccountsEndpoints.journalEntries,
        queryParameters: {
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
          if (skip != null) 'skip': skip,
          if (take != null) 'take': take,
        },
      );
      return asList(response.data, key: 'entries')
          .whereType<Map>()
          .map(
            (e) => AccountsJournalEntry.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      throwApi(e, 'Journal entries');
    }
  }

  Future<AccountsJournalEntry> postJournalEntry({
    required DateTime entryDate,
    required String reference,
    required String description,
    required String debitAccount,
    required String creditAccount,
    required double amount,
  }) async {
    final response = await dio.post<dynamic>(
      AccountsEndpoints.journalEntries,
      data: {
        'entryDate': entryDate.toUtc().toIso8601String(),
        'reference': reference,
        'description': description,
        'debitAccount': debitAccount,
        'creditAccount': creditAccount,
        'amount': amount,
      },
    );
    return AccountsJournalEntry.fromJson(asMap(response.data));
  }

  Future<List<AccountsChartAccount>> fetchChartOfAccounts() async {
    try {
      final response =
          await dio.get<dynamic>(AccountsEndpoints.chartOfAccounts);
      return asList(response.data, key: 'accounts')
          .whereType<Map>()
          .map(
            (e) => AccountsChartAccount.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      throwApi(e, 'Chart of accounts');
    }
  }

  Future<AccountsChartAccount> createChartAccount({
    required String code,
    required String name,
    required String type,
  }) async {
    final response = await dio.post<dynamic>(
      AccountsEndpoints.chartOfAccounts,
      data: {'code': code, 'name': name, 'type': type},
    );
    return AccountsChartAccount.fromJson(asMap(response.data));
  }
}
