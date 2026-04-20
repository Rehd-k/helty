import 'package:dio/dio.dart';

import '../models/handover_report_model.dart';
import 'api_service.dart';

class HandoverReportService {
  HandoverReportService() : _dio = ApiService().dio;

  final Dio _dio;

  List<dynamic> _listData(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'] ?? raw['items'] ?? raw['results'];
      return inner is List ? inner : const [];
    }
    return const [];
  }

  /// GET `/admissions/:admissionId/handover-reports`
  Future<List<HandoverReportModel>> list(String admissionId) async {
    final response = await _dio.get<dynamic>(
      '/admissions/$admissionId/handover-reports',
    );
    return _listData(response.data)
        .map(
          (e) => HandoverReportModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// POST `/admissions/:admissionId/handover-reports`
  Future<HandoverReportModel> create({
    required String admissionId,
    required String shiftType,
    required String summary,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'shiftType': shiftType,
      'summary': summary,
      'content': summary,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/admissions/$admissionId/handover-reports',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Create handover report returned no data');
    }
    return HandoverReportModel.fromJson(data);
  }
}
