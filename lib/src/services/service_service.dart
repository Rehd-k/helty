import 'package:dio/dio.dart';

import 'api_service.dart';
import '../models/service_model.dart';

/// Paged list returned by Nest `findAll` (`services`, `total`, `skip`, `take`).
class PagedServicesResult {
  const PagedServicesResult({
    required this.services,
    required this.total,
    required this.skip,
    required this.take,
  });

  final List<ServiceModel> services;
  final int total;
  final int skip;
  final int take;
}

/// Provides network operations around hospital services (the Prisma
/// `Service` model).  Targets the `/services` endpoint.
class ServiceService {
  ServiceService() : _dio = ApiService().dio;
  final Dio _dio;

  // ── Read ─────────────────────────────────────────────────────────────────

  /// Server-side pagination + filters (matches backend `findAll`).
  Future<PagedServicesResult> findAll({
    int skip = 0,
    int take = 10,
    String search = '',
    String filterCategory = '',
    String? departmentId,
    String? categoryId,
  }) async {
    final resp = await _dio.get(
      '/services',
      queryParameters: {
        'skip': skip,
        'take': take,
        if (search.trim().isNotEmpty) 'search': search.trim(),
        if (filterCategory.trim().isNotEmpty)
          'filterCategory': filterCategory.trim(),
        if (departmentId != null && departmentId.trim().isNotEmpty)
          'departmentId': departmentId.trim(),
        if (categoryId != null && categoryId.trim().isNotEmpty)
          'categoryId': categoryId.trim(),
      },
    );

    if (resp.data is List) {
      final list = (resp.data as List)
          .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
          .toList();
      return PagedServicesResult(
        services: list,
        total: list.length,
        skip: skip,
        take: take,
      );
    }

    final map = resp.data as Map<String, dynamic>;
    final rawList = map['services'] as List<dynamic>? ?? [];
    final services = rawList
        .map((e) => ServiceModel.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = (map['total'] as num?)?.toInt() ?? services.length;
    final rSkip = (map['skip'] as num?)?.toInt() ?? skip;
    final rTake = (map['take'] as num?)?.toInt() ?? take;
    return PagedServicesResult(
      services: services,
      total: total,
      skip: rSkip,
      take: rTake,
    );
  }

  /// Returns one page of services (list only). Prefer [findAll] when you need [total].
  Future<List<ServiceModel>> fetchServices({
    String? query,
    String? categoryId,
    String? departmentId,
    int skip = 0,
    int take = 10,
  }) async {
    final page = await findAll(
      skip: skip,
      take: take,
      search: query ?? '',
      departmentId: departmentId,
      categoryId: categoryId,
    );
    return page.services;
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
