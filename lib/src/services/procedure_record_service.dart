import 'package:dio/dio.dart';

import '../helper/app_timezone.dart';
import '../models/procedure_record_model.dart';
import 'api_service.dart';

class ProcedureRecordService {
  ProcedureRecordService() : _dio = ApiService().dio;

  final Dio _dio;

  List<dynamic> _listData(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map<String, dynamic>) {
      final inner = raw['data'] ?? raw['items'] ?? raw['results'];
      return inner is List ? inner : const [];
    }
    return const [];
  }

  /// GET `/admissions/:admissionId/procedure-records`
  Future<List<ProcedureRecordModel>> list(String admissionId) async {
    final response = await _dio.get<dynamic>(
      '/admissions/$admissionId/procedure-records',
    );
    return _listData(response.data)
        .map(
          (e) => ProcedureRecordModel.fromJson(e as Map<String, dynamic>),
        )
        .toList();
  }

  /// POST `/admissions/:admissionId/procedure-records`
  Future<ProcedureRecordModel> create({
    required String admissionId,
    required String nurseId,
    required String procedureType,
    required String description,
    String? outcome,
    String? complications,
    DateTime? recordedAt,
  }) async {
    final body = <String, dynamic>{
      'nurseId': nurseId,
      'procedureType': procedureType,
      'description': description,
      if (outcome != null && outcome.isNotEmpty) 'outcome': outcome,
      if (complications != null && complications.isNotEmpty)
        'complications': complications,
      'recordedAt': AppTimezone.toBackendIso(recordedAt ?? AppTimezone.now()),
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/admissions/$admissionId/procedure-records',
      data: body,
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Create procedure record returned no data');
    }
    return ProcedureRecordModel.fromJson(data);
  }
}
