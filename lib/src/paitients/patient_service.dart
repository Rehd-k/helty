import 'package:dio/dio.dart';

import 'patient_model.dart';
import '../services/api_service.dart';

class PatientService {
  PatientService() : _dio = ApiService().dio;
  final Dio _dio;

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<List<Patient>> fetchPatients({
    String? query,
    int skip = 0,
    int take = 20,
    String? filterCategory,
    DateTime? fromDate,
    DateTime? toDate,
    String? sortBy,
    required bool isAscending,
  }) async {
    final resp = await _dio.get(
      '/patients',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        'skip': skip,
        'take': take,
        'filterCategory': filterCategory,
        if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
        if (toDate != null) 'toDate': toDate.toIso8601String(),
        if (sortBy != null) 'sortBy': sortBy,
        'isAscending': isAscending,
      },
    );

    // log the raw response so we can see the structure in debug

    // the API sometimes returns a wrapped object, sometimes a raw list
    final dynamic raw = resp.data['patients'] ?? resp.data['data'] ?? resp.data;
    // if we still don’t have a list, avoid crashing by treating it as empty
    final List<dynamic> list = raw is List
        ? raw
        : (raw is Map<String, dynamic> && raw['data'] is List
              ? raw['data'] as List
              : <dynamic>[]);

    return list
        .map(
          (e) => Patient.fromJson(
            Map<String, dynamic>.from(e as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  Future<Patient> getPatientById(String id) async {
    final resp = await _dio.get('/patients/$id');
    return Patient.fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<Patient> createPatient(Patient p) async {
    final resp = await _dio.post('/patients', data: p.toJson());
    return Patient.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Patient> updatePatient(Patient p) async {
    final resp = await _dio.patch('/patients/${p.id}', data: p.toJson());
    return Patient.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deletePatient(String id) async {
    await _dio.delete('/patients/$id');
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<List<Patient>> searchPatients(String query, bool isAscending) =>
      fetchPatients(query: query, take: 50, isAscending: isAscending);
}
