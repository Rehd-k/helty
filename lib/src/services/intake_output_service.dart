import 'package:dio/dio.dart';

import '../models/intake_output_record_model.dart';
import 'api_service.dart';

class IntakeOutputService {
  IntakeOutputService() : _dio = ApiService().dio;

  final Dio _dio;

  List<dynamic> _listData(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'] ?? raw['items'] ?? raw['results'];
      return inner is List ? inner : const [];
    }
    return const [];
  }

  /// GET `/admissions/:admissionId/intake-output-records`
  Future<List<IntakeOutputRecordModel>> list(String admissionId) async {
    final response = await _dio.get<dynamic>(
      '/admissions/$admissionId/intake-output-records',
    );
    return _listData(response.data)
        .map(
          (e) => IntakeOutputRecordModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  /// POST `/admissions/:admissionId/intake-output-records`
  Future<IntakeOutputRecordModel> create({
    required String admissionId,
    required String nurseId,
    required String type,
    required String category,
    required double amountMl,
    DateTime? recordedAt,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      'nurseId': nurseId,
      'type': type,
      'category': category,
      'amountMl': amountMl,
      if (recordedAt != null)
        'recordedAt': recordedAt.toUtc().toIso8601String(),
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/admissions/$admissionId/intake-output-records',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Create intake/output returned no data');
    }
    return IntakeOutputRecordModel.fromJson(data);
  }

  /// PATCH `/admissions/:admissionId/intake-output-records/:recordId`
  Future<IntakeOutputRecordModel> update({
    required String admissionId,
    required String recordId,
    String? type,
    String? category,
    double? amountMl,
    DateTime? recordedAt,
    String? notes,
  }) async {
    final body = <String, dynamic>{
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      if (amountMl != null) 'amountMl': amountMl,
      if (recordedAt != null)
        'recordedAt': recordedAt.toUtc().toIso8601String(),
      if (notes != null) 'notes': notes,
    };
    final response = await _dio.patch<Map<String, dynamic>>(
      '/admissions/$admissionId/intake-output-records/$recordId',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Update intake/output returned no data');
    }
    return IntakeOutputRecordModel.fromJson(data);
  }
}
