enum EmergencyRequestStatus {
  submitted('SUBMITTED', 'Submitted'),
  acknowledged('ACKNOWLEDGED', 'Acknowledged'),
  dispatched('DISPATCHED', 'Dispatched'),
  closed('CLOSED', 'Closed'),
  cancelled('CANCELLED', 'Cancelled');

  const EmergencyRequestStatus(this.apiValue, this.label);
  final String apiValue;
  final String label;

  static EmergencyRequestStatus fromApi(String? value) {
    return EmergencyRequestStatus.values.firstWhere(
      (e) => e.apiValue == value,
      orElse: () => EmergencyRequestStatus.submitted,
    );
  }
}

class EmergencyRequestPatient {
  const EmergencyRequestPatient({
    required this.id,
    this.patientId,
    this.firstName,
    this.surname,
    this.otherName,
    this.phoneNumber,
    this.avatarUrl,
  });

  final String id;
  final String? patientId;
  final String? firstName;
  final String? surname;
  final String? otherName;
  final String? phoneNumber;
  final String? avatarUrl;

  String get displayName {
    final parts = [firstName, otherName, surname]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return patientId ?? id;
    return parts.join(' ');
  }

  factory EmergencyRequestPatient.fromJson(Map<String, dynamic> json) {
    return EmergencyRequestPatient(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String?,
      firstName: json['firstName'] as String?,
      surname: json['surname'] as String?,
      otherName: json['otherName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

class EmergencyRequestResponder {
  const EmergencyRequestResponder({
    required this.id,
    this.firstName,
    this.lastName,
  });

  final String id;
  final String? firstName;
  final String? lastName;

  String get displayName {
    final parts = [firstName, lastName]
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'ED staff' : parts.join(' ');
  }

  factory EmergencyRequestResponder.fromJson(Map<String, dynamic> json) {
    return EmergencyRequestResponder(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
    );
  }
}

class StaffEmergencyRequest {
  const StaffEmergencyRequest({
    required this.id,
    required this.status,
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.addressText,
    this.description,
    this.voiceUrl,
    this.videoUrl,
    this.staffNote,
    this.patient,
    this.respondedBy,
    this.acknowledgedAt,
    this.dispatchedAt,
    this.closedAt,
    this.cancelledAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final EmergencyRequestStatus status;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final String? addressText;
  final String? description;
  final String? voiceUrl;
  final String? videoUrl;
  final String? staffNote;
  final EmergencyRequestPatient? patient;
  final EmergencyRequestResponder? respondedBy;
  final DateTime? acknowledgedAt;
  final DateTime? dispatchedAt;
  final DateTime? closedAt;
  final DateTime? cancelledAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasVoice => voiceUrl != null && voiceUrl!.isNotEmpty;
  bool get hasVideo => videoUrl != null && videoUrl!.isNotEmpty;

  factory StaffEmergencyRequest.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return StaffEmergencyRequest(
      id: json['id'] as String? ?? '',
      status: EmergencyRequestStatus.fromApi(json['status'] as String?),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      accuracyMeters: (json['accuracyMeters'] as num?)?.toDouble(),
      addressText: json['addressText'] as String?,
      description: json['description'] as String?,
      voiceUrl: json['voiceUrl'] as String?,
      videoUrl: json['videoUrl'] as String?,
      staffNote: json['staffNote'] as String?,
      patient: json['patient'] is Map<String, dynamic>
          ? EmergencyRequestPatient.fromJson(
              json['patient'] as Map<String, dynamic>,
            )
          : null,
      respondedBy: json['respondedBy'] is Map<String, dynamic>
          ? EmergencyRequestResponder.fromJson(
              json['respondedBy'] as Map<String, dynamic>,
            )
          : null,
      acknowledgedAt: parseDate(json['acknowledgedAt']),
      dispatchedAt: parseDate(json['dispatchedAt']),
      closedAt: parseDate(json['closedAt']),
      cancelledAt: parseDate(json['cancelledAt']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
    );
  }
}

class StaffEmergencyRequestListResponse {
  const StaffEmergencyRequestListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<StaffEmergencyRequest> data;
  final int total;
  final int page;
  final int limit;

  factory StaffEmergencyRequestListResponse.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = json['data'];
    final list = raw is List
        ? raw
              .whereType<Map>()
              .map(
                (e) => StaffEmergencyRequest.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
        : <StaffEmergencyRequest>[];
    return StaffEmergencyRequestListResponse(
      data: list,
      total: (json['total'] as num?)?.toInt() ?? list.length,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
    );
  }
}
