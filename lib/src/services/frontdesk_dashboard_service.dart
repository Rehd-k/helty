import 'package:dio/dio.dart';

import '../models/frontdesk_dashboard_models.dart';
import 'api_service.dart';

/// Frontdesk KPI + live queue (`docs/flutter-frontdesk-dashboard.md`).
class FrontdeskDashboardService {
  FrontdeskDashboardService() : _dio = ApiService().dio;

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

  /// `GET /frontdesk/dashboard/summary`
  Future<FrontdeskDashboardSummary> getSummary({DateTime? asOf}) async {
    try {
      final response = await _dio.get(
        '/frontdesk/dashboard/summary',
        queryParameters: {
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
        },
      );
      return FrontdeskDashboardSummary.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception('Frontdesk summary: ${_dioMessage(e, 'Unknown error')}');
    }
  }

  /// `GET /frontdesk/dashboard/queue`
  Future<List<FrontdeskQueueRow>> getQueue({DateTime? asOf}) async {
    try {
      final response = await _dio.get(
        '/frontdesk/dashboard/queue',
        queryParameters: {
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
        },
      );
      final data = response.data;
      if (data is! List) {
        throw FormatException('Expected JSON array for queue');
      }
      return data
          .map((e) => FrontdeskQueueRow.fromJson(_asMap(e)))
          .toList();
    } on DioException catch (e) {
      throw Exception('Frontdesk queue: ${_dioMessage(e, 'Unknown error')}');
    }
  }
}
