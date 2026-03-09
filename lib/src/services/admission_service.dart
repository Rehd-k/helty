import 'dart:developer';

import 'package:dio/dio.dart';

import 'api_service.dart';
import '../models/admission_model.dart';

class AdmissionService {
  AdmissionService() : _dio = ApiService().dio;

  final Dio _dio;

  /// POST /admissions — create admission from encounter. Returns created admission with id from API.
  Future<AdmissionModel> create({
    required String patientId,
    required String encounterId,
    String? reason,
    String? ward,
    String? bedPreference,
    String? provisionalDiagnosis,
    String? expectedLOS,
    bool isolationRequired = false,
    String? specialInstructions,
    String? attendingDoctorId,
  }) async {
    final body = <String, dynamic>{
      'patientId': patientId,
      'encounterId': encounterId,
      'isolationRequired': isolationRequired,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (ward != null && ward.isNotEmpty) 'ward': ward,
      if (bedPreference != null && bedPreference.isNotEmpty)
        'bedPreference': bedPreference,
      if (provisionalDiagnosis != null && provisionalDiagnosis.isNotEmpty)
        'provisionalDiagnosis': provisionalDiagnosis,
      if (expectedLOS != null && expectedLOS.isNotEmpty)
        'expectedLOS': expectedLOS,
      if (specialInstructions != null && specialInstructions.isNotEmpty)
        'specialInstructions': specialInstructions,
      if (attendingDoctorId != null && attendingDoctorId.isNotEmpty)
        'attendingDoctorId': attendingDoctorId,
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/admissions',
      data: body,
    );
    final data = response.data;
    if (data == null) throw StateError('Create admission returned no data');
    return AdmissionModel.fromJson(data);
  }

  /// GET /admissions — list admissions. Query: status, ward, attendingDoctorId.
  Future<List<AdmissionModel>> list({
    String? status,
    String? ward,
    String? attendingDoctorId,
  }) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (ward != null && ward.isNotEmpty) query['ward'] = ward;
    if (attendingDoctorId != null && attendingDoctorId.isNotEmpty) {
      query['attendingDoctorId'] = attendingDoctorId;
    }
    final response = await _dio.get<Map<String, dynamic>>(
      '/admissions',
      queryParameters: query.isEmpty ? null : query,
    );
    final data = response.data;
    log('data: $data');
    if (data == null) return [];

    final admissionsData = data['admissions'];
    if (admissionsData == null) return [];

    if (admissionsData is List) {
      return admissionsData
          .whereType<Map<String, dynamic>>()
          .map(AdmissionModel.fromJson)
          .toList();
    }

    if (admissionsData is Map<String, dynamic>) {
      return [AdmissionModel.fromJson(admissionsData)];
    }

    return [];
  }
}
