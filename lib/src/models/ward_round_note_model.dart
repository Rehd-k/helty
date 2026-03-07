/// Ward round (progress) note for an inpatient admission.
/// SOAP-style note linked to admission and doctor, with round date.
class WardRoundNoteModel {
  const WardRoundNoteModel({
    required this.id,
    required this.admissionId,
    required this.doctorId,
    required this.roundDate,
    this.subjective,
    this.objective,
    this.assessment,
    this.plan,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String admissionId;
  final String doctorId;
  final DateTime roundDate;
  final String? subjective;
  final String? objective;
  final String? assessment;
  final String? plan;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory WardRoundNoteModel.fromJson(Map<String, dynamic> json) {
    return WardRoundNoteModel(
      id: (json['id'] ?? '').toString(),
      admissionId: (json['admissionId'] ?? '').toString(),
      doctorId: (json['doctorId'] ?? '').toString(),
      roundDate: json['roundDate'] != null
          ? (DateTime.tryParse(json['roundDate'].toString()) ?? DateTime.now())
          : DateTime.now(),
      subjective: json['subjective']?.toString(),
      objective: json['objective']?.toString(),
      assessment: json['assessment']?.toString(),
      plan: json['plan']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'admissionId': admissionId,
        'doctorId': doctorId,
        'roundDate': roundDate.toIso8601String().split('T').first,
        if (subjective != null) 'subjective': subjective,
        if (objective != null) 'objective': objective,
        if (assessment != null) 'assessment': assessment,
        if (plan != null) 'plan': plan,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };
}
