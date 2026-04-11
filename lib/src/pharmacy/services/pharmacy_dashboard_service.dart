import 'package:dio/dio.dart';

import '../../services/api_service.dart';
import '../models/pharmacy_dashboard_model.dart';

class PharmacyDashboardQuery {
  const PharmacyDashboardQuery({
    required this.fromDate,
    required this.toDate,
    this.storeId,
    this.payerType,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final String? storeId;
  final String? payerType;

  Map<String, dynamic> toQuery() {
    return {
      'fromDate': fromDate.toUtc().toIso8601String(),
      'toDate': toDate.toUtc().toIso8601String(),
      if (storeId != null && storeId!.trim().isNotEmpty) 'storeId': storeId,
      if (payerType != null &&
          payerType!.trim().isNotEmpty &&
          payerType!.toLowerCase() != 'all')
        'payerType': payerType,
    };
  }
}

class PharmacyDashboardService {
  PharmacyDashboardService() : _dio = ApiService().dio;

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

  Future<PharmacyDashboardSummary> getSummary(PharmacyDashboardQuery query) async {
    try {
      final response = await _dio.get(
        '/pharmacy/dashboard/summary',
        queryParameters: query.toQuery(),
      );
      return PharmacyDashboardSummary.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Unable to load pharmacy summary.'));
    }
  }

  Future<List<PharmacyOrderStatusItem>> getOrderStatuses(
    PharmacyDashboardQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/pharmacy/dashboard/orders-status',
        queryParameters: query.toQuery(),
      );
      return _asList(response.data)
          .map(PharmacyOrderStatusItem.fromJson)
          .toList();
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Unable to load order statuses.'));
    }
  }

  Future<List<PharmacyTopSellingItem>> getTopSelling(
    PharmacyDashboardQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/pharmacy/dashboard/top-selling',
        queryParameters: query.toQuery(),
      );
      return _asList(response.data).map(PharmacyTopSellingItem.fromJson).toList();
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Unable to load top-selling medications.'));
    }
  }

  Future<List<PharmacyRevenuePoint>> getRevenueTrend(
    PharmacyDashboardQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/pharmacy/dashboard/charts/revenue',
        queryParameters: query.toQuery(),
      );
      return _asList(response.data).map(PharmacyRevenuePoint.fromJson).toList();
    } on DioException catch (_) {
      return const <PharmacyRevenuePoint>[];
    }
  }

  Future<PharmacySafetySummary> getSafetySummary(
    PharmacyDashboardQuery query,
  ) async {
    try {
      final alertsResp = await _dio.get(
        '/pharmacy/dashboard/interaction-alerts',
        queryParameters: query.toQuery(),
      );
      final controlledResp = await _dio.get(
        '/pharmacy/dashboard/controlled-substances',
        queryParameters: query.toQuery(),
      );
      final alerts = _asMap(alertsResp.data);
      final controlled = _asMap(controlledResp.data);
      return PharmacySafetySummary.fromJson(<String, dynamic>{
        ...alerts,
        ...controlled,
      });
    } on DioException catch (_) {
      return const PharmacySafetySummary(
        totalAlerts: 0,
        highSeverityAlerts: 0,
        overriddenAlerts: 0,
        acceptedAlerts: 0,
        controlledDiscrepancies: 0,
      );
    }
  }

  Future<PharmacyDashboardData> getDashboardData(
    PharmacyDashboardQuery query,
  ) async {
    final results = await Future.wait<dynamic>([
      getSummary(query),
      getOrderStatuses(query),
      getTopSelling(query),
      getRevenueTrend(query),
      getSafetySummary(query),
    ]);

    return PharmacyDashboardData(
      summary: results[0] as PharmacyDashboardSummary,
      orderStatuses: results[1] as List<PharmacyOrderStatusItem>,
      topSelling: results[2] as List<PharmacyTopSellingItem>,
      revenueTrend: results[3] as List<PharmacyRevenuePoint>,
      safety: results[4] as PharmacySafetySummary,
    );
  }
}
