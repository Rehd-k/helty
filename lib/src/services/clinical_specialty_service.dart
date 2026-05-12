import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../models/clinical_specialty_models.dart';
import 'api_service.dart';

/// Clinical specialty catalog, encounter module sync, and per-section JSON.
class ClinicalSpecialtyService {
  ClinicalSpecialtyService() : _dio = ApiService().dio;

  final Dio _dio;

  Never _handleError(DioException e) {
    if (e.error is AppException) {
      throw e.error as AppException;
    }
    final message = e.response?.data is Map
        ? (e.response!.data['message'] ?? e.message)?.toString()
        : e.message;
    throw UnknownException(
      message?.toString().isNotEmpty == true
          ? message!
          : 'Clinical specialty request failed.',
    );
  }

  List<dynamic> _asList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['data'] is List) return raw['data'] as List;
    return const [];
  }

  /// GET /clinical/specialties
  Future<ClinicalSpecialtyCatalogModel> fetchCatalog() async {
    try {
      final resp = await _dio.get<Map<String, dynamic>>('/clinical/specialties');
      final data = resp.data;
      if (data == null) {
        return const ClinicalSpecialtyCatalogModel(
          catalogVersion: 0,
          specialties: [],
        );
      }
      return ClinicalSpecialtyCatalogModel.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// GET /encounters/:id/specialty-modules
  Future<List<EncounterSpecialtyModuleModel>> listModules(
    String encounterId,
  ) async {
    try {
      final resp = await _dio.get<dynamic>(
        '/encounters/$encounterId/specialty-modules',
      );
      final list = _asList(resp.data);
      return list
          .map((e) {
            if (e is Map<String, dynamic>) {
              return EncounterSpecialtyModuleModel.fromJson(e);
            }
            return EncounterSpecialtyModuleModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            );
          })
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// PUT /encounters/:id/specialty-modules — full replacement.
  Future<List<EncounterSpecialtyModuleModel>> syncModules(
    String encounterId,
    List<EncounterSpecialtyModuleModel> modules,
  ) async {
    try {
      final body = {
        'modules': modules.map((m) => m.toSyncBody()).toList(),
      };
      final resp = await _dio.put<dynamic>(
        '/encounters/$encounterId/specialty-modules',
        data: body,
      );
      final list = _asList(resp.data);
      return list
          .map((e) {
            if (e is Map<String, dynamic>) {
              return EncounterSpecialtyModuleModel.fromJson(e);
            }
            return EncounterSpecialtyModuleModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            );
          })
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// GET /encounters/:id/clinical-sections
  Future<List<EncounterClinicalSectionRowModel>> listSections(
    String encounterId, {
    String? specialty,
    List<String>? keys,
  }) async {
    try {
      final qp = <String, dynamic>{};
      if (specialty != null && specialty.isNotEmpty) {
        qp['specialty'] = specialty;
      }
      if (keys != null && keys.isNotEmpty) {
        qp['keys'] = keys.join(',');
      }
      final resp = await _dio.get<dynamic>(
        '/encounters/$encounterId/clinical-sections',
        queryParameters: qp.isEmpty ? null : qp,
      );
      final list = _asList(resp.data);
      return list
          .map((e) {
            if (e is Map<String, dynamic>) {
              return EncounterClinicalSectionRowModel.fromJson(e);
            }
            return EncounterClinicalSectionRowModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            );
          })
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// PUT /encounters/:id/clinical-sections/:specialty/:sectionKey
  Future<EncounterClinicalSectionRowModel> upsertSection(
    String encounterId,
    String specialty,
    String sectionKey,
    Map<String, dynamic> data, {
    int schemaVersion = 1,
  }) async {
    try {
      final resp = await _dio.put<Map<String, dynamic>>(
        '/encounters/$encounterId/clinical-sections/$specialty/$sectionKey',
        data: {
          'data': data,
          'schemaVersion': schemaVersion,
        },
      );
      final row = resp.data;
      if (row == null) throw const UnknownException('Empty response');
      return EncounterClinicalSectionRowModel.fromJson(row);
    } on DioException catch (e) {
      _handleError(e);
    }
  }
}
