class AdmissionModel {
  const AdmissionModel({
    required this.id,
    required this.patientId,
    required this.encounterId,
    this.reason,
    this.ward,
    this.bedPreference,
    this.provisionalDiagnosis,
    this.expectedLOS,
    this.isolationRequired = false,
    this.specialInstructions,
    required this.status,
    this.attendingDoctorId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String patientId;
  final String encounterId;
  final String? reason;
  final String? ward;
  final String? bedPreference;
  final String? provisionalDiagnosis;
  final String? expectedLOS;
  final bool isolationRequired;
  final String? specialInstructions;
  final String status;
  final String? attendingDoctorId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AdmissionModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v != null) ? v.toString() : '';
    return AdmissionModel(
      id: str(json['id']),
      patientId: str(json['patientId']),
      encounterId: str(json['encounterId']),
      reason: json['reason']?.toString(),
      ward: json['ward']?.toString(),
      bedPreference: json['bedPreference']?.toString(),
      provisionalDiagnosis: json['provisionalDiagnosis']?.toString(),
      expectedLOS: json['expectedLOS']?.toString(),
      isolationRequired: json['isolationRequired'] == true,
      specialInstructions: json['specialInstructions']?.toString(),
      status: (json['status']?.toString()) ?? 'Pending',
      attendingDoctorId: json['attendingDoctorId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }
}
