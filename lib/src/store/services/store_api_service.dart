import 'package:dio/dio.dart';

import '../../services/api_service.dart';
import '../models/store_models.dart';

/// API client for store module. All endpoints under /store.
class StoreApiService {
  StoreApiService() : _dio = ApiService().dio;

  final Dio _dio;
  static const _prefix = '/store';

  // ── Categories ───────────────────────────────────────────────────────────

  Future<StoreCategory> createCategory(CreateStoreCategoryDto dto) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/categories',
      data: dto.toJson(),
    );
    final data = response.data;
    if (data == null) throw StateError('Create category returned no data');
    return StoreCategory.fromJson(data);
  }

  Future<StoreCategoriesResponse> getCategories() async {
    final response = await _dio.get<dynamic>('$_prefix/categories');
    final data = response.data;
    if (data == null) throw StateError('Get categories returned no data');

    if (data is List) {
      final list = data;
      return StoreCategoriesResponse(
        data: list
            .map((e) => StoreCategory.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: list.length,
      );
    }
    if (data is Map<String, dynamic>) {
      return StoreCategoriesResponse.fromJson(data);
    }
    throw StateError('Get categories returned unexpected type: ${data.runtimeType}');
  }

  Future<StoreCategory> getCategoryById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/categories/$id',
    );
    final data = response.data;
    if (data == null) throw StateError('Get category returned no data');
    return StoreCategory.fromJson(data);
  }

  Future<StoreCategory> updateCategory(
    String id,
    UpdateStoreCategoryDto dto,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/categories/$id',
      data: dto.toJson(),
    );
    final data = response.data;
    if (data == null) throw StateError('Update category returned no data');
    return StoreCategory.fromJson(data);
  }

  // ── Items ────────────────────────────────────────────────────────────────

  Future<StoreItem> createItem(CreateStoreItemDto dto) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/items',
      data: dto.toJson(),
    );
    final data = response.data;
    if (data == null) throw StateError('Create item returned no data');
    return StoreItem.fromJson(data);
  }

  Future<StoreItemsResponse> getItems({
    String? categoryId,
    bool? isActive,
    int limit = 20,
    int skip = 0,
  }) async {
    final response = await _dio.get<dynamic>(
      '$_prefix/items',
      queryParameters: {
        if (categoryId != null) 'categoryId': categoryId,
        if (isActive != null) 'isActive': isActive,
        'limit': limit,
        'skip': skip,
      },
    );
    final data = response.data;
    if (data == null) throw StateError('Get items returned no data');
    if (data is List) {
      final list = data;
      return StoreItemsResponse(
        data: list
            .map((e) => StoreItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: list.length,
      );
    }
    if (data is Map<String, dynamic>) {
      return StoreItemsResponse.fromJson(data);
    }
    throw StateError('Get items returned unexpected type: ${data.runtimeType}');
  }

  Future<StoreItem> getItemById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>('$_prefix/items/$id');
    final data = response.data;
    if (data == null) throw StateError('Get item returned no data');
    return StoreItem.fromJson(data);
  }

  Future<StoreItem> updateItem(String id, UpdateStoreItemDto dto) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/items/$id',
      data: dto.toJson(),
    );
    final data = response.data;
    if (data == null) throw StateError('Update item returned no data');
    return StoreItem.fromJson(data);
  }

  // ── Locations ─────────────────────────────────────────────────────────────

  Future<StoreLocation> createLocation(CreateStoreLocationDto dto) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '$_prefix/locations',
      data: dto.toJson(),
    );
    final data = response.data;
    if (data == null) throw StateError('Create location returned no data');
    return StoreLocation.fromJson(data);
  }

  Future<StoreLocationsResponse> getLocations() async {
    final response = await _dio.get<dynamic>('$_prefix/locations');
    final data = response.data;
    if (data == null) throw StateError('Get locations returned no data');
    if (data is List) {
      final list = data;
      return StoreLocationsResponse(
        data: list
            .map((e) => StoreLocation.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: list.length,
      );
    }
    if (data is Map<String, dynamic>) {
      return StoreLocationsResponse.fromJson(data);
    }
    throw StateError('Get locations returned unexpected type: ${data.runtimeType}');
  }

  Future<StoreLocation> getLocationById(String id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/locations/$id',
    );
    final data = response.data;
    if (data == null) throw StateError('Get location returned no data');
    return StoreLocation.fromJson(data);
  }

  Future<StoreLocation> updateLocation(
    String id,
    UpdateStoreLocationDto dto,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '$_prefix/locations/$id',
      data: dto.toJson(),
    );
    final data = response.data;
    if (data == null) throw StateError('Update location returned no data');
    return StoreLocation.fromJson(data);
  }

  // ── Stock ────────────────────────────────────────────────────────────────

  Future<StoreStockResponse> getStock({
    String? locationId,
    String? itemId,
    int limit = 20,
    int skip = 0,
  }) async {
    final response = await _dio.get<dynamic>(
      '$_prefix/stock',
      queryParameters: {
        if (locationId != null) 'locationId': locationId,
        if (itemId != null) 'itemId': itemId,
        'limit': limit,
        'skip': skip,
      },
    );
    final data = response.data;
    if (data == null) throw StateError('Get stock returned no data');
    if (data is List) {
      final list = data;
      return StoreStockResponse(
        data: list
            .map((e) => StoreStock.fromJson(e as Map<String, dynamic>))
            .toList(),
        total: list.length,
      );
    }
    if (data is Map<String, dynamic>) {
      return StoreStockResponse.fromJson(data);
    }
    throw StateError('Get stock returned unexpected type: ${data.runtimeType}');
  }

  // ── Movements ─────────────────────────────────────────────────────────────

  Future<void> issueItems(IssueItemsRequest request) async {
    await _dio.post('$_prefix/movements/issue', data: request.toJson());
  }

  Future<void> receiveItems(ReceiveItemsRequest request) async {
    await _dio.post('$_prefix/movements/receive', data: request.toJson());
  }

  Future<void> transferItems(TransferItemsRequest request) async {
    await _dio.post('$_prefix/movements/transfer', data: request.toJson());
  }

  // ── Analytics ─────────────────────────────────────────────────────────────

  Future<StoreAnalytics> getAnalyticsDashboard({
    String? fromDate,
    String? toDate,
    String? departmentId,
    String? categoryId,
    int limit = 10,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '$_prefix/analytics/dashboard',
      queryParameters: {
        if (fromDate != null) 'fromDate': fromDate,
        if (toDate != null) 'toDate': toDate,
        if (departmentId != null) 'departmentId': departmentId,
        if (categoryId != null) 'categoryId': categoryId,
        'limit': limit,
      },
    );
    final data = response.data;
    if (data == null) throw StateError('Get analytics returned no data');
    return StoreAnalytics.fromJson(data);
  }
}
