import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../services/api_service.dart';
import '../models/purchases_model.dart';

class PurchasesQueryParams {
  const PurchasesQueryParams({
    this.page = 1,
    this.pageSize = 20,
    this.sortBy,
    this.sortOrder = SortOrder.desc,
    this.search,
    this.filters = const {},
  });

  final int page;
  final int pageSize;
  final String? sortBy;
  final SortOrder sortOrder;
  final String? search;
  final Map<String, dynamic> filters;

  PurchasesQueryParams copyWith({
    int? page,
    int? pageSize,
    String? sortBy,
    SortOrder? sortOrder,
    String? search,
    Map<String, dynamic>? filters,
  }) => PurchasesQueryParams(
    page: page ?? this.page,
    pageSize: pageSize ?? this.pageSize,
    sortBy: sortBy ?? this.sortBy,
    sortOrder: sortOrder ?? this.sortOrder,
    search: search ?? this.search,
    filters: filters ?? this.filters,
  );
}

enum SortOrder { asc, desc }

class PurchasesApiService {
  PurchasesApiService() : _dio = ApiService().dio;
  final Dio _dio;

  static const String _basePath = '/purchases';

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
          : 'Purchases request failed.',
    );
  }

  Map<String, dynamic> _buildQuery(PurchasesQueryParams q) {
    return {
      'page': q.page,
      'pageSize': q.pageSize,
      if (q.sortBy != null && q.sortBy!.isNotEmpty) 'sortBy': q.sortBy,
      'sortOrder': q.sortOrder.name,
      if (q.search != null && q.search!.trim().isNotEmpty)
        'search': q.search!.trim(),
      if (q.search != null && q.search!.trim().isNotEmpty)
        'q': q.search!.trim(),
      ...q.filters,
    };
  }

  Map<String, dynamic> _mapFromResponse(Response<dynamic> resp) {
    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const UnknownException('Invalid response format from purchases API.');
  }

  PaginatedResponse<T> _parsePaginated<T>(
    Response<dynamic> resp,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    dynamic data = resp.data;
    if (data == null) {
      return PaginatedResponse<T>(items: [], total: 0, page: 1, pageSize: 20);
    }
    if (data is List) {
      final items = data
          .map(
            (e) => fromJson(
              e is Map<String, dynamic>
                  ? e
                  : Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
      return PaginatedResponse<T>(
        items: items,
        total: items.length,
        page: 1,
        pageSize: items.length,
      );
    }
    if (data is! Map) {
      return PaginatedResponse<T>(items: [], total: 0, page: 1, pageSize: 20);
    }
    Map<String, dynamic> map = Map<String, dynamic>.from(data);
    final inner = map['data'];
    if (inner is Map && inner is! List) {
      final innerMap = Map<String, dynamic>.from(inner);
      if (innerMap.containsKey('data') || innerMap.containsKey('items')) {
        map = innerMap;
      }
    }
    final list = map['data'] ?? map['items'] ?? map['results'] ?? map['list'];
    final rawList = list is List ? list : <dynamic>[];
    final items = rawList
        .map(
          (e) => fromJson(
            e is Map<String, dynamic> ? e : Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
    final total = _toInt(
      map['total'] ?? map['totalCount'] ?? map['totalRecords'],
      items.length,
    );
    final skip = _toInt(map['skip'], 0);
    final take = _toInt(map['take'] ?? map['limit'], 20);
    final page = _toInt(map['page'], take > 0 ? (skip ~/ take) + 1 : 1);
    final pageSize = _toInt(map['pageSize'] ?? map['limit'], take);
    return PaginatedResponse<T>(
      items: items,
      total: total,
      page: page,
      pageSize: pageSize > 0 ? pageSize : 20,
    );
  }

  int _toInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value == null) return fallback;
    return int.tryParse(value.toString()) ?? fallback;
  }

  Map<String, dynamic> _buildBatchSearchQuery(PurchasesQueryParams q) {
    final skip = ((q.page - 1) * q.pageSize).clamp(0, 0x7fffffff);
    final limit = q.pageSize.clamp(1, 100);
    return {
      'limit': limit,
      'skip': skip,
      'sortBy': q.sortBy ?? 'createdAt',
      'sortOrder': q.sortOrder.name,
      ...q.filters,
    };
  }

  // ITEMS
  Future<PaginatedResponse<PurchaseItem>> searchItems(
    SearchPurchaseItemParams dto,
  ) async {
    try {
      final resp = await _dio.get(
        '$_basePath/items',
        queryParameters: dto.toQuery(),
      );
      return _parsePaginated(resp, (m) => PurchaseItem.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse items: ${e.toString()}');
    }
  }

  Future<PaginatedResponse<PurchaseItem>> getItems([
    PurchasesQueryParams? q,
  ]) async {
    final params = q ?? const PurchasesQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/items',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => PurchaseItem.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse items: ${e.toString()}');
    }
  }

  Future<PurchaseItem> getItemById(String id) async {
    try {
      final resp = await _dio.get('$_basePath/items/$id');
      return PurchaseItem.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PurchaseItem> createItem(PurchaseItem item) async {
    try {
      final resp = await _dio.post('$_basePath/items', data: item.toJson());
      return PurchaseItem.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PurchaseItem> updateItem(PurchaseItem item) async {
    if (item.id == null || item.id!.isEmpty) {
      throw const ValidationException('Item id required for update.');
    }
    try {
      final resp = await _dio.patch(
        '$_basePath/items/${item.id}',
        data: item.toJson(),
      );
      return PurchaseItem.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteItem(String id) async {
    try {
      await _dio.delete('$_basePath/items/$id');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // MANUFACTURERS
  Future<PaginatedResponse<PurchasesManufacturer>> getManufacturers([
    PurchasesQueryParams? q,
  ]) async {
    final params = q ?? const PurchasesQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/manufacturers',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => PurchasesManufacturer.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PurchasesManufacturer> createManufacturer(
    PurchasesManufacturer manufacturer,
  ) async {
    try {
      final resp = await _dio.post(
        '$_basePath/manufacturers',
        data: manufacturer.toJson(),
      );
      return PurchasesManufacturer.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // SUPPLIERS
  Future<PaginatedResponse<PurchasesSupplier>> getSuppliers([
    PurchasesQueryParams? q,
  ]) async {
    final params = q ?? const PurchasesQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/suppliers',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => PurchasesSupplier.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PurchasesSupplier> getSupplierById(String id) async {
    try {
      final resp = await _dio.get('$_basePath/suppliers/$id');
      return PurchasesSupplier.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PurchasesSupplier> createSupplier(PurchasesSupplier supplier) async {
    try {
      final resp = await _dio.post(
        '$_basePath/suppliers',
        data: supplier.toJson(),
      );
      return PurchasesSupplier.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PurchasesSupplier> updateSupplier(PurchasesSupplier supplier) async {
    if (supplier.id == null || supplier.id!.isEmpty) {
      throw const ValidationException('Supplier id required for update.');
    }
    try {
      final resp = await _dio.patch(
        '$_basePath/suppliers/${supplier.id}',
        data: supplier.toJson(),
      );
      return PurchasesSupplier.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteSupplier(String id) async {
    try {
      await _dio.delete('$_basePath/suppliers/$id');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // PURCHASE ORDERS
  Future<PaginatedResponse<PurchaseOrder>> getPurchaseOrders([
    PurchasesQueryParams? q,
  ]) async {
    final params = q ?? const PurchasesQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/purchase-orders',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => PurchaseOrder.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PurchaseOrder> createPurchaseOrder(PurchaseOrder order) async {
    try {
      final resp = await _dio.post(
        '$_basePath/purchase-orders',
        data: order.toJson(),
      );
      final data = _mapFromResponse(resp);
      if (data.isEmpty || data['id'] == null) return order;
      return PurchaseOrder.fromJson(data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // BATCHES
  Future<PaginatedResponse<PurchaseItemBatch>> getItemBatches([
    PurchasesQueryParams? q,
  ]) async {
    final params = q ?? const PurchasesQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/batches',
        queryParameters: _buildBatchSearchQuery(params),
      );
      return _parsePaginated(resp, (m) => PurchaseItemBatch.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PurchaseItemBatch> createItemBatch(PurchaseItemBatch batch) async {
    try {
      final resp = await _dio.post('$_basePath/batches', data: batch.toJson());
      return PurchaseItemBatch.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PurchaseItemBatch> correctItemBatchQuantity(
    String batchId,
    CorrectBatchQuantityDto dto,
  ) async {
    try {
      final resp = await _dio.patch(
        '$_basePath/batches/$batchId/quantity-correction',
        data: dto.toJson(),
      );
      return PurchaseItemBatch.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // GOODS RECEIPTS
  Future<PaginatedResponse<GoodsReceipt>> getGoodsReceipts([
    PurchasesQueryParams? q,
  ]) async {
    final params = q ?? const PurchasesQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/goods-receipts',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => GoodsReceipt.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<GoodsReceipt> createGoodsReceipt(GoodsReceipt receipt) async {
    try {
      final resp = await _dio.post(
        '$_basePath/goods-receipts',
        data: receipt.toJson(),
      );
      return GoodsReceipt.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // STOCK TRANSFERS
  Future<PaginatedResponse<PurchasesStockTransfer>> getStockTransfers([
    PurchasesQueryParams? q,
  ]) async {
    final params = q ?? const PurchasesQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/stock-transfers',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => PurchasesStockTransfer.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PaginatedResponse<PurchasesStockTransfer>> getTransferHistory(
    TransferHistoryQuery query,
  ) async {
    try {
      final resp = await _dio.get(
        '$_basePath/stock-transfers/history',
        queryParameters: query.toQuery(),
      );
      return _parsePaginated(resp, (m) => PurchasesStockTransfer.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PurchasesStockTransfer> createStockTransfer(
    CreateStockTransferDto dto,
  ) async {
    try {
      final resp = await _dio.post(
        '$_basePath/stock-transfers',
        data: dto.toJson(),
      );
      return PurchasesStockTransfer.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PurchasesStockTransfer> updateStockTransfer(
    PurchasesStockTransfer transfer,
  ) async {
    if (transfer.id == null || transfer.id!.isEmpty) {
      throw const ValidationException('Stock transfer id required for update.');
    }
    try {
      final resp = await _dio.patch(
        '$_basePath/stock-transfers/${transfer.id}',
        data: transfer.toJson(),
      );
      return PurchasesStockTransfer.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // LOCATIONS
  Future<PaginatedResponse<PurchasesLocation>> getLocations([
    PurchasesQueryParams? q,
  ]) async {
    final params = q ?? const PurchasesQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/locations',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => PurchasesLocation.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PurchasesLocation> createLocation(PurchasesLocation location) async {
    try {
      final resp = await _dio.post(
        '$_basePath/locations',
        data: location.toJson(),
      );
      return PurchasesLocation.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PurchasesLocation> updateLocation(PurchasesLocation location) async {
    if (location.id == null || location.id!.isEmpty) {
      throw const ValidationException('Location id required for update.');
    }
    try {
      final resp = await _dio.patch(
        '$_basePath/locations/${location.id}',
        data: location.toJson(),
      );
      return PurchasesLocation.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteLocation(String id) async {
    try {
      await _dio.delete('$_basePath/locations/$id');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<List<ItemLocationQuantity>> getItemLocationQuantities(
    String itemId, {
    String? locationId,
  }) async {
    try {
      final resp = await _dio.get(
        '$_basePath/locations/item/$itemId/quantity',
        queryParameters: {
          if (locationId != null && locationId.trim().isNotEmpty)
            'locationId': locationId.trim(),
        },
      );
      final payload = resp.data;
      List? listData;
      if (payload is List) {
        listData = payload;
      } else if (payload is Map) {
        final map = Map<String, dynamic>.from(payload);
        listData = map['data'] ?? map['items'] ?? map['results'];
      }
      if (listData == null) return [];
      return listData
          .whereType<Map>()
          .map(
            (e) => ItemLocationQuantity.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PurchasesLocation> getLocationById(String id) async {
    try {
      final resp = await _dio.get('$_basePath/locations/$id');
      return PurchasesLocation.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // REQUISITIONS
  Future<PaginatedResponse<Requisition>> getRequisitions([
    PurchasesQueryParams? q,
  ]) async {
    final params = q ?? const PurchasesQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/requisitions',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => Requisition.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Requisition> getRequisitionById(String id) async {
    try {
      final resp = await _dio.get('$_basePath/requisitions/$id');
      return Requisition.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Requisition> createRequisition(CreateRequisitionDto dto) async {
    try {
      final resp = await _dio.post(
        '$_basePath/requisitions',
        data: dto.toJson(),
      );
      return Requisition.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Requisition> approveRequisition(String id, {String? notes}) async {
    try {
      final resp = await _dio.post(
        '$_basePath/requisitions/$id/approve',
        data: {if (notes != null) 'notes': notes},
      );
      return Requisition.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Requisition> rejectRequisition(String id, {String? reason}) async {
    try {
      final resp = await _dio.post(
        '$_basePath/requisitions/$id/reject',
        data: {if (reason != null) 'reason': reason},
      );
      return Requisition.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PurchaseOrder> convertRequisitionToPo(String id) async {
    try {
      final resp = await _dio.post('$_basePath/requisitions/$id/convert-to-po');
      return PurchaseOrder.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }
}
