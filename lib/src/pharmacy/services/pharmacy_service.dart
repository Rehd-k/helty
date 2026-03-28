import 'package:dio/dio.dart';

import '../../core/errors/app_exception.dart';
import '../../services/api_service.dart';
import '../models/pharmacy_model.dart';

/// Common query parameters for paginated, sortable, filterable list endpoints.
class PharmacyQueryParams {
  const PharmacyQueryParams({
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

  PharmacyQueryParams copyWith({
    int? page,
    int? pageSize,
    String? sortBy,
    SortOrder? sortOrder,
    String? search,
    Map<String, dynamic>? filters,
  }) => PharmacyQueryParams(
    page: page ?? this.page,
    pageSize: pageSize ?? this.pageSize,
    sortBy: sortBy ?? this.sortBy,
    sortOrder: sortOrder ?? this.sortOrder,
    search: search ?? this.search,
    filters: filters ?? this.filters,
  );
}

enum SortOrder { asc, desc }

/// Pharmacy API service using the shared [ApiService] Dio client.
/// All list methods return [PaginatedResponse<T>]; all errors are [AppException].
class PharmacyApiService {
  PharmacyApiService() : _dio = ApiService().dio;
  final Dio _dio;

  static const String _basePath = '/pharmacy';

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
          : 'Pharmacy request failed.',
    );
  }

  /// Builds query map for list endpoints: page, pageSize, sort, search, and custom filters.
  Map<String, dynamic> _buildQuery(PharmacyQueryParams q) {
    final map = <String, dynamic>{
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
    return map;
  }

  Map<String, dynamic> _mapFromResponse(Response<dynamic> resp) {
    final data = resp.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const UnknownException('Invalid response format from pharmacy API.');
  }

  /// Parses paginated response. Supports:
  /// - { data: [], total, page, pageSize }
  /// - { data: [], total, skip, take } (backend uses skip/take)
  /// - { items: [], totalCount } with optional page/pageSize
  /// - Nested: { data: { data: [], total, skip, take } }
  /// - Null or non-Map/List: returns empty result instead of throwing
  PaginatedResponse<T> _parsePaginated<T>(
    Response<dynamic> resp,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    dynamic data = resp.data;

    // Null or unexpected type: return empty to avoid "Invalid paginated response"
    if (data == null) {
      return PaginatedResponse<T>(items: [], total: 0, page: 1, pageSize: 20);
    }

    // Some endpoints return a bare list.
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

    // Nested payload: e.g. { data: { data: [], total, skip, take } }
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

  // ═══════════════════════════════════════════════════════════════════════════
  // DRUGS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Search drugs with full SearchDrugDto filters (GET /pharmacy/drugs).
  Future<PaginatedResponse<Drug>> searchDrugs(SearchDrugParams dto) async {
    try {
      final resp = await _dio.get(
        '$_basePath/drugs',
        queryParameters: dto.toQuery(),
      );
      return _parsePaginated(resp, (m) => Drug.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse drugs: ${e.toString()}');
    }
  }

  Future<PaginatedResponse<Drug>> getDrugs([PharmacyQueryParams? q]) async {
    final params = q ?? const PharmacyQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/drugs',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => Drug.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse drugs: ${e.toString()}');
    }
  }

  Future<Drug> getDrugById(String id) async {
    try {
      final resp = await _dio.get('$_basePath/drugs/$id');
      return Drug.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse drug: ${e.toString()}');
    }
  }

  Future<Drug> createDrug(Drug drug) async {
    try {
      final resp = await _dio.post('$_basePath/drugs', data: drug.toJson());
      return Drug.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Drug> updateDrug(Drug drug) async {
    if (drug.id == null || drug.id!.isEmpty) {
      throw const ValidationException('Drug id required for update.');
    }
    try {
      final resp = await _dio.patch(
        '$_basePath/drugs/${drug.id}',
        data: drug.toJson(),
      );
      return Drug.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteDrug(String id) async {
    try {
      await _dio.delete('$_basePath/drugs/$id');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MANUFACTURERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PaginatedResponse<Manufacturer>> getManufacturers([
    PharmacyQueryParams? q,
  ]) async {
    final params = q ?? const PharmacyQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/manufacturers',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => Manufacturer.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse manufacturers: ${e.toString()}');
    }
  }

  Future<Manufacturer> getManufacturerById(String id) async {
    try {
      final resp = await _dio.get('$_basePath/manufacturers/$id');
      return Manufacturer.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse manufacturer: ${e.toString()}');
    }
  }

  Future<Manufacturer> createManufacturer(Manufacturer manufacturer) async {
    try {
      final resp = await _dio.post(
        '$_basePath/manufacturers',
        data: manufacturer.toJson(),
      );
      return Manufacturer.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Manufacturer> updateManufacturer(Manufacturer manufacturer) async {
    if (manufacturer.id == null || manufacturer.id!.isEmpty) {
      throw const ValidationException('Manufacturer id required for update.');
    }
    try {
      final resp = await _dio.patch(
        '$_basePath/manufacturers/${manufacturer.id}',
        data: manufacturer.toJson(),
      );
      return Manufacturer.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteManufacturer(String id) async {
    try {
      await _dio.delete('$_basePath/manufacturers/$id');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SUPPLIERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PaginatedResponse<Supplier>> getSuppliers([
    PharmacyQueryParams? q,
  ]) async {
    final params = q ?? const PharmacyQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/suppliers',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => Supplier.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse suppliers: ${e.toString()}');
    }
  }

  Future<Supplier> getSupplierById(String id) async {
    try {
      final resp = await _dio.get('$_basePath/suppliers/$id');
      return Supplier.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse supplier: ${e.toString()}');
    }
  }

  Future<Supplier> createSupplier(Supplier supplier) async {
    try {
      final resp = await _dio.post(
        '$_basePath/suppliers',
        data: supplier.toJson(),
      );
      return Supplier.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Supplier> updateSupplier(Supplier supplier) async {
    if (supplier.id == null || supplier.id!.isEmpty) {
      throw const ValidationException('Supplier id required for update.');
    }
    try {
      final resp = await _dio.patch(
        '$_basePath/suppliers/${supplier.id}',
        data: supplier.toJson(),
      );
      return Supplier.fromJson(_mapFromResponse(resp));
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

  // ═══════════════════════════════════════════════════════════════════════════
  // CONSUMABLES
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PaginatedResponse<Consumable>> getConsumables([
    PharmacyQueryParams? q,
  ]) async {
    final params = q ?? const PharmacyQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/consumables',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => Consumable.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse consumables: ${e.toString()}');
    }
  }

  Future<Consumable> getConsumableById(String id) async {
    try {
      final resp = await _dio.get('$_basePath/consumables/$id');
      return Consumable.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse consumable: ${e.toString()}');
    }
  }

  Future<Consumable> createConsumable(Consumable consumable) async {
    try {
      final resp = await _dio.post(
        '$_basePath/consumables',
        data: consumable.toJson(),
      );
      return Consumable.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Consumable> updateConsumable(Consumable consumable) async {
    if (consumable.id == null || consumable.id!.isEmpty) {
      throw const ValidationException('Consumable id required for update.');
    }
    try {
      final resp = await _dio.patch(
        '$_basePath/consumables/${consumable.id}',
        data: consumable.toJson(),
      );
      return Consumable.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteConsumable(String id) async {
    try {
      await _dio.delete('$_basePath/consumables/$id');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PURCHASE ORDERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PaginatedResponse<PurchaseOrder>> getPurchaseOrders([
    PharmacyQueryParams? q,
  ]) async {
    final params = q ?? const PharmacyQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/purchase-orders',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => PurchaseOrder.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException(
        'Failed to parse purchase orders: ${e.toString()}',
      );
    }
  }

  Future<PurchaseOrder> getPurchaseOrderById(String id) async {
    try {
      final resp = await _dio.get('$_basePath/purchase-orders/$id');
      return PurchaseOrder.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse purchase order: ${e.toString()}');
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

  Future<PurchaseOrder> updatePurchaseOrder(PurchaseOrder order) async {
    if (order.id == null || order.id!.isEmpty) {
      throw const ValidationException('Purchase order id required for update.');
    }
    try {
      final resp = await _dio.patch(
        '$_basePath/purchase-orders/${order.id}',
        data: order.toJson(),
      );
      return PurchaseOrder.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<void> deletePurchaseOrder(String id) async {
    try {
      await _dio.delete('$_basePath/purchase-orders/$id');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DRUG BATCHES
  // ═══════════════════════════════════════════════════════════════════════════

  /// Builds query for batch search: backend expects limit, skip, sortBy, sortOrder + filters.
  Map<String, dynamic> _buildBatchSearchQuery(PharmacyQueryParams q) {
    final skip = ((q.page - 1) * q.pageSize).clamp(0, 0x7fffffff);
    final limit = q.pageSize.clamp(1, 100);
    final map = <String, dynamic>{
      'limit': limit,
      'skip': skip,
      'sortBy': q.sortBy ?? 'expiryDate',
      'sortOrder': q.sortOrder.name,
      ...q.filters,
    };
    return map;
  }

  Future<PaginatedResponse<DrugBatch>> getDrugBatches([
    PharmacyQueryParams? q,
  ]) async {
    final params = q ?? const PharmacyQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/batches',
        queryParameters: _buildBatchSearchQuery(params),
      );
      return _parsePaginated(resp, (m) => DrugBatch.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse drug batches: ${e.toString()}');
    }
  }

  Future<DrugBatch> getDrugBatchById(String id) async {
    try {
      final resp = await _dio.get('$_basePath/batches/$id');
      return DrugBatch.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse drug batch: ${e.toString()}');
    }
  }

  Future<DrugBatch> createDrugBatch(DrugBatch batch) async {
    try {
      final resp = await _dio.post('$_basePath/batches', data: batch.toJson());
      return DrugBatch.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<DrugBatch> updateDrugBatch(DrugBatch batch) async {
    if (batch.id == null || batch.id!.isEmpty) {
      throw const ValidationException('Drug batch id required for update.');
    }
    try {
      final resp = await _dio.patch(
        '$_basePath/batches/${batch.id}',
        data: batch.toJson(),
      );
      return DrugBatch.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteDrugBatch(String id) async {
    try {
      await _dio.delete('$_basePath/batches/$id');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // GOODS RECEIPTS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PaginatedResponse<GoodsReceipt>> getGoodsReceipts([
    PharmacyQueryParams? q,
  ]) async {
    final params = q ?? const PharmacyQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/goods-receipts',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => GoodsReceipt.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse goods receipts: ${e.toString()}');
    }
  }

  Future<GoodsReceipt> getGoodsReceiptById(String id) async {
    try {
      final resp = await _dio.get('$_basePath/goods-receipts/$id');
      return GoodsReceipt.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse goods receipt: ${e.toString()}');
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

  Future<void> deleteGoodsReceipt(String id) async {
    try {
      await _dio.delete('$_basePath/goods-receipts/$id');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STOCK TRANSFERS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PaginatedResponse<StockTransfer>> getStockTransfers([
    PharmacyQueryParams? q,
  ]) async {
    final params = q ?? const PharmacyQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/stock-transfers',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => StockTransfer.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException(
        'Failed to parse stock transfers: ${e.toString()}',
      );
    }
  }

  Future<StockTransfer> getStockTransferById(String id) async {
    try {
      final resp = await _dio.get('$_basePath/stock-transfers/$id');
      return StockTransfer.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse stock transfer: ${e.toString()}');
    }
  }

  Future<StockTransfer> createStockTransfer(StockTransfer transfer) async {
    try {
      final resp = await _dio.post(
        '$_basePath/stock-transfers',
        data: transfer.toJson(),
      );
      return StockTransfer.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<StockTransfer> updateStockTransfer(StockTransfer transfer) async {
    if (transfer.id == null || transfer.id!.isEmpty) {
      throw const ValidationException('Stock transfer id required for update.');
    }
    try {
      final resp = await _dio.patch(
        '$_basePath/stock-transfers/${transfer.id}',
        data: transfer.toJson(),
      );
      return StockTransfer.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteStockTransfer(String id) async {
    try {
      await _dio.delete('$_basePath/stock-transfers/$id');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DISPENSATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PaginatedResponse<Dispensation>> getDispensations([
    PharmacyQueryParams? q,
  ]) async {
    final params = q ?? const PharmacyQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/dispensations',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => Dispensation.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse dispensations: ${e.toString()}');
    }
  }

  Future<Dispensation> getDispensationById(String id) async {
    try {
      final resp = await _dio.get('$_basePath/dispensations/$id');
      return Dispensation.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException('Failed to parse dispensation: ${e.toString()}');
    }
  }

  Future<Dispensation> createDispensation(Dispensation dispensation) async {
    try {
      final resp = await _dio.post(
        '$_basePath/dispensations',
        data: dispensation.toJson(),
      );
      return Dispensation.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Dispensation> updateDispensation(Dispensation dispensation) async {
    if (dispensation.id == null || dispensation.id!.isEmpty) {
      throw const ValidationException('Dispensation id required for update.');
    }
    try {
      final resp = await _dio.patch(
        '$_basePath/dispensations/${dispensation.id}',
        data: dispensation.toJson(),
      );
      return Dispensation.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<void> deleteDispensation(String id) async {
    try {
      await _dio.delete('$_basePath/dispensations/$id');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PHARMACY LOCATIONS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<PaginatedResponse<PharmacyLocation>> getPharmacyLocations([
    PharmacyQueryParams? q,
  ]) async {
    final params = q ?? const PharmacyQueryParams();
    try {
      final resp = await _dio.get(
        '$_basePath/locations',
        queryParameters: _buildQuery(params),
      );
      return _parsePaginated(resp, (m) => PharmacyLocation.fromJson(m));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException(
        'Failed to parse pharmacy locations: ${e.toString()}',
      );
    }
  }

  Future<PharmacyLocation> getPharmacyLocationById(String id) async {
    try {
      final resp = await _dio.get('$_basePath/locations/$id');
      return PharmacyLocation.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    } on TypeError catch (e) {
      throw UnknownException(
        'Failed to parse pharmacy location: ${e.toString()}',
      );
    }
  }

  Future<PharmacyLocation> createPharmacyLocation(
    PharmacyLocation location,
  ) async {
    try {
      final resp = await _dio.post(
        '$_basePath/locations',
        data: location.toJson(),
      );
      return PharmacyLocation.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<PharmacyLocation> updatePharmacyLocation(
    PharmacyLocation location,
  ) async {
    if (location.id == null || location.id!.isEmpty) {
      throw const ValidationException(
        'Pharmacy location id required for update.',
      );
    }
    try {
      final resp = await _dio.patch(
        '$_basePath/locations/${location.id}',
        data: location.toJson(),
      );
      return PharmacyLocation.fromJson(_mapFromResponse(resp));
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<void> deletePharmacyLocation(String id) async {
    try {
      await _dio.delete('$_basePath/locations/$id');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<List<DrugLocationQuantity>> getDrugLocationQuantities(
    String drugId,
  ) async {
    if (drugId.trim().isEmpty) {
      throw const ValidationException('Drug id is required.');
    }
    try {
      final resp = await _dio.get('$_basePath/locations/drug/$drugId/quantity');
      final payload = resp.data;
      final dynamic listData;
      if (payload is List) {
        listData = payload;
      } else if (payload is Map) {
        final map = Map<String, dynamic>.from(payload);
        listData = map['data'] ?? map['items'] ?? map['results'] ?? map['list'];
      } else {
        listData = null;
      }

      if (listData is! List) return <DrugLocationQuantity>[];
      return listData
          .whereType<Map>()
          .map(
            (e) => DrugLocationQuantity.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }
}
