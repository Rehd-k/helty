import 'package:helty/src/core/utils/api_decimal.dart';
import 'package:helty/src/core/utils/patient_display_name.dart';

// Models for GET/POST/PATCH `/hmos` (see docs/hmo-service-pricing-guide.md).

double _moneyFromJson(dynamic v, [double fallback = 0]) {
  if (v is String) {
    final t = v.trim().replaceAll(',', '');
    if (t.isEmpty) return fallback;
    return parseApiDecimal(t, fallback: fallback);
  }
  return parseApiDecimal(v, fallback: fallback);
}

double? _moneyFromJsonNullable(dynamic v) {
  if (v is String) {
    final t = v.trim().replaceAll(',', '');
    if (t.isEmpty) return null;
    return tryParseApiDecimal(t);
  }
  return tryParseApiDecimal(v);
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
    this.defaultCoveragePercent,
    this.counts,
  });

  final String id;
  final String name;
  final String? code;
  final String? notes;
  final double? defaultCoveragePercent;
  final HmoCounts? counts;

  factory HmoListItem.fromJson(Map<String, dynamic> json) {
    return HmoListItem(
      id: '${json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      code: json['code']?.toString(),
      notes: json['notes']?.toString(),
      defaultCoveragePercent: _moneyFromJsonNullable(json['defaultCoveragePercent']),
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
    final fullCost = _moneyFromJson(json['fullCost'] ?? json['cost']);
    final hmoPaysRaw = json['hmoPays'];
    final patientPaysRaw = json['patientPays'];
    final hasSplit = hmoPaysRaw != null || patientPaysRaw != null;
    return HmoServicePriceRow(
      id: json['id']?.toString(),
      serviceId:
          json['serviceId']?.toString() ??
          (svc is Map ? svc['id']?.toString() : null) ??
          '',
      fullCost: fullCost,
      hmoPays: hasSplit ? _moneyFromJson(hmoPaysRaw) : fullCost,
      patientPays: hasSplit ? _moneyFromJson(patientPaysRaw) : 0,
      service: svc is Map<String, dynamic>
          ? HmoNestedService.fromJson(svc)
          : null,
    );
  }

  bool get hasConfiguredSplit =>
      (hmoPays * 100).round() != (fullCost * 100).round() ||
      patientPays > 0;

  Map<String, dynamic> toCreatePatchJson() => {
    'serviceId': serviceId,
    'fullCost': fullCost,
    'hmoPays': hmoPays,
    'patientPays': patientPays,
  };

  Map<String, dynamic> toUpsertJson({bool useCostShorthand = true}) {
    if (useCostShorthand && !hasConfiguredSplit) {
      return {'serviceId': serviceId, 'cost': fullCost};
    }
    return toCreatePatchJson();
  }
}

/// Full HMO from GET /hmos/:id or POST/PATCH response.
class HmoDetail {
  HmoDetail({
    required this.id,
    required this.name,
    this.code,
    this.notes,
    this.defaultCoveragePercent,
    this.servicePrices = const [],
    this.counts,
  });

  final String id;
  final String name;
  final String? code;
  final String? notes;
  final double? defaultCoveragePercent;
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
      defaultCoveragePercent: _moneyFromJsonNullable(json['defaultCoveragePercent']),
      servicePrices: prices,
      counts: HmoCounts.fromJson(json['_count'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toCreateJson({List<HmoServicePriceRow>? servicePrices}) {
    return {
      'name': name,
      if (code != null && code!.trim().isNotEmpty) 'code': code!.trim(),
      if (notes != null && notes!.trim().isNotEmpty) 'notes': notes!.trim(),
      if (defaultCoveragePercent != null)
        'defaultCoveragePercent': defaultCoveragePercent,
      if (servicePrices != null && servicePrices.isNotEmpty)
        'servicePrices': servicePrices.map((e) => e.toCreatePatchJson()).toList(),
    };
  }

  Map<String, dynamic> toPatchJson({
    String? name,
    String? code,
    String? notes,
    double? defaultCoveragePercent,
    List<HmoServicePriceRow>? servicePrices,
  }) {
    final m = <String, dynamic>{};
    if (name != null) m['name'] = name;
    if (code != null) m['code'] = code;
    if (notes != null) m['notes'] = notes;
    if (defaultCoveragePercent != null) {
      m['defaultCoveragePercent'] = defaultCoveragePercent;
    }
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
    this.title,
    required this.surname,
    required this.firstName,
    this.otherName,
    this.phoneNumber,
  });

  final String id;
  final String patientId;
  final String? title;
  final String surname;
  final String firstName;
  final String? otherName;
  final String? phoneNumber;

  factory HmoPatientRow.fromJson(Map<String, dynamic> json) {
    return HmoPatientRow(
      id: '${json['id'] ?? ''}',
      patientId: json['patientId']?.toString() ?? '',
      title: json['title']?.toString(),
      surname: json['surname']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      otherName: json['otherName']?.toString(),
      phoneNumber: json['phoneNumber']?.toString(),
    );
  }

  String get displayName => formatPatientDisplayName(
        title: title,
        firstName: firstName,
        otherName: otherName,
        surname: surname,
        unknownFallback: patientId,
      );
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
