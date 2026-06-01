import 'package:dio/dio.dart';

import '../models/monitoring_chart_model.dart';
import 'api_service.dart';

class MonitoringChartService {
  MonitoringChartService() : _dio = ApiService().dio;

  final Dio _dio;

  List<dynamic> _listData(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'] ?? raw['items'] ?? raw['results'];
      return inner is List ? inner : const [];
    }
    return const [];
  }

  /// GET `/admissions/:admissionId/monitoring-charts`
  Future<List<MonitoringChartModel>> list(String admissionId) async {
    final response = await _dio.get<dynamic>(
      '/admissions/$admissionId/monitoring-charts',
    );
    return _listData(response.data)
        .map(
          (e) => MonitoringChartModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// POST `/admissions/:admissionId/monitoring-charts`
  Future<MonitoringChartModel> create({
    required String admissionId,
    required String chartType,
    required Map<String, dynamic> value,
    String? nurseId,
  }) async {
    final body = <String, dynamic>{
      'chartType': chartType,
      'value': value,
      if (nurseId != null && nurseId.isNotEmpty) 'nurseId': nurseId,
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/admissions/$admissionId/monitoring-charts',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Create monitoring chart returned no data');
    }
    return MonitoringChartModel.fromJson(data);
  }

  /// PATCH `/admissions/:admissionId/monitoring-charts/:chartId`
  Future<MonitoringChartModel> update({
    required String admissionId,
    required String chartId,
    Map<String, dynamic>? value,
    String? chartType,
  }) async {
    final body = <String, dynamic>{
      if (value != null) 'value': value,
      if (chartType != null) 'chartType': chartType,
    };
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admissions/$admissionId/monitoring-charts/$chartId',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Update monitoring chart returned no data');
    }
    return MonitoringChartModel.fromJson(data);
  }
}
