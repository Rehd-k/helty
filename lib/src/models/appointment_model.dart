// ignore_for_file: public_member_api_docs

import 'package:helty/src/core/utils/patient_display_name.dart';

/// Mirrors `/appointments` API — aligns with Prisma `Appointment`:
/// id, patientId, date, status, notes?, referral?, createdAt, staffId?,
/// createdById, updatedById?, nested patient/staff/createdBy/updatedBy when included.
class Appointment {
  const Appointment({
    required this.id,
    required this.patientId,
    this.staffId,
    required this.patientFirstName,
    required this.patientLastName,
    this.patientTitle,
    this.patientOtherName,
    this.patientApiDisplayName,
    this.staffFirstName,
    this.staffLastName,
    required this.appointmentDate,
    required this.status,
    this.notes,
    this.referral,
    this.createdAt,
    this.updatedAt,
    this.createdById,
    this.updatedById,
    this.createdByFirstName,
    this.createdByLastName,
    this.updatedByFirstName,
    this.updatedByLastName,
  });

  final String id;
  final String patientId;

  /// Assigned clinician (Prisma `staffId`); optional.
  final String? staffId;

  /// Same as [staffId] — kept for older UI / API field names.
  String? get doctorId => staffId;

  /// Patient name (from nested `patient` or flat legacy fields).
  final String patientFirstName;
  final String patientLastName;
  final String? patientTitle;
  final String? patientOtherName;
  final String? patientApiDisplayName;

  /// Optional staff display (nested `staff` or legacy `doctor`).
  final String? staffFirstName;
  final String? staffLastName;

  final DateTime appointmentDate;
  final String status;
  final String? notes;
  final String? referral;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String? createdById;
  final String? updatedById;

  final String? createdByFirstName;
  final String? createdByLastName;
  final String? updatedByFirstName;
  final String? updatedByLastName;

  /// Backwards-compatible aliases for older UI code.
  String get firstName => patientFirstName;
  String get lastName => patientLastName;

  String get patientDisplayName {
    final preferred = preferPatientFormattedName(
      displayName: patientApiDisplayName,
    );
    if (preferred != null) return preferred;
    final formatted = formatPatientDisplayNameOrNull(
      title: patientTitle,
      firstName: patientFirstName,
      otherName: patientOtherName,
      surname: patientLastName,
    );
    return formatted ?? '—';
  }

  /// Doctor / staff column — prefers `staff`, falls back to `createdBy`.
  String get doctorDisplayName {
    final f = staffFirstName?.trim().isNotEmpty == true
        ? staffFirstName!.trim()
        : (createdByFirstName?.trim() ?? '');
    final l = staffLastName?.trim().isNotEmpty == true
        ? staffLastName!.trim()
        : (createdByLastName?.trim() ?? '');
    if (f.isEmpty && l.isEmpty) return '—';
    return 'Dr. ${f.isEmpty ? '' : '$f '}$l'.trim();
  }

  factory Appointment.fromJson(Map<String, dynamic> json) {
    final patient = json['patient'];
    String pf = '';
    String pl = '';
    String? pt;
    String? po;
    String? apiName;
    if (patient is Map) {
      final m = Map<String, dynamic>.from(patient);
      pf = (m['firstName'] ?? '').toString();
      pl = (m['surname'] ?? m['lastName'] ?? '').toString();
      pt = m['title']?.toString();
      po = m['otherName']?.toString();
      apiName = preferPatientFormattedName(
        patientName: m['patientName']?.toString(),
        name: m['name']?.toString(),
        displayName: m['displayName']?.toString(),
      );
    }
    if (pf.isEmpty) pf = (json['firstName'] ?? '').toString();
    if (pl.isEmpty) pl = (json['lastName'] ?? json['surname'] ?? '').toString();
    apiName ??= preferPatientFormattedName(
      patientName: json['patientName']?.toString(),
      displayName: json['displayName']?.toString(),
    );

    final staff = json['staff'] ?? json['doctor'];
    String? sf;
    String? sl;
    if (staff is Map) {
      final m = Map<String, dynamic>.from(staff);
      sf = m['firstName']?.toString();
      sl = m['lastName']?.toString();
    }

    final createdBy = json['createdBy'];
    String? cbf;
    String? cbl;
    if (createdBy is Map) {
      final m = Map<String, dynamic>.from(createdBy);
      cbf = m['firstName']?.toString();
      cbl = m['lastName']?.toString();
    }

    final updatedBy = json['updatedBy'];
    String? ubf;
    String? ubl;
    if (updatedBy is Map) {
      final m = Map<String, dynamic>.from(updatedBy);
      ubf = m['firstName']?.toString();
      ubl = m['lastName']?.toString();
    }

    final pid = json['patientId']?.toString() ?? '';
    final sid =
        json['staffId']?.toString() ?? json['doctorId']?.toString();

    final dateRaw = json['date'] ??
        json['appointmentDate'] ??
        json['startTime'] ??
        json['scheduledAt'];
    final parsed = dateRaw != null ? DateTime.tryParse(dateRaw.toString()) : null;

    return Appointment(
      id: json['id']?.toString() ?? '',
      patientId: pid,
      staffId: sid,
      patientFirstName: pf,
      patientLastName: pl,
      patientTitle: pt,
      patientOtherName: po,
      patientApiDisplayName: apiName,
      staffFirstName: sf,
      staffLastName: sl,
      appointmentDate: parsed ?? DateTime.fromMillisecondsSinceEpoch(0),
      status: (json['status'] ?? 'UNKNOWN').toString(),
      notes: json['notes'] as String?,
      referral: json['referral'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      createdById: json['createdById']?.toString(),
      updatedById: json['updatedById']?.toString(),
      createdByFirstName: cbf,
      createdByLastName: cbl,
      updatedByFirstName: ubf,
      updatedByLastName: ubl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'patientId': patientId,
        if (staffId != null) 'staffId': staffId,
        'firstName': patientFirstName,
        'lastName': patientLastName,
        'date': appointmentDate.toUtc().toIso8601String(),
        'appointmentDate': appointmentDate.toUtc().toIso8601String(),
        'status': status,
        if (notes != null) 'notes': notes,
        if (referral != null) 'referral': referral,
        if (createdAt != null) 'createdAt': createdAt!.toUtc().toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
        if (createdById != null) 'createdById': createdById,
        if (updatedById != null) 'updatedById': updatedById,
      };
}
