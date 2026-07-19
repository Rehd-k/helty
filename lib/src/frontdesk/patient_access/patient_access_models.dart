/// Patient summary nested on device / child rows.
class PatientAccessPatientSummary {
  const PatientAccessPatientSummary({
    required this.id,
    required this.patientId,
    required this.displayName,
  });

  /// System UUID (`Patient.id`).
  final String id;

  /// Hospital card / display ID.
  final String patientId;
  final String displayName;

  factory PatientAccessPatientSummary.fromJson(Map<String, dynamic> json) {
    final first = json['firstName']?.toString().trim() ?? '';
    final last = json['lastName']?.toString().trim() ?? '';
    final combined = '$first $last'.trim();
    final name =
        json['displayName']?.toString().trim() ??
        json['fullName']?.toString().trim() ??
        json['name']?.toString().trim() ??
        (combined.isNotEmpty ? combined : '');
    return PatientAccessPatientSummary(
      id: json['id']?.toString() ?? '',
      patientId:
          json['patientId']?.toString() ??
          json['hospitalId']?.toString() ??
          json['cardNo']?.toString() ??
          '',
      displayName: name.isNotEmpty ? name : (json['id']?.toString() ?? ''),
    );
  }
}

/// A registered patient-app device row.
class PatientDeviceRow {
  const PatientDeviceRow({
    required this.id,
    required this.deviceLabel,
    required this.platform,
    required this.status,
    required this.createdAt,
    this.patient,
  });

  final String id;
  final String deviceLabel;
  final String platform;
  final String status;
  final DateTime? createdAt;
  final PatientAccessPatientSummary? patient;

  bool get isPending => status.toUpperCase() == 'PENDING';
  bool get isApproved => status.toUpperCase() == 'APPROVED';

  factory PatientDeviceRow.fromJson(Map<String, dynamic> json) {
    PatientAccessPatientSummary? patient;
    final rawPatient = json['patient'];
    if (rawPatient is Map) {
      patient = PatientAccessPatientSummary.fromJson(
        Map<String, dynamic>.from(rawPatient),
      );
    } else if (json['patientUuid'] != null ||
        json['patientName'] != null ||
        json['hospitalPatientId'] != null) {
      patient = PatientAccessPatientSummary(
        id: json['patientUuid']?.toString() ?? '',
        patientId: json['hospitalPatientId']?.toString() ??
            json['patientHospitalId']?.toString() ??
            '',
        displayName: json['patientName']?.toString() ?? '',
      );
    }

    return PatientDeviceRow(
      id: json['id']?.toString() ?? '',
      deviceLabel:
          json['deviceLabel']?.toString() ??
          json['label']?.toString() ??
          json['deviceName']?.toString() ??
          'Device',
      platform: json['platform']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: _parseDate(json['createdAt']),
      patient: patient,
    );
  }
}

/// Paginated device list from `GET /frontdesk/patient-devices`.
class PatientDevicePage {
  const PatientDevicePage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
  });

  final List<PatientDeviceRow> items;
  final int page;
  final int limit;
  final int total;

  bool get hasMore => page * limit < total;

  factory PatientDevicePage.fromJson(Map<String, dynamic> json) {
    final list = _extractList(json);
    final meta = json['meta'] is Map
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : json;
    return PatientDevicePage(
      items: list
          .whereType<Map>()
          .map((e) => PatientDeviceRow.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      page: _asInt(meta['page'] ?? json['page'], fallback: 1),
      limit: _asInt(meta['limit'] ?? json['limit'], fallback: 20),
      total: _asInt(
        meta['total'] ?? json['total'] ?? meta['totalCount'] ?? json['count'],
        fallback: list.length,
      ),
    );
  }
}

/// A linked child patient under a parent.
class FamilyChildRow {
  const FamilyChildRow({
    required this.id,
    required this.patientId,
    required this.displayName,
  });

  /// Child patient UUID.
  final String id;
  final String patientId;
  final String displayName;

  factory FamilyChildRow.fromJson(Map<String, dynamic> json) {
    // Prefer nested patient object when present.
    final nested = json['child'] ?? json['patient'] ?? json['childPatient'];
    if (nested is Map) {
      final summary = PatientAccessPatientSummary.fromJson(
        Map<String, dynamic>.from(nested),
      );
      return FamilyChildRow(
        id: summary.id.isNotEmpty
            ? summary.id
            : (json['childPatientId']?.toString() ??
                  json['childId']?.toString() ??
                  ''),
        patientId: summary.patientId,
        displayName: summary.displayName,
      );
    }

    final first = json['firstName']?.toString().trim() ?? '';
    final last = json['lastName']?.toString().trim() ?? '';
    final combined = '$first $last'.trim();
    final name =
        json['displayName']?.toString().trim() ??
        json['fullName']?.toString().trim() ??
        json['name']?.toString().trim() ??
        (combined.isNotEmpty ? combined : '');

    return FamilyChildRow(
      id: json['id']?.toString() ??
          json['childPatientId']?.toString() ??
          json['childId']?.toString() ??
          '',
      patientId:
          json['patientId']?.toString() ??
          json['hospitalId']?.toString() ??
          '',
      displayName: name.isNotEmpty ? name : (json['id']?.toString() ?? ''),
    );
  }
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

List<dynamic> _extractList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    for (final key in ['data', 'items', 'rows', 'results', 'devices', 'children']) {
      final v = map[key];
      if (v is List) return v;
    }
  }
  return const [];
}

/// Unwraps `{ data: ... }` envelopes used by some backend handlers.
/// Only unwraps when `data` is the sole key so pagination siblings are kept.
dynamic unwrapPatientAccessPayload(dynamic data) {
  if (data is Map) {
    final map = Map<String, dynamic>.from(data);
    if (map.length == 1 && map.containsKey('data')) {
      return map['data'];
    }
  }
  return data;
}

Map<String, dynamic> patientAccessAsMap(dynamic data) {
  final raw = unwrapPatientAccessPayload(data);
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) return Map<String, dynamic>.from(raw);
  return <String, dynamic>{};
}

List<dynamic> patientAccessAsList(dynamic data) {
  final raw = unwrapPatientAccessPayload(data);
  return _extractList(raw);
}
