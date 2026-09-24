import 'package:dio/dio.dart';

import '../models/patient_clinical_record_models.dart';
import 'api_service.dart';

class PatientClinicalRecordsService {
  PatientClinicalRecordsService() : _dio = ApiService().dio;

  final Dio _dio;

  List<dynamic> _asList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map) {
      final inner = raw['data'] ?? raw['items'] ?? raw['results'];
      if (inner is List) return inner;
    }
    return const [];
  }

  Future<List<PatientAllergyRecord>> listAllergies(String patientId) async {
    final resp = await _dio.get<dynamic>('/patients/$patientId/allergies');
    return _asList(resp.data)
        .whereType<Map>()
        .map((e) => PatientAllergyRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<PatientAllergyRecord> createAllergy({
    required String patientId,
    required String allergen,
    String? reaction,
    String? severity,
    String? type,
    String? notes,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/patients/$patientId/allergies',
      data: {
        'allergen': allergen,
        if (reaction != null && reaction.trim().isNotEmpty)
          'reaction': reaction,
        if (severity != null && severity.trim().isNotEmpty)
          'severity': severity,
        if (type != null && type.trim().isNotEmpty) 'type': type,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes,
      },
    );
    return PatientAllergyRecord.fromJson(resp.data ?? {});
  }

  Future<void> deleteAllergy({
    required String patientId,
    required String allergyId,
  }) async {
    await _dio.delete('/patients/$patientId/allergies/$allergyId');
  }

  Future<List<PatientImmunizationRecord>> listImmunizations(
    String patientId,
  ) async {
    final resp = await _dio.get<dynamic>('/patients/$patientId/immunizations');
    return _asList(resp.data)
        .whereType<Map>()
        .map(
          (e) =>
              PatientImmunizationRecord.fromJson(Map<String, dynamic>.from(e)),
        )
        .toList();
  }

  Future<PatientImmunizationRecord> createImmunization({
    required String patientId,
    required String vaccineName,
    String? detail,
    int? doseNumber,
    required DateTime administeredAt,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/patients/$patientId/immunizations',
      data: {
        'vaccineName': vaccineName,
        if (detail != null && detail.trim().isNotEmpty) 'detail': detail,
        'doseNumber': ?doseNumber,
        'administeredAt': administeredAt.toUtc().toIso8601String(),
      },
    );
    return PatientImmunizationRecord.fromJson(resp.data ?? {});
  }

  Future<void> deleteImmunization({
    required String patientId,
    required String immunizationId,
  }) async {
    await _dio.delete('/patients/$patientId/immunizations/$immunizationId');
  }
}
