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
    this.seen,
    this.skip = 0,
    this.take = 20,
    this.sortBy,
    this.sortOrder = 'asc',
    this.fromDate,
    this.toDate,
  });

  final String? q;
  final String? patientId;
  final String? consultingRoomId;
  final bool? unassignedOnly;
  final bool? seen;
  final int skip;
  final int take;
  final String? sortBy;
  final String sortOrder;
  final DateTime? fromDate;
  final DateTime? toDate;

  Map<String, dynamic> toQueryParameters() => {
    if (q != null && q!.isNotEmpty) 'q': q,
    if (patientId != null && patientId!.isNotEmpty) 'patientId': patientId,
    if (consultingRoomId != null && consultingRoomId!.isNotEmpty)
      'consultingRoomId': consultingRoomId,
    if (unassignedOnly != null) 'unassignedOnly': unassignedOnly,
    if (seen != null) 'seen': seen,
    // Explicit strings so Dio never drops/coerces paging params oddly.
    'skip': '$skip',
    'take': '$take',
    if (fromDate != null) 'fromDate': fromDate!.toIso8601String(),
    if (toDate != null) 'toDate': toDate!.toIso8601String(),
    if (sortBy != null && sortBy!.isNotEmpty) 'sortBy': sortBy,
    'sortOrder': sortOrder,
  };
}

/// Query params for GET consulting-rooms (all / filter).
class ConsultingRoomQuery {
  const ConsultingRoomQuery({this.q, this.skip = 0, this.take = 50});

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
    this.hasMore = false,
  });

  final List<WaitingPatientModel> data;
  final int total;
  final int skip;
  final int take;

  /// True when another page of [take] rows may exist.
  final bool hasMore;
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value.trim()) ?? fallback;
  return fallback;
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
    final resp = await _dio.post('/patient-vitals', data: dto.toJson());
    return PatientVitalsModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<PatientVitalsModel> updatePatientVitals(
    String id,
    UpdatePatientVitalsDto dto,
  ) async {
    final resp = await _dio.patch('/patient-vitals/$id', data: dto.toJson());
    return PatientVitalsModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deletePatientVitals(String id) async {
    await _dio.delete('/patient-vitals/$id');
  }

  /// GET /patient-vitals?encounterId= — vitals for an ED (or other) encounter.
  Future<List<PatientVitalsModel>> fetchVitalsByEncounter(
    String encounterId,
  ) async {
    final resp = await _dio.get<dynamic>(
      '/patient-vitals',
      queryParameters: {'encounterId': encounterId},
    );
    final raw = resp.data;
    if (raw is List) {
      return raw
          .map((e) => PatientVitalsModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    if (raw is Map<String, dynamic>) {
      final list = raw['data'] as List? ?? [];
      return list
          .map((e) => PatientVitalsModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
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

  // ── Waiting patients (invoice-backed queue) ────────────────────────────────
  // GET: waiting-patients
  // GET: waiting-patients/:invoiceId
  // POST: waiting-patients/:invoiceId/send-to-room
  // PATCH: waiting-patients/:invoiceId

  /// GET waiting-patients — list/filter waiting patients.
  Future<PaginatedWaitingPatients> fetchWaitingPatients([
    WaitingPatientQuery? query,
  ]) async {
    final q = query ?? const WaitingPatientQuery();
    final take = q.take.clamp(1, 20);
    final skip = q.skip < 0 ? 0 : q.skip;
    final resp = await _dio.get(
      '/waiting-patients',
      queryParameters: WaitingPatientQuery(
        q: q.q,
        patientId: q.patientId,
        consultingRoomId: q.consultingRoomId,
        unassignedOnly: q.unassignedOnly,
        seen: q.seen,
        skip: skip,
        take: take,
        sortBy: q.sortBy,
        sortOrder: q.sortOrder,
        fromDate: q.fromDate,
        toDate: q.toDate,
      ).toQueryParameters(),
    );
    final raw = resp.data;
    final body = raw is Map
        ? Map<String, dynamic>.from(raw)
        : <String, dynamic>{};

    final rawList = body['data'] is List
        ? body['data'] as List
        : raw is List
        ? raw
        : <dynamic>[];

    final reported = body['total'] ?? body['count'];
    var total = reported != null
        ? _readInt(reported, fallback: skip + rawList.length)
        : skip + rawList.length;
    if (total < skip + rawList.length) {
      total = skip + rawList.length;
    }

    // Page rule from product: full page of [take] → Next on; fewer → Next off.
    final hasMore = rawList.length >= take;

    return PaginatedWaitingPatients(
      data: rawList
          .map((e) => WaitingPatientModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ))
          .toList(),
      total: total,
      skip: _readInt(body['skip'], fallback: skip),
      take: _readInt(body['take'], fallback: take),
      hasMore: hasMore,
    );
  }

  Future<WaitingPatientModel> getWaitingPatientByInvoiceId(
    String invoiceId,
  ) async {
    final resp = await _dio.get('/waiting-patients/$invoiceId');
    return WaitingPatientModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<WaitingPatientModel> sendInvoiceToRoom({
    required String invoiceId,
    required String consultingRoomId,
    String? staffId,
  }) async {
    final body = <String, dynamic>{
      'consultingRoomId': consultingRoomId,
      if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
    };
    final resp = await _dio.post(
      '/waiting-patients/$invoiceId/send-to-room',
      data: body,
    );
    return WaitingPatientModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<WaitingPatientModel> updateWaitingPatientAssignment({
    required String invoiceId,
    required String consultingRoomId,
    String? staffId,
  }) async {
    final patch = <String, dynamic>{
      'consultingRoomId': consultingRoomId,
      if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
    };
    final resp = await _dio.patch('/waiting-patients/$invoiceId', data: patch);
    return WaitingPatientModel.fromJson(resp.data as Map<String, dynamic>);
  }

  /// Frontdesk check-in: reset invoice queue fields so patient appears
  /// unassigned in triage (fresh vitals required before room assignment).
  Future<WaitingPatientModel> reEnlistToQueue({
    required String invoiceId,
    String? staffId,
  }) async {
    await _dio.patch('/invoices/$invoiceId', data: {
      'consultingRoomId': null,
      'vitalsId': null,
      if (staffId != null && staffId.isNotEmpty) 'staffId': staffId,
    });
    return getWaitingPatientByInvoiceId(invoiceId);
  }

  /// Backward-compatible wrapper for older callers.
  /// Prefer [updateWaitingPatientAssignment] in new code.
  Future<WaitingPatientModel> updateWaitingPatient(
    String id,
    Map<String, dynamic> patch,
  ) async {
    final resp = await _dio.patch('/waiting-patients/$id', data: patch);
    return WaitingPatientModel.fromJson(resp.data as Map<String, dynamic>);
  }

  // Legacy endpoints (deprecated by backend: may return 410).
  @Deprecated('Use invoice-backed queue flow endpoints instead.')
  Future<WaitingPatientModel> createWaitingPatient({
    required String patientId,
    required String consultingRoomId,
    String? staffId,
  }) => sendInvoiceToRoom(
    invoiceId: patientId,
    consultingRoomId: consultingRoomId,
    staffId: staffId,
  );

  @Deprecated('Use invoice-backed queue flow endpoints instead.')
  Future<void> removeWaitingPatient(String id) async {}
}
