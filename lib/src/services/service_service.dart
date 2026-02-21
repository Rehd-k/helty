import 'package:dio/dio.dart';

import 'api_service.dart';
import '../models/service_model.dart';

/// Provides network operations around hospital services (the Prisma
/// `Service` model).  This is largely identical in structure to the
/// existing `DepartmentService` but targets the `/services` endpoint.
class ServiceService {
  ServiceService() : _dio = ApiService().dio;
  final Dio _dio;

  // ── Read ─────────────────────────────────────────────────────────────────

  Future<List<ServiceModel>> fetchServices({String? query}) async {
    final resp = await _dio.get(
      '/services',
      queryParameters: {if (query != null && query.isNotEmpty) 'q': query},
    );
    final data = resp.data is List
        ? resp.data as List
        : (resp.data['services'] as List);
    return data
        .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ServiceModel> getServiceById(String id) async {
    final resp = await _dio.get('/services/$id');
    return ServiceModel.fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<ServiceModel> createService(ServiceModel service) async {
    final resp = await _dio.post('/services', data: service.toJson());
    return ServiceModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<ServiceModel> updateService(ServiceModel service) async {
    final resp = await _dio.patch(
      '/services/${service.id}',
      data: service.toJson(),
    );
    return ServiceModel.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteService(String id) async {
    await _dio.delete('/services/$id');
  }
}
