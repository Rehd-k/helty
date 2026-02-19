import 'package:dio/dio.dart';
import 'dart:developer';

import '../models/patient_model.dart';
import 'api_service.dart';

class PatientService {
  PatientService() : _dio = ApiService().dio;
  final Dio _dio;

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<List<Patient>> fetchPatients({
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    final resp = await _dio.get(
      '/patients',
      queryParameters: {
        if (query != null && query.isNotEmpty) 'q': query,
        'page': page,
        'limit': limit,
      },
    );
    final data = resp.data is List
        ? resp.data as List
        : (resp.data['data'] as List);
    return data
        .map((e) => Patient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Patient> getPatientById(String id) async {
    final resp = await _dio.get('/patients/$id');
    return Patient.fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<Patient> createPatient(Patient p) async {
    log('Creating patient: ${p.toJson()}');
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

  Future<List<Patient>> searchPatients(String query) =>
      fetchPatients(query: query, limit: 50);
}
