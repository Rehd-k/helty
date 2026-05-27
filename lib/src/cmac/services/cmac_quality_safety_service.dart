import 'package:dio/dio.dart';

import '../../services/api_service.dart';
import '../models/cmac_from_json.dart';
import '../models/cmac_quality_safety_models.dart';
import 'cmac_endpoints.dart';

class CmacQualitySafetyService {
  CmacQualitySafetyService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  final Dio _dio;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    return Map<String, dynamic>.from(data as Map);
  }

  String _path(QualitySafetyEntity entity, [String? id]) {
    switch (entity) {
      case QualitySafetyEntity.referrals:
        return CmacEndpoints.qualityReferrals(id);
      case QualitySafetyEntity.complaints:
        return CmacEndpoints.qualityComplaints(id);
      case QualitySafetyEntity.incidents:
        return CmacEndpoints.qualityIncidents(id);
      case QualitySafetyEntity.infections:
        return CmacEndpoints.qualityInfections(id);
    }
  }

  Future<List<QualitySafetyRecord>> list(
    QualitySafetyEntity entity,
    QualitySafetyListQuery query,
  ) async {
    final response = await _dio.get<dynamic>(
      _path(entity),
      queryParameters: query.toQueryParams(),
    );
    return parseQualitySafetyList(response.data, entity);
  }

  Future<QualitySafetyRecord> getById(
    QualitySafetyEntity entity,
    String id,
  ) async {
    final response = await _dio.get<dynamic>(_path(entity, id));
    return parseQualitySafetyDetail(_asMap(response.data), entity);
  }

  Future<QualitySafetyRecord> create(
    QualitySafetyEntity entity,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.post<dynamic>(_path(entity), data: body);
    return parseQualitySafetyDetail(_asMap(response.data), entity);
  }

  Future<QualitySafetyRecord> patch(
    QualitySafetyEntity entity,
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _dio.patch<dynamic>(_path(entity, id), data: body);
    return parseQualitySafetyDetail(_asMap(response.data), entity);
  }
}
