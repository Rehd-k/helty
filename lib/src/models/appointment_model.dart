class Appointment {
  final String id;
  final String patientId;
  final String patientName;
  final DateTime date;
  final String status;
  final String? notes;

  Appointment({
    required this.id,
    required this.patientId,
    required this.patientName,
    required this.date,
    required this.status,
    this.notes,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['id'] as String,
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'patientName': patientName,
    'date': date.toIso8601String(),
    'status': status,
    'notes': notes,
  };
}
