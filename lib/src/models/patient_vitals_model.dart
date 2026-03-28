class PatientVitalsModel {
  const PatientVitalsModel({
    required this.id,
    required this.patientId,
    this.systolic,
    this.diastolic,
    this.temperature,
    this.height,
    this.weight,
    this.bmi,
    this.respRate,
    this.pulseRate,
    this.spo2,
    this.painScore,
    this.bloodGlucose,
    this.notes,
    this.recordedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String patientId;

  final int? systolic;
  final int? diastolic;
  final double? temperature;
  final double? height;
  final double? weight;
  final double? bmi;
  final int? respRate;
  final int? pulseRate;
  final double? spo2;

  // Additional vitals fields shown in the UI
  final String? painScore;
  final String? bloodGlucose;
  final String? notes;
  final String? recordedBy;

  final DateTime createdAt;
  final DateTime updatedAt;

  factory PatientVitalsModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v != null) ? v.toString() : '';

    DateTime parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      if (value is DateTime) return value;
      return DateTime.now();
    }

    num? numOrNull(dynamic v) {
      if (v == null) return null;
      if (v is num) return v;
      if (v is String) return num.tryParse(v);
      return null;
    }

    return PatientVitalsModel(
      id: str(json['id']),
      patientId: str(json['patientId']).isEmpty
          ? str(json['waitingPatientId'])
          : str(json['patientId']),
      systolic: numOrNull(json['systolic'])?.toInt(),
      diastolic: numOrNull(json['diastolic'])?.toInt(),
      temperature: numOrNull(json['temperature'])?.toDouble(),
      height: numOrNull(json['height'])?.toDouble(),
      weight: numOrNull(json['weight'])?.toDouble(),
      bmi: numOrNull(json['bmi'])?.toDouble(),
      respRate: numOrNull(json['respRate'])?.toInt(),
      pulseRate: numOrNull(json['pulseRate'])?.toInt(),
      spo2: numOrNull(json['spo2'])?.toDouble(),
      painScore: json['painScore']?.toString(),
      bloodGlucose: json['bloodGlucose']?.toString(),
      notes: json['notes']?.toString(),
      recordedBy: json['recordedBy']?.toString() ??
          json['recordedById']?.toString(),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    if (systolic != null) 'systolic': systolic,
    if (diastolic != null) 'diastolic': diastolic,
    if (temperature != null) 'temperature': temperature,
    if (height != null) 'height': height,
    if (weight != null) 'weight': weight,
    if (bmi != null) 'bmi': bmi,
    if (respRate != null) 'respRate': respRate,
    if (pulseRate != null) 'pulseRate': pulseRate,
    if (spo2 != null) 'spo2': spo2,
    if (painScore != null) 'painScore': painScore,
    if (bloodGlucose != null) 'bloodGlucose': bloodGlucose,
    if (notes != null) 'notes': notes,
    if (recordedBy != null) 'recordedBy': recordedBy,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// DTO used when creating a new [PatientVitalsModel].
class CreatePatientVitalsDto {
  const CreatePatientVitalsDto({
    this.waitingPatientId,
    this.admissionId,
    this.systolic,
    this.diastolic,
    this.temperature,
    this.height,
    this.weight,
    this.bmi,
    this.respRate,
    this.pulseRate,
    this.spo2,
    this.notes,
    this.bloodGlucose,
    this.painScore,
  });

  final String? waitingPatientId;
  final String? admissionId;
  final int? systolic;
  final int? diastolic;
  final double? temperature;
  final double? height;
  final double? weight;
  final double? bmi;
  final int? respRate;
  final int? pulseRate;
  final double? spo2;
  final String? notes;
  final String? bloodGlucose;
  final String? painScore;

  Map<String, dynamic> toJson() => {
    if (waitingPatientId != null) 'waitingPatientId': waitingPatientId,
    if (admissionId != null) 'admissionId': admissionId,
    if (systolic != null) 'systolic': systolic,
    if (diastolic != null) 'diastolic': diastolic,
    if (temperature != null) 'temperature': temperature,
    if (height != null) 'height': height,
    if (weight != null) 'weight': weight,
    if (bmi != null) 'bmi': bmi,
    if (respRate != null) 'respRate': respRate,
    if (pulseRate != null) 'pulseRate': pulseRate,
    if (spo2 != null) 'spo2': spo2,
    if (notes != null) 'notes': notes,
    if (bloodGlucose != null) 'bloodGlucose': bloodGlucose,
    if (painScore != null) 'painScore': painScore,
  };
}

/// DTO for partial update of vitals (PATCH patient-vitals/:id).
class UpdatePatientVitalsDto {
  const UpdatePatientVitalsDto({
    this.systolic,
    this.diastolic,
    this.temperature,
    this.height,
    this.weight,
    this.bmi,
    this.respRate,
    this.pulseRate,
    this.spo2,
  });

  final int? systolic;
  final int? diastolic;
  final double? temperature;
  final double? height;
  final double? weight;
  final double? bmi;
  final int? respRate;
  final int? pulseRate;
  final double? spo2;

  Map<String, dynamic> toJson() => {
    if (systolic != null) 'systolic': systolic,
    if (diastolic != null) 'diastolic': diastolic,
    if (temperature != null) 'temperature': temperature,
    if (height != null) 'height': height,
    if (weight != null) 'weight': weight,
    if (bmi != null) 'bmi': bmi,
    if (respRate != null) 'respRate': respRate,
    if (pulseRate != null) 'pulseRate': pulseRate,
    if (spo2 != null) 'spo2': spo2,
  };
}
