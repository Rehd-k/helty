import 'package:dio/dio.dart';
import 'package:helty/src/paitients/noid_patient.model.dart';

import '../models/consultation_credit_model.dart';
import 'patient_model.dart';
import 'registered_today_response.dart';
import '../services/api_service.dart';

class PatientDeleteException implements Exception {
  PatientDeleteException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class SimilarPatientMatch {
  SimilarPatientMatch({
    required this.id,
    this.patientId,
    this.firstName,
    this.surname,
    this.otherName,
    this.dob,
    this.phoneNumber,
  });

  final String id;
  final String? patientId;
  final String? firstName;
  final String? surname;
  final String? otherName;
  final DateTime? dob;
  final String? phoneNumber;

  String get displayName {
    final parts = [
      firstName?.trim(),
      otherName?.trim(),
      surname?.trim(),
    ].whereType<String>().where((s) => s.isNotEmpty);
    final name = parts.join(' ').trim();
    return name.isEmpty ? 'Unknown patient' : name;
  }

  factory SimilarPatientMatch.fromJson(Map<String, dynamic> json) {
    return SimilarPatientMatch(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString(),
      firstName: json['firstName']?.toString(),
      surname: json['surname']?.toString(),
      otherName: json['otherName']?.toString(),
      dob: DateTime.tryParse(json['dob']?.toString() ?? ''),
      phoneNumber: json['phoneNumber']?.toString(),
    );
  }
}

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
    PatientListStatusFilter listStatusFilter = PatientListStatusFilter.none,
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
        if (listStatusFilter != PatientListStatusFilter.none)
          'listStatusFilter': listStatusFilter.name,
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

  Future<Patient> getPatientById(String id, [String? select]) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/patients/$id',
      queryParameters: select != null ? {'select': select} : null,
    );
    final data = resp.data;

    if (data == null) {
      throw StateError('Patient response was empty');
    }

    // The API may wrap the patient object, or return it directly
    final dynamic raw = data['patient'] ?? data['data'] ?? data;

    if (raw is! Map<String, dynamic>) {
      throw StateError(
        'Unexpected patient payload type: ${raw.runtimeType}. Expected Map<String, dynamic>.',
      );
    }

    return Patient.fromJson(raw);
  }

  /// GET /patients/registered/today — patients created today (includes no-ID).
  Future<RegisteredTodayResponse> fetchRegisteredToday({
    int skip = 0,
    int take = 50,
    String? q,
    DateTime? asOf,
  }) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/patients/registered/today',
      queryParameters: {
        'skip': skip,
        'take': take,
        if (q != null && q.isNotEmpty) 'q': q,
        if (asOf != null) 'asOf': asOf.toIso8601String(),
      },
    );
    final data = resp.data;
    if (data == null) {
      throw StateError('Registered today response was empty');
    }
    return RegisteredTodayResponse.fromJson(data);
  }

  /// GET /patients/:patientId/consultation-credits — OPD visit bundles.
  Future<List<ConsultationCredit>> fetchConsultationCredits(
    String patientId,
  ) async {
    final resp = await _dio.get<Map<String, dynamic>>(
      '/patients/$patientId/consultation-credits',
    );
    final data = resp.data;
    if (data == null) return [];
    return ConsultationCreditsResponse.fromJson(data).credits;
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<List<SimilarPatientMatch>> findSimilarMatches({
    required String firstName,
    required String surname,
    String? otherName,
    required DateTime dob,
  }) async {
    final resp = await _dio.get(
      '/patients/similar-matches',
      queryParameters: {
        'firstName': firstName.trim(),
        'surname': surname.trim(),
        if (otherName != null && otherName.trim().isNotEmpty)
          'otherName': otherName.trim(),
        'dob': dob.toIso8601String().split('T').first,
      },
    );
    final raw = resp.data;
    final list = raw is List
        ? raw
        : (raw is Map && raw['candidates'] is List
              ? raw['candidates'] as List
              : (raw is Map && raw['data'] is List ? raw['data'] as List : const []));
    return list
        .whereType<Map>()
        .map((e) => SimilarPatientMatch.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Patient> createPatient(Patient p, {bool forceCreate = false}) async {
    final body = {
      ...p.toJson(),
      if (forceCreate) 'forceCreate': true,
    };
    final resp = await _dio.post(
      '/patients',
      data: body,
      queryParameters: forceCreate ? {'forceCreate': true} : null,
    );
    return Patient.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Patient> mergePatients({
    required String survivorId,
    required String duplicateId,
  }) async {
    final resp = await _dio.post(
      '/patients/merge',
      data: {
        'survivorId': survivorId,
        'duplicateId': duplicateId,
      },
    );
    return Patient.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<Patient> updatePatient(Patient p, String? patientId) async {
    final resp = await _dio.patch('/patients/$patientId', data: p.toJson());
    return Patient.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deletePatient(String id) async {
    try {
      await _dio.delete('/patients/$id');
    } on DioException catch (e) {
      throw _deletePatientError(e);
    }
  }

  PatientDeleteException _deletePatientError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    var message = 'Failed to delete patient.';
    if (data is Map && data['message'] != null) {
      message = data['message'].toString();
    } else if (data is String && data.trim().isNotEmpty) {
      message = data.trim();
    } else if (e.message != null && e.message!.trim().isNotEmpty) {
      message = e.message!.trim();
    }
    if (status == 404) {
      return PatientDeleteException(
        'Patient not found.',
        statusCode: status,
      );
    }
    if (status == 409) {
      return PatientDeleteException(message, statusCode: status);
    }
    return PatientDeleteException(message, statusCode: status);
  }

  Future<NoIdPatient> createNoIdPatient(Map<String, dynamic> data) async {
    final resp = await _dio.post('/no-id-patient', data: data);
    return NoIdPatient.fromJson(resp.data as Map<String, dynamic>);
  }
  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<List<Patient>> searchPatients(String query, bool isAscending) =>
      fetchPatients(query: query, take: 50, isAscending: isAscending);
}
