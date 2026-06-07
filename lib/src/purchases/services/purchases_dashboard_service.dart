import 'package:dio/dio.dart';

import '../../services/api_service.dart';
import '../models/purchases_dashboard_model.dart';
import '../models/purchases_model.dart';
import '../models/purchases_usage_history_model.dart';

class PurchasesDashboardQuery {
  const PurchasesDashboardQuery({
    required this.fromDate,
    required this.toDate,
    this.storeId,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final String? storeId;

  Map<String, dynamic> toQuery() => {
    'fromDate': fromDate.toUtc().toIso8601String(),
    'toDate': toDate.toUtc().toIso8601String(),
    if (storeId != null && storeId!.trim().isNotEmpty) 'storeId': storeId,
  };
}

class PurchasesDashboardService {
  PurchasesDashboardService() : _dio = ApiService().dio;

  final Dio _dio;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  List<Map<String, dynamic>> _asList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (data is Map) {
      final map = _asMap(data);
      final nested = map['data'] ?? map['items'] ?? map['results'] ?? map['list'];
      if (nested is List) {
        return nested
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
    }
    return const <Map<String, dynamic>>[];
  }

  String _dioMessage(DioException e, String fallback) {
    final payload = e.response?.data;
    if (payload is Map && payload['message'] != null) {
      return payload['message'].toString();
    }
    return e.message ?? fallback;
  }

  int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value == null) return fallback;
    return int.tryParse(value.toString()) ?? fallback;
  }

  PaginatedResponse<T> _parsePaginated<T>(
    Response<dynamic> resp,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    dynamic data = resp.data;
    if (data == null) {
      return PaginatedResponse<T>(items: [], total: 0, page: 1, pageSize: 20);
    }
    if (data is List) {
      final items = data
          .map(
            (e) => fromJson(
              e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
      return PaginatedResponse<T>(
        items: items,
        total: items.length,
        page: 1,
        pageSize: items.length,
      );
    }
    if (data is! Map) {
      return PaginatedResponse<T>(items: [], total: 0, page: 1, pageSize: 20);
    }
    var map = Map<String, dynamic>.from(data);
    final inner = map['data'];
    if (inner is Map && inner is! List) {
      final innerMap = Map<String, dynamic>.from(inner);
      if (innerMap.containsKey('data') || innerMap.containsKey('items')) {
        map = innerMap;
      }
    }
    final list = map['data'] ?? map['items'] ?? map['results'] ?? map['list'];
    final rawList = list is List ? list : <dynamic>[];
    final items = rawList
        .map(
          (e) => fromJson(
            e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    final total = _toInt(
      map['total'] ?? map['totalCount'] ?? map['totalRecords'],
      items.length,
    );
    final skip = _toInt(map['skip'], 0);
    final take = _toInt(map['take'] ?? map['limit'], 20);
    final page = _toInt(map['page'], take > 0 ? (skip ~/ take) + 1 : 1);
    final pageSize = _toInt(map['pageSize'] ?? map['limit'], take);
    return PaginatedResponse<T>(
      items: items,
      total: total,
      page: page,
      pageSize: pageSize > 0 ? pageSize : 20,
    );
  }

  Future<PurchasesDashboardSummary> getSummary(
    PurchasesDashboardQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/purchases/dashboard/summary',
        queryParameters: query.toQuery(),
      );
      return PurchasesDashboardSummary.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Unable to load purchases summary.'));
    }
  }

  Future<List<PurchasesOrderStatusItem>> getOrderStatuses(
    PurchasesDashboardQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/purchases/dashboard/orders-status',
        queryParameters: query.toQuery(),
      );
      return _asList(response.data)
          .map(PurchasesOrderStatusItem.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Unable to load order statuses.'));
    }
  }

  Future<List<PurchasesTopItem>> getTopItems(
    PurchasesDashboardQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/purchases/dashboard/top-items',
        queryParameters: query.toQuery(),
      );
      return _asList(response.data).map(PurchasesTopItem.fromJson).toList();
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Unable to load top purchased items.'));
    }
  }

  Future<List<PurchasesTrendPoint>> getPurchaseTrend(
    PurchasesDashboardQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/purchases/dashboard/charts/purchase-value',
        queryParameters: query.toQuery(),
      );
      return _asList(response.data).map(PurchasesTrendPoint.fromJson).toList();
    } on DioException catch (_) {
      return const <PurchasesTrendPoint>[];
    }
  }

  Future<List<SupplierPerformanceItem>> getSupplierPerformance(
    PurchasesDashboardQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/purchases/dashboard/supplier-performance',
        queryParameters: query.toQuery(),
      );
      return _asList(response.data)
          .map(SupplierPerformanceItem.fromJson)
          .toList();
    } on DioException catch (_) {
      return const <SupplierPerformanceItem>[];
    }
  }

  Future<PaginatedResponse<PurchaseUsageHistoryItem>> getUsageHistory(
    PurchaseUsageHistoryQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/purchases/dashboard/usage-history',
        queryParameters: query.toQuery(),
      );
      return _parsePaginated(
        response,
        (m) => PurchaseUsageHistoryItem.fromJson(m),
      );
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Unable to load usage history.'));
    }
  }

  Future<PurchasesDashboardData> getDashboardData(
    PurchasesDashboardQuery query,
  ) async {
    final results = await Future.wait<dynamic>([
      getSummary(query),
      getOrderStatuses(query),
      getTopItems(query),
      getPurchaseTrend(query),
      getSupplierPerformance(query),
    ]);

    return PurchasesDashboardData(
      summary: results[0] as PurchasesDashboardSummary,
      orderStatuses: results[1] as List<PurchasesOrderStatusItem>,
      topItems: results[2] as List<PurchasesTopItem>,
      purchaseTrend: results[3] as List<PurchasesTrendPoint>,
      supplierPerformance: results[4] as List<SupplierPerformanceItem>,
    );
  }
}
