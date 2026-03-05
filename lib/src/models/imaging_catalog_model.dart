class ImagingCatalogModel {
  const ImagingCatalogModel({
    required this.id,
    required this.name,
    this.area,
    this.contrastAvailable = false,
    this.cost,
  });

  final String id;
  final String name;
  final String? area;
  final bool contrastAvailable;
  final double? cost;

  factory ImagingCatalogModel.fromJson(Map<String, dynamic> json) =>
      ImagingCatalogModel(
        id: json['id'] as String,
        name: json['name'] as String,
        area: json['area'] as String?,
        contrastAvailable: json['contrastAvailable'] as bool? ?? false,
        cost: (json['cost'] as num?)?.toDouble(),
      );
}
