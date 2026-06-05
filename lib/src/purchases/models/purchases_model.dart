// ignore_for_file: constant_identifier_names

enum PurchasesLocationType { STORE, WAREHOUSE, DEPARTMENT, COLD_ROOM }

enum PurchasesInventoryMovementType {
  PURCHASE,
  TRANSFER_OUT,
  TRANSFER_IN,
  ADJUSTMENT,
  RETURN,
  EXPIRY_WRITEOFF,
}

enum PurchasesMovementReferenceType {
  PURCHASE_ORDER,
  TRANSFER,
  MANUAL,
  REQUISITION,
}

enum PurchaseOrderStatus { DRAFT, PENDING, APPROVED, COMPLETED, CANCELLED }

enum StockTransferStatus { PENDING, APPROVED, IN_TRANSIT, COMPLETED, REJECTED }

enum RequisitionStatus { PENDING, APPROVED, REJECTED, FULFILLED, CANCELLED }

enum RequestingDepartment { PHARMACY, STORE, PURCHASES, LAB, RADIOLOGY, OTHER }

class SearchPurchaseItemParams {
  const SearchPurchaseItemParams({
    this.itemName,
    this.manufacturerId,
    this.supplierId,
    this.manufacturingDateFrom,
    this.manufacturingDateTo,
    this.expiryDateFrom,
    this.expiryDateTo,
    this.minCostPrice,
    this.maxCostPrice,
    this.locationType,
    this.inStock,
    this.search,
    this.lowStock,
    this.expiringSoon,
    this.limit = 20,
    this.cursorId,
    this.cursorCreatedAt,
    this.sortBy,
    this.sortOrder = 'desc',
    this.page,
    this.pageSize,
  });

  final String? itemName;
  final String? manufacturerId;
  final String? supplierId;
  final DateTime? manufacturingDateFrom;
  final DateTime? manufacturingDateTo;
  final DateTime? expiryDateFrom;
  final DateTime? expiryDateTo;
  final double? minCostPrice;
  final double? maxCostPrice;
  final String? locationType;
  final bool? inStock;
  final String? search;
  final bool? lowStock;
  final bool? expiringSoon;
  final int limit;
  final String? cursorId;
  final DateTime? cursorCreatedAt;
  final String? sortBy;
  final String sortOrder;
  final int? page;
  final int? pageSize;

  Map<String, dynamic> toQuery() {
    final q = <String, dynamic>{};
    if (itemName != null && itemName!.isNotEmpty) q['itemName'] = itemName;
    if (manufacturerId != null && manufacturerId!.isNotEmpty) {
      q['manufacturerId'] = manufacturerId;
    }
    if (supplierId != null && supplierId!.isNotEmpty) {
      q['supplierId'] = supplierId;
    }
    if (manufacturingDateFrom != null) {
      q['manufacturingDateFrom'] = manufacturingDateFrom!.toIso8601String();
    }
    if (manufacturingDateTo != null) {
      q['manufacturingDateTo'] = manufacturingDateTo!.toIso8601String();
    }
    if (expiryDateFrom != null) {
      q['expiryDateFrom'] = expiryDateFrom!.toIso8601String();
    }
    if (expiryDateTo != null) {
      q['expiryDateTo'] = expiryDateTo!.toIso8601String();
    }
    if (minCostPrice != null) q['minCostPrice'] = minCostPrice;
    if (maxCostPrice != null) q['maxCostPrice'] = maxCostPrice;
    if (locationType != null && locationType!.isNotEmpty) {
      q['locationType'] = locationType;
    }
    if (inStock != null) q['inStock'] = inStock;
    if (search != null && search!.trim().isNotEmpty) {
      q['search'] = search!.trim();
    }
    if (lowStock != null) q['lowStock'] = lowStock;
    if (expiringSoon != null) q['expiringSoon'] = expiringSoon;
    q['limit'] = limit.toString();
    if (cursorId != null && cursorId!.isNotEmpty) q['cursorId'] = cursorId;
    if (cursorCreatedAt != null) {
      q['cursorCreatedAt'] = cursorCreatedAt!.toIso8601String();
    }
    if (sortBy != null && sortBy!.isNotEmpty) q['sortBy'] = sortBy;
    q['sortOrder'] = sortOrder;
    if (page != null) q['page'] = page;
    if (pageSize != null) q['pageSize'] = pageSize;
    return q;
  }
}

class TransferHistoryQuery {
  const TransferHistoryQuery({
    required this.fromDate,
    required this.toDate,
    this.itemId,
    this.status,
    this.skip = 0,
    this.take = 20,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final String? itemId;
  final String? status;
  final int skip;
  final int take;

  Map<String, dynamic> toQuery() => {
    'fromDate': fromDate.toUtc().toIso8601String(),
    'toDate': toDate.toUtc().toIso8601String(),
    if (itemId != null && itemId!.trim().isNotEmpty) 'itemId': itemId!.trim(),
    if (status != null && status!.trim().isNotEmpty) 'status': status!.trim(),
    'skip': skip,
    'take': take,
  };
}

class PaginatedResponse<T> {
  PaginatedResponse({
    required this.items,
    required this.total,
    this.page = 1,
    this.pageSize = 20,
  }) : totalPages = pageSize > 0 ? (total / pageSize).ceil() : 0;

  final List<T> items;
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  bool get hasNext => page < totalPages;
  bool get hasPrevious => page > 1;
}

class PurchasesManufacturer {
  final String? id;
  final String name;
  final String? country;
  final Map<String, dynamic>? contactInfo;

  PurchasesManufacturer({
    this.id,
    required this.name,
    this.country,
    this.contactInfo,
  });

  factory PurchasesManufacturer.fromJson(Map<String, dynamic> json) =>
      PurchasesManufacturer(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '',
        country: json['country']?.toString(),
        contactInfo: json['contactInfo'] is Map
            ? Map<String, dynamic>.from(json['contactInfo'] as Map)
            : null,
      );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    if (country != null) 'country': country,
    if (contactInfo != null) 'contactInfo': contactInfo,
  };
}

class PurchasesSupplier {
  final String? id;
  final String name;
  final String? licenseNumber;
  final Map<String, dynamic>? contactInfo;
  final String? creditTerms;
  final int? leadTimeDays;
  final int? rating;
  final bool isBlacklisted;

  PurchasesSupplier({
    this.id,
    required this.name,
    this.licenseNumber,
    this.contactInfo,
    this.creditTerms,
    this.leadTimeDays,
    this.rating,
    this.isBlacklisted = false,
  });

  factory PurchasesSupplier.fromJson(Map<String, dynamic> json) =>
      PurchasesSupplier(
        id: (json['id'] ?? json['_id'])?.toString(),
        name: json['name']?.toString() ?? '',
        licenseNumber: json['licenseNumber']?.toString(),
        contactInfo: json['contactInfo'] is Map
            ? Map<String, dynamic>.from(json['contactInfo'] as Map)
            : null,
        creditTerms: json['creditTerms']?.toString(),
        leadTimeDays: json['leadTimeDays'] is int
            ? json['leadTimeDays'] as int
            : int.tryParse(json['leadTimeDays']?.toString() ?? ''),
        rating: json['rating'] is int
            ? json['rating'] as int
            : int.tryParse(json['rating']?.toString() ?? ''),
        isBlacklisted: json['isBlacklisted'] == true,
      );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    if (licenseNumber != null) 'licenseNumber': licenseNumber,
    if (contactInfo != null) 'contactInfo': contactInfo,
    if (creditTerms != null) 'creditTerms': creditTerms,
    if (leadTimeDays != null) 'leadTimeDays': leadTimeDays,
    if (rating != null) 'rating': rating,
    'isBlacklisted': isBlacklisted,
  };
}

class PurchaseItem {
  final String? id;
  final String itemName;
  final String? sku;
  final String? category;
  final String? description;
  final String? manufacturerId;
  final String? unitOfMeasure;
  final int reorderLevel;
  final int reorderQuantity;
  final int? stock;
  final String? unit;
  final DateTime? expiryDate;
  final double? price;
  final String? manufacturerName;

  PurchaseItem({
    this.id,
    required this.itemName,
    this.sku,
    this.category,
    this.description,
    this.manufacturerId,
    this.unitOfMeasure,
    this.reorderLevel = 0,
    this.reorderQuantity = 0,
    this.stock,
    this.unit,
    this.expiryDate,
    this.price,
    this.manufacturerName,
  });

  int get displayStock => stock ?? 0;
  String get displayUnit => unit ?? unitOfMeasure ?? 'units';

  String get displayStatus {
    if (stock == null) return 'In Stock';
    if (stock! <= 0) return 'Out of Stock';
    if (reorderLevel > 0 && stock! <= reorderLevel) return 'Low Stock';
    if (expiryDate != null &&
        expiryDate!.difference(DateTime.now()).inDays <= 90) {
      return 'Expiring Soon';
    }
    return 'In Stock';
  }

  factory PurchaseItem.fromJson(Map<String, dynamic> json) => PurchaseItem(
    id: json['id']?.toString(),
    itemName: json['itemName']?.toString() ?? json['name']?.toString() ?? '',
    sku: json['sku']?.toString(),
    category: json['category']?.toString(),
    description: json['description']?.toString(),
    manufacturerId: json['manufacturerId']?.toString(),
    unitOfMeasure: json['unitOfMeasure']?.toString(),
    reorderLevel: _toInt(json['reorderLevel'], 0),
    reorderQuantity: _toInt(json['reorderQuantity'], 0),
    stock: () {
      if (json['stockRemaining'] != null) {
        return _toInt(json['stockRemaining'], 0);
      }
      if (json['quantity'] != null) {
        return _toInt(json['quantity'], 0);
      }
      return null;
    }(),
    unit: json['unit']?.toString(),
    expiryDate: json['expiryDate'] != null
        ? DateTime.tryParse(json['expiryDate'].toString())
        : null,
    price: _toDoubleOrNull(json['price']),
    manufacturerName: json['manufacturerName']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'itemName': itemName,
    if (sku != null) 'sku': sku,
    if (category != null) 'category': category,
    if (description != null) 'description': description,
    if (manufacturerId != null) 'manufacturerId': manufacturerId,
    if (unitOfMeasure != null) 'unitOfMeasure': unitOfMeasure,
    'reorderLevel': reorderLevel,
    'reorderQuantity': reorderQuantity,
    if (stock != null) 'quantity': stock,
    if (unit != null) 'unit': unit,
    if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
    if (price != null) 'price': price,
    if (manufacturerName != null) 'manufacturerName': manufacturerName,
  };
}

class PurchaseItemBatch {
  final String? id;
  final String itemId;
  final String? purchaseOrderId;
  final String? supplierId;
  final String? batchNumber;
  final DateTime? expiryDate;
  final DateTime? manufacturingDate;
  final int quantityReceived;
  final int? quantityRemaining;
  final double? sellingPrice;
  final String? fromLocationId;
  final String? toLocationId;
  final PurchasesLocation? fromLocation;
  final PurchasesLocation? toLocation;
  final String? grnId;
  final double? costPrice;
  final DateTime? createdAt;
  final PurchaseItem? item;
  final String? supplierName;

  PurchaseItemBatch({
    this.id,
    required this.itemId,
    this.manufacturingDate,
    this.purchaseOrderId,
    this.supplierId,
    this.batchNumber,
    this.expiryDate,
    this.quantityReceived = 0,
    this.quantityRemaining,
    this.sellingPrice,
    this.fromLocationId,
    this.toLocationId,
    this.fromLocation,
    this.toLocation,
    this.grnId,
    this.costPrice,
    this.createdAt,
    this.item,
    this.supplierName,
  });

  factory PurchaseItemBatch.fromJson(Map<String, dynamic> json) =>
      PurchaseItemBatch(
        id: json['id']?.toString(),
        itemId: json['itemId']?.toString() ?? '',
        purchaseOrderId: json['purchaseOrderId']?.toString(),
        supplierId: json['supplierId']?.toString(),
        batchNumber: json['batchNumber']?.toString(),
        manufacturingDate: json['manufacturingDate'] != null
            ? DateTime.tryParse(json['manufacturingDate'].toString())
            : null,
        expiryDate: json['expiryDate'] != null
            ? DateTime.tryParse(json['expiryDate'].toString())
            : null,
        quantityReceived: _toInt(json['quantityReceived'], 0),
        quantityRemaining: json['quantityRemaining'] != null
            ? _toInt(json['quantityRemaining'], 0)
            : null,
        sellingPrice: _toDoubleOrNull(json['sellingPrice']),
        fromLocationId: json['fromLocationId']?.toString(),
        toLocationId: json['toLocationId']?.toString(),
        fromLocation: json['fromLocation'] is Map
            ? PurchasesLocation.fromJson(
                Map<String, dynamic>.from(json['fromLocation'] as Map),
              )
            : null,
        toLocation: json['toLocation'] is Map
            ? PurchasesLocation.fromJson(
                Map<String, dynamic>.from(json['toLocation'] as Map),
              )
            : null,
        grnId: json['grnId']?.toString(),
        costPrice: _toDoubleOrNull(json['costPrice']),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        item: json['item'] is Map
            ? PurchaseItem.fromJson(
                Map<String, dynamic>.from(json['item'] as Map),
              )
            : null,
        supplierName: json['supplierName']?.toString(),
      );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'itemId': itemId,
    if (purchaseOrderId != null) 'purchaseOrderId': purchaseOrderId,
    if (supplierId != null) 'supplierId': supplierId,
    if (batchNumber != null) 'batchNumber': batchNumber,
    if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
    if (manufacturingDate != null)
      'manufacturingDate': manufacturingDate!.toIso8601String(),
    'quantityReceived': quantityReceived,
    if (quantityRemaining != null) 'quantityRemaining': quantityRemaining,
    if (sellingPrice != null) 'sellingPrice': sellingPrice,
    if (fromLocationId != null) 'fromLocationId': fromLocationId,
    if (toLocationId != null) 'toLocationId': toLocationId,
    if (grnId != null) 'grnId': grnId,
    if (costPrice != null) 'costPrice': costPrice,
    if (supplierName != null) 'supplierName': supplierName,
  };
}

class PurchaseOrder {
  final String? id;
  final String supplierId;
  final PurchaseOrderStatus status;
  final double totalAmount;
  final String createdById;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final PurchasesSupplier? supplier;

  PurchaseOrder({
    this.id,
    required this.supplierId,
    this.status = PurchaseOrderStatus.DRAFT,
    required this.totalAmount,
    required this.createdById,
    this.createdAt,
    this.updatedAt,
    this.supplier,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) => PurchaseOrder(
    id: json['id']?.toString(),
    supplierId: json['supplierId']?.toString() ?? '',
    status: _parsePurchaseOrderStatus(json['status']),
    totalAmount: _toDouble(json['totalAmount'], 0),
    createdById: json['createdById']?.toString() ?? '',
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'].toString())
        : null,
    supplier: json['supplier'] is Map
        ? PurchasesSupplier.fromJson(
            Map<String, dynamic>.from(json['supplier'] as Map),
          )
        : null,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'supplierId': supplierId,
    'status': status.name,
    'totalAmount': totalAmount,
    'createdById': createdById,
  };
}

class GoodsReceipt {
  final String? id;
  final String purchaseOrderId;
  final String receivedById;
  final DateTime? receivedAt;
  final String? notes;
  final DateTime? createdAt;

  GoodsReceipt({
    this.id,
    required this.purchaseOrderId,
    required this.receivedById,
    this.receivedAt,
    this.notes,
    this.createdAt,
  });

  factory GoodsReceipt.fromJson(Map<String, dynamic> json) => GoodsReceipt(
    id: json['id']?.toString(),
    purchaseOrderId: json['purchaseOrderId']?.toString() ?? '',
    receivedById: json['receivedById']?.toString() ?? '',
    receivedAt: json['receivedAt'] != null
        ? DateTime.tryParse(json['receivedAt'].toString())
        : null,
    notes: json['notes']?.toString(),
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'purchaseOrderId': purchaseOrderId,
    'receivedById': receivedById,
    if (receivedAt != null) 'receivedAt': receivedAt!.toIso8601String(),
    if (notes != null) 'notes': notes,
  };
}

class StockTransferItemDto {
  const StockTransferItemDto({required this.batchId, required this.quantity});

  final String batchId;
  final int quantity;

  Map<String, dynamic> toJson() => {'batchId': batchId, 'quantity': quantity};
}

class CreateStockTransferDto {
  const CreateStockTransferDto({
    required this.fromLocationId,
    required this.toLocationId,
    required this.items,
  });

  final String fromLocationId;
  final String toLocationId;
  final List<StockTransferItemDto> items;

  Map<String, dynamic> toJson() => {
    'fromLocationId': fromLocationId,
    'toLocationId': toLocationId,
    'items': items.map((e) => e.toJson()).toList(),
  };
}

class CorrectBatchQuantityDto {
  const CorrectBatchQuantityDto({
    required this.quantityReceived,
    required this.quantityRemaining,
  });

  final int quantityReceived;
  final int quantityRemaining;

  Map<String, dynamic> toJson() => {
    'quantityReceived': quantityReceived,
    'quantityRemaining': quantityRemaining,
  };
}

class PurchasesStockTransfer {
  final String? id;
  final String fromLocationId;
  final String toLocationId;
  final String itemId;
  final int quantity;
  final StockTransferStatus status;
  final String? requestedById;
  final String? requestedByName;
  final String? approvedById;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final PurchaseItem? item;
  final PurchasesLocation? fromLocation;
  final PurchasesLocation? toLocation;

  PurchasesStockTransfer({
    this.id,
    required this.fromLocationId,
    required this.toLocationId,
    required this.itemId,
    required this.quantity,
    this.status = StockTransferStatus.PENDING,
    this.requestedById,
    this.requestedByName,
    this.approvedById,
    this.createdAt,
    this.completedAt,
    this.item,
    this.fromLocation,
    this.toLocation,
  });

  factory PurchasesStockTransfer.fromJson(Map<String, dynamic> json) =>
      PurchasesStockTransfer(
        id: json['id']?.toString(),
        fromLocationId: json['fromLocationId']?.toString() ?? '',
        toLocationId: json['toLocationId']?.toString() ?? '',
        itemId: json['itemId']?.toString() ?? '',
        quantity: _toInt(json['quantity'], 0),
        status: _parseStockTransferStatus(json['status']),
        requestedById: json['requestedById']?.toString(),
        requestedByName: json['requestedByName']?.toString(),
        approvedById: json['approvedById']?.toString(),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'].toString())
            : null,
        item: json['item'] is Map
            ? PurchaseItem.fromJson(
                Map<String, dynamic>.from(json['item'] as Map),
              )
            : null,
        fromLocation: json['fromLocation'] is Map
            ? PurchasesLocation.fromJson(
                Map<String, dynamic>.from(json['fromLocation'] as Map),
              )
            : null,
        toLocation: json['toLocation'] is Map
            ? PurchasesLocation.fromJson(
                Map<String, dynamic>.from(json['toLocation'] as Map),
              )
            : null,
      );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'fromLocationId': fromLocationId,
    'toLocationId': toLocationId,
    'itemId': itemId,
    'quantity': quantity,
    'status': status.name,
    if (requestedById != null) 'requestedById': requestedById,
    if (approvedById != null) 'approvedById': approvedById,
  };
}

class PurchasesLocation {
  final String? id;
  final String name;
  final PurchasesLocationType type;
  final String? description;
  final String? staffId;
  final String? staffName;
  final bool isActive;
  final DateTime? createdAt;

  PurchasesLocation({
    this.id,
    required this.name,
    this.type = PurchasesLocationType.STORE,
    this.description,
    this.staffId,
    this.staffName,
    this.isActive = true,
    this.createdAt,
  });

  factory PurchasesLocation.fromJson(Map<String, dynamic> json) =>
      PurchasesLocation(
        id: (json['id'] ?? json['_id'])?.toString(),
        name: json['name']?.toString() ?? '',
        type: _parseLocationType(json['type'] ?? json['locationType']),
        description: json['description']?.toString(),
        staffId: json['staffId']?.toString(),
        staffName: json['staffName']?.toString(),
        isActive: json['isActive'] ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );

  Map<String, dynamic> toJson() => {
    if (id != null && id!.isNotEmpty) 'id': id,
    'name': name.trim(),
    'locationType': type.name,
    if (description != null && description!.trim().isNotEmpty)
      'description': description!.trim(),
    if (staffId != null && staffId!.trim().isNotEmpty) 'staffId': staffId,
    'isActive': isActive,
  };
}

class ItemLocationQuantity {
  final String locationName;
  final int quantity;

  const ItemLocationQuantity({
    required this.locationName,
    required this.quantity,
  });

  factory ItemLocationQuantity.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final nestedName = location is Map
        ? Map<String, dynamic>.from(location)['name']?.toString()
        : null;
    final directName = json['locationName']?.toString();
    final name = (directName?.trim().isNotEmpty == true
            ? directName!.trim()
            : (nestedName?.trim().isNotEmpty == true ? nestedName!.trim() : '—'))
        .toString();
    return ItemLocationQuantity(
      locationName: name,
      quantity: _toInt(json['quantity'], 0),
    );
  }
}

class RequisitionLine {
  final String? id;
  final String itemType;
  final String itemId;
  final String itemName;
  final int quantity;
  final String priority;
  final String? notes;

  RequisitionLine({
    this.id,
    required this.itemType,
    required this.itemId,
    required this.itemName,
    required this.quantity,
    this.priority = 'Normal',
    this.notes,
  });

  factory RequisitionLine.fromJson(Map<String, dynamic> json) => RequisitionLine(
    id: json['id']?.toString(),
    itemType: json['itemType']?.toString() ?? '',
    itemId: json['itemId']?.toString() ?? '',
    itemName: json['itemName']?.toString() ?? '',
    quantity: _toInt(json['quantity'], 0),
    priority: json['priority']?.toString() ?? 'Normal',
    notes: json['notes']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'itemType': itemType,
    'itemId': itemId,
    'itemName': itemName,
    'quantity': quantity,
    'priority': priority,
    if (notes != null) 'notes': notes,
  };
}

class Requisition {
  final String? id;
  final String requestingDepartment;
  final String? requestedById;
  final String? requestedByName;
  final RequisitionStatus status;
  final String? notes;
  final List<RequisitionLine> lines;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Requisition({
    this.id,
    required this.requestingDepartment,
    this.requestedById,
    this.requestedByName,
    this.status = RequisitionStatus.PENDING,
    this.notes,
    this.lines = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory Requisition.fromJson(Map<String, dynamic> json) => Requisition(
    id: json['id']?.toString(),
    requestingDepartment:
        json['requestingDepartment']?.toString() ?? 'OTHER',
    requestedById: json['requestedById']?.toString(),
    requestedByName: json['requestedByName']?.toString(),
    status: _parseRequisitionStatus(json['status']),
    notes: json['notes']?.toString(),
    lines: (json['lines'] as List?)
            ?.whereType<Map>()
            .map((e) => RequisitionLine.fromJson(Map<String, dynamic>.from(e)))
            .toList() ??
        const [],
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
    updatedAt: json['updatedAt'] != null
        ? DateTime.tryParse(json['updatedAt'].toString())
        : null,
  );
}

class CreateRequisitionDto {
  const CreateRequisitionDto({
    required this.requestingDepartment,
    required this.requestedById,
    required this.lines,
    this.notes,
  });

  final String requestingDepartment;
  final String requestedById;
  final List<RequisitionLine> lines;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'requestingDepartment': requestingDepartment,
    'requestedById': requestedById,
    if (notes != null) 'notes': notes,
    'lines': lines.map((e) => e.toJson()).toList(),
  };
}

PurchaseOrderStatus _parsePurchaseOrderStatus(dynamic value) {
  if (value == null) return PurchaseOrderStatus.DRAFT;
  final s = value.toString().toUpperCase();
  return PurchaseOrderStatus.values.firstWhere(
    (e) => e.name == s,
    orElse: () => PurchaseOrderStatus.DRAFT,
  );
}

StockTransferStatus _parseStockTransferStatus(dynamic value) {
  if (value == null) return StockTransferStatus.PENDING;
  final s = value.toString().toUpperCase();
  return StockTransferStatus.values.firstWhere(
    (e) => e.name == s,
    orElse: () => StockTransferStatus.PENDING,
  );
}

RequisitionStatus _parseRequisitionStatus(dynamic value) {
  if (value == null) return RequisitionStatus.PENDING;
  final s = value.toString().toUpperCase();
  return RequisitionStatus.values.firstWhere(
    (e) => e.name == s,
    orElse: () => RequisitionStatus.PENDING,
  );
}

PurchasesLocationType _parseLocationType(dynamic value) {
  if (value == null) return PurchasesLocationType.STORE;
  final s = value.toString().toUpperCase().replaceAll(' ', '_');
  return PurchasesLocationType.values.firstWhere(
    (e) => e.name == s,
    orElse: () => PurchasesLocationType.STORE,
  );
}

int _toInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value == null) return fallback;
  return int.tryParse(value.toString()) ?? fallback;
}

double _toDouble(dynamic value, double fallback) {
  if (value is num) return value.toDouble();
  if (value == null) return fallback;
  return double.tryParse(value.toString()) ?? fallback;
}

double? _toDoubleOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
