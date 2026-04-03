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

  /// helper for debug output
  @override
  String toString() => name;

  /// Parses from either a full service object or an API InvoiceItem
  /// (with quantity, priceAtTime, and nested service).
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final service = json['service'] as Map<String, dynamic>?;
    final costValue = json['unitPrice'] ?? json['priceAtTime'] ?? json['cost'];
    final recurringRaw = json['isRecurringDaily'];
    final isRecurringDaily =
        recurringRaw == true ||
        recurringRaw == 1 ||
        recurringRaw?.toString().toLowerCase() == 'true';
    final quantity = json['quantity'] ?? json['qty'];
    final parsedCost = costValue is num
        ? costValue.toDouble()
        : double.tryParse(costValue?.toString() ?? '') ?? 0.0;
    final root = service ?? json;
    final cb = root['createdBy'] ?? json['createdBy'];
    String? createdByName;
    if (cb is Map<String, dynamic>) {
      final fn = cb['firstName']?.toString().trim() ?? '';
      final ln = cb['lastName']?.toString().trim() ?? '';
      final t = '$fn $ln'.trim();
      createdByName = t.isEmpty ? null : t;
    }
    final createdAtRaw = root['createdAt'] ?? json['createdAt'];
    var sid =
        (json['serviceId'] ?? service?['id'] ?? json['searviceCode'])
            ?.toString() ??
        '';
    if (sid.isEmpty) sid = json['id']?.toString() ?? '';
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      name: (service?['name'] ?? json['name']) as String? ?? '',
      description: (service?['description'] ?? json['description']) as String?,
      cost: parsedCost,
      serviceId: sid,
      serviceCode: (service?['serviceCode'] ?? json['serviceCode']) as String?,
      categoryId: (service?['categoryId'] ?? json['categoryId']) as String?,
      categoryName:
          (service?['category']?['name'] ?? json['category']?['name'])
              as String?,
      departmentId:
          (service?['departmentId'] ?? json['departmentId']) as String?,
      departmentName:
          (service?['department']?['name'] ?? json['department']?['name'])
              as String?,
      qty: quantity != null
          ? (quantity is int ? quantity : (quantity as num).toInt())
          : null,
      isRecurringDaily: isRecurringDaily,
      createdAtIso: createdAtRaw?.toString(),
      createdByName: createdByName,
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
  };
}
