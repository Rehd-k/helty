// ignore_for_file: constant_identifier_names

import 'package:helty/src/core/utils/api_decimal.dart';
import 'package:helty/src/core/utils/patient_display_name.dart';

import '../../providers/module_request_flow_provider.dart';

enum DialysisSessionStatus {
  pending,
  inProgress,
  completed,
  cancelled;

  String get apiValue {
    switch (this) {
      case DialysisSessionStatus.pending:
        return 'PENDING';
      case DialysisSessionStatus.inProgress:
        return 'IN_PROGRESS';
      case DialysisSessionStatus.completed:
        return 'COMPLETED';
      case DialysisSessionStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static DialysisSessionStatus? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toUpperCase().replaceAll(' ', '_');
    for (final e in DialysisSessionStatus.values) {
      if (e.apiValue == v) return e;
    }
    return null;
  }

  String get displayLabel {
    switch (this) {
      case DialysisSessionStatus.pending:
        return 'Pending';
      case DialysisSessionStatus.inProgress:
        return 'In progress';
      case DialysisSessionStatus.completed:
        return 'Completed';
      case DialysisSessionStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class DialysisPatientRef {
  const DialysisPatientRef({
    required this.id,
    this.patientId,
    this.title,
    this.firstName,
    this.otherName,
    this.surname,
  });

  final String id;
  final String? patientId;
  final String? title;
  final String? firstName;
  final String? otherName;
  final String? surname;

  String get displayName {
    final formatted = formatPatientDisplayNameOrNull(
      title: title,
      firstName: firstName,
      otherName: otherName,
      surname: surname,
    );
    if (formatted != null) return formatted;
    return patientId ?? id;
  }

  factory DialysisPatientRef.fromJson(Map<String, dynamic> json) {
    return DialysisPatientRef(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString(),
      title: json['title']?.toString(),
      firstName: json['firstName']?.toString(),
      otherName: json['otherName']?.toString(),
      surname: (json['surname'] ?? json['lastName'])?.toString(),
    );
  }
}

class DialysisStaffRef {
  const DialysisStaffRef({
    required this.id,
    this.firstName,
    this.surname,
  });

  final String id;
  final String? firstName;
  final String? surname;

  String get displayName {
    final f = firstName?.trim() ?? '';
    final s = surname?.trim() ?? '';
    if (f.isNotEmpty && s.isNotEmpty) return '$f $s';
    if (f.isNotEmpty) return f;
    if (s.isNotEmpty) return s;
    return id;
  }

  factory DialysisStaffRef.fromJson(Map<String, dynamic> json) {
    return DialysisStaffRef(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      surname: json['surname']?.toString(),
    );
  }
}

class DialysisServiceRef {
  const DialysisServiceRef({
    required this.id,
    this.name,
  });

  final String id;
  final String? name;

  factory DialysisServiceRef.fromJson(Map<String, dynamic> json) {
    return DialysisServiceRef(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
    );
  }
}

class DialysisConsumableRef {
  const DialysisConsumableRef({
    required this.id,
    this.name,
  });

  final String id;
  final String? name;

  factory DialysisConsumableRef.fromJson(Map<String, dynamic> json) {
    return DialysisConsumableRef(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
    );
  }
}

class DialysisSessionConsumable {
  const DialysisSessionConsumable({
    required this.id,
    required this.sessionId,
    required this.consumableId,
    required this.storeLocationId,
    required this.quantity,
    required this.unitPrice,
    this.invoiceId,
    this.invoiceItemId,
    this.createdAt,
    this.consumable,
  });

  final String id;
  final String sessionId;
  final String consumableId;
  final String storeLocationId;
  final int quantity;
  final double unitPrice;
  final String? invoiceId;
  final String? invoiceItemId;
  final DateTime? createdAt;
  final DialysisConsumableRef? consumable;

  factory DialysisSessionConsumable.fromJson(Map<String, dynamic> json) {
    return DialysisSessionConsumable(
      id: json['id']?.toString() ?? '',
      sessionId: json['sessionId']?.toString() ?? '',
      consumableId: json['consumableId']?.toString() ?? '',
      storeLocationId: json['storeLocationId']?.toString() ?? '',
      quantity: _toInt(json['quantity'], 1),
      unitPrice: _toDouble(json['unitPrice']),
      invoiceId: json['invoiceId']?.toString(),
      invoiceItemId: json['invoiceItemId']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      consumable: json['consumable'] is Map
          ? DialysisConsumableRef.fromJson(
              Map<String, dynamic>.from(json['consumable'] as Map),
            )
          : null,
    );
  }
}

class DialysisSession {
  const DialysisSession({
    required this.id,
    required this.patientId,
    required this.status,
    this.invoiceId,
    this.invoiceItemId,
    this.serviceId,
    this.doctorId,
    this.performedById,
    this.machineId,
    this.notes,
    this.startedAt,
    this.completedAt,
    this.createdAt,
    this.updatedAt,
    this.patient,
    this.doctor,
    this.service,
    this.consumables = const [],
  });

  final String id;
  final String patientId;
  final DialysisSessionStatus status;
  final String? invoiceId;
  final String? invoiceItemId;
  final String? serviceId;
  final String? doctorId;
  final String? performedById;
  final String? machineId;
  final String? notes;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DialysisPatientRef? patient;
  final DialysisStaffRef? doctor;
  final DialysisServiceRef? service;
  final List<DialysisSessionConsumable> consumables;

  factory DialysisSession.fromJson(Map<String, dynamic> json) {
    final rawConsumables = json['consumables'];
    return DialysisSession(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      status:
          DialysisSessionStatus.fromString(json['status']?.toString()) ??
          DialysisSessionStatus.pending,
      invoiceId: json['invoiceId']?.toString(),
      invoiceItemId: json['invoiceItemId']?.toString(),
      serviceId: json['serviceId']?.toString(),
      doctorId: json['doctorId']?.toString(),
      performedById: json['performedById']?.toString(),
      machineId: json['machineId']?.toString(),
      notes: json['notes']?.toString(),
      startedAt: _parseDate(json['startedAt']),
      completedAt: _parseDate(json['completedAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      patient: json['patient'] is Map
          ? DialysisPatientRef.fromJson(
              Map<String, dynamic>.from(json['patient'] as Map),
            )
          : null,
      doctor: json['doctor'] is Map
          ? DialysisStaffRef.fromJson(
              Map<String, dynamic>.from(json['doctor'] as Map),
            )
          : null,
      service: json['service'] is Map
          ? DialysisServiceRef.fromJson(
              Map<String, dynamic>.from(json['service'] as Map),
            )
          : null,
      consumables: rawConsumables is List
          ? rawConsumables
              .whereType<Map>()
              .map(
                (e) => DialysisSessionConsumable.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class DialysisSessionsResponse {
  const DialysisSessionsResponse({
    required this.sessions,
    required this.total,
  });

  final List<DialysisSession> sessions;
  final int total;

  factory DialysisSessionsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['sessions'] ?? json['data'] ?? json['items'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (e) => DialysisSession.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList()
        : <DialysisSession>[];
    return DialysisSessionsResponse(
      sessions: list,
      total: _toInt(json['total'], list.length),
    );
  }
}

int _toInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value == null) return fallback;
  return int.tryParse(value.toString()) ?? fallback;
}

double _toDouble(dynamic value) => parseApiDecimal(value);

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}

bool isDialysisCategoryName(String name) {
  final c = name.toLowerCase().trim();
  return c == 'dialysis' || c == 'dialysis services';
}

List<PaidInvoiceServiceLine> dialysisServiceLines(
  PaidModuleRequestContext? ctx,
) {
  if (ctx == null) return const [];
  return ctx.serviceLines
      .where((l) => isDialysisCategoryName(l.categoryName))
      .toList();
}
