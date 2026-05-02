// ignore_for_file: constant_identifier_names

enum PharmacyLocationType { STORE, DISPENSARY, WARD, COLD_ROOM }

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

/// Query parameters for GET /pharmacy/drugs search (SearchDrugDto).
class SearchDrugParams {
  const SearchDrugParams({
    this.genericName,
    this.brandName,
    this.manufacturerId,
    this.supplierId,
    this.manufacturingDateFrom,
    this.manufacturingDateTo,
    this.expiryDateFrom,
    this.expiryDateTo,
    this.minCostPrice,
    this.maxCostPrice,
    this.minSellingPrice,
    this.maxSellingPrice,
    this.locationType,
    this.inStock,
    this.isControlled,
    this.search,
    this.therapeuticClass,
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

  final String? genericName;
  final String? brandName;
  final String? manufacturerId;
  final String? supplierId;
  final DateTime? manufacturingDateFrom;
  final DateTime? manufacturingDateTo;
  final DateTime? expiryDateFrom;
  final DateTime? expiryDateTo;
  final double? minCostPrice;
  final double? maxCostPrice;
  final double? minSellingPrice;
  final double? maxSellingPrice;
  final String? locationType; // e.g. MAIN_STORE, DISPENSARY, WARD
  final bool? inStock;
  final bool? isControlled;
  final String? search;
  final String? therapeuticClass; // e.g. Antibiotic, Analgesic
  final bool? lowStock;
  final bool? expiringSoon;
  final int limit;
  final String? cursorId;
  final DateTime? cursorCreatedAt;
  final String? sortBy;
  final String sortOrder; // 'asc' | 'desc'
  /// Optional page-based pagination (if API supports page/pageSize).
  final int? page;
  final int? pageSize;

  SearchDrugParams copyWith({
    String? genericName,
    String? brandName,
    String? manufacturerId,
    String? supplierId,
    DateTime? manufacturingDateFrom,
    DateTime? manufacturingDateTo,
    DateTime? expiryDateFrom,
    DateTime? expiryDateTo,
    double? minCostPrice,
    double? maxCostPrice,
    double? minSellingPrice,
    double? maxSellingPrice,
    String? locationType,
    bool? inStock,
    bool? isControlled,
    String? search,
    String? therapeuticClass,
    bool? lowStock,
    bool? expiringSoon,
    int? limit,
    String? cursorId,
    DateTime? cursorCreatedAt,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? pageSize,
  }) => SearchDrugParams(
    genericName: genericName ?? this.genericName,
    brandName: brandName ?? this.brandName,
    manufacturerId: manufacturerId ?? this.manufacturerId,
    supplierId: supplierId ?? this.supplierId,
    manufacturingDateFrom: manufacturingDateFrom ?? this.manufacturingDateFrom,
    manufacturingDateTo: manufacturingDateTo ?? this.manufacturingDateTo,
    expiryDateFrom: expiryDateFrom ?? this.expiryDateFrom,
    expiryDateTo: expiryDateTo ?? this.expiryDateTo,
    minCostPrice: minCostPrice ?? this.minCostPrice,
    maxCostPrice: maxCostPrice ?? this.maxCostPrice,
    minSellingPrice: minSellingPrice ?? this.minSellingPrice,
    maxSellingPrice: maxSellingPrice ?? this.maxSellingPrice,
    locationType: locationType ?? this.locationType,
    inStock: inStock ?? this.inStock,
    isControlled: isControlled ?? this.isControlled,
    search: search ?? this.search,
    therapeuticClass: therapeuticClass ?? this.therapeuticClass,
    lowStock: lowStock ?? this.lowStock,
    expiringSoon: expiringSoon ?? this.expiringSoon,
    limit: limit ?? this.limit,
    cursorId: cursorId ?? this.cursorId,
    cursorCreatedAt: cursorCreatedAt ?? this.cursorCreatedAt,
    sortBy: sortBy ?? this.sortBy,
    sortOrder: sortOrder ?? this.sortOrder,
    page: page ?? this.page,
    pageSize: pageSize ?? this.pageSize,
  );

  Map<String, dynamic> toQuery() {
    final q = <String, dynamic>{};
    if (genericName != null && genericName!.isNotEmpty) {
      q['genericName'] = genericName;
    }
    if (brandName != null && brandName!.isNotEmpty) q['brandName'] = brandName;
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
    if (minSellingPrice != null) q['minSellingPrice'] = minSellingPrice;
    if (maxSellingPrice != null) q['maxSellingPrice'] = maxSellingPrice;
    if (locationType != null && locationType!.isNotEmpty) {
      q['locationType'] = locationType;
    }
    if (inStock != null) q['inStock'] = inStock;
    if (isControlled != null) q['isControlled'] = isControlled;
    if (search != null && search!.trim().isNotEmpty) {
      q['search'] = search!.trim();
    }
    if (therapeuticClass != null && therapeuticClass!.isNotEmpty) {
      q['therapeuticClass'] = therapeuticClass;
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

class DispenseHistoryQuery {
  const DispenseHistoryQuery({
    required this.fromDate,
    required this.toDate,
    this.drugId,
    this.patientQuery,
    this.skip = 0,
    this.take = 20,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final String? drugId;
  final String? patientQuery;
  final int skip;
  final int take;

  Map<String, dynamic> toQuery() => {
    'fromDate': fromDate.toUtc().toIso8601String(),
    'toDate': toDate.toUtc().toIso8601String(),
    if (drugId != null && drugId!.trim().isNotEmpty) 'drugId': drugId!.trim(),
    if (patientQuery != null && patientQuery!.trim().isNotEmpty)
      'patientQuery': patientQuery!.trim(),
    'skip': skip,
    'take': take,
  };
}

class DispenseHistoryPatient {
  const DispenseHistoryPatient({
    required this.id,
    required this.patientId,
    required this.name,
  });

  final String id;
  final String patientId;
  final String name;

  factory DispenseHistoryPatient.fromJson(Map<String, dynamic> json) =>
      DispenseHistoryPatient(
        id: json['id']?.toString() ?? '',
        patientId: json['patientId']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown patient',
      );
}

class DispenseHistoryDrug {
  const DispenseHistoryDrug({required this.id, required this.name});

  final String id;
  final String name;

  factory DispenseHistoryDrug.fromJson(Map<String, dynamic> json) =>
      DispenseHistoryDrug(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown drug',
      );
}

class DispenseHistoryItem {
  const DispenseHistoryItem({
    required this.invoiceItemId,
    required this.invoiceUUID,
    required this.invoiceId,
    required this.dispensedAt,
    required this.encounterId,
    required this.quantity,
    required this.unitPrice,
    required this.amountPaid,
    required this.drug,
    required this.patient,
  });

  final String invoiceUUID;
  final String invoiceItemId;
  final String invoiceId;
  final DateTime? dispensedAt;
  final String encounterId;
  final int quantity;
  final double unitPrice;
  final double amountPaid;
  final DispenseHistoryDrug drug;
  final DispenseHistoryPatient patient;

  factory DispenseHistoryItem.fromJson(Map<String, dynamic> json) =>
      DispenseHistoryItem(
        invoiceItemId: json['invoiceItemId']?.toString() ?? '',
        invoiceId: json['invoiceId']?.toString() ?? '',
        invoiceUUID: json['invoiceUUID']?.toString() ?? '',
        dispensedAt: json['dispensedAt'] == null
            ? null
            : DateTime.tryParse(json['dispensedAt'].toString()),
        encounterId: json['encounterId']?.toString() ?? '',
        quantity: () {
          final v = json['quantity'];
          if (v is int) return v;
          if (v is num) return v.toInt();
          return int.tryParse(v?.toString() ?? '') ?? 0;
        }(),
        unitPrice: () {
          final v = json['unitPrice'];
          if (v is num) return v.toDouble();
          return double.tryParse(v?.toString() ?? '') ?? 0;
        }(),
        amountPaid: () {
          final v = json['amountPaid'];
          if (v is num) return v.toDouble();
          return double.tryParse(v?.toString() ?? '') ?? 0;
        }(),
        drug: DispenseHistoryDrug.fromJson(
          Map<String, dynamic>.from((json['drug'] as Map?) ?? const {}),
        ),
        patient: DispenseHistoryPatient.fromJson(
          Map<String, dynamic>.from((json['patient'] as Map?) ?? const {}),
        ),
      );
}

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
    id: (json['id'] ?? json['_id'])?.toString(),
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
  final List<DrugPrice>? prices;

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
    this.prices,
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
    stock: (json['quantity'] is int)
        ? json['quantity'] as int
        : int.tryParse(json['quantity']?.toString() ?? ''),
    prices: (json['drugPrices'] as List?)
        ?.whereType<Map<String, dynamic>>()
        .map(DrugPrice.fromJson)
        .toList(),
    unit: json['unit']?.toString(),
    expiryDate: json['expiryDate'] != null
        ? DateTime.tryParse(json['expiryDate'].toString())
        : null,
    price: () {
      final v = json['price'];
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }(),
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
    if (prices != null && prices!.isNotEmpty)
      'prices': prices!.map((p) => p.toJson()).toList(),
    if (stock != null) 'stock': stock,
    if (stock != null) 'quantity': stock,
    if (unit != null) 'unit': unit,
    if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
    if (price != null) 'price': price,
    if (manufacturerName != null) 'manufacturerName': manufacturerName,
  };
}

class DrugPrice {
  final String? id;
  final String wardId;
  final String? wardName;
  final double price;

  DrugPrice({
    this.id,
    required this.wardId,
    this.wardName,
    required this.price,
  });

  factory DrugPrice.fromJson(Map<String, dynamic> json) => DrugPrice(
    id: json['id']?.toString(),
    wardId: json['wardId']?.toString() ?? '',
    wardName: json['ward'] is Map
        ? (json['ward'] as Map)['name']?.toString()
        : json['wardName']?.toString(),
    price: () {
      final raw =
          json['price'] ??
          json['computedPrice'] ??
          json['sellingPrice'] ??
          json['amount'];
      if (raw is num) return raw.toDouble();
      return double.tryParse(raw?.toString() ?? '0') ?? 0;
    }(),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'wardId': wardId,
    if (wardName != null) 'wardName': wardName,
    'price': price,
  };
}

/// Quantity of a specific drug at a specific pharmacy location.
class DrugLocationQuantity {
  final String locationName;
  final int quantity;

  const DrugLocationQuantity({
    required this.locationName,
    required this.quantity,
  });

  factory DrugLocationQuantity.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    final nestedName = location is Map
        ? Map<String, dynamic>.from(location)['name']?.toString()
        : null;
    final directName = json['locationName']?.toString();
    final name =
        (directName?.trim().isNotEmpty == true
                ? directName!.trim()
                : (nestedName?.trim().isNotEmpty == true
                      ? nestedName!.trim()
                      : '—'))
            .toString();

    final rawQty = json['quantity'];
    final qty = rawQty is int
        ? rawQty
        : int.tryParse(rawQty?.toString() ?? '') ?? 0;

    return DrugLocationQuantity(locationName: name, quantity: qty);
  }

  Map<String, dynamic> toJson() => {
    'locationName': locationName,
    'quantity': quantity,
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
  final String? supplierId;
  final String? batchNumber;
  final DateTime? expiryDate;
  final DateTime? manufacturingDate;
  final int quantityReceived;

  /// Remaining (available) quantity for this batch, when backend provides it.
  /// If null, consumers should fall back to [quantityReceived].
  final int? quantityRemaining;
  final double? sellingPrice;
  final String? fromLocationId;
  final String? toLocationId;
  final PharmacyLocation? fromLocation;
  final PharmacyLocation? toLocation;
  final String? grnId;
  final double? costPrice;
  final DateTime? createdAt;
  final Drug? drug;
  final String? supplierName;

  DrugBatch({
    this.id,
    required this.drugId,
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
    this.drug,
    this.supplierName,
  });

  factory DrugBatch.fromJson(Map<String, dynamic> json) => DrugBatch(
    id: json['id']?.toString(),
    drugId: json['drugId']?.toString() ?? '',
    purchaseOrderId: json['purchaseOrderId']?.toString(),
    supplierId: () {
      final id = json['supplierId']?.toString();
      if (id != null && id.isNotEmpty) return id;
      final supplier = json['supplier'];
      if (supplier is Map) {
        final map = Map<String, dynamic>.from(supplier);
        final nestedId = map['id']?.toString();
        if (nestedId != null && nestedId.isNotEmpty) return nestedId;
      }
      return null;
    }(),
    batchNumber: json['batchNumber']?.toString(),
    manufacturingDate: json['manufacturingDate'] != null
        ? DateTime.tryParse(json['manufacturingDate'].toString())
        : null,
    expiryDate: json['expiryDate'] != null
        ? DateTime.tryParse(json['expiryDate'].toString())
        : null,
    quantityReceived: () {
      final v = json['quantityReceived'];
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }(),
    quantityRemaining: () {
      final v = json['quantityRemaining'];
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }(),
    sellingPrice: () {
      final v = json['sellingPrice'];
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }(),
    fromLocationId: json['fromLocationId']?.toString(),
    toLocationId: json['toLocationId']?.toString(),
    fromLocation: json['fromLocation'] != null && json['fromLocation'] is Map
        ? PharmacyLocation.fromJson(
            Map<String, dynamic>.from(json['fromLocation'] as Map),
          )
        : null,
    toLocation: json['toLocation'] != null && json['toLocation'] is Map
        ? PharmacyLocation.fromJson(
            Map<String, dynamic>.from(json['toLocation'] as Map),
          )
        : null,
    grnId: json['grnId']?.toString(),
    costPrice: () {
      final v = json['costPrice'];
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }(),
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'].toString())
        : null,
    drug: json['drug'] != null && json['drug'] is Map
        ? Drug.fromJson(Map<String, dynamic>.from(json['drug'] as Map))
        : null,
    supplierName: () {
      final supplier = json['supplier'];
      if (supplier is Map) {
        final map = Map<String, dynamic>.from(supplier);
        return map['name']?.toString();
      }
      return json['supplierName']?.toString();
    }(),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'drugId': drugId,
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

/// Single line in POST /stock-transfers body (CreateStockTransferDto.items).
class StockTransferItemDto {
  const StockTransferItemDto({required this.batchId, required this.quantity});

  final String batchId;
  final int quantity;

  Map<String, dynamic> toJson() => {'batchId': batchId, 'quantity': quantity};
}

/// Request body for creating a stock transfer with multiple batch lines.
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

/// Body for PATCH /pharmacy/batches/:id/quantity-correction (pharmacy head; batch age rules on server).
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

/// Pharmacy location (main store, dispensary, ward, cold room).
class PharmacyLocation {
  final String? id;
  final String name;
  final PharmacyLocationType type;
  final String? description;
  final String? staffId;
  final String? staffName; // Optional display name when API returns staff
  final bool isActive;
  final DateTime? createdAt;

  PharmacyLocation({
    this.id,
    required this.name,
    this.type = PharmacyLocationType.STORE,
    this.description,
    this.staffId,
    this.staffName,
    this.isActive = true,
    this.createdAt,
  });

  factory PharmacyLocation.fromJson(Map<String, dynamic> json) =>
      PharmacyLocation(
        id: (json['id'] ?? json['_id'])?.toString(),
        name: json['name']?.toString() ?? '',
        type: _parseLocationType(json['type'] ?? json['locationType']),
        description: json['description']?.toString(),
        staffId: json['staffId']?.toString(),
        staffName: () {
          final staff = json['staff'];
          if (staff is Map) {
            final m = Map<String, dynamic>.from(staff);
            return m['name']?.toString();
          }
          return json['staffName']?.toString();
        }(),
        isActive: json['isActive'] ?? true,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'].toString())
            : null,
      );

  static PharmacyLocationType _parseLocationType(dynamic value) {
    if (value == null) return PharmacyLocationType.STORE;
    final s = value.toString().toUpperCase().replaceAll(' ', '_');
    return PharmacyLocationType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => PharmacyLocationType.STORE,
    );
  }

  /// Payload for create/update: name, locationType, description?, staffId?
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
