import 'package:dio/dio.dart';

import 'api_service.dart';
import '../models/service_category_model.dart';

/// CRUD operations for service categories.
class ServiceCategoryService {
  ServiceCategoryService() : _dio = ApiService().dio;
  final Dio _dio;

  Future<List<ServiceCategory>> fetchCategories({String? query}) async {
    final resp = await _dio.get(
      '/service-categories',
      queryParameters: {if (query != null && query.isNotEmpty) 'q': query},
    );
    final data = resp.data is List
        ? resp.data as List
        : (resp.data['categories'] as List);
    return data
        .map((e) => ServiceCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ServiceCategory> getCategoryById(String id) async {
    final resp = await _dio.get('/service-categories/$id');
    return ServiceCategory.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<ServiceCategory> createCategory(ServiceCategory c) async {
    final resp = await _dio.post('/service-categories', data: c.toJson());
    return ServiceCategory.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<ServiceCategory> updateCategory(ServiceCategory c) async {
    final resp = await _dio.patch(
      '/service-categories/${c.id}',
      data: c.toJson(),
    );
    return ServiceCategory.fromJson(resp.data as Map<String, dynamic>);
  }

  Future<void> deleteCategory(String id) async {
    await _dio.delete('/service-categories/$id');
  }
}
