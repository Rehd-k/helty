class LabCatalogModel {
  const LabCatalogModel({
    required this.id,
    required this.name,
    this.department,
    this.cost,
    this.turnaround,
    this.sampleType,
    this.preparation,
  });

  final String id;
  final String name;
  final String? department;
  final double? cost;
  final String? turnaround;
  final String? sampleType;
  final String? preparation;

  factory LabCatalogModel.fromJson(Map<String, dynamic> json) =>
      LabCatalogModel(
        id: json['id'] as String,
        name: json['name'] as String,
        department: json['department'] as String?,
        cost: (json['cost'] as num?)?.toDouble(),
        turnaround: json['turnaround'] as String?,
        sampleType: json['sampleType'] as String?,
        preparation: json['preparation'] as String?,
      );
}
