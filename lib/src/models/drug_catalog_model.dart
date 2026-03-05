class DrugCatalogModel {
  const DrugCatalogModel({
    required this.id,
    required this.name,
    this.generic,
    this.strength,
    this.form,
    this.stockStatus,
    this.contraindications,
    this.interactions,
  });

  final String id;
  final String name;
  final String? generic;
  final String? strength;
  final String? form;
  final String? stockStatus;
  final String? contraindications;
  final String? interactions;

  factory DrugCatalogModel.fromJson(Map<String, dynamic> json) =>
      DrugCatalogModel(
        id: json['id'] as String,
        name: json['name'] as String,
        generic: json['generic'] as String?,
        strength: json['strength'] as String?,
        form: json['form'] as String?,
        stockStatus: json['stockStatus'] as String?,
        contraindications: json['contraindications'] as String?,
        interactions: json['interactions'] as String?,
      );
}
