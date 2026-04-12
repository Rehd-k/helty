import 'package:dio/dio.dart';

import '../models/nurse_dashboard_models.dart';
import 'api_service.dart';

/// Nurse overview dashboard (`docs/nestjs-nurse-dashboard-api-prompt.md`).
class NurseDashboardService {
  NurseDashboardService() : _dio = ApiService().dio;

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

  /// `GET /nurses/dashboard/overview`
  Future<NurseDashboardOverview> getOverview({
    required String timeRange,
    DateTime? asOf,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        '/nurses/dashboard/overview',
        queryParameters: {
          'timeRange': timeRange,
          if (asOf != null) 'asOf': asOf.toUtc().toIso8601String(),
        },
      );
      return NurseDashboardOverview.fromJson(_asMap(response.data));
    } on DioException catch (e) {
      throw Exception(
        'Nurse dashboard: ${_dioMessage(e, 'Unknown error')}',
      );
    }
  }
}
