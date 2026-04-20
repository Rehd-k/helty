// Models for GET/POST/PATCH `/hmos` (see docs/hmo-client.md).

double _moneyFromJson(dynamic v, [double fallback = 0]) {
  if (v == null) return fallback;
  if (v is num) return v.toDouble();
  if (v is String) {
    final t = v.trim().replaceAll(',', '');
    if (t.isEmpty) return fallback;
    return double.tryParse(t) ?? fallback;
  }
  return fallback;
}

double? _moneyFromJsonNullable(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  if (v is String) {
    final t = v.trim().replaceAll(',', '');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }
  return null;
}

class HmoCounts {
  const HmoCounts({this.patients = 0, this.servicePrices = 0});

  final int patients;
  final int servicePrices;

  factory HmoCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const HmoCounts();
    final c = json['_count'];
    if (c is Map<String, dynamic>) {
      return HmoCounts(
        patients: (c['patients'] as num?)?.toInt() ?? 0,
        servicePrices: (c['servicePrices'] as num?)?.toInt() ?? 0,
      );
    }
    return const HmoCounts();
  }
}

/// List row from GET /hmos
class HmoListItem {
  HmoListItem({
    required this.id,
    required this.name,
    this.code,
    this.notes,
    this.counts,
  });

  final String id;
  final String name;
  final String? code;
  final String? notes;
  final HmoCounts? counts;

  factory HmoListItem.fromJson(Map<String, dynamic> json) {
    return HmoListItem(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      code: json['code']?.toString(),
      notes: json['notes']?.toString(),
      counts: HmoCounts.fromJson(json['_count'] as Map<String, dynamic>?),
    );
  }
}

class HmoPagedResult {
  const HmoPagedResult({
    required this.items,
    required this.total,
    required this.skip,
    required this.take,
  });

  final List<HmoListItem> items;
  final int total;
  final int skip;
  final int take;
}

/// Nested service summary on a price row.
class HmoNestedService {
  HmoNestedService({
    required this.id,
    required this.name,
    this.serviceCode,
    this.cost,
  });

  final String id;
  final String name;
  final String? serviceCode;
  final double? cost;

  factory HmoNestedService.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return HmoNestedService(id: '', name: '');
    }
    return HmoNestedService(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      serviceCode: json['serviceCode']?.toString() ?? json['searviceCode']?.toString(),
      cost: _moneyFromJsonNullable(json['cost']),
    );
  }
}

/// One configured price for an HMO + service.
class HmoServicePriceRow {
  HmoServicePriceRow({
    required this.serviceId,
    required this.fullCost,
    required this.hmoPays,
    required this.patientPays,
    this.id,
    this.service,
  });

  final String? id;
  final String serviceId;
  final double fullCost;
  final double hmoPays;
  final double patientPays;
  final HmoNestedService? service;

  factory HmoServicePriceRow.fromJson(Map<String, dynamic> json) {
    final svc = json['service'];
    return HmoServicePriceRow(
      id: json['id']?.toString(),
      serviceId:
          json['serviceId']?.toString() ??
          (svc is Map ? svc['id']?.toString() : null) ??
          '',
      fullCost: _moneyFromJson(json['fullCost']),
      hmoPays: _moneyFromJson(json['hmoPays']),
      patientPays: _moneyFromJson(json['patientPays']),
      service: svc is Map<String, dynamic>
          ? HmoNestedService.fromJson(svc)
          : null,
    );
  }

  Map<String, dynamic> toCreatePatchJson() => {
    'serviceId': serviceId,
    'fullCost': fullCost,
    'hmoPays': hmoPays,
    'patientPays': patientPays,
  };
}

/// Full HMO from GET /hmos/:id or POST/PATCH response.
class HmoDetail {
  HmoDetail({
    required this.id,
    required this.name,
    this.code,
    this.notes,
    this.servicePrices = const [],
    this.counts,
  });

  final String id;
  final String name;
  final String? code;
  final String? notes;
  final List<HmoServicePriceRow> servicePrices;
  final HmoCounts? counts;

  factory HmoDetail.fromJson(Map<String, dynamic> json) {
    final raw = json['servicePrices'];
    final prices = <HmoServicePriceRow>[];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map<String, dynamic>) {
          prices.add(HmoServicePriceRow.fromJson(e));
        }
      }
    }
    return HmoDetail(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      code: json['code']?.toString(),
      notes: json['notes']?.toString(),
      servicePrices: prices,
      counts: HmoCounts.fromJson(json['_count'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toCreateJson({List<HmoServicePriceRow>? servicePrices}) {
    return {
      'name': name,
      if (code != null && code!.trim().isNotEmpty) 'code': code!.trim(),
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      if (servicePrices != null && servicePrices.isNotEmpty)
        'servicePrices': servicePrices.map((e) => e.toCreatePatchJson()).toList(),
    };
  }

  Map<String, dynamic> toPatchJson({
    String? name,
    String? code,
    String? notes,
    List<HmoServicePriceRow>? servicePrices,
  }) {
    final m = <String, dynamic>{};
    if (name != null) m['name'] = name;
    if (code != null) m['code'] = code;
    if (notes != null) m['notes'] = notes;
    if (servicePrices != null) {
      m['servicePrices'] = servicePrices.map((e) => e.toCreatePatchJson()).toList();
    }
    return m;
  }
}

/// Patient under an HMO from GET /hmos/:id/patients
class HmoPatientRow {
  HmoPatientRow({
    required this.id,
    required this.patientId,
    required this.surname,
    required this.firstName,
    this.phoneNumber,
  });

  final String id;
  final String patientId;
  final String surname;
  final String firstName;
  final String? phoneNumber;

  factory HmoPatientRow.fromJson(Map<String, dynamic> json) {
    return HmoPatientRow(
      id: '${json['id'] ?? ''}',
      patientId: json['patientId']?.toString() ?? '',
      surname: json['surname']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString(),
    );
  }

  String get displayName => '$surname $firstName'.trim();
}

class HmoPatientsPagedResult {
  const HmoPatientsPagedResult({
    required this.patients,
    required this.total,
    required this.skip,
    required this.take,
  });

  final List<HmoPatientRow> patients;
  final int total;
  final int skip;
  final int take;
}

/// Provider summary on patient responses (GET /patients).
class HmoProviderSummary {
  const HmoProviderSummary({
    required this.id,
    required this.name,
    this.code,
  });

  final String id;
  final String name;
  final String? code;

  factory HmoProviderSummary.fromJson(Map<String, dynamic> json) {
    return HmoProviderSummary(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      code: json['code']?.toString(),
    );
  }
}
