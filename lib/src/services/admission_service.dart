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
  }) async {
    final body = <String, dynamic>{
      'patientId': patientId,
      'encounterId': encounterId,
      'isolationRequired': isolationRequired,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (ward != null && ward.isNotEmpty) 'ward': ward,
      if (bedPreference != null && bedPreference.isNotEmpty) 'bedPreference': bedPreference,
      if (provisionalDiagnosis != null && provisionalDiagnosis.isNotEmpty)
        'provisionalDiagnosis': provisionalDiagnosis,
      if (expectedLOS != null && expectedLOS.isNotEmpty) 'expectedLOS': expectedLOS,
      if (specialInstructions != null && specialInstructions.isNotEmpty)
        'specialInstructions': specialInstructions,
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/admissions',
      data: body,
    );
    final data = response.data;
    if (data == null) throw StateError('Create admission returned no data');
    return AdmissionModel.fromJson(data);
  }
}
