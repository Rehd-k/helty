import 'package:dio/dio.dart';

import 'api_service.dart';
import '../models/encounter_model.dart';

/// Encounter (OPD visit) CRUD. All methods use the real API.
class EncounterService {
  EncounterService() : _dio = ApiService().dio;

  final Dio _dio;

  /// GET /encounters/:id — get one encounter (used by all encounter tabs).
  Future<EncounterModel?> getById(String encounterId) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/encounters/$encounterId',
    );
    final data = response.data;
    if (data == null) return null;
    return EncounterModel.fromJson(data);
  }

  /// GET /encounters — list encounters. Query: doctorId, date (ISO date), status, skip, take.
  /// Response: { data: Encounter[], total: number } or array.
  Future<List<EncounterModel>> fetchOutpatientEncounters({
    String? doctorId,
    DateTime? date,
    String? status,
    int skip = 0,
    int take = 50,
  }) async {
    final query = <String, dynamic>{'skip': skip, 'take': take};
    if (doctorId != null && doctorId.isNotEmpty) query['doctorId'] = doctorId;
    if (date != null) query['date'] = date.toIso8601String().split('T').first;
    if (status != null && status.isNotEmpty) query['status'] = status;

    final response = await _dio.get<dynamic>(
      '/encounters',
      queryParameters: query,
    );
    final raw = response.data;
    if (raw is List) {
      return raw
          .map((e) => EncounterModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (raw is Map<String, dynamic>) {
      final list = raw['data'] as List? ?? [];
      return list
          .map((e) => EncounterModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// POST /encounters — create encounter. Returns the created encounter with real id from API.
  Future<EncounterModel> create({
    required String patientId,
    required String doctorId,
    String? encounterType,
    String? appointmentId,
    String? visitType,
    String? insurance,
  }) async {
    final body = <String, dynamic>{
      'patientId': patientId,
      'doctorId': doctorId,
      if (encounterType != null && encounterType.isNotEmpty)
        'encounterType': encounterType,
      if (appointmentId != null && appointmentId.isNotEmpty)
        'appointmentId': appointmentId,
      if (visitType != null && visitType.isNotEmpty) 'visitType': visitType,
      if (insurance != null && insurance.isNotEmpty) 'insurance': insurance,
    };
    final response = await _dio.post<Map<String, dynamic>>(
      '/encounters',
      data: body,
    );
    final data = response.data;
    if (data == null) throw StateError('Create encounter returned no data');
    return EncounterModel.fromJson(data);
  }

  /// PATCH /encounters/:id — partial update (any subset of encounter fields).
  Future<EncounterModel> update(String id, Map<String, dynamic> patch) async {
    // Serialize DateTime fields to ISO strings for API
    final body = Map<String, dynamic>.from(patch);
    if (body['closedAt'] is DateTime) {
      body['closedAt'] = (body['closedAt'] as DateTime).toIso8601String();
    }
    if (body['soapLockedAt'] is DateTime) {
      body['soapLockedAt'] = (body['soapLockedAt'] as DateTime)
          .toIso8601String();
    }

    final response = await _dio.patch<Map<String, dynamic>>(
      '/encounters/$id',
      data: body,
    );
    final data = response.data;
    if (data == null) throw StateError('Update encounter returned no data');
    return EncounterModel.fromJson(data);
  }

  /// PATCH /encounters/:id — partial update (any subset of encounter fields).
  Future<EncounterModel> saveDiagnosis(
    String id,
    Map<String, dynamic> patch,
  ) async {
    // Serialize DateTime fields to ISO strings for API
    final body = Map<String, dynamic>.from(patch);

    final response = await _dio.post<Map<String, dynamic>>(
      '/encounters/$id/diagnoses',
      data: body,
    );
    final data = response.data;
    if (data == null) throw StateError('Update encounter returned no data');
    return EncounterModel.fromJson(data);
  }

  /// Marks encounter as done and sets closedAt. Use when the doctor finishes with the patient.
  /// PATCH /encounters/:id with status: 'done', closedAt: now.
  Future<EncounterModel> complete(String encounterId) async {
    final now = DateTime.now();
    return update(encounterId, {
      'status': 'COMPLETED',
      'closedAt': now.toIso8601String(),
    });
  }
}
