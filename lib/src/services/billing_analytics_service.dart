import 'package:dio/dio.dart';

import '../models/billing_analytics_models.dart';
import 'api_service.dart';

/// Analytics under `/billing/analytics` (see docs/billing-dashboard-api.md).
class BillingAnalyticsService {
  BillingAnalyticsService() : _dio = ApiService().dio;

  final Dio _dio;

  String _dioMessage(DioException e, String fallback) {
    final payload = e.response?.data;
    if (payload is Map && payload['message'] != null) {
      return payload['message'].toString();
    }
    return e.message ?? fallback;
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw FormatException('Expected JSON object');
  }

  Future<RevenueSummary> getRevenueSummary({
    required String period,
    DateTime? asOf,
  }) async {
    try {
      final response = await _dio.get(
        '/billing/analytics/revenue-summary',
        queryParameters: {
          'period': period,
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
        },
      );
      return RevenueSummary.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception('Revenue summary: ${_dioMessage(e, 'Unknown error')}');
    }
  }

  Future<UnpaidSummary> getUnpaidSummary({
    required String period,
    DateTime? asOf,
  }) async {
    try {
      final response = await _dio.get(
        '/billing/analytics/unpaid-summary',
        queryParameters: {
          'period': period,
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
        },
      );
      return UnpaidSummary.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception('Unpaid summary: ${_dioMessage(e, 'Unknown error')}');
    }
  }

  Future<OverdueSummary> getOverdueSummary({
    required String period,
    DateTime? asOf,
  }) async {
    try {
      final response = await _dio.get(
        '/billing/analytics/overdue-summary',
        queryParameters: {
          'period': period,
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
        },
      );
      return OverdueSummary.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception('Overdue summary: ${_dioMessage(e, 'Unknown error')}');
    }
  }

  Future<RevenueSeries> getRevenueSeries({
    required String period,
    DateTime? asOf,
  }) async {
    try {
      final response = await _dio.get(
        '/billing/analytics/revenue-series',
        queryParameters: {
          'period': period,
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
        },
      );
      return RevenueSeries.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception('Revenue series: ${_dioMessage(e, 'Unknown error')}');
    }
  }

  Future<RevenueByDepartment> getRevenueByDepartment({
    required String period,
    DateTime? asOf,
  }) async {
    try {
      final response = await _dio.get(
        '/billing/analytics/revenue-by-department',
        queryParameters: {
          'period': period,
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
        },
      );
      return RevenueByDepartment.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        'Revenue by department: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }

  Future<RecentInvoicesResponse> getRecentInvoices({
    required String period,
    DateTime? asOf,
    int take = 20,
  }) async {
    final capped = take.clamp(1, 100);
    try {
      final response = await _dio.get(
        '/billing/analytics/recent-invoices',
        queryParameters: {
          'period': period,
          'take': capped,
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
        },
      );
      return RecentInvoicesResponse.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception('Recent invoices: ${_dioMessage(e, 'Unknown error')}');
    }
  }
}
