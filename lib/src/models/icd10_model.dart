/// ICD-10 code and description for diagnosis.
class Icd10Model {
  const Icd10Model({
    required this.code,
    required this.description,
  });

  final String code;
  final String description;

  factory Icd10Model.fromJson(Map<String, dynamic> json) => Icd10Model(
        code: json['code'] as String,
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {'code': code, 'description': description};

  @override
  String toString() => '$code — $description';
}
