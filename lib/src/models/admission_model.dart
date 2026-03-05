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

  factory AdmissionModel.fromJson(Map<String, dynamic> json) => AdmissionModel(
        id: json['id'] as String,
        patientId: json['patientId'] as String,
        encounterId: json['encounterId'] as String,
        reason: json['reason'] as String?,
        ward: json['ward'] as String?,
        bedPreference: json['bedPreference'] as String?,
        provisionalDiagnosis: json['provisionalDiagnosis'] as String?,
        expectedLOS: json['expectedLOS'] as String?,
        isolationRequired: json['isolationRequired'] as bool? ?? false,
        specialInstructions: json['specialInstructions'] as String?,
        status: json['status'] as String? ?? 'Pending',
      );
}
