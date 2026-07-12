enum FrontdeskFeedbackKind { complaint, suggestion, general }

enum FrontdeskFeedbackStatus { open, inReview, resolved, closed }

extension FrontdeskFeedbackKindDisplay on FrontdeskFeedbackKind {
  String get label => switch (this) {
    FrontdeskFeedbackKind.complaint => 'Complaint',
    FrontdeskFeedbackKind.suggestion => 'Suggestion',
    FrontdeskFeedbackKind.general => 'General feedback',
  };

  String get apiValue => switch (this) {
    FrontdeskFeedbackKind.complaint => 'COMPLAINT',
    FrontdeskFeedbackKind.suggestion => 'SUGGESTION',
    FrontdeskFeedbackKind.general => 'GENERAL',
  };
}

extension FrontdeskFeedbackStatusDisplay on FrontdeskFeedbackStatus {
  String get label => switch (this) {
    FrontdeskFeedbackStatus.open => 'Open',
    FrontdeskFeedbackStatus.inReview => 'In review',
    FrontdeskFeedbackStatus.resolved => 'Resolved',
    FrontdeskFeedbackStatus.closed => 'Closed',
  };

  String get apiValue => switch (this) {
    FrontdeskFeedbackStatus.open => 'OPEN',
    FrontdeskFeedbackStatus.inReview => 'IN_REVIEW',
    FrontdeskFeedbackStatus.resolved => 'RESOLVED',
    FrontdeskFeedbackStatus.closed => 'CLOSED',
  };
}

FrontdeskFeedbackKind _kindFromApi(String? value) {
  return switch (value) {
    'COMPLAINT' => FrontdeskFeedbackKind.complaint,
    'SUGGESTION' => FrontdeskFeedbackKind.suggestion,
    _ => FrontdeskFeedbackKind.general,
  };
}

FrontdeskFeedbackStatus _statusFromApi(String? value) {
  return switch (value) {
    'IN_REVIEW' => FrontdeskFeedbackStatus.inReview,
    'RESOLVED' => FrontdeskFeedbackStatus.resolved,
    'CLOSED' => FrontdeskFeedbackStatus.closed,
    _ => FrontdeskFeedbackStatus.open,
  };
}

class FrontdeskFeedbackPatient {
  const FrontdeskFeedbackPatient({
    required this.id,
    required this.patientName,
    this.title,
    this.firstName,
    this.otherName,
    this.surname,
  });

  final String id;
  final String patientName;
  final String? title;
  final String? firstName;
  final String? otherName;
  final String? surname;

  factory FrontdeskFeedbackPatient.fromJson(Map<String, dynamic> json) {
    return FrontdeskFeedbackPatient(
      id: json['id'] as String? ?? '',
      patientName: json['patientName'] as String? ?? 'Patient',
      title: json['title'] as String?,
      firstName: json['firstName'] as String?,
      otherName: json['otherName'] as String?,
      surname: json['surname'] as String?,
    );
  }
}

class FrontdeskFeedbackDepartment {
  const FrontdeskFeedbackDepartment({required this.id, required this.name});

  final String id;
  final String name;

  factory FrontdeskFeedbackDepartment.fromJson(Map<String, dynamic> json) =>
      FrontdeskFeedbackDepartment(
        id: json['id'] as String,
        name: json['name'] as String,
      );
}

class FrontdeskFeedbackResponder {
  const FrontdeskFeedbackResponder({
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
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty);
    final name = parts.join(' ');
    return name.isEmpty ? 'Staff' : name;
  }

  factory FrontdeskFeedbackResponder.fromJson(Map<String, dynamic> json) =>
      FrontdeskFeedbackResponder(
        id: json['id'] as String? ?? '',
        firstName: json['firstName'] as String?,
        lastName: json['lastName'] as String?,
      );
}

class FrontdeskFeedbackItem {
  const FrontdeskFeedbackItem({
    required this.id,
    required this.kind,
    required this.status,
    required this.subject,
    required this.message,
    required this.patient,
    this.department,
    this.staffResponse,
    this.resolvedAt,
    this.respondedBy,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final FrontdeskFeedbackKind kind;
  final FrontdeskFeedbackStatus status;
  final String subject;
  final String message;
  final FrontdeskFeedbackPatient patient;
  final FrontdeskFeedbackDepartment? department;
  final String? staffResponse;
  final DateTime? resolvedAt;
  final FrontdeskFeedbackResponder? respondedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory FrontdeskFeedbackItem.fromJson(Map<String, dynamic> json) {
    final patientJson = json['patient'];
    final departmentJson = json['department'];
    final responderJson = json['respondedBy'];

    return FrontdeskFeedbackItem(
      id: json['id'] as String,
      kind: _kindFromApi(json['kind'] as String?),
      status: _statusFromApi(json['status'] as String?),
      subject: json['subject'] as String? ?? '',
      message: json['message'] as String? ?? '',
      patient: patientJson is Map<String, dynamic>
          ? FrontdeskFeedbackPatient.fromJson(patientJson)
          : const FrontdeskFeedbackPatient(id: '', patientName: 'Patient'),
      department: departmentJson is Map<String, dynamic>
          ? FrontdeskFeedbackDepartment.fromJson(departmentJson)
          : null,
      staffResponse: json['staffResponse'] as String?,
      resolvedAt: json['resolvedAt'] == null
          ? null
          : DateTime.parse(json['resolvedAt'] as String),
      respondedBy: responderJson is Map<String, dynamic>
          ? FrontdeskFeedbackResponder.fromJson(responderJson)
          : null,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class FrontdeskFeedbackListResponse {
  const FrontdeskFeedbackListResponse({
    required this.data,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<FrontdeskFeedbackItem> data;
  final int total;
  final int page;
  final int limit;

  factory FrontdeskFeedbackListResponse.fromJson(Map<String, dynamic> json) {
    final items = json['data'];
    return FrontdeskFeedbackListResponse(
      data: items is List
          ? items
                .whereType<Map>()
                .map(
                  (item) => FrontdeskFeedbackItem.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 20,
    );
  }
}
