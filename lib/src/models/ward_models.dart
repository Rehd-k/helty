import 'package:helty/src/core/utils/api_decimal.dart';

enum WardType { general, private, icu, maternity, paediatric, surgical }

WardType _wardTypeFromJson(String? value) {
  if (value == null) return WardType.general;
  switch (value.toUpperCase()) {
    case 'GENERAL':
      return WardType.general;
    case 'PRIVATE':
      return WardType.private;
    case 'ICU':
      return WardType.icu;
    case 'MATERNITY':
      return WardType.maternity;
    case 'PAEDIATRIC':
    case 'PAEDIATRICS':
      return WardType.paediatric;
    case 'SURGICAL':
      return WardType.surgical;
    default:
      return WardType.general;
  }
}

String wardTypeToJson(WardType type) {
  switch (type) {
    case WardType.general:
      return 'GENERAL';
    case WardType.private:
      return 'PRIVATE';
    case WardType.icu:
      return 'ICU';
    case WardType.maternity:
      return 'MATERNITY';
    case WardType.paediatric:
      return 'PAEDIATRIC';
    case WardType.surgical:
      return 'SURGICAL';
  }
}

enum BedStatus { available, occupied, reserved, outOfService }

BedStatus _bedStatusFromJson(String? value) {
  if (value == null) return BedStatus.available;
  switch (value.toUpperCase()) {
    case 'AVAILABLE':
      return BedStatus.available;
    case 'OCCUPIED':
      return BedStatus.occupied;
    case 'RESERVED':
      return BedStatus.reserved;
    case 'OUT_OF_SERVICE':
    case 'OUTOFSERVICE':
      return BedStatus.outOfService;
    default:
      return BedStatus.available;
  }
}

String bedStatusToJson(BedStatus status) {
  switch (status) {
    case BedStatus.available:
      return 'AVAILABLE';
    case BedStatus.occupied:
      return 'OCCUPIED';
    case BedStatus.reserved:
      return 'RESERVED';
    case BedStatus.outOfService:
      return 'OUT_OF_SERVICE';
  }
}

class Bed {
  Bed({
    required this.id,
    required this.wardId,
    required this.bedNumber,
    required this.status,
  });

  final String id;
  final String wardId;
  final String bedNumber;
  final BedStatus status;

  factory Bed.fromJson(Map<String, dynamic> json) => Bed(
    id: json['id']?.toString() ?? '',
    wardId: json['wardId']?.toString() ?? '',
    bedNumber: json['bedNumber'] as String? ?? '',
    status: _bedStatusFromJson(json['status'] as String?),
  );

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'wardId': wardId,
    'bedNumber': bedNumber,
    'status': bedStatusToJson(status),
  };
}

int _calendarDaysSinceAdmission(DateTime admission) {
  final now = DateTime.now();
  final a = DateTime(admission.year, admission.month, admission.day);
  final n = DateTime(now.year, now.month, now.day);
  return n.difference(a).inDays;
}

DateTime? _parseAdmissionDate(Map<String, dynamic> json) {
  const keys = ['admissionDateTime', 'admissionDate', 'admittedAt'];
  for (final k in keys) {
    final v = json[k];
    if (v != null) {
      final d = DateTime.tryParse(v.toString());
      if (d != null) return d;
    }
  }
  return null;
}

int _daysAdmittedFromJson(Map<String, dynamic> json) {
  if (json.containsKey('daysAdmitted') && json['daysAdmitted'] != null) {
    final v = json['daysAdmitted'];
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
  if (json.containsKey('lengthOfStay') && json['lengthOfStay'] != null) {
    final v = json['lengthOfStay'];
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
  if (json.containsKey('los') && json['los'] != null) {
    final v = json['los'];
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
  final ad = _parseAdmissionDate(json);
  if (ad != null) return _calendarDaysSinceAdmission(ad);
  return 0;
}

class InpatientCensus {
  InpatientCensus({
    required this.id,
    required this.patientId,
    required this.name,
    required this.ageGender,
    required this.wardName,
    required this.bedLabel,
    required this.diagnosis,
    required this.daysAdmitted,
    this.encounterId,
  });

  final String id;
  final String patientId;
  final String name;
  final String ageGender;
  final String wardName;
  final String bedLabel;
  final String diagnosis;
  final int daysAdmitted;

  /// Linked encounter for this admission, when returned by the ward API.
  final String? encounterId;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  factory InpatientCensus.fromJson(Map<String, dynamic> json) {
    final patientRaw = json['patient'];
    final wardRaw = json['ward'];
    final bedRaw = json['bed'];

    final patient = patientRaw is Map<String, dynamic> ? patientRaw : null;
    final ward = wardRaw is Map<String, dynamic> ? wardRaw : null;
    final bed = bedRaw is Map<String, dynamic> ? bedRaw : null;

    final firstName = (patient?['firstName'] ?? patient?['firstname'] ?? '')
        .toString()
        .trim();
    final lastName =
        (patient?['lastName'] ??
                patient?['lastname'] ??
                patient?['surname'] ??
                '')
            .toString()
            .trim();
    final joinedPatientName = [
      firstName,
      lastName,
    ].where((e) => e.isNotEmpty).join(' ').trim();
    final fullName = json['name'] ?? json['patientName'] ?? joinedPatientName;

    final age = json['age']?.toString() ?? patient?['age']?.toString();
    final gender = json['gender'] ?? patient?['gender'];
    final ageGender = [
      if (age != null && age.isNotEmpty) '$age yrs',
      if (gender != null && gender.toString().isNotEmpty)
        gender.toString().substring(0, 1).toUpperCase() +
            gender.toString().substring(1).toLowerCase(),
    ].join(' • ');

    final wardName =
        json['wardName'] ?? ward?['name'] ?? json['ward']?.toString() ?? '';
    final bedLabel =
        json['bedNumber'] ?? bed?['bedNumber'] ?? json['bed']?.toString() ?? '';

    final diagnosis =
        json['diagnosis'] ??
        json['primaryDiagnosis'] ??
        json['provisionalDiagnosis'] ??
        json['reason'] ??
        '';

    final encounterRaw = json['encounter'];
    String? encounterId;
    if (encounterRaw is Map<String, dynamic>) {
      encounterId = encounterRaw['id']?.toString();
    }

    final days = _daysAdmittedFromJson(json);

    return InpatientCensus(
      id: json['id']?.toString() ?? '',
      patientId:
          patient?['id']?.toString() ??
          json['patientId']?.toString() ??
          patient?['patientId']?.toString() ??
          '',
      name: (fullName is String && fullName.trim().isNotEmpty)
          ? fullName
          : 'Unknown patient',
      ageGender: ageGender,
      wardName: wardName.toString(),
      bedLabel: bedLabel.toString(),
      diagnosis: diagnosis.toString(),
      daysAdmitted: days,
      encounterId: encounterId,
    );
  }
}

class Ward {
  Ward({
    required this.id,
    required this.name,
    required this.capacity,
    required this.type,
    this.departmentId,
    this.departmentName,
    this.drugPricePercentage,
    this.createdAt,
    this.updatedAt,
    this.beds = const [],
    this.inpatients = const [],
  });

  final String id;
  final String name;
  final int capacity;
  final WardType type;
  final String? departmentId;

  /// From nested `department` on GET /wards when included.
  final String? departmentName;
  final double? drugPricePercentage;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<Bed> beds;
  final List<InpatientCensus> inpatients;

  factory Ward.fromJson(Map<String, dynamic> json) {
    final bedsJson = json['beds'];
    final inpatientsJson = json['admissions'];
    return Ward(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      capacity: (json['capacity'] as num?)?.toInt() ?? 0,
      type: _wardTypeFromJson(json['type'] as String?),
      departmentId: json['departmentId'] as String?,
      departmentName: json['department'] is Map
          ? (json['department'] as Map)['name'] as String?
          : null,
      drugPricePercentage: tryParseApiDecimal(json['drugPricePercentage']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      beds: bedsJson is List
          ? bedsJson
                .whereType<Map<String, dynamic>>()
                .map(Bed.fromJson)
                .toList()
          : const [],
      inpatients: inpatientsJson is List
          ? inpatientsJson
                .whereType<Map<String, dynamic>>()
                .map(InpatientCensus.fromJson)
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toJson() => {
    if (id.isNotEmpty) 'id': id,
    'name': name,
    'capacity': capacity,
    'type': wardTypeToJson(type),
    if (departmentId != null) 'departmentId': departmentId,
    if (drugPricePercentage != null) 'drugPricePercentage': drugPricePercentage,
  };
}
