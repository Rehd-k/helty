import 'package:dio/dio.dart';

import 'api_service.dart';
import 'appointment_service.dart';
import '../models/encounter_edit_meta.dart';
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

  /// GET /encounters — list EMERGENCY encounters (ED board interim).
  Future<List<EncounterModel>> fetchEmergencyEncounters({
    String? doctorId,
    DateTime? fromDate,
    DateTime? toDate,
    String status = 'ONGOING',
    int skip = 0,
    int take = 50,
  }) async {
    final query = <String, dynamic>{
      'skip': skip,
      'take': take,
      'encounterType': 'EMERGENCY',
      'status': status,
    };
    if (doctorId != null && doctorId.isNotEmpty) query['doctorId'] = doctorId;
    if (fromDate != null) {
      query['fromDate'] = fromDate.toIso8601String();
    }
    if (toDate != null) {
      query['toDate'] = toDate.toIso8601String();
    }

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
    String? chiefComplaint,
    String? triageNotes,
    String? hpi,
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
      if (chiefComplaint != null && chiefComplaint.isNotEmpty)
        'chiefComplaint': chiefComplaint,
      if (triageNotes != null && triageNotes.isNotEmpty)
        'triageNotes': triageNotes,
      if (hpi != null && hpi.isNotEmpty) 'hpi': hpi,
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

  /// POST /encounters/:encounterId/diagnoses
  Future<EncounterModel> saveDiagnosis(
    String encounterId,
    Map<String, dynamic> patch, {
    String? editReason,
  }) async {
    final body = Map<String, dynamic>.from(patch);
    if (editReason != null && editReason.isNotEmpty) {
      body['editReason'] = editReason;
    }

    final response = await _dio.post<Map<String, dynamic>>(
      '/encounters/$encounterId/diagnoses',
      data: body,
    );
    final data = response.data;
    if (data == null) throw StateError('Create diagnosis returned no data');
    return EncounterModel.fromJson(data);
  }

  /// PATCH /encounters/:encounterId/diagnoses/:diagnosisId
  Future<EncounterModel> patchDiagnosis(
    String encounterId,
    String diagnosisId,
    Map<String, dynamic> patch, {
    String? editReason,
  }) async {
    final body = Map<String, dynamic>.from(patch);
    if (editReason != null && editReason.isNotEmpty) {
      body['editReason'] = editReason;
    }

    final response = await _dio.patch<Map<String, dynamic>>(
      '/encounters/$encounterId/diagnoses/$diagnosisId',
      data: body,
    );
    final data = response.data;
    if (data == null) throw StateError('Update diagnosis returned no data');
    return EncounterModel.fromJson(data);
  }

  /// DELETE /encounters/:encounterId/diagnoses/:diagnosisId
  Future<void> deleteDiagnosis(
    String encounterId,
    String diagnosisId, {
    String? editReason,
  }) async {
    await _dio.delete<void>(
      '/encounters/$encounterId/diagnoses/$diagnosisId',
      queryParameters: editReason != null && editReason.isNotEmpty
          ? {'editReason': editReason}
          : null,
    );
  }

  /// GET /encounters/:id/edit-history — newest first.
  Future<List<EncounterEditHistorySummary>> listEditHistory(
    String encounterId,
  ) async {
    final response = await _dio.get<dynamic>(
      '/encounters/$encounterId/edit-history',
    );
    final raw = response.data;
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map(
          (e) => EncounterEditHistorySummary.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .toList();
  }

  /// GET /encounters/:id/edit-history/:historyId
  Future<EncounterEditHistoryDetail> getEditHistoryDetail(
    String encounterId,
    String historyId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/encounters/$encounterId/edit-history/$historyId',
    );
    final data = response.data;
    if (data == null) {
      throw StateError('Edit history detail returned no data');
    }
    return EncounterEditHistoryDetail.fromJson(data);
  }

  /// PATCH /encounters/:id — set status to CANCELLED (e.g. ED LWBS).
  Future<EncounterModel> cancelEncounter(String encounterId) async {
    return update(encounterId, {'status': 'CANCELLED'});
  }

  /// PATCH /encounters/:id/complete — treating doctor only.
  Future<EncounterModel> complete(String encounterId) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/encounters/$encounterId/complete',
    );
    final data = response.data;
    if (data == null) throw StateError('Complete encounter returned no data');
    return EncounterModel.fromJson(data);
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
