// ignore_for_file: constant_identifier_names

import 'package:helty/src/core/utils/api_decimal.dart';
import 'package:helty/src/core/utils/patient_display_name.dart';
import 'package:helty/src/core/utils/patient_initials.dart';

enum SurgeryRequestStatus {
  requested,
  scheduled,
  inProgress,
  completed,
  billed,
  cancelled;

  String get apiValue {
    switch (this) {
      case SurgeryRequestStatus.requested:
        return 'REQUESTED';
      case SurgeryRequestStatus.scheduled:
        return 'SCHEDULED';
      case SurgeryRequestStatus.inProgress:
        return 'IN_PROGRESS';
      case SurgeryRequestStatus.completed:
        return 'COMPLETED';
      case SurgeryRequestStatus.billed:
        return 'BILLED';
      case SurgeryRequestStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static SurgeryRequestStatus? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toUpperCase().replaceAll(' ', '_');
    for (final e in SurgeryRequestStatus.values) {
      if (e.apiValue == v) return e;
    }
    return null;
  }

  String get displayLabel {
    switch (this) {
      case SurgeryRequestStatus.requested:
        return 'Requested';
      case SurgeryRequestStatus.scheduled:
        return 'Scheduled';
      case SurgeryRequestStatus.inProgress:
        return 'In progress';
      case SurgeryRequestStatus.completed:
        return 'Completed';
      case SurgeryRequestStatus.billed:
        return 'Billed';
      case SurgeryRequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}

enum SurgeryPriority {
  routine,
  urgent,
  emergency;

  String get apiValue {
    switch (this) {
      case SurgeryPriority.routine:
        return 'ROUTINE';
      case SurgeryPriority.urgent:
        return 'URGENT';
      case SurgeryPriority.emergency:
        return 'EMERGENCY';
    }
  }

  static SurgeryPriority? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toUpperCase();
    for (final e in SurgeryPriority.values) {
      if (e.apiValue == v) return e;
    }
    return null;
  }

  String get displayLabel {
    switch (this) {
      case SurgeryPriority.routine:
        return 'Routine';
      case SurgeryPriority.urgent:
        return 'Urgent';
      case SurgeryPriority.emergency:
        return 'Emergency';
    }
  }
}

enum TheatreTeamRole {
  surgeon,
  assistant,
  scrub,
  circulating,
  anaesthetist;

  String get apiValue {
    switch (this) {
      case TheatreTeamRole.surgeon:
        return 'SURGEON';
      case TheatreTeamRole.assistant:
        return 'ASSISTANT';
      case TheatreTeamRole.scrub:
        return 'SCRUB';
      case TheatreTeamRole.circulating:
        return 'CIRCULATING';
      case TheatreTeamRole.anaesthetist:
        return 'ANAESTHETIST';
    }
  }

  static TheatreTeamRole? fromString(String? value) {
    if (value == null || value.isEmpty) return null;
    final v = value.toUpperCase();
    for (final e in TheatreTeamRole.values) {
      if (e.apiValue == v) return e;
    }
    return null;
  }

  String get displayLabel {
    switch (this) {
      case TheatreTeamRole.surgeon:
        return 'Surgeon';
      case TheatreTeamRole.assistant:
        return 'Assistant';
      case TheatreTeamRole.scrub:
        return 'Scrub';
      case TheatreTeamRole.circulating:
        return 'Circulating';
      case TheatreTeamRole.anaesthetist:
        return 'Anaesthetist';
    }
  }
}

class TheatrePatientRef {
  const TheatrePatientRef({
    required this.id,
    this.patientId,
    this.title,
    this.firstName,
    this.otherName,
    this.surname,
    this.avatarUrl,
  });

  final String id;
  final String? patientId;
  final String? title;
  final String? firstName;
  final String? otherName;
  final String? surname;
  final String? avatarUrl;

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

  factory TheatrePatientRef.fromJson(Map<String, dynamic> json) {
    return TheatrePatientRef(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString(),
      title: json['title']?.toString(),
      firstName: json['firstName']?.toString(),
      otherName: json['otherName']?.toString(),
      surname: (json['surname'] ?? json['lastName'])?.toString(),
      avatarUrl: avatarUrlFromJson(json),
    );
  }
}

class TheatreStaffRef {
  const TheatreStaffRef({
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

  factory TheatreStaffRef.fromJson(Map<String, dynamic> json) {
    return TheatreStaffRef(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      surname: json['surname']?.toString(),
    );
  }
}

class TheatreServiceRef {
  const TheatreServiceRef({
    required this.id,
    this.name,
  });

  final String id;
  final String? name;

  factory TheatreServiceRef.fromJson(Map<String, dynamic> json) {
    return TheatreServiceRef(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
    );
  }
}

class TheatreRoomRef {
  const TheatreRoomRef({
    required this.id,
    this.name,
    this.isActive,
  });

  final String id;
  final String? name;
  final bool? isActive;

  factory TheatreRoomRef.fromJson(Map<String, dynamic> json) {
    return TheatreRoomRef(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
      isActive: json['isActive'] is bool ? json['isActive'] as bool : null,
    );
  }
}

class TheatreTeamMember {
  const TheatreTeamMember({
    required this.staffId,
    required this.role,
    this.staff,
  });

  final String staffId;
  final TheatreTeamRole role;
  final TheatreStaffRef? staff;

  Map<String, dynamic> toJson() => {
    'staffId': staffId,
    'role': role.apiValue,
  };

  factory TheatreTeamMember.fromJson(Map<String, dynamic> json) {
    return TheatreTeamMember(
      staffId: json['staffId']?.toString() ?? '',
      role:
          TheatreTeamRole.fromString(json['role']?.toString()) ??
          TheatreTeamRole.surgeon,
      staff: json['staff'] is Map
          ? TheatreStaffRef.fromJson(
              Map<String, dynamic>.from(json['staff'] as Map),
            )
          : null,
    );
  }
}

class TheatreConsumableRef {
  const TheatreConsumableRef({
    required this.id,
    this.name,
  });

  final String id;
  final String? name;

  factory TheatreConsumableRef.fromJson(Map<String, dynamic> json) {
    return TheatreConsumableRef(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString(),
    );
  }
}

class TheatreCaseConsumable {
  const TheatreCaseConsumable({
    required this.id,
    required this.consumableId,
    required this.storeLocationId,
    required this.quantity,
    required this.unitPrice,
    this.billable = true,
    this.invoiceId,
    this.invoiceItemId,
    this.createdAt,
    this.consumable,
  });

  final String id;
  final String consumableId;
  final String storeLocationId;
  final int quantity;
  final double unitPrice;
  final bool billable;
  final String? invoiceId;
  final String? invoiceItemId;
  final DateTime? createdAt;
  final TheatreConsumableRef? consumable;

  factory TheatreCaseConsumable.fromJson(Map<String, dynamic> json) {
    return TheatreCaseConsumable(
      id: json['id']?.toString() ?? '',
      consumableId: json['consumableId']?.toString() ?? '',
      storeLocationId: json['storeLocationId']?.toString() ?? '',
      quantity: _toInt(json['quantity'], 1),
      unitPrice: _toDouble(json['unitPrice']),
      billable: json['billable'] is bool ? json['billable'] as bool : true,
      invoiceId: json['invoiceId']?.toString(),
      invoiceItemId: json['invoiceItemId']?.toString(),
      createdAt: _parseDate(json['createdAt']),
      consumable: json['consumable'] is Map
          ? TheatreConsumableRef.fromJson(
              Map<String, dynamic>.from(json['consumable'] as Map),
            )
          : null,
    );
  }
}

class TheatreCase {
  const TheatreCase({
    required this.id,
    this.surgeryRequestId,
    this.findings,
    this.complications,
    this.operativeNotes,
    this.performedById,
    this.performedBy,
    this.team = const [],
    this.consumables = const [],
    this.startedAt,
    this.endedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? surgeryRequestId;
  final String? findings;
  final String? complications;
  final String? operativeNotes;
  final String? performedById;
  final TheatreStaffRef? performedBy;
  final List<TheatreTeamMember> team;
  final List<TheatreCaseConsumable> consumables;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TheatreCase.fromJson(Map<String, dynamic> json) {
    final rawTeam = json['team'];
    final rawConsumables = json['consumables'];
    return TheatreCase(
      id: json['id']?.toString() ?? '',
      surgeryRequestId: json['surgeryRequestId']?.toString(),
      findings: json['findings']?.toString(),
      complications: json['complications']?.toString(),
      operativeNotes: json['operativeNotes']?.toString(),
      performedById: json['performedById']?.toString(),
      performedBy: json['performedBy'] is Map
          ? TheatreStaffRef.fromJson(
              Map<String, dynamic>.from(json['performedBy'] as Map),
            )
          : null,
      team: rawTeam is List
          ? rawTeam
              .whereType<Map>()
              .map(
                (e) => TheatreTeamMember.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
      consumables: rawConsumables is List
          ? rawConsumables
              .whereType<Map>()
              .map(
                (e) => TheatreCaseConsumable.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
      startedAt: _parseDate(json['startedAt']),
      endedAt: _parseDate(json['endedAt']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

class TheatreSchedule {
  const TheatreSchedule({
    required this.id,
    required this.surgeryRequestId,
    required this.theatreRoomId,
    this.scheduledAt,
    this.estimatedDurationMins,
    this.surgeonId,
    this.anaesthetistId,
    this.scrubNurseId,
    this.theatreRoom,
    this.surgeon,
    this.anaesthetist,
    this.scrubNurse,
    this.surgeryRequest,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String surgeryRequestId;
  final String theatreRoomId;
  final DateTime? scheduledAt;
  final int? estimatedDurationMins;
  final String? surgeonId;
  final String? anaesthetistId;
  final String? scrubNurseId;
  final TheatreRoomRef? theatreRoom;
  final TheatreStaffRef? surgeon;
  final TheatreStaffRef? anaesthetist;
  final TheatreStaffRef? scrubNurse;
  final SurgeryRequest? surgeryRequest;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TheatreSchedule.fromJson(Map<String, dynamic> json) {
    return TheatreSchedule(
      id: json['id']?.toString() ?? '',
      surgeryRequestId: json['surgeryRequestId']?.toString() ?? '',
      theatreRoomId: json['theatreRoomId']?.toString() ?? '',
      scheduledAt: _parseDate(json['scheduledAt']),
      estimatedDurationMins: json['estimatedDurationMins'] is int
          ? json['estimatedDurationMins'] as int
          : int.tryParse(json['estimatedDurationMins']?.toString() ?? ''),
      surgeonId: json['surgeonId']?.toString(),
      anaesthetistId: json['anaesthetistId']?.toString(),
      scrubNurseId: json['scrubNurseId']?.toString(),
      theatreRoom: json['theatreRoom'] is Map
          ? TheatreRoomRef.fromJson(
              Map<String, dynamic>.from(json['theatreRoom'] as Map),
            )
          : null,
      surgeon: json['surgeon'] is Map
          ? TheatreStaffRef.fromJson(
              Map<String, dynamic>.from(json['surgeon'] as Map),
            )
          : null,
      anaesthetist: json['anaesthetist'] is Map
          ? TheatreStaffRef.fromJson(
              Map<String, dynamic>.from(json['anaesthetist'] as Map),
            )
          : null,
      scrubNurse: json['scrubNurse'] is Map
          ? TheatreStaffRef.fromJson(
              Map<String, dynamic>.from(json['scrubNurse'] as Map),
            )
          : null,
      surgeryRequest: json['surgeryRequest'] is Map
          ? SurgeryRequest.fromJson(
              Map<String, dynamic>.from(json['surgeryRequest'] as Map),
            )
          : null,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

class TheatreRoom {
  const TheatreRoom({
    required this.id,
    required this.name,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory TheatreRoom.fromJson(Map<String, dynamic> json) {
    return TheatreRoom(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      isActive: json['isActive'] is bool ? json['isActive'] as bool : true,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

class SurgeryRequest {
  const SurgeryRequest({
    required this.id,
    required this.encounterId,
    required this.patientId,
    required this.status,
    this.requestedById,
    this.serviceId,
    this.admissionId,
    this.priority,
    this.clinicalNotes,
    this.preferredDate,
    this.invoiceId,
    this.invoiceItemId,
    this.patient,
    this.service,
    this.requestedBy,
    this.schedule,
    this.theatreCase,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String encounterId;
  final String patientId;
  final SurgeryRequestStatus status;
  final String? requestedById;
  final String? serviceId;
  final String? admissionId;
  final SurgeryPriority? priority;
  final String? clinicalNotes;
  final DateTime? preferredDate;
  final String? invoiceId;
  final String? invoiceItemId;
  final TheatrePatientRef? patient;
  final TheatreServiceRef? service;
  final TheatreStaffRef? requestedBy;
  final TheatreSchedule? schedule;
  final TheatreCase? theatreCase;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory SurgeryRequest.fromJson(Map<String, dynamic> json) {
    return SurgeryRequest(
      id: json['id']?.toString() ?? '',
      encounterId: json['encounterId']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      status:
          SurgeryRequestStatus.fromString(json['status']?.toString()) ??
          SurgeryRequestStatus.requested,
      requestedById: json['requestedById']?.toString(),
      serviceId: json['serviceId']?.toString(),
      admissionId: json['admissionId']?.toString(),
      priority: SurgeryPriority.fromString(json['priority']?.toString()),
      clinicalNotes: json['clinicalNotes']?.toString(),
      preferredDate: _parseDate(json['preferredDate']),
      invoiceId: json['invoiceId']?.toString(),
      invoiceItemId: json['invoiceItemId']?.toString(),
      patient: json['patient'] is Map
          ? TheatrePatientRef.fromJson(
              Map<String, dynamic>.from(json['patient'] as Map),
            )
          : null,
      service: json['service'] is Map
          ? TheatreServiceRef.fromJson(
              Map<String, dynamic>.from(json['service'] as Map),
            )
          : null,
      requestedBy: json['requestedBy'] is Map
          ? TheatreStaffRef.fromJson(
              Map<String, dynamic>.from(json['requestedBy'] as Map),
            )
          : null,
      schedule: json['schedule'] is Map
          ? TheatreSchedule.fromJson(
              Map<String, dynamic>.from(json['schedule'] as Map),
            )
          : null,
      theatreCase: json['case'] is Map
          ? TheatreCase.fromJson(Map<String, dynamic>.from(json['case'] as Map))
          : json['theatreCase'] is Map
          ? TheatreCase.fromJson(
              Map<String, dynamic>.from(json['theatreCase'] as Map),
            )
          : null,
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }
}

class SurgeryRequestsResponse {
  const SurgeryRequestsResponse({
    required this.requests,
    required this.total,
  });

  final List<SurgeryRequest> requests;
  final int total;

  factory SurgeryRequestsResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['requests'] ?? json['data'] ?? json['items'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (e) => SurgeryRequest.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList()
        : <SurgeryRequest>[];
    return SurgeryRequestsResponse(
      requests: list,
      total: _toInt(json['total'], list.length),
    );
  }
}

class TheatreSchedulesResponse {
  const TheatreSchedulesResponse({
    required this.schedules,
    required this.total,
  });

  final List<TheatreSchedule> schedules;
  final int total;

  factory TheatreSchedulesResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['schedules'] ?? json['data'] ?? json['items'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (e) => TheatreSchedule.fromJson(Map<String, dynamic>.from(e)),
            )
            .toList()
        : <TheatreSchedule>[];
    return TheatreSchedulesResponse(
      schedules: list,
      total: _toInt(json['total'], list.length),
    );
  }
}

class TheatreRoomsResponse {
  const TheatreRoomsResponse({
    required this.rooms,
    required this.total,
  });

  final List<TheatreRoom> rooms;
  final int total;

  factory TheatreRoomsResponse.fromJson(dynamic json) {
    if (json is List) {
      final list = json
          .whereType<Map>()
          .map((e) => TheatreRoom.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return TheatreRoomsResponse(rooms: list, total: list.length);
    }
    if (json is Map<String, dynamic>) {
      final raw = json['rooms'] ?? json['data'] ?? json['items'];
      if (raw is List) {
        final list = raw
            .whereType<Map>()
            .map((e) => TheatreRoom.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        return TheatreRoomsResponse(
          rooms: list,
          total: _toInt(json['total'], list.length),
        );
      }
    }
    return const TheatreRoomsResponse(rooms: [], total: 0);
  }
}

/// Category names accepted for surgery service picker (per API spec).
const kSurgeryServiceCategoryNames = {
  'Surgical Procedures',
  'General Procedures',
  'Cardiology Procedures',
  'Orthopaedics',
  'Therapy & Rehabilitation',
  'Physiotherapy',
};

bool isSurgeryServiceCategoryName(String name) {
  final normalized = name.trim();
  for (final c in kSurgeryServiceCategoryNames) {
    if (c.toLowerCase() == normalized.toLowerCase()) return true;
  }
  return false;
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
