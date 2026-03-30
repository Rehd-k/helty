// ignore_for_file: public_member_api_docs

/// Mirrors API responses for `/appointments` (list + nested relations when included).
class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    this.doctorId,
    required this.patientFirstName,
    required this.patientLastName,
    this.doctorFirstName,
    this.doctorLastName,
    required this.appointmentDate,
    required this.status,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String patientId;
  final String? doctorId;

  /// Patient name (from nested `patient` or flat legacy fields).
  final String patientFirstName;
  final String patientLastName;

  /// Optional doctor display (from nested `doctor` / `staff`).
  final String? doctorFirstName;
  final String? doctorLastName;

  final DateTime appointmentDate;
  final String status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Backwards-compatible aliases for older UI code.
  String get firstName => patientFirstName;
  String get lastName => patientLastName;

  String get patientDisplayName {
    final t = '${patientFirstName.trim()} ${patientLastName.trim()}'.trim();
    return t.isEmpty ? '—' : t;
  }

  String get doctorDisplayName {
    final f = doctorFirstName?.trim() ?? '';
    final l = doctorLastName?.trim() ?? '';
    if (f.isEmpty && l.isEmpty) return '—';
    return 'Dr. ${f.isEmpty ? '' : '$f '}$l'.trim();
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'];
    String pf = '';
    String pl = '';
    if (patient is Map) {
      final m = Map<String, dynamic>.from(patient);
      pf = (m['firstName'] ?? '').toString();
      pl = (m['surname'] ?? m['lastName'] ?? '').toString();
    }
    if (pf.isEmpty) pf = (json['firstName'] ?? '').toString();
    if (pl.isEmpty) pl = (json['lastName'] ?? json['surname'] ?? '').toString();

    final doctor = json['doctor'] ?? json['staff'];
    String? df;
    String? dl;
    if (doctor is Map) {
      final m = Map<String, dynamic>.from(doctor);
      df = m['firstName']?.toString();
      dl = m['lastName']?.toString();
    }

    final pid = json['patientId']?.toString() ?? '';
    final did = json['doctorId']?.toString() ?? json['staffId']?.toString();

    final dateRaw =
        json['appointmentDate'] ?? json['date'] ?? json['startTime'] ?? json['scheduledAt'];
    final parsed = dateRaw != null ? DateTime.tryParse(dateRaw.toString()) : null;

    return Appointment(
      id: json['id']?.toString() ?? '',
      patientId: pid,
      doctorId: did,
      patientFirstName: pf,
      patientLastName: pl,
      doctorFirstName: df,
      doctorLastName: dl,
      appointmentDate: parsed ?? DateTime.fromMillisecondsSinceEpoch(0),
      status: (json['status'] ?? 'UNKNOWN').toString(),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        if (doctorId != null) 'doctorId': doctorId,
        'firstName': patientFirstName,
        'lastName': patientLastName,
        'appointmentDate': appointmentDate.toUtc().toIso8601String(),
        'status': status,
        if (notes != null) 'notes': notes,
        if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
      };
}
