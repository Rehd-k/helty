class ServiceModel {
  ServiceModel({
    required this.id,
    required this.name,
    required this.serviceId,
    this.description,
    required this.cost,
    this.categoryId,
    this.categoryName,
    this.departmentId,
    this.departmentName,
    this.qty,
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
  int? qty;

  /// helper for debug output
  @override
  String toString() => name;

  /// Parses from either a full service object or an API InvoiceItem
  /// (with quantity, priceAtTime, and nested service).
  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    final service = json['service'] as Map<String, dynamic>?;
    final costValue = json['priceAtTime'] ?? json['cost'];
    final quantity = json['quantity'] ?? json['qty'];
    return ServiceModel(
      id: json['id']?.toString() ?? '',
      name: (service?['name'] ?? json['name']) as String? ?? '',
      description: (service?['description'] ?? json['description']) as String?,
      cost: costValue != null ? (costValue as num).toDouble() : 0.0,
      serviceId: (json['serviceId'] ?? service?['id'] ?? json['searviceCode'] ?? '') as String,
      categoryId: (service?['categoryId'] ?? json['categoryId']) as String?,
      categoryName: (service?['category']?['name'] ?? json['category']?['name']) as String?,
      departmentId: (service?['departmentId'] ?? json['departmentId']) as String?,
      departmentName: (service?['department']?['name'] ?? json['department']?['name']) as String?,
      qty: quantity != null ? (quantity is int ? quantity : (quantity as num).toInt()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'name': name,
    if (description != null) 'description': description,
    'cost': cost,
    if (categoryId != null) 'categoryId': categoryId,
    if (departmentId != null) 'departmentId': departmentId,
  };
}
