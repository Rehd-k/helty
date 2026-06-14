import 'package:dio/dio.dart';

import '../core/errors/app_exception.dart';
import '../models/encounter_template_model.dart';
import 'api_service.dart';

/// CRUD for `/encounter-templates` (doctor-owned clinical prefills).
class EncounterTemplateService {
  EncounterTemplateService() : _dio = ApiService().dio;

  final Dio _dio;
  static const _prefix = '/encounter-templates';

  String _message(DioException e, String fallback) {
    final payload = e.response?.data;
    if (payload is Map) {
      final msg = payload['message'];
      if (msg != null) return msg.toString();
    } else if (payload is String && payload.trim().isNotEmpty) {
      return payload;
    }
    return e.message ?? fallback;
  }

  Never _handleError(DioException e, String fallback) {
    if (e.error is AppException) {
      throw e.error as AppException;
    }
    throw UnknownException(_message(e, fallback));
  }

  /// GET /encounter-templates
  Future<EncounterTemplateListResult> list({String? encounterType}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _prefix,
        queryParameters: encounterType != null && encounterType.trim().isNotEmpty
            ? {'encounterType': encounterType.trim().toUpperCase()}
            : null,
      );
      final data = response.data;
      if (data == null) {
        return const EncounterTemplateListResult(templates: [], total: 0);
      }
      final raw = data['templates'];
      final templates = <EncounterTemplateModel>[];
      if (raw is List) {
        for (final e in raw) {
          if (e is Map<String, dynamic>) {
            templates.add(EncounterTemplateModel.fromJson(e));
          } else if (e is Map) {
            templates.add(
              EncounterTemplateModel.fromJson(Map<String, dynamic>.from(e)),
            );
          }
        }
      }
      final totalRaw = data['total'];
      final total = totalRaw is int
          ? totalRaw
          : int.tryParse('$totalRaw') ?? templates.length;
      return EncounterTemplateListResult(templates: templates, total: total);
    } on DioException catch (e) {
      _handleError(e, 'Failed to load encounter templates');
    }
  }

  /// GET /encounter-templates/:id
  Future<EncounterTemplateModel> getById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('$_prefix/$id');
      final data = response.data;
      if (data == null) {
        throw const UnknownException('Encounter template not found');
      }
      return EncounterTemplateModel.fromJson(data);
    } on DioException catch (e) {
      _handleError(e, 'Failed to load encounter template');
    }
  }

  /// POST /encounter-templates
  Future<EncounterTemplateModel> create(Map<String, dynamic> body) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _prefix,
        data: body,
      );
      final data = response.data;
      if (data == null) {
        throw const UnknownException('Create template returned no data');
      }
      return EncounterTemplateModel.fromJson(data);
    } on DioException catch (e) {
      _handleError(e, 'Failed to create encounter template');
    }
  }

  /// PATCH /encounter-templates/:id
  Future<EncounterTemplateModel> update(
    String id,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await _dio.patch<Map<String, dynamic>>(
        '$_prefix/$id',
        data: body,
      );
      final data = response.data;
      if (data == null) {
        throw const UnknownException('Update template returned no data');
      }
      return EncounterTemplateModel.fromJson(data);
    } on DioException catch (e) {
      _handleError(e, 'Failed to update encounter template');
    }
  }

  /// DELETE /encounter-templates/:id
  Future<EncounterTemplateDeleteResult> delete(String id) async {
    try {
      final response = await _dio.delete<Map<String, dynamic>>('$_prefix/$id');
      final data = response.data;
      if (data == null) {
        throw const UnknownException('Delete template returned no data');
      }
      return EncounterTemplateDeleteResult.fromJson(data);
    } on DioException catch (e) {
      _handleError(e, 'Failed to delete encounter template');
    }
  }
}
