class TodaysPatient {
  final String id;
  final String patientId;
  final String firstName;
  final String lastName;
  final String linkDetails;
  final String status;
  final String? notes;
  final String? invoiceNo;
  final List<String>? services;
  final String? initiator;
  final String? scheme;
  final DateTime createdAt;

  TodaysPatient({
    required this.id,
    required this.patientId,
    required this.firstName,
    required this.lastName,
    required this.linkDetails,
    required this.invoiceNo,
    required this.services,
    required this.initiator,
    required this.scheme,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  factory TodaysPatient.fromJson(Map<String, dynamic> json) {
    return TodaysPatient(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      status: json['status'] as String,
      linkDetails: json['linkDetails'] as String,
      invoiceNo: json['invoiceNo'] as String?,
      services: json['services'] as List<String>?,
      initiator: json['initiator'] as String?,
      scheme: json['scheme'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'firstName': firstName,
    'lastName': lastName,
    'createdAt': createdAt.toIso8601String(),
    'linkDetails': linkDetails,
    'invoiceNo': invoiceNo,
    'status': status,
    'notes': notes,
    'services': services,
    'initiator': initiator,
    'scheme': scheme,
  };
}
