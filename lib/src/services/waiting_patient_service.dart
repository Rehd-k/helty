import 'package:dio/dio.dart';

import 'api_service.dart';
import '../models/consulting_room_model.dart';
import '../models/patient_vitals_model.dart';
import '../models/waiting_patient_model.dart';

// ── Query / filter DTOs ─────────────────────────────────────────────────────

/// Query params for GET waiting-patients (all / filter).
class WaitingPatientQuery {
  const WaitingPatientQuery({
    this.q,
    this.patientId,
    this.consultingRoomId,
    this.unassignedOnly,
    this.skip = 0,
    this.take = 20,
    this.sortBy,
    this.sortOrder = 'asc',
  });

  final String? q;
  final String? patientId;
  final String? consultingRoomId;
  final bool? unassignedOnly;
  final int skip;
  final int take;
  final String? sortBy;
  final String sortOrder;

  Map<String, dynamic> toQueryParameters() => {
        if (q != null && q!.isNotEmpty) 'q': q,
        if (patientId != null && patientId!.isNotEmpty) 'patientId': patientId,
        if (consultingRoomId != null && consultingRoomId!.isNotEmpty)
          'consultingRoomId': consultingRoomId,
        if (unassignedOnly != null) 'unassignedOnly': unassignedOnly,
        'skip': skip,
        'take': take,
        if (sortBy != null && sortBy!.isNotEmpty) 'sortBy': sortBy,
        'sortOrder': sortOrder,
      };
}

/// Query params for GET consulting-rooms (all / filter).
class ConsultingRoomQuery {
  const ConsultingRoomQuery({
    this.q,
    this.skip = 0,
    this.take = 50,
  });

  final String? q;
  final int skip;
  final int take;

  Map<String, dynamic> toQueryParameters() => {
        if (q != null && q!.isNotEmpty) 'q': q,
        'skip': skip,
        'take': take,
      };
}

/// Paginated list response (when API returns { data: [], total: n }).
class PaginatedWaitingPatients {
  const PaginatedWaitingPatients({
    required this.data,
    required this.total,
    this.skip = 0,
    this.take = 20,
  });

  final List<WaitingPatientModel> data;
  final int total;
  final int skip;
  final int take;

  bool get hasMore => skip + data.length < total;
}

/// Network operations for the nursing / triage flow.
///
/// Routes:
/// - GET/POST waiting-patients, PATCH/DELETE waiting-patients/:id
/// - POST patient-vitals, PATCH/DELETE patient-vitals/:id
/// - GET consulting-rooms (all / filter)
class WaitingPatientService {
  WaitingPatientService() : _dio = ApiService().dio;

  final Dio _dio;

  // ── Consulting rooms ────────────────────────────────────────────────────────
  // GET all / filter: consulting-rooms

  Future<List<ConsultingRoomModel>> fetchConsultingRooms([
    ConsultingRoomQuery? query,
  ]) async {
    final params = query?.toQueryParameters() ?? <String, dynamic>{};
    final resp = await _dio.get(
      '/consulting-rooms',
      queryParameters: params.isNotEmpty ? params : null,
    );
    final data = resp.data;

    final list = data is List
        ? data
        : (data is Map<String, dynamic> ? (data['data'] as List? ?? []) : []);

    return list
        .map((e) => ConsultingRoomModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── Patient vitals ──────────────────────────────────────────────────────────
  // POST: patient-vitals (add)
  // PATCH: patient-vitals/:id (update)
  // DELETE: patient-vitals/:id (delete)

  Future<PatientVitalsModel> createPatientVitals(
    CreatePatientVitalsDto dto,
  ) async {
    final resp = await _dio.post(
      '/patient-vitals',
      data: dto.toJson(),
    );
    return PatientVitalsModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<PatientVitalsModel> updatePatientVitals(
    String id,
    UpdatePatientVitalsDto dto,
  ) async {
    final resp = await _dio.patch(
      '/patient-vitals/$id',
      data: dto.toJson(),
    );
    return PatientVitalsModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deletePatientVitals(String id) async {
    await _dio.delete('/patient-vitals/$id');
  }

  // ── Consulting rooms CRUD (CMD admin) ───────────────────────────────────────

  Future<ConsultingRoomModel> createConsultingRoom({
    required String name,
    String? description,
    String? location,
    int capacity = 0,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      if (description != null && description.isNotEmpty)
        'description': description,
      if (location != null && location.isNotEmpty) 'location': location,
      'capacity': capacity,
    };

    final resp = await _dio.post('/consulting-rooms', data: body);
    return ConsultingRoomModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<ConsultingRoomModel> updateConsultingRoom(
    String id, {
    String? name,
    String? description,
    String? location,
    int? capacity,
  }) async {
    final body = <String, dynamic>{};
    if (name != null && name.isNotEmpty) body['name'] = name;
    if (description != null) body['description'] = description;
    if (location != null) body['location'] = location;
    if (capacity != null) body['capacity'] = capacity;

    final resp = await _dio.patch('/consulting-rooms/$id', data: body);
    return ConsultingRoomModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteConsultingRoom(String id) async {
    await _dio.delete('/consulting-rooms/$id');
  }

  // ── Waiting patients ────────────────────────────────────────────────────────
  // GET all / filter: waiting-patients
  // POST: waiting-patients (add to list)
  // PATCH: waiting-patients/:id (update)
  // DELETE: waiting-patients/:id (remove from list)

  /// GET waiting-patients — list/filter waiting patients.
  Future<PaginatedWaitingPatients> fetchWaitingPatients([
    WaitingPatientQuery? query,
  ]) async {
    final q = query ?? const WaitingPatientQuery();
    final resp = await _dio.get(
      '/waiting-patients',
      queryParameters: q.toQueryParameters(),
    );
    final body = resp.data as Map<String, dynamic>? ?? {};
    final rawList = body['data'] is List
        ? body['data'] as List
        : resp.data is List
            ? resp.data as List
            : <dynamic>[];
    final total = (body['total'] as num?)?.toInt() ?? rawList.length;

    return PaginatedWaitingPatients(
      data: rawList
          .map((e) => WaitingPatientModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: total,
      skip: q.skip,
      take: q.take,
    );
  }

  /// POST waiting-patients — add patient to waiting list.
  Future<WaitingPatientModel> createWaitingPatient({
    required String patientId,
    required String consultingRoomId,
    String? staffId,
  }) async {
    final body = <String, dynamic>{
      'patientId': patientId,
      'consultingRoomId': consultingRoomId,
      if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
    };

    final resp = await _dio.post('/waiting-patients', data: body);
    return WaitingPatientModel.fromJson(resp.data as Map<String, dynamic>);
  }

  /// PATCH waiting-patients/:id — update patient in waiting list.
  Future<WaitingPatientModel> updateWaitingPatient(
    String id,
    Map<String, dynamic> patch,
  ) async {
    final resp = await _dio.patch('/waiting-patients/$id', data: patch);
    return WaitingPatientModel.fromJson(resp.data as Map<String, dynamic>);
  }

  /// DELETE waiting-patients/:id — remove patient from waiting list.
  Future<void> removeWaitingPatient(String id) async {
    await _dio.delete('/waiting-patients/$id');
  }
}

