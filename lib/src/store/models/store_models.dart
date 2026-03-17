// Store module — typed models for /store API.
// Matches backend DTOs and list response shapes.

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
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        description: json['description'] as String?,
        isActive: (json['isActive'] as bool?) ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
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
        id: json['id'] as String,
        name: json['name'] as String,
        sku: json['sku'] as String?,
        categoryId: json['categoryId'] as String,
        category: json['category'] != null
            ? StoreCategoryRef.fromJson(json['category'] as Map<String, dynamic>)
            : null,
        unitOfMeasure: json['unitOfMeasure'] as String? ?? 'unit',
        reorderLevel: (json['reorderLevel'] as num?)?.toDouble() ?? 0,
        isActive: (json['isActive'] as bool?) ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
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
        id: json['id'] as String,
        name: json['name'] as String,
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
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        description: json['description'] as String?,
        isPrimary: (json['isPrimary'] as bool?) ?? false,
        isActive: (json['isActive'] as bool?) ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        updatedAt: json['updatedAt'] != null
            ? DateTime.tryParse(json['updatedAt'] as String)
            : null,
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
        id: json['id'] as String,
        locationId: json['locationId'] as String,
        itemId: json['itemId'] as String,
        quantity: (json['quantity'] as num).toDouble(),
        unitCost: (json['unitCost'] as num?)?.toDouble(),
        location: json['location'] != null
            ? StoreLocation.fromJson(json['location'] as Map<String, dynamic>)
            : null,
        item: json['item'] != null
            ? StoreItem.fromJson(json['item'] as Map<String, dynamic>)
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
        data: (json['data'] as List<dynamic>?)
                ?.map((e) => StoreCategory.fromJson(e as Map<String, dynamic>))
                .toList() ??
            (json['data'] == null && json['items'] != null
                ? (json['items'] as List<dynamic>)
                    .map((e) => StoreCategory.fromJson(e as Map<String, dynamic>))
                    .toList()
                : []),
        total: (json['total'] as num?)?.toInt() ?? 0,
        skip: (json['skip'] as num?)?.toInt(),
        limit: (json['limit'] as num?)?.toInt() ?? (json['take'] as num?)?.toInt(),
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
        data: (json['data'] as List<dynamic>?)
                ?.map((e) => StoreItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            (json['data'] == null && json['items'] != null
                ? (json['items'] as List<dynamic>)
                    .map((e) => StoreItem.fromJson(e as Map<String, dynamic>))
                    .toList()
                : []),
        total: (json['total'] as num?)?.toInt() ?? 0,
        skip: (json['skip'] as num?)?.toInt(),
        limit: (json['limit'] as num?)?.toInt() ?? (json['take'] as num?)?.toInt(),
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
        data: (json['data'] as List<dynamic>?)
                ?.map((e) => StoreLocation.fromJson(e as Map<String, dynamic>))
                .toList() ??
            (json['data'] == null && json['items'] != null
                ? (json['items'] as List<dynamic>)
                    .map((e) => StoreLocation.fromJson(e as Map<String, dynamic>))
                    .toList()
                : []),
        total: (json['total'] as num?)?.toInt() ?? 0,
        skip: (json['skip'] as num?)?.toInt(),
        limit: (json['limit'] as num?)?.toInt() ?? (json['take'] as num?)?.toInt(),
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
        data: (json['data'] as List<dynamic>?)
                ?.map((e) => StoreStock.fromJson(e as Map<String, dynamic>))
                .toList() ??
            (json['data'] == null && json['items'] != null
                ? (json['items'] as List<dynamic>)
                    .map((e) => StoreStock.fromJson(e as Map<String, dynamic>))
                    .toList()
                : []),
        total: (json['total'] as num?)?.toInt() ?? 0,
        skip: (json['skip'] as num?)?.toInt(),
        limit: (json['limit'] as num?)?.toInt() ?? (json['take'] as num?)?.toInt(),
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
        itemId: json['itemId'] as String? ?? '',
        itemName: json['itemName'] as String? ?? json['name'] as String? ?? '',
        locationId: json['locationId'] as String? ?? '',
        locationName: json['locationName'] as String? ?? json['locationName'] as String? ?? '',
        quantity: (json['quantity'] as num?)?.toDouble() ?? 0,
        reorderLevel: (json['reorderLevel'] as num?)?.toDouble() ?? 0,
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
        itemId: json['itemId'] as String? ?? '',
        itemName: json['itemName'] as String? ?? json['name'] as String? ?? '',
        quantityMoved: (json['quantityMoved'] as num?)?.toDouble() ?? (json['quantity'] as num?)?.toDouble() ?? 0,
        movementType: json['movementType'] as String?,
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
          .map((e) => LowStockEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['lowStock'] is List) {
      lowStock = (json['lowStock'] as List<dynamic>)
          .map((e) => LowStockEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    List<TopMovingEntry> topMoving = [];
    if (json['topMovingItems'] is List) {
      topMoving = (json['topMovingItems'] as List<dynamic>)
          .map((e) => TopMovingEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } else if (json['topMoving'] is List) {
      topMoving = (json['topMoving'] as List<dynamic>)
          .map((e) => TopMovingEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return StoreAnalytics(
      lowStockItems: lowStock,
      topMovingItems: topMoving,
      issueCount: (json['issueCount'] as num?)?.toInt() ?? (json['issuesCount'] as num?)?.toInt(),
      receiveCount: (json['receiveCount'] as num?)?.toInt() ?? (json['receivesCount'] as num?)?.toInt(),
      transferCount: (json['transferCount'] as num?)?.toInt() ?? (json['transfersCount'] as num?)?.toInt(),
      fromDate: json['fromDate'] != null
          ? DateTime.tryParse(json['fromDate'] as String)
          : null,
      toDate: json['toDate'] != null
          ? DateTime.tryParse(json['toDate'] as String)
          : null,
    );
  }
}
