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
    this.pulseRate,
    this.spo2,
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
  final int? pulseRate;
  final double? spo2;

  final DateTime createdAt;
  final DateTime updatedAt;

  factory PatientVitalsModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return PatientVitalsModel(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      systolic: (json['systolic'] as num?)?.toInt(),
      diastolic: (json['diastolic'] as num?)?.toInt(),
      temperature: (json['temperature'] as num?)?.toDouble(),
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      bmi: (json['bmi'] as num?)?.toDouble(),
      pulseRate: (json['pulseRate'] as num?)?.toInt(),
      spo2: (json['spo2'] as num?)?.toDouble(),
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
    if (pulseRate != null) 'pulseRate': pulseRate,
    if (spo2 != null) 'spo2': spo2,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}

/// DTO used when creating a new [PatientVitalsModel].
class CreatePatientVitalsDto {
  const CreatePatientVitalsDto({
    required this.patientId,
    this.systolic,
    this.diastolic,
    this.temperature,
    this.height,
    this.weight,
    this.bmi,
    this.pulseRate,
    this.spo2,
  });

  final String patientId;
  final int? systolic;
  final int? diastolic;
  final double? temperature;
  final double? height;
  final double? weight;
  final double? bmi;
  final int? pulseRate;
  final double? spo2;

  Map<String, dynamic> toJson() => {
    'patientId': patientId,
    if (systolic != null) 'systolic': systolic,
    if (diastolic != null) 'diastolic': diastolic,
    if (temperature != null) 'temperature': temperature,
    if (height != null) 'height': height,
    if (weight != null) 'weight': weight,
    if (bmi != null) 'bmi': bmi,
    if (pulseRate != null) 'pulseRate': pulseRate,
    if (spo2 != null) 'spo2': spo2,
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
    this.pulseRate,
    this.spo2,
  });

  final int? systolic;
  final int? diastolic;
  final double? temperature;
  final double? height;
  final double? weight;
  final double? bmi;
  final int? pulseRate;
  final double? spo2;

  Map<String, dynamic> toJson() => {
    if (systolic != null) 'systolic': systolic,
    if (diastolic != null) 'diastolic': diastolic,
    if (temperature != null) 'temperature': temperature,
    if (height != null) 'height': height,
    if (weight != null) 'weight': weight,
    if (bmi != null) 'bmi': bmi,
    if (pulseRate != null) 'pulseRate': pulseRate,
    if (spo2 != null) 'spo2': spo2,
  };
}
