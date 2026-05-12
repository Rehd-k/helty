import 'package:dio/dio.dart';

import 'api_service.dart';
import 'appointment_service.dart';
import '../models/encounter_model.dart';

/// Encounter (OPD visit) CRUD. All methods use the real API.
class EncounterService {
  EncounterService() : _dio = ApiService().dio;

  final Dio _dio;

  /// GET /encounters/:id — get one encounter (used by all encounter tabs).
  /// Optional [expand] e.g. `['specialtyModules','clinicalSections']` or `['*']`.
  Future<EncounterModel?> getById(
    String encounterId, {
    List<String>? expand,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/encounters/$encounterId',
      queryParameters: expand != null && expand.isNotEmpty
          ? {'expand': expand.join(',')}
          : null,
    );
    final data = response.data;
    if (data == null) return null;
    return EncounterModel.fromJson(data);
  }

  /// GET /encounters — list encounters.
  /// Query: doctorId, fromDate, toDate, status, skip, take.
  /// Omit [doctorId] to return encounters for all doctors (e.g. completed list).
  /// Response: { data: Encounter[], total: number } or array.
  Future<List<EncounterModel>> fetchOutpatientEncounters({
    String? doctorId,
    DateTime? fromDate,
    DateTime? toDate,
    String? status,
    int skip = 0,
    int take = 50,
  }) async {
    final query = <String, dynamic>{'skip': skip, 'take': take};
    if (doctorId != null && doctorId.isNotEmpty) query['doctorId'] = doctorId;
    if (fromDate != null) {
      query['fromDate'] = fromDate.toIso8601String();
    }
    if (toDate != null) {
      query['toDate'] = toDate.toIso8601String();
    }
    query['status'] = status ?? 'COMPLETED';

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

  /// Persists follow-up via [Appointment] when a date is set or an existing
  /// [followUpAppointmentId] is present; otherwise updates legacy encounter fields only.
  Future<EncounterModel> saveFollowUp({
    required String status,
    required String encounterId,
    required String patientId,
    DateTime? followUpDate,
    String? notes,
    String? referral,
    String? staffId,
    String? createdById,
    String? followUpAppointmentId,
    String? updatedById,
  }) async {
    final apptSvc = AppointmentService();

    if (followUpAppointmentId != null && followUpAppointmentId.isNotEmpty) {
      await apptSvc.updateAppointment(
        followUpAppointmentId,
        appointmentDate: followUpDate,
        status: 'SCHEDULED',
        notes: notes,
        referral: referral,
        staffId: staffId,
        updatedById: updatedById,
      );
      return await getById(encounterId) ??
          update(encounterId, {'followUpAppointmentId': followUpAppointmentId});
    }

    if (followUpDate != null) {
      final created = await apptSvc.createAppointment(
        patientId: patientId,
        appointmentDate: followUpDate,
        staffId: staffId,
        status: 'SCHEDULED',
        notes: notes,
        referral: referral,
        createdById: createdById,
        encounterId: encounterId,
      );
      return await getById(encounterId) ??
          update(encounterId, {'followUpAppointmentId': created.id});
    }

    return update(encounterId, {
      'followUpDate': followUpDate?.toIso8601String(),
      'followUpInstructions': notes,
      'referral': referral,
      'status': 'SCHEDULED',
    });
  }
}
