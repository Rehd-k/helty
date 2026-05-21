/// ICD-10 code and description for diagnosis.
class Icd10Model {
  const Icd10Model({
    required this.code,
    required this.description,
    this.id,
    this.specialty,
    this.icdGroup,
    this.range,
  });

  final String code;
  final String description;
  final String? id;
  final String? specialty;
  final String? icdGroup;
  final String? range;

  String get displayLabel => '$code — $description';

  factory Icd10Model.fromJson(Map<String, dynamic> json) => Icd10Model(
        code: json['code']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        id: json['id']?.toString(),
        specialty: json['specialty']?.toString(),
        icdGroup: json['icdGroup']?.toString(),
        range: json['range']?.toString(),
      );

  Map<String, dynamic> toJson() => {'code': code, 'description': description};

  @override
  String toString() => displayLabel;
}
