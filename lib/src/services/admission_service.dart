import 'package:dio/dio.dart';

import 'api_service.dart';
import '../models/admission_model.dart';

class AdmissionDischargeBlockedException implements Exception {
  AdmissionDischargeBlockedException(this.message, {this.raw});

  final String message;
  final Object? raw;

  @override
  String toString() => message;
}

class AdmissionService {
  AdmissionService() : _dio = ApiService().dio;

  final Dio _dio;

  AdmissionModel _parseAdmissionFromResponse(dynamic data) {
    if (data is Map<String, dynamic>) {
      final nested =
          data['admission'] ??
          data['data'] ??
          data['result'] ??
          data['item'] ??
          data;
      if (nested is Map<String, dynamic>) {
        return AdmissionModel.fromJson(nested);
      }
    }
    throw StateError('Admission response shape is invalid');
  }

  /// POST /admissions — create admission from encounter. Returns created admission with id from API.
  Future<AdmissionModel> create({
    required String patientId,
    required String encounterId,
    String? reason,
    String? ward,
    String? wardId,
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
      if (wardId != null && wardId.isNotEmpty) 'wardId': wardId,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
      if (ward != null && ward.isNotEmpty) 'ward': ward,
      if (bedPreference != null && bedPreference.isNotEmpty)
        'bedId': bedPreference,
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
    return _parseAdmissionFromResponse(data);
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
    final response = await _dio.get<dynamic>(
      '/admissions',
      queryParameters: query.isEmpty ? null : query,
    );
    final data = response.data;
    if (data == null) return [];

    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => AdmissionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (data is! Map) return [];

    final map = Map<String, dynamic>.from(data);
    final admissionsData = map['admissions'];
    if (admissionsData == null) return [];

    if (admissionsData is List) {
      return admissionsData
          .whereType<Map>()
          .map((e) => AdmissionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (admissionsData is Map) {
      return [
        AdmissionModel.fromJson(Map<String, dynamic>.from(admissionsData)),
      ];
    }

    return [];
  }

  /// GET /admissions/:id — get a single admission by id.
  Future<AdmissionModel> getOneById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('/admissions/$id');
    final data = response.data;
    if (data == null) throw StateError('Get admission returned no data');
    return _parseAdmissionFromResponse(data);
  }

  /// GET /admissions/patient/:patientId — list admissions for a patient.
  Future<List<AdmissionModel>> getByPatientId(String patientId) async {
    final response = await _dio.get<dynamic>('/admissions/patient/$patientId');
    final data = response.data;
    if (data == null) return [];

    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => AdmissionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (data is! Map) return [];

    final map = Map<String, dynamic>.from(data);
    final admissionsData = map['admissions'] ?? map['data'] ?? map['items'];
    if (admissionsData is List) {
      return admissionsData
          .whereType<Map>()
          .map((e) => AdmissionModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }
    if (admissionsData is Map) {
      return [
        AdmissionModel.fromJson(Map<String, dynamic>.from(admissionsData)),
      ];
    }
    return [];
  }

  /// PATCH /admissions/:id — partial update admission.
  Future<AdmissionModel> patch(String id, Map<String, dynamic> patch) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '/admissions/$id',
        data: patch,
      );
      final data = response.data;
      if (data == null) throw StateError('Patch admission returned no data');
      return _parseAdmissionFromResponse(data);
    } on DioException catch (e) {
      final payload = e.response?.data;
      final message = payload is Map && payload['message'] != null
          ? payload['message'].toString()
          : (e.message ?? 'Failed to update admission');
      if (e.response?.statusCode == 400 &&
          message.toLowerCase().contains('cannot discharge') &&
          message.toLowerCase().contains('unpaid')) {
        throw AdmissionDischargeBlockedException(message, raw: payload);
      }
      rethrow;
    }
  }

  Future<AdmissionModel> dischargeAdmission(
    String id, {
    DateTime? dischargeDate,
    required String outcome,
    required String dischargeSummary,
    String? otherImportantNotes,
  }) {
    final body = <String, dynamic>{
      'dischargeDate': (dischargeDate ?? DateTime.now())
          .toUtc()
          .toIso8601String(),
      'outcome': outcome,
      'dischargeSummary': dischargeSummary.trim(),
    };
    final other = otherImportantNotes?.trim();
    if (other != null && other.isNotEmpty) {
      body['otherImportantNotes'] = other;
    }
    return patch(id, body);
  }

  /// DELETE /admissions/:id — delete admission.
  Future<void> delete(String id) async {
    await _dio.delete('/admissions/$id');
  }
}
