import 'package:dio/dio.dart';

import '../models/admission_alert_model.dart';
import 'api_service.dart';

class AdmissionAlertService {
  AdmissionAlertService() : _dio = ApiService().dio;

  final Dio _dio;

  List<dynamic> _listData(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'] ?? raw['items'] ?? raw['results'];
      return inner is List ? inner : const [];
    }
    return const [];
  }

  /// GET `/admissions/:admissionId/alerts`
  Future<List<AdmissionAlertModel>> list(
    String admissionId, {
    bool unresolvedOnly = false,
  }) async {
    final response = await _dio.get<dynamic>(
      '/admissions/$admissionId/alerts',
      queryParameters: {
        if (unresolvedOnly) 'unresolvedOnly': 'true',
      },
    );
    return _listData(response.data)
        .map(
          (e) => AdmissionAlertModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// POST `/admissions/:admissionId/alerts`
  Future<AdmissionAlertModel> create({
    required String admissionId,
    required String severity,
    required String message,
    String? title,
  }) async {
    final body = <String, dynamic>{
      'severity': severity,
      'message': message,
      if (title != null && title.isNotEmpty) 'title': title,
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/admissions/$admissionId/alerts',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Create alert returned no data');
    }
    return AdmissionAlertModel.fromJson(data);
  }

  /// PATCH `/admissions/:admissionId/alerts/:alertId/resolve`
  Future<AdmissionAlertModel> resolve({
    required String admissionId,
    required String alertId,
    String? note,
  }) async {
    final body = <String, dynamic>{
      if (note != null && note.isNotEmpty) 'note': note,
    };
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admissions/$admissionId/alerts/$alertId/resolve',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Resolve alert returned no data');
    }
    return AdmissionAlertModel.fromJson(data);
  }
}
