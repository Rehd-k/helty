import 'package:helty/src/core/utils/api_decimal.dart';

/// HMO tariff row embedded on a service from `GET /services?hmoId=...`.
class ServiceHmoPrice {
  const ServiceHmoPrice({
    required this.hmoId,
    required this.cost,
    this.hmoName,
    this.hmoCode,
  });

  final String hmoId;
  final double cost;
  final String? hmoName;
  final String? hmoCode;

  factory ServiceHmoPrice.fromJson(Map<String, dynamic> json) {
    final parsedCost = parseApiDecimal(json['cost']);
    return ServiceHmoPrice(
      hmoId: '${json['hmoId'] ?? ''}',
      cost: parsedCost,
      hmoName: json['hmoName']?.toString(),
      hmoCode: json['hmoCode']?.toString(),
    );
  }
}

class ServiceModel {
  ServiceModel({
    required this.id,
    required this.name,
    required this.serviceId,
    this.description,
    required this.cost,
    this.categoryId,
    this.serviceCode,
    this.categoryName,
    this.departmentId,
    this.departmentName,
    this.qty,
    this.isRecurringDaily = false,
    this.createdAtIso,
    this.createdByName,
    this.settled = false,
    this.amountPaid = 0.0,
    this.transactionItemId,
    this.drugId,
    this.invoiceId,
    this.hmoPrices = const [],
  });

  final String id;
  final String name;
  final String? description;
  final double cost;
  final String? categoryId;
  final String? categoryName;
  final String? departmentId;
  final String? departmentName;
  final String serviceId;
  final String? serviceCode;
  int? qty;
  final bool isRecurringDaily;
  final String? createdAtIso;
  final String? createdByName;
  final bool settled;
  final double amountPaid;
  final String? transactionItemId;
  final String? drugId;
  final String? invoiceId;
  final List<ServiceHmoPrice> hmoPrices;

  /// Standard catalog price, or the HMO tariff when [hmoId] matches a row.
  double costForHmo(String? hmoId) {
    final hid = hmoId?.trim() ?? '';
    if (hid.isEmpty) return cost;
    for (final row in hmoPrices) {
      if (row.hmoId.trim() == hid) return row.cost;
    }
    return cost;
  }

  /// helper for debug output
  @override
  String toString() => name;

  /// Parses from either a full service object or an API InvoiceItem
  /// (with quantity, priceAtTime, and nested service).
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // 1. Extract sub-objects
    final service = json['service'] as Map<String, dynamic>?;
    final drug = json['drug'] as Map<String, dynamic>?;
    final consumableRaw = json['consumable'];
    final consumable = consumableRaw is Map<String, dynamic>
        ? consumableRaw
        : (consumableRaw is Map
              ? Map<String, dynamic>.from(consumableRaw)
              : null);
    final purchaseItemRaw = json['purchaseItem'];
    final purchaseItem = purchaseItemRaw is Map<String, dynamic>
        ? purchaseItemRaw
        : (purchaseItemRaw is Map
              ? Map<String, dynamic>.from(purchaseItemRaw)
              : null);

    // 2. Identify IDs (Priority: Direct field > Drug > Service > Purchase item)
    final drugId = json['drugId']?.toString() ?? drug?['id']?.toString();
    final purchaseItemId =
        json['purchaseItemId']?.toString() ?? purchaseItem?['id']?.toString();

    // serviceId is the "template" ID.
    // We check root serviceId, then service object, then drug object, then purchase item, then fallback to root id.
    String sid =
        (json['serviceId'] ?? service?['id'] ?? drug?['id'] ?? purchaseItemId)
            ?.toString() ??
        '';
    if (sid.isEmpty) sid = json['id']?.toString() ?? '';

    // 3. Resolve Name & Description (mirrors BillingInvoiceItem.displayLabel priority)
    String? trimmed(dynamic v) {
      final s = v?.toString().trim() ?? '';
      return s.isEmpty ? null : s;
    }

    final customDesc = trimmed(json['customDescription']);
    final purchaseName = purchaseItem == null
        ? null
        : trimmed(
            purchaseItem['itemName'] ??
                purchaseItem['name'] ??
                purchaseItem['label'],
          );
    final consumableName = consumable == null
        ? null
        : trimmed(consumable['name'] ?? consumable['label']);
    final drugName =
        trimmed(drug?['genericName']) ?? trimmed(drug?['brandName']);
    final serviceName = trimmed(service?['name']) ?? trimmed(json['name']);

    final name =
        customDesc ??
        purchaseName ??
        consumableName ??
        drugName ??
        serviceName ??
        'Unknown Item';

    final description =
        (json['description'] ?? service?['description'] ?? drug?['description'])
            ?.toString();

    // 4. Parse Cost/Price
    final costValue =
        json['unitPrice'] ??
        json['priceAtTime'] ??
        json['cost'] ??
        service?['cost'] ??
        drug?['price'];
    final parsedCost = parseApiDecimal(costValue);

    // 5. Category & Department (Typically from service, but check drug too)
    final categoryId =
        (json['categoryId'] ?? service?['categoryId'] ?? drug?['categoryId'])
            ?.toString();
    final categoryName =
        (json['category']?['name'] ??
                service?['category']?['name'] ??
                drug?['category']?['name'])
            ?.toString();
    final departmentId = (json['departmentId'] ?? service?['departmentId'])
        ?.toString();
    final departmentName =
        (json['department']?['name'] ?? service?['department']?['name'])
            ?.toString();

    // 6. User Info
    final cb = json['createdBy'] ?? service?['createdBy'] ?? drug?['createdBy'];
    String? createdByName;
    if (cb is Map<String, dynamic>) {
      final fn = cb['firstName']?.toString().trim() ?? '';
      final ln = cb['lastName']?.toString().trim() ?? '';
      final t = '$fn $ln'.trim();
      createdByName = t.isEmpty ? null : t;
    }

    // 7. Quantity & Booleans
    final quantity = json['quantity'] ?? json['qty'];
    int? qty;
    if (quantity != null) {
      qty = quantity is num
          ? quantity.toInt()
          : int.tryParse(quantity.toString());
    }

    final recurringRaw = json['isRecurringDaily'];
    final isRecurringDaily =
        recurringRaw == true ||
        recurringRaw == 1 ||
        recurringRaw?.toString().toLowerCase() == 'true';

    final amountPaid = parseApiDecimal(json['amountPaid']);

    final s = json['settled'];
    final settled = s is bool ? s : s?.toString().toLowerCase() == 'true';

    final rawHmoPrices = json['hmoPrices'] ?? service?['hmoPrices'];
    final hmoPrices = <ServiceHmoPrice>[];
    if (rawHmoPrices is List) {
      for (final e in rawHmoPrices) {
        if (e is Map<String, dynamic>) {
          hmoPrices.add(ServiceHmoPrice.fromJson(e));
        }
      }
    }

    final serviceCodeRaw =
        json['serviceCode'] ??
        json['searviceCode'] ??
        service?['serviceCode'] ??
        service?['searviceCode'];

    return ServiceModel(
      id: json['id']?.toString() ?? '',
      name: name,
      description: description,
      cost: parsedCost,
      serviceId: sid,
      serviceCode: serviceCodeRaw?.toString(),
      categoryId: categoryId,
      categoryName: categoryName,
      departmentId: departmentId,
      departmentName: departmentName,
      qty: qty,
      isRecurringDaily: isRecurringDaily,
      createdAtIso:
          (json['createdAt'] ?? service?['createdAt'] ?? drug?['createdAt'])
              ?.toString(),
      createdByName: createdByName,
      settled: settled,
      amountPaid: amountPaid,
      transactionItemId: json['transactionItemId']?.toString(),
      drugId: drugId,
      invoiceId: json['invoiceId']?.toString(),
      hmoPrices: hmoPrices,
    );
  }
  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'name': name,
    'serviceCode': serviceCode,
    if (description != null) 'description': description,
    'cost': cost,
    if (categoryId != null) 'categoryId': categoryId,
    if (departmentId != null) 'departmentId': departmentId,
    if (qty != null) 'qty': qty,
    'isRecurringDaily': isRecurringDaily,
    if (createdAtIso != null) 'createdAtIso': createdAtIso,
    if (createdByName != null) 'createdByName': createdByName,
    'settled': settled,
    'amountPaid': amountPaid,
    if (transactionItemId != null) 'transactionItemId': transactionItemId,
    if (drugId != null) 'drugId': drugId,
    if (invoiceId != null) 'invoiceId': invoiceId,
  };
}
