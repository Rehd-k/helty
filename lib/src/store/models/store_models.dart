// Store module — typed models for /store API.
// Matches backend DTOs and list response shapes.

import 'package:helty/src/core/utils/api_decimal.dart';

double _storeParseDouble(dynamic value, [double fallback = 0]) =>
    parseApiDecimal(value, fallback: fallback);

int _storeParseInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

int? _storeParseIntNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

Map<String, dynamic> _storeMapFrom(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('Expected JSON object, got ${value.runtimeType}');
}

String _storeString(dynamic value, [String fallback = '']) {
  if (value == null) return fallback;
  return value.toString();
}

bool _storeBool(dynamic value, [bool fallback = true]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  final s = value.toString().toLowerCase().trim();
  if (s == 'true' || s == '1' || s == 'yes') return true;
  if (s == 'false' || s == '0' || s == 'no') return false;
  return fallback;
}

DateTime? _storeDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

/// Normalizes `data` / `items` list fields (null, nested map, or non-list → empty list).
List<Map<String, dynamic>> _storeJsonObjectList(dynamic raw, [int depth = 0]) {
  if (raw == null || depth > 5) return const [];
  if (raw is Map) {
    final inner = raw['data'] ?? raw['items'];
    if (inner == null) return const [];
    return _storeJsonObjectList(inner, depth + 1);
  }
  if (raw is! List) return const [];
  final out = <Map<String, dynamic>>[];
  for (final e in raw) {
    if (e is Map) out.add(Map<String, dynamic>.from(e));
  }
  return out;
}

/// Store item category (e.g. Consumables, Equipment).
class StoreCategory {
  const StoreCategory({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String code;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory StoreCategory.fromJson(Map<String, dynamic> json) => StoreCategory(
        id: _storeString(json['id']),
        name: _storeString(json['name']),
        code: _storeString(json['code']),
        description: json['description']?.toString(),
        isActive: _storeBool(json['isActive'] ?? json['is_active'], true),
        createdAt: _storeDate(json['createdAt'] ?? json['created_at']),
        updatedAt: _storeDate(json['updatedAt'] ?? json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        if (description != null) 'description': description,
        'isActive': isActive,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}

/// Create store category request (POST categories).
class CreateStoreCategoryDto {
  const CreateStoreCategoryDto({
    required this.name,
    required this.code,
    this.description,
    this.isActive = true,
  });

  final String name;
  final String code;
  final String? description;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        if (description != null && description!.isNotEmpty) 'description': description,
        'isActive': isActive,
      };
}

/// Update store category request (PATCH categories/:id).
class UpdateStoreCategoryDto {
  const UpdateStoreCategoryDto({
    this.name,
    this.code,
    this.description,
    this.isActive,
  });

  final String? name;
  final String? code;
  final String? description;
  final bool? isActive;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (code != null) 'code': code,
        if (description != null) 'description': description,
        if (isActive != null) 'isActive': isActive,
      };
}

// ── Store item ─────────────────────────────────────────────────────────────

/// Store item (inventory item).
class StoreItem {
  const StoreItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.unitOfMeasure,
    this.sku,
    this.reorderLevel = 0,
    this.isActive = true,
    this.category,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? sku;
  final String categoryId;
  final StoreCategoryRef? category;
  final String unitOfMeasure;
  final double reorderLevel;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory StoreItem.fromJson(Map<String, dynamic> json) => StoreItem(
        id: _storeString(json['id']),
        name: _storeString(json['name']),
        sku: json['sku'] != null ? _storeString(json['sku']) : null,
        categoryId: _storeString(json['categoryId'] ?? json['category_id']),
        category: json['category'] != null
            ? StoreCategoryRef.fromJson(_storeMapFrom(json['category']))
            : null,
        unitOfMeasure: _storeString(
          json['unitOfMeasure'] ?? json['unit_of_measure'],
          'unit',
        ),
        reorderLevel: _storeParseDouble(
          json['reorderLevel'] ?? json['reorder_level'],
        ),
        isActive: _storeBool(json['isActive'] ?? json['is_active'], true),
        createdAt: _storeDate(json['createdAt'] ?? json['created_at']),
        updatedAt: _storeDate(json['updatedAt'] ?? json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (sku != null) 'sku': sku,
        'categoryId': categoryId,
        'unitOfMeasure': unitOfMeasure,
        'reorderLevel': reorderLevel,
        'isActive': isActive,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}

class StoreCategoryRef {
  const StoreCategoryRef({required this.id, required this.name});
  final String id;
  final String name;

  factory StoreCategoryRef.fromJson(Map<String, dynamic> json) =>
      StoreCategoryRef(
        id: _storeString(json['id']),
        name: _storeString(json['name']),
      );
  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

/// Create store item request (POST items).
class CreateStoreItemDto {
  const CreateStoreItemDto({
    required this.name,
    required this.categoryId,
    required this.unitOfMeasure,
    this.sku,
    this.reorderLevel = 0,
    this.isActive = true,
  });

  final String name;
  final String? sku;
  final String categoryId;
  final String unitOfMeasure;
  final double reorderLevel;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'name': name,
        if (sku != null && sku!.isNotEmpty) 'sku': sku,
        'categoryId': categoryId,
        'unitOfMeasure': unitOfMeasure,
        'reorderLevel': reorderLevel,
        'isActive': isActive,
      };
}

/// Update store item request (PATCH items/:id).
class UpdateStoreItemDto {
  const UpdateStoreItemDto({
    this.name,
    this.sku,
    this.categoryId,
    this.unitOfMeasure,
    this.reorderLevel,
    this.isActive,
  });

  final String? name;
  final String? sku;
  final String? categoryId;
  final String? unitOfMeasure;
  final double? reorderLevel;
  final bool? isActive;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (sku != null) 'sku': sku,
        if (categoryId != null) 'categoryId': categoryId,
        if (unitOfMeasure != null) 'unitOfMeasure': unitOfMeasure,
        if (reorderLevel != null) 'reorderLevel': reorderLevel,
        if (isActive != null) 'isActive': isActive,
      };
}

// ── Store location ─────────────────────────────────────────────────────────

/// Store location (warehouse, main store, etc.).
class StoreLocation {
  const StoreLocation({
    required this.id,
    required this.name,
    required this.code,
    this.description,
    this.isPrimary = false,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String code;
  final String? description;
  final bool isPrimary;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory StoreLocation.fromJson(Map<String, dynamic> json) => StoreLocation(
        id: _storeString(json['id']),
        name: _storeString(json['name']),
        code: _storeString(json['code']),
        description: json['description']?.toString(),
        isPrimary: _storeBool(json['isPrimary'] ?? json['is_primary'], false),
        isActive: _storeBool(json['isActive'] ?? json['is_active'], true),
        createdAt: _storeDate(json['createdAt'] ?? json['created_at']),
        updatedAt: _storeDate(json['updatedAt'] ?? json['updated_at']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        if (description != null) 'description': description,
        'isPrimary': isPrimary,
        'isActive': isActive,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}

/// Create store location request (POST locations).
class CreateStoreLocationDto {
  const CreateStoreLocationDto({
    required this.name,
    required this.code,
    this.description,
    this.isPrimary = false,
    this.isActive = true,
  });

  final String name;
  final String code;
  final String? description;
  final bool isPrimary;
  final bool isActive;

  Map<String, dynamic> toJson() => {
        'name': name,
        'code': code,
        if (description != null && description!.isNotEmpty) 'description': description,
        'isPrimary': isPrimary,
        'isActive': isActive,
      };
}

/// Update store location request (PATCH locations/:id).
class UpdateStoreLocationDto {
  const UpdateStoreLocationDto({
    this.name,
    this.code,
    this.description,
    this.isPrimary,
    this.isActive,
  });

  final String? name;
  final String? code;
  final String? description;
  final bool? isPrimary;
  final bool? isActive;

  Map<String, dynamic> toJson() => {
        if (name != null) 'name': name,
        if (code != null) 'code': code,
        if (description != null) 'description': description,
        if (isPrimary != null) 'isPrimary': isPrimary,
        if (isActive != null) 'isActive': isActive,
      };
}

// ── Stock ──────────────────────────────────────────────────────────────────

/// Stock record at a location for an item.
class StoreStock {
  const StoreStock({
    required this.id,
    required this.locationId,
    required this.itemId,
    required this.quantity,
    this.unitCost,
    this.location,
    this.item,
  });

  final String id;
  final String locationId;
  final String itemId;
  final double quantity;
  final double? unitCost;
  final StoreLocation? location;
  final StoreItem? item;

  factory StoreStock.fromJson(Map<String, dynamic> json) => StoreStock(
        id: _storeString(json['id']),
        locationId: _storeString(json['locationId'] ?? json['location_id']),
        itemId: _storeString(json['itemId'] ?? json['item_id']),
        quantity: _storeParseDouble(json['quantity']),
        unitCost: json['unitCost'] != null || json['unit_cost'] != null
            ? _storeParseDouble(json['unitCost'] ?? json['unit_cost'])
            : null,
        location: json['location'] != null
            ? StoreLocation.fromJson(_storeMapFrom(json['location']))
            : null,
        item: json['item'] != null
            ? StoreItem.fromJson(_storeMapFrom(json['item']))
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'locationId': locationId,
        'itemId': itemId,
        'quantity': quantity,
        if (unitCost != null) 'unitCost': unitCost,
        if (location != null) 'location': location!.toJson(),
        if (item != null) 'item': item!.toJson(),
      };
}

// ── Movement DTOs ──────────────────────────────────────────────────────────

/// Single line for issue request.
class IssueItemLine {
  const IssueItemLine({
    required this.itemId,
    required this.quantity,
    this.unitCost,
  });

  final String itemId;
  final double quantity;
  final double? unitCost;

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'quantity': quantity,
        if (unitCost != null) 'unitCost': unitCost,
      };
}

/// Issue items to department request (POST movements/issue).
class IssueItemsRequest {
  const IssueItemsRequest({
    required this.departmentId,
    required this.fromLocationId,
    this.reason,
    required this.items,
  });

  final String departmentId;
  final String fromLocationId;
  final String? reason;
  final List<IssueItemLine> items;

  Map<String, dynamic> toJson() => {
        'departmentId': departmentId,
        'fromLocationId': fromLocationId,
        if (reason != null && reason!.isNotEmpty) 'reason': reason,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

/// Single line for receive request.
class ReceiveItemLine {
  const ReceiveItemLine({
    required this.itemId,
    required this.quantity,
    required this.unitCost,
  });

  final String itemId;
  final double quantity;
  final double unitCost;

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'quantity': quantity,
        'unitCost': unitCost,
      };
}

/// Receive items request (POST movements/receive).
class ReceiveItemsRequest {
  const ReceiveItemsRequest({
    required this.toLocationId,
    this.departmentId,
    this.reason,
    this.referenceType,
    this.referenceId,
    required this.items,
  });

  final String toLocationId;
  final String? departmentId;
  final String? reason;
  final String? referenceType;
  final String? referenceId;
  final List<ReceiveItemLine> items;

  Map<String, dynamic> toJson() => {
        'toLocationId': toLocationId,
        if (departmentId != null) 'departmentId': departmentId,
        if (reason != null && reason!.isNotEmpty) 'reason': reason,
        if (referenceType != null) 'referenceType': referenceType,
        if (referenceId != null) 'referenceId': referenceId,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

/// Single line for transfer request.
class TransferItemLine {
  const TransferItemLine({
    required this.itemId,
    required this.quantity,
  });

  final String itemId;
  final double quantity;

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'quantity': quantity,
      };
}

/// Transfer items between locations request (POST movements/transfer).
class TransferItemsRequest {
  const TransferItemsRequest({
    required this.fromLocationId,
    required this.toLocationId,
    this.reason,
    required this.items,
  });

  final String fromLocationId;
  final String toLocationId;
  final String? reason;
  final List<TransferItemLine> items;

  Map<String, dynamic> toJson() => {
        'fromLocationId': fromLocationId,
        'toLocationId': toLocationId,
        if (reason != null && reason!.isNotEmpty) 'reason': reason,
        'items': items.map((e) => e.toJson()).toList(),
      };
}

// ── List responses ──────────────────────────────────────────────────────────

class StoreCategoriesResponse {
  const StoreCategoriesResponse({
    required this.data,
    required this.total,
    this.skip,
    this.limit,
  });

  final List<StoreCategory> data;
  final int total;
  final int? skip;
  final int? limit;

  factory StoreCategoriesResponse.fromJson(Map<String, dynamic> json) =>
      StoreCategoriesResponse(
        data: _storeJsonObjectList(json['data'] ?? json['items'])
            .map(StoreCategory.fromJson)
            .toList(),
        total: _storeParseInt(json['total']),
        skip: _storeParseIntNullable(json['skip']),
        limit: _storeParseIntNullable(json['limit']) ??
            _storeParseIntNullable(json['take']),
      );
}

class StoreItemsResponse {
  const StoreItemsResponse({
    required this.data,
    required this.total,
    this.skip,
    this.limit,
  });

  final List<StoreItem> data;
  final int total;
  final int? skip;
  final int? limit;

  factory StoreItemsResponse.fromJson(Map<String, dynamic> json) =>
      StoreItemsResponse(
        data: _storeJsonObjectList(json['data'] ?? json['items'])
            .map(StoreItem.fromJson)
            .toList(),
        total: _storeParseInt(json['total']),
        skip: _storeParseIntNullable(json['skip']),
        limit: _storeParseIntNullable(json['limit']) ??
            _storeParseIntNullable(json['take']),
      );
}

class StoreLocationsResponse {
  const StoreLocationsResponse({
    required this.data,
    required this.total,
    this.skip,
    this.limit,
  });

  final List<StoreLocation> data;
  final int total;
  final int? skip;
  final int? limit;

  factory StoreLocationsResponse.fromJson(Map<String, dynamic> json) =>
      StoreLocationsResponse(
        data: _storeJsonObjectList(json['data'] ?? json['items'])
            .map(StoreLocation.fromJson)
            .toList(),
        total: _storeParseInt(json['total']),
        skip: _storeParseIntNullable(json['skip']),
        limit: _storeParseIntNullable(json['limit']) ??
            _storeParseIntNullable(json['take']),
      );
}

class StoreStockResponse {
  const StoreStockResponse({
    required this.data,
    required this.total,
    this.skip,
    this.limit,
  });

  final List<StoreStock> data;
  final int total;
  final int? skip;
  final int? limit;

  factory StoreStockResponse.fromJson(Map<String, dynamic> json) =>
      StoreStockResponse(
        data: _storeJsonObjectList(json['data'] ?? json['items'])
            .map(StoreStock.fromJson)
            .toList(),
        total: _storeParseInt(json['total']),
        skip: _storeParseIntNullable(json['skip']),
        limit: _storeParseIntNullable(json['limit']) ??
            _storeParseIntNullable(json['take']),
      );
}

// ── Analytics ───────────────────────────────────────────────────────────────

/// Low stock entry for analytics.
class LowStockEntry {
  const LowStockEntry({
    required this.itemId,
    required this.itemName,
    required this.locationId,
    required this.locationName,
    required this.quantity,
    required this.reorderLevel,
  });

  final String itemId;
  final String itemName;
  final String locationId;
  final String locationName;
  final double quantity;
  final double reorderLevel;

  factory LowStockEntry.fromJson(Map<String, dynamic> json) => LowStockEntry(
        itemId: _storeString(json['itemId'] ?? json['item_id']),
        itemName: _storeString(
          json['itemName'] ?? json['item_name'] ?? json['name'],
        ),
        locationId: _storeString(json['locationId'] ?? json['location_id']),
        locationName: _storeString(
          json['locationName'] ?? json['location_name'],
        ),
        quantity: _storeParseDouble(json['quantity']),
        reorderLevel: _storeParseDouble(
          json['reorderLevel'] ?? json['reorder_level'],
        ),
      );
}

/// Top moving item entry.
class TopMovingEntry {
  const TopMovingEntry({
    required this.itemId,
    required this.itemName,
    required this.quantityMoved,
    this.movementType,
  });

  final String itemId;
  final String itemName;
  final double quantityMoved;
  final String? movementType;

  factory TopMovingEntry.fromJson(Map<String, dynamic> json) => TopMovingEntry(
        itemId: _storeString(json['itemId'] ?? json['item_id']),
        itemName: _storeString(
          json['itemName'] ?? json['item_name'] ?? json['name'],
        ),
        quantityMoved: json['quantityMoved'] != null ||
                json['quantity_moved'] != null
            ? _storeParseDouble(
                json['quantityMoved'] ?? json['quantity_moved'],
              )
            : _storeParseDouble(json['quantity']),
        movementType: () {
          final v = json['movementType'] ?? json['movement_type'];
          if (v == null) return null;
          final s = _storeString(v);
          return s.isEmpty ? null : s;
        }(),
      );
}

/// Store analytics dashboard response (flexible; extend when backend spec is known).
class StoreAnalytics {
  const StoreAnalytics({
    this.lowStockItems = const [],
    this.topMovingItems = const [],
    this.issueCount,
    this.receiveCount,
    this.transferCount,
    this.fromDate,
    this.toDate,
  });

  final List<LowStockEntry> lowStockItems;
  final List<TopMovingEntry> topMovingItems;
  final int? issueCount;
  final int? receiveCount;
  final int? transferCount;
  final DateTime? fromDate;
  final DateTime? toDate;

  factory StoreAnalytics.fromJson(Map<String, dynamic> json) {
    List<LowStockEntry> lowStock = [];
    if (json['lowStockItems'] is List) {
      lowStock = (json['lowStockItems'] as List<dynamic>)
          .map((e) => LowStockEntry.fromJson(_storeMapFrom(e)))
          .toList();
    } else if (json['lowStock'] is List) {
      lowStock = (json['lowStock'] as List<dynamic>)
          .map((e) => LowStockEntry.fromJson(_storeMapFrom(e)))
          .toList();
    }

    List<TopMovingEntry> topMoving = [];
    if (json['topMovingItems'] is List) {
      topMoving = (json['topMovingItems'] as List<dynamic>)
          .map((e) => TopMovingEntry.fromJson(_storeMapFrom(e)))
          .toList();
    } else if (json['topMoving'] is List) {
      topMoving = (json['topMoving'] as List<dynamic>)
          .map((e) => TopMovingEntry.fromJson(_storeMapFrom(e)))
          .toList();
    }

    return StoreAnalytics(
      lowStockItems: lowStock,
      topMovingItems: topMoving,
      issueCount: json['issueCount'] != null
          ? _storeParseInt(json['issueCount'])
          : _storeParseIntNullable(json['issuesCount']),
      receiveCount: json['receiveCount'] != null
          ? _storeParseInt(json['receiveCount'])
          : _storeParseIntNullable(json['receivesCount']),
      transferCount: json['transferCount'] != null
          ? _storeParseInt(json['transferCount'])
          : _storeParseIntNullable(json['transfersCount']),
      fromDate: _storeDate(json['fromDate'] ?? json['from_date']),
      toDate: _storeDate(json['toDate'] ?? json['to_date']),
    );
  }
}
