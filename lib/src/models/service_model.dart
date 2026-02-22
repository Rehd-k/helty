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

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    cost: num.parse(json['cost']).toDouble(),
    serviceId: json['serviceId'] as String,
    categoryId: json['categoryId'] as String?,
    categoryName: json['category']?['name'] as String?,
    departmentId: json['departmentId'] as String?,
    departmentName: json['department']?['name'] as String?,
  );

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'name': name,
    if (description != null) 'description': description,
    'cost': cost,
    if (categoryId != null) 'categoryId': categoryId,
    if (departmentId != null) 'departmentId': departmentId,
  };
}
