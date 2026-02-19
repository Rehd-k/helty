import 'dart:developer';

import '../models/patient_model.dart';
import 'api_service.dart';

class PatientService {
  final _dio = ApiService().dio;

  Future<List<Patient>> fetchPatients({String? query}) async {
    final resp = await _dio.get(
      '/patients',
      queryParameters: {if (query != null && query.isNotEmpty) 'q': query},
    );
    final data = resp.data as List;
    return data
        .map((e) => Patient.fromJson(e as Map<String, dynamic>))
        .toList();
  }

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
}
