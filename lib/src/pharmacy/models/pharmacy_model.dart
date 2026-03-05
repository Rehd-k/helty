/// Enums inferred from Prisma schema
// ignore_for_file: constant_identifier_names

enum PharmacyLocationType { MAIN_STORE, DISPENSARY, WARD }

enum InventoryMovementType {
  PURCHASE,
  TRANSFER_OUT,
  TRANSFER_IN,
  DISPENSE,
  ADJUSTMENT,
  RETURN,
  EXPIRY_WRITEOFF,
}

enum MovementReferenceType { PURCHASE_ORDER, DISPENSATION, TRANSFER, MANUAL }

enum PurchaseOrderStatus { DRAFT, PENDING, APPROVED, COMPLETED, CANCELLED }

enum StockTransferStatus { PENDING, APPROVED, IN_TRANSIT, COMPLETED, REJECTED }

enum DispensationStatus { DRAFT, PENDING, DISPENSED, CANCELLED }

class InventoryMovement {
  final String? id;
  final String batchId;
  final String drugId;
  final String fromLocationId;
  final String toLocationId;
  final InventoryMovementType movementType;
  final int quantity;
  final MovementReferenceType referenceType;
  final String referenceId;

  InventoryMovement({
    this.id,
    required this.batchId,
    required this.drugId,
    required this.fromLocationId,
    required this.toLocationId,
    required this.movementType,
    required this.quantity,
    required this.referenceType,
    required this.referenceId,
  });

  factory InventoryMovement.fromJson(Map<String, dynamic> json) =>
      InventoryMovement(
        id: json['id'],
        batchId: json['batchId'],
        drugId: json['drugId'],
        fromLocationId: json['fromLocationId'],
        toLocationId: json['toLocationId'],
        movementType: InventoryMovementType.values.firstWhere(
          (e) => e.name == json['movementType'],
        ),
        quantity: json['quantity'],
        referenceType: MovementReferenceType.values.firstWhere(
          (e) => e.name == json['referenceType'],
        ),
        referenceId: json['referenceId'],
      );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'batchId': batchId,
    'drugId': drugId,
    'fromLocationId': fromLocationId,
    'toLocationId': toLocationId,
    'movementType': movementType.name,
    'quantity': quantity,
    'referenceType': referenceType.name,
    'referenceId': referenceId,
  };
}

class Manufacturer {
  final String? id;
  final String name;
  final String? country;
  final Map<String, dynamic>? contactInfo;

  Manufacturer({this.id, required this.name, this.country, this.contactInfo});

  factory Manufacturer.fromJson(Map<String, dynamic> json) => Manufacturer(
    id: json['id'],
    name: json['name'],
    country: json['country'],
    contactInfo: json['contactInfo'],
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'country': country,
    'contactInfo': contactInfo,
  };
}

class Supplier {
  final String? id;
  final String name;
  final String? licenseNumber;
  final Map<String, dynamic>? contactInfo;
  final String? creditTerms;
  final int? leadTimeDays;
  final int? rating;
  final bool isBlacklisted;

  Supplier({
    this.id,
    required this.name,
    this.licenseNumber,
    this.contactInfo,
    this.creditTerms,
    this.leadTimeDays,
    this.rating,
    this.isBlacklisted = false,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) => Supplier(
    id: json['id']?.toString(),
    name: json['name']?.toString() ?? '',
    licenseNumber: json['licenseNumber'],
    contactInfo: json['contactInfo'],
    creditTerms: json['creditTerms'],
    leadTimeDays: json['leadTimeDays'],
    rating: json['rating'],
    isBlacklisted: json['isBlacklisted'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'licenseNumber': licenseNumber,
    'contactInfo': contactInfo,
    'creditTerms': creditTerms,
    'leadTimeDays': leadTimeDays,
    'rating': rating,
    'isBlacklisted': isBlacklisted,
  };
}

class Drug {
  final String? id;
  final String genericName;
  final String brandName;
  final String? strength;
  final String? dosageForm;
  final String? route;
  final String? therapeuticClass;
  final String? atcCode;
  final String? manufacturerId;
  final bool isControlled;
  final bool isRefrigerated;
  final bool isHighAlert;
  final double? maxDailyDose;
  final int reorderLevel;
  final int reorderQuantity;

  /// Optional inventory fields (when API returns stock/expiry data).
  final int? stock;
  final String? unit;
  final DateTime? expiryDate;
  final double? price;
  final String? manufacturerName;

  Drug({
    this.id,
    required this.genericName,
    required this.brandName,
    this.strength,
    this.dosageForm,
    this.route,
    this.therapeuticClass,
    this.atcCode,
    this.manufacturerId,
    this.isControlled = false,
    this.isRefrigerated = false,
    this.isHighAlert = false,
    this.maxDailyDose,
    this.reorderLevel = 0,
    this.reorderQuantity = 0,
    this.stock,
    this.unit,
    this.expiryDate,
    this.price,
    this.manufacturerName,
  });

  /// Display stock count (from inventory or reorder quantity as fallback).
  int get displayStock => stock ?? reorderQuantity;

  /// Display unit for stock (e.g. "units", "tablets").
  String get displayUnit => unit ?? 'units';

  /// Status derived from stock vs reorder level when stock is available.
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

  factory Drug.fromJson(Map<String, dynamic> json) => Drug(
    id: json['id']?.toString(),
    genericName: json['genericName']?.toString() ?? '',
    brandName: json['brandName']?.toString() ?? '',
    strength: json['strength']?.toString(),
    dosageForm: json['dosageForm']?.toString(),
    route: json['route']?.toString(),
    therapeuticClass: json['therapeuticClass']?.toString(),
    atcCode: json['atcCode']?.toString(),
    manufacturerId: json['manufacturerId']?.toString(),
    isControlled: json['isControlled'] ?? false,
    isRefrigerated: json['isRefrigerated'] ?? false,
    isHighAlert: json['isHighAlert'] ?? false,
    maxDailyDose: json['maxDailyDose'] != null
        ? double.tryParse(json['maxDailyDose'].toString())
        : null,
    reorderLevel: (json['reorderLevel'] is int)
        ? json['reorderLevel'] as int
        : int.tryParse(json['reorderLevel']?.toString() ?? '') ?? 0,
    reorderQuantity: (json['reorderQuantity'] is int)
        ? json['reorderQuantity'] as int
        : int.tryParse(json['reorderQuantity']?.toString() ?? '') ?? 0,
    stock: (json['stock'] is int)
        ? json['stock'] as int
        : int.tryParse(json['stock']?.toString() ?? ''),
    unit: json['unit']?.toString(),
    expiryDate: json['expiryDate'] != null
        ? DateTime.tryParse(json['expiryDate'].toString())
        : null,
    price: json['price'] != null ? (json['price'] as num).toDouble() : null,
    manufacturerName: json['manufacturerName']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'genericName': genericName,
    'brandName': brandName,
    'strength': strength,
    'dosageForm': dosageForm,
    'route': route,
    'therapeuticClass': therapeuticClass,
    'atcCode': atcCode,
    'manufacturerId': manufacturerId,
    'isControlled': isControlled,
    'isRefrigerated': isRefrigerated,
    'isHighAlert': isHighAlert,
    'maxDailyDose': maxDailyDose,
    'reorderLevel': reorderLevel,
    'reorderQuantity': reorderQuantity,
    if (stock != null) 'stock': stock,
    if (unit != null) 'unit': unit,
    if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
    if (price != null) 'price': price,
    if (manufacturerName != null) 'manufacturerName': manufacturerName,
  };
}

class Consumable {
  final String? id;
  final String name;
  final String? category;
  final int? reorderLevel;
  final bool isBillable;

  Consumable({
    this.id,
    required this.name,
    this.category,
    this.reorderLevel,
    this.isBillable = true,
  });

  factory Consumable.fromJson(Map<String, dynamic> json) => Consumable(
    id: json['id'],
    name: json['name'],
    category: json['category'],
    reorderLevel: json['reorderLevel'],
    isBillable: json['isBillable'] ?? true,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'category': category,
    'reorderLevel': reorderLevel,
    'isBillable': isBillable,
  };
}

/// Generic paginated API response. Backend may return { data: [], total, page, pageSize } or similar.
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

class PurchaseOrder {
  final String? id;
  final String supplierId;
  final PurchaseOrderStatus status;
  final double totalAmount;
  final String createdById;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Supplier? supplier;

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
    supplier: json['supplier'] != null && json['supplier'] is Map
        ? Supplier.fromJson(Map<String, dynamic>.from(json['supplier'] as Map))
        : null,
  );

  static PurchaseOrderStatus _parsePurchaseOrderStatus(dynamic value) {
    if (value == null) return PurchaseOrderStatus.DRAFT;
    final s = value.toString().toUpperCase();
    return PurchaseOrderStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => PurchaseOrderStatus.DRAFT,
    );
  }

  static double _toDouble(dynamic v, double def) {
    if (v == null) return def;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? def;
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'supplierId': supplierId,
    'status': status.name,
    'totalAmount': totalAmount,
    'createdById': createdById,
  };
}

/// Line item or batch on a purchase order / goods receipt.
class DrugBatch {
  final String? id;
  final String drugId;
  final String? purchaseOrderId;
  final String? batchNumber;
  final DateTime? expiryDate;
  final int quantityReceived;
  final double? unitCost;
  final DateTime? createdAt;
  final Drug? drug;

  DrugBatch({
    this.id,
    required this.drugId,
    this.purchaseOrderId,
    this.batchNumber,
    this.expiryDate,
    this.quantityReceived = 0,
    this.unitCost,
    this.createdAt,
    this.drug,
  });

  factory DrugBatch.fromJson(Map<String, dynamic> json) => DrugBatch(
    id: json['id']?.toString(),
    drugId: json['drugId']?.toString() ?? '',
    purchaseOrderId: json['purchaseOrderId']?.toString(),
    batchNumber: json['batchNumber']?.toString(),
    expiryDate: json['expiryDate'] != null
        ? DateTime.tryParse(json['expiryDate'].toString())
        : null,
    quantityReceived: (json['quantityReceived'] is int)
        ? json['quantityReceived'] as int
        : int.tryParse(json['quantityReceived'].toString()) ?? 0,
    unitCost: json['unitCost'] != null
        ? (json['unitCost'] as num).toDouble()
        : null,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
    drug: json['drug'] != null && json['drug'] is Map
        ? Drug.fromJson(Map<String, dynamic>.from(json['drug'] as Map))
        : null,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'drugId': drugId,
    if (purchaseOrderId != null) 'purchaseOrderId': purchaseOrderId,
    if (batchNumber != null) 'batchNumber': batchNumber,
    if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
    'quantityReceived': quantityReceived,
    if (unitCost != null) 'unitCost': unitCost,
  };
}

/// Goods receipt (incoming stock) linked to a purchase order.
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

/// Stock transfer between locations.
class StockTransfer {
  final String? id;
  final String fromLocationId;
  final String toLocationId;
  final String drugId;
  final int quantity;
  final StockTransferStatus status;
  final String? requestedById;
  final String? approvedById;
  final DateTime? createdAt;
  final DateTime? completedAt;

  StockTransfer({
    this.id,
    required this.fromLocationId,
    required this.toLocationId,
    required this.drugId,
    required this.quantity,
    this.status = StockTransferStatus.PENDING,
    this.requestedById,
    this.approvedById,
    this.createdAt,
    this.completedAt,
  });

  factory StockTransfer.fromJson(Map<String, dynamic> json) => StockTransfer(
    id: json['id']?.toString(),
    fromLocationId: json['fromLocationId']?.toString() ?? '',
    toLocationId: json['toLocationId']?.toString() ?? '',
    drugId: json['drugId']?.toString() ?? '',
    quantity: (json['quantity'] is int)
        ? json['quantity'] as int
        : int.tryParse(json['quantity'].toString()) ?? 0,
    status: _parseStockTransferStatus(json['status']),
    requestedById: json['requestedById']?.toString(),
    approvedById: json['approvedById']?.toString(),
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
    completedAt: json['completedAt'] != null
        ? DateTime.tryParse(json['completedAt'].toString())
        : null,
  );

  static StockTransferStatus _parseStockTransferStatus(dynamic value) {
    if (value == null) return StockTransferStatus.PENDING;
    final s = value.toString().toUpperCase();
    return StockTransferStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => StockTransferStatus.PENDING,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'fromLocationId': fromLocationId,
    'toLocationId': toLocationId,
    'drugId': drugId,
    'quantity': quantity,
    'status': status.name,
    if (requestedById != null) 'requestedById': requestedById,
    if (approvedById != null) 'approvedById': approvedById,
  };
}

/// Dispensation (patient dispensing record).
class Dispensation {
  final String? id;
  final String encounterId;
  final String drugId;
  final int quantity;
  final String? instructions;
  final DispensationStatus status;
  final String? dispensedById;
  final DateTime? dispensedAt;
  final DateTime? createdAt;

  Dispensation({
    this.id,
    required this.encounterId,
    required this.drugId,
    required this.quantity,
    this.instructions,
    this.status = DispensationStatus.DRAFT,
    this.dispensedById,
    this.dispensedAt,
    this.createdAt,
  });

  factory Dispensation.fromJson(Map<String, dynamic> json) => Dispensation(
    id: json['id']?.toString(),
    encounterId: json['encounterId']?.toString() ?? '',
    drugId: json['drugId']?.toString() ?? '',
    quantity: (json['quantity'] is int)
        ? json['quantity'] as int
        : int.tryParse(json['quantity'].toString()) ?? 0,
    instructions: json['instructions']?.toString(),
    status: _parseDispensationStatus(json['status']),
    dispensedById: json['dispensedById']?.toString(),
    dispensedAt: json['dispensedAt'] != null
        ? DateTime.tryParse(json['dispensedAt'].toString())
        : null,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
  );

  static DispensationStatus _parseDispensationStatus(dynamic value) {
    if (value == null) return DispensationStatus.DRAFT;
    final s = value.toString().toUpperCase();
    return DispensationStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => DispensationStatus.DRAFT,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'encounterId': encounterId,
    'drugId': drugId,
    'quantity': quantity,
    if (instructions != null) 'instructions': instructions,
    'status': status.name,
    if (dispensedById != null) 'dispensedById': dispensedById,
    if (dispensedAt != null) 'dispensedAt': dispensedAt!.toIso8601String(),
  };
}

/// Pharmacy location (main store, dispensary, ward).
class PharmacyLocation {
  final String? id;
  final String name;
  final PharmacyLocationType type;
  final bool isActive;
  final DateTime? createdAt;

  PharmacyLocation({
    this.id,
    required this.name,
    this.type = PharmacyLocationType.MAIN_STORE,
    this.isActive = true,
    this.createdAt,
  });

  factory PharmacyLocation.fromJson(Map<String, dynamic> json) =>
      PharmacyLocation(
        id: json['id']?.toString(),
        name: json['name']?.toString() ?? '',
        type: _parseLocationType(json['type']),
        isActive: json['isActive'] ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );

  static PharmacyLocationType _parseLocationType(dynamic value) {
    if (value == null) return PharmacyLocationType.MAIN_STORE;
    final s = value.toString().toUpperCase();
    return PharmacyLocationType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => PharmacyLocationType.MAIN_STORE,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'type': type.name,
    'isActive': isActive,
  };
}
