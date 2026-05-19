import 'dart:io';

import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../services/api_service.dart';
import '../models/archived_encounter_models.dart';
import '../models/patient_chart_models.dart';

class PatientChartService {
  PatientChartService() : _dio = ApiService().dio;
  final Dio _dio;

  String _parseError(dynamic data, String fallback) {
    if (data == null) return fallback;
    if (data is String && data.trim().isNotEmpty) return data;
    if (data is! Map) return fallback;
    final message = data['message']?.toString();
    if (message != null && message.trim().isNotEmpty) return message;
    return fallback;
  }

  Never _handleError(DioException e, String fallback) {
    if (e.error is AppException) throw e.error as AppException;
    throw UnknownException(
      _parseError(e.response?.data, e.message ?? fallback),
    );
  }

  Future<PatientChartResponse> getChart(
    String patientUuid, {
    List<String>? include,
    int limit = 20,
    int skip = 0,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final query = <String, dynamic>{
        'limit': limit,
        'skip': skip,
        if (include != null && include.isNotEmpty)
          'include': include.join(','),
        if (fromDate != null) 'fromDate': fromDate.toIso8601String(),
        if (toDate != null) 'toDate': toDate.toIso8601String(),
      };
      final resp = await _dio.get<Map<String, dynamic>>(
        '/patients/$patientUuid/chart',
        queryParameters: query,
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty chart response');
      return PatientChartResponse.fromJson(data);
    } on DioException catch (e) {
      _handleError(e, 'Failed to load patient chart');
    }
  }

  Future<List<PatientArchivedEncounter>> listArchivedEncounters(
    String patientUuid,
  ) async {
    try {
      final resp = await _dio.get<dynamic>(
        '/patients/$patientUuid/archived-encounters',
      );
      final data = resp.data;
      final list = data is List
          ? data
          : (data is Map && data['data'] is List ? data['data'] as List : []);
      return list
          .whereType<Map>()
          .map((e) => PatientArchivedEncounter.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList();
    } on DioException catch (e) {
      _handleError(e, 'Failed to load archived encounters');
    }
  }

  Future<PatientArchivedEncounter> uploadArchivedEncounter({
    required String patientUuid,
    required DateTime encounterOccurredAt,
    required List<String> filePaths,
    String? title,
    String? notes,
  }) async {
    try {
      final files = await Future.wait(
        filePaths.map(
          (p) => MultipartFile.fromFile(
            p,
            filename: p.split(RegExp(r'[/\\]')).last,
          ),
        ),
      );
      final form = FormData.fromMap({
        'encounterOccurredAt': encounterOccurredAt.toUtc().toIso8601String(),
        if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        'files': files,
      });
      final resp = await _dio.post<Map<String, dynamic>>(
        '/patients/$patientUuid/archived-encounters',
        data: form,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );
      final data = resp.data;
      if (data == null) throw const UnknownException('Empty upload response');
      return PatientArchivedEncounter.fromJson(data);
    } on DioException catch (e) {
      _handleError(e, 'Failed to upload archived encounter');
    }
  }

  Future<List<int>> downloadArchivedDocument(String documentId) async {
    try {
      final resp = await _dio.get<List<int>>(
        '/patients/archived-encounters/documents/$documentId/file',
        options: Options(responseType: ResponseType.bytes),
      );
      return resp.data ?? [];
    } on DioException catch (e) {
      _handleError(e, 'Failed to download document');
    }
  }

  Future<void> deleteArchivedDocument(String documentId) async {
    try {
      await _dio.delete(
        '/patients/archived-encounters/documents/$documentId',
      );
    } on DioException catch (e) {
      _handleError(e, 'Failed to delete document');
    }
  }

  /// Convenience for mobile/desktop file upload from [File].
  Future<PatientArchivedEncounter> uploadArchivedEncounterFiles({
    required String patientUuid,
    required DateTime encounterOccurredAt,
    required List<File> files,
    String? title,
    String? notes,
  }) =>
      uploadArchivedEncounter(
        patientUuid: patientUuid,
        encounterOccurredAt: encounterOccurredAt,
        filePaths: files.map((f) => f.path).toList(),
        title: title,
        notes: notes,
      );
}
