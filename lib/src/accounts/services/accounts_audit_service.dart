import 'package:dio/dio.dart';

import '../models/accounts_models.dart';
import 'accounts_base_service.dart';
import 'accounts_endpoints.dart';

class AccountsAuditService extends AccountsBaseService {
  AccountsAuditService({super.dio});

  Future<AccountsAuditComplianceBundle> fetchAuditLogs({
    String? entity,
    String? action,
    String? user,
    DateTime? from,
    DateTime? to,
    int? skip,
    int? take,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        AccountsEndpoints.auditLogs,
        queryParameters: {
          if (entity != null && entity.isNotEmpty) 'entity': entity,
          if (action != null && action.isNotEmpty) 'action': action,
          if (user != null && user.isNotEmpty) 'user': user,
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
          if (skip != null) 'skip': skip,
          if (take != null) 'take': take,
        },
      );
      final map = asMap(response.data);
      final logs = asList(map, key: 'logs')
          .whereType<Map>()
          .map(
            (e) =>
                AccountsAuditLogEntry.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
      final compliance = asList(map, key: 'compliance')
          .whereType<Map>()
          .map(
            (e) =>
                AccountsComplianceItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
      return AccountsAuditComplianceBundle(logs: logs, compliance: compliance);
    } on DioException catch (e) {
      throwApi(e, 'Audit logs');
    }
  }

  Future<List<AccountsComplianceItem>> fetchComplianceChecklist() async {
    try {
      final response =
          await dio.get<dynamic>(AccountsEndpoints.complianceChecklist);
      return asList(response.data, key: 'compliance')
          .whereType<Map>()
          .map(
            (e) =>
                AccountsComplianceItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      throwApi(e, 'Compliance checklist');
    }
  }

  Future<void> acknowledgeCompliance(String code) async {
    try {
      await dio.patch<void>(
        '${AccountsEndpoints.complianceChecklist}/$code',
        data: {'status': 'Compliant'},
      );
    } on DioException catch (e) {
      throwApi(e, 'Acknowledge compliance');
    }
  }

  Future<List<AccountsInvoiceChangeEntry>> fetchInvoiceChanges({
    String? query,
    DateTime? from,
    DateTime? to,
    int? skip,
    int? take,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        AccountsEndpoints.invoiceChanges,
        queryParameters: {
          if (query != null && query.isNotEmpty) 'query': query,
          if (from != null) 'from': from.toUtc().toIso8601String(),
          if (to != null) 'to': to.toUtc().toIso8601String(),
          if (skip != null) 'skip': skip,
          if (take != null) 'take': take,
        },
      );
      return asList(response.data, key: 'changes')
          .whereType<Map>()
          .map(
            (e) => AccountsInvoiceChangeEntry.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    } on DioException catch (e) {
      throwApi(e, 'Invoice changes');
    }
  }

  Future<List<AccountsLeakFlag>> fetchLeakDetection() async {
    try {
      final response = await dio.get<dynamic>(AccountsEndpoints.leakDetection);
      return asList(response.data, key: 'leaks')
          .whereType<Map>()
          .map((e) => AccountsLeakFlag.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } on DioException catch (e) {
      throwApi(e, 'Leak detection');
    }
  }

  Future<List<AccountsStaffActivityRow>> fetchStaffActivity({
    required String period,
    DateTime? asOf,
  }) async {
    try {
      final response = await dio.get<dynamic>(
        AccountsEndpoints.staffActivity,
        queryParameters: {
          'period': period,
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
        },
      );
      return asList(response.data, key: 'rows')
          .whereType<Map>()
          .map(
            (e) =>
                AccountsStaffActivityRow.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      throwApi(e, 'Staff activity');
    }
  }

  Future<List<AccountsAuditLogEntry>> fetchRefundHistory({
    DateTime? from,
    DateTime? to,
    int take = 100,
  }) async {
    final bundle = await fetchAuditLogs(
      action: 'REFUND',
      from: from,
      to: to,
      take: take,
    );
    if (bundle.logs.isNotEmpty) return bundle.logs;

    // Fallback: filter audit logs by action containing refund (case-insensitive).
    final all = await fetchAuditLogs(from: from, to: to, take: take);
    return all.logs
        .where((l) => l.action.toUpperCase().contains('REFUND'))
        .toList();
  }
}
