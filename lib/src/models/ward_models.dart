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
  });

  final String id;
  final String patientId;
  final String name;
  final String ageGender;
  final String wardName;
  final String bedLabel;
  final String diagnosis;
  final int daysAdmitted;

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

    final firstName = patient?['firstName'] ?? patient?['firstname'];
    final lastName = patient?['lastName'] ?? patient?['lastname'];
    final fullName =
        json['name'] ?? json['patientName'] ?? '$firstName $lastName';

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

    final daysRaw =
        json['daysAdmitted'] ?? json['lengthOfStay'] ?? json['los'] ?? 0;

    final days = daysRaw is num
        ? daysRaw.toInt()
        : int.tryParse('$daysRaw') ?? 0;

    return InpatientCensus(
      id: json['id']?.toString() ?? '',
      patientId:
          json['patientId']?.toString() ?? patient?['id']?.toString() ?? '',
      name: (fullName is String && fullName.trim().isNotEmpty)
          ? fullName
          : 'Unknown patient',
      ageGender: ageGender,
      wardName: wardName.toString(),
      bedLabel: bedLabel.toString(),
      diagnosis: diagnosis.toString(),
      daysAdmitted: days,
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
      drugPricePercentage: () {
        final v = json['drugPricePercentage'];
        if (v == null) return null;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString());
      }(),
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
