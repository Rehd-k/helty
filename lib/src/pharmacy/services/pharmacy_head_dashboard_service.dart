import 'package:dio/dio.dart';

import '../../services/api_service.dart';
import '../models/pharmacy_reports_model.dart';
import 'pharmacy_reports_service.dart';

class PharmacyHeadDashboardQuery {
  const PharmacyHeadDashboardQuery({
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

class PharmacyHeadDashboardService {
  PharmacyHeadDashboardService()
    : _dio = ApiService().dio,
      _reports = PharmacyReportsService();

  final Dio _dio;
  final PharmacyReportsService _reports;

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

  Future<PharmacyHeadSummary> getSummary(
    PharmacyHeadDashboardQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/pharmacy/dashboard/head-summary',
        queryParameters: query.toQuery(),
      );
      return PharmacyHeadSummary.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Unable to load pharmacy head summary.'));
    }
  }

  Future<List<PharmacySalesProfitPoint>> getSalesProfitTrend(
    PharmacyHeadDashboardQuery query,
  ) async {
    try {
      final response = await _dio.get(
        '/pharmacy/dashboard/charts/sales-profit',
        queryParameters: query.toQuery(),
      );
      return _asList(response.data)
          .map(PharmacySalesProfitPoint.fromJson)
          .toList();
    } on DioException catch (_) {
      return const <PharmacySalesProfitPoint>[];
    }
  }

  /// Fetches summary, sales/profit trend, and per-store valuation in parallel.
  /// Only the summary is fatal; charts and valuation degrade to empty on error.
  Future<PharmacyHeadDashboardData> getDashboardData(
    PharmacyHeadDashboardQuery query,
  ) async {
    final results = await Future.wait<dynamic>([
      getSummary(query),
      getSalesProfitTrend(query),
      _reports
          .getInventoryValuation(
            const PharmacyValuationQuery(),
          )
          .catchError((_) => PharmacyInventoryValuation.empty),
    ]);

    return PharmacyHeadDashboardData(
      summary: results[0] as PharmacyHeadSummary,
      salesProfitTrend: results[1] as List<PharmacySalesProfitPoint>,
      storeValuations:
          (results[2] as PharmacyInventoryValuation).stores,
    );
  }
}
