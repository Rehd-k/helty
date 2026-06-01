import 'package:dio/dio.dart';

import '../../services/api_service.dart';

/// Stub for PROPOSED encounter-scoped nursing routes.
///
/// Mirrors `admissions/:admissionId/...` under `encounters/:encounterId/...`.
/// UI deferred until backend Phase 3.
class EncountersNursingService {
  EncountersNursingService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  final Dio _dio;

  String _base(String encounterId) => '/encounters/$encounterId';

  /// GET /encounters/:encounterId/monitoring-charts
  Future<List<Map<String, dynamic>>> listMonitoringCharts(
    String encounterId,
  ) async {
    final resp = await _dio.get<dynamic>(
      '${_base(encounterId)}/monitoring-charts',
    );
    return _asMapList(resp.data);
  }

  /// POST /encounters/:encounterId/nursing-notes
  Future<Map<String, dynamic>> createNursingNote(
    String encounterId,
    Map<String, dynamic> body,
  ) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '${_base(encounterId)}/nursing-notes',
      data: body,
    );
    return Map<String, dynamic>.from(resp.data ?? {});
  }

  /// GET /encounters/:encounterId/nursing-notes
  Future<List<Map<String, dynamic>>> listNursingNotes(
    String encounterId,
  ) async {
    final resp = await _dio.get<dynamic>(
      '${_base(encounterId)}/nursing-notes',
    );
    return _asMapList(resp.data);
  }

  /// GET /encounters/:encounterId/medication-administrations
  Future<List<Map<String, dynamic>>> listMedicationAdministrations(
    String encounterId,
  ) async {
    final resp = await _dio.get<dynamic>(
      '${_base(encounterId)}/medication-administrations',
    );
    return _asMapList(resp.data);
  }

  List<Map<String, dynamic>> _asMapList(dynamic raw) {
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    if (raw is Map && raw['data'] is List) {
      return (raw['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }
}
