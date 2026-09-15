class PatientAllergyRecord {
  const PatientAllergyRecord({
    required this.id,
    required this.patientId,
    required this.allergen,
    this.reaction,
    this.severity,
    this.type,
    this.notes,
    this.createdAt,
  });

  final String id;
  final String patientId;
  final String allergen;
  final String? reaction;
  final String? severity;
  final String? type;
  final String? notes;
  final DateTime? createdAt;

  String get displayLabel {
    final sev = severity?.trim();
    if (sev == null || sev.isEmpty) return allergen;
    return '$allergen (${_titleCase(sev)})';
  }

  factory PatientAllergyRecord.fromJson(Map<String, dynamic> json) {
    return PatientAllergyRecord(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      allergen: (json['allergen'] ?? json['name'])?.toString().trim() ?? '',
      reaction: json['reaction']?.toString(),
      severity: json['severity']?.toString(),
      type: json['type']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
    );
  }
}

class PatientImmunizationRecord {
  const PatientImmunizationRecord({
    required this.id,
    required this.patientId,
    required this.vaccineName,
    this.detail,
    this.doseNumber,
    required this.administeredAt,
  });

  final String id;
  final String patientId;
  final String vaccineName;
  final String? detail;
  final int? doseNumber;
  final DateTime administeredAt;

  factory PatientImmunizationRecord.fromJson(Map<String, dynamic> json) {
    return PatientImmunizationRecord(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      vaccineName: json['vaccineName']?.toString().trim() ?? '',
      detail: json['detail']?.toString(),
      doseNumber: json['doseNumber'] is num
          ? (json['doseNumber'] as num).toInt()
          : int.tryParse(json['doseNumber']?.toString() ?? ''),
      administeredAt:
          DateTime.tryParse(json['administeredAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

String _titleCase(String value) {
  if (value.isEmpty) return value;
  return '${value[0].toUpperCase()}${value.substring(1).toLowerCase()}';
}

const kAllergySeverities = ['MILD', 'MODERATE', 'SEVERE', 'CRITICAL'];
