import 'package:helty/src/models/appointment_model.dart';
import 'package:helty/src/models/clinical_specialty_models.dart';
import 'package:helty/src/models/encounter_edit_meta.dart';
import 'package:helty/src/models/staff_attribution.dart';

/// Nested admission summary on GET /encounters/:id.
class EncounterAdmissionSnapshot {
  const EncounterAdmissionSnapshot({
    required this.id,
    this.status,
  });

  final String id;
  final String? status;

  factory EncounterAdmissionSnapshot.fromJson(Map<String, dynamic> json) {
    return EncounterAdmissionSnapshot(
      id: json['id']?.toString() ?? '',
      status: json['status']?.toString(),
    );
  }
}

/// One row from `diagnoses[]` on GET /encounters/:id (when not duplicated on flat fields).
class EncounterDiagnosisSnapshot {
  const EncounterDiagnosisSnapshot({
    this.primaryIcdCode,
    this.primaryIcdDescription,
    this.secondaryDiagnosesJson,
  });

  final String? primaryIcdCode;
  final String? primaryIcdDescription;
  final String? secondaryDiagnosesJson;
}

/// Outpatient encounter (visit) linked to Patient and optional Appointment.
/// Optional documentation fields for History, Examination, and Notes tabs.
/// Follow-up may be stored as a linked [followUpAppointment] (Prisma) and/or
/// legacy flat fields on the encounter.
class EncounterModel {
  const EncounterModel({
    required this.id,
    required this.patientId,
    this.appointmentId,
    required this.doctorId,
    this.doctorDisplayName,
    required this.status,
    required this.startedAt,
    this.closedAt,
    this.visitType,
    this.encounterType,
    this.admissionId,
    this.triageNotes,
    this.insurance,
    this.chiefComplaint,
    this.hpi,
    this.pmh,
    this.surgicalHistory,
    this.drugHistory,
    this.allergyHistory,
    this.familyHistory,
    this.socialHistory,
    this.examinationNotes,
    this.soapSubjective,
    this.soapObjective,
    this.soapAssessment,
    this.soapPlan,
    this.soapLockedAt,
    this.primaryIcdCode,
    this.primaryIcdDescription,
    this.secondaryDiagnosesJson,
    this.proceduresJson,
    this.followUpAppointmentId,
    this.followUpAppointment,
    this.followUpDate,
    this.followUpInstructions,
    this.referral,
    this.visitAppointment,
    this.linkedDiagnoses = const [],
    this.specialtyModules,
    this.clinicalSections,
    this.editMeta,
    this.createdBy,
    this.updatedBy,
    this.admission,
  });

  final String id;
  final String patientId;
  final String? appointmentId;
  final String doctorId;
  final String? doctorDisplayName;
  final String status;
  final DateTime startedAt;
  final DateTime? closedAt;
  final String? visitType;
  final String? encounterType;
  final String? admissionId;
  final String? triageNotes;
  final String? insurance;
  // History tab
  final String? chiefComplaint;
  final String? hpi;
  final String? pmh;
  final String? surgicalHistory;
  final String? drugHistory;
  final String? allergyHistory;
  final String? familyHistory;
  final String? socialHistory;
  // Examination tab
  final String? examinationNotes;
  // Notes tab (SOAP)
  final String? soapSubjective;
  final String? soapObjective;
  final String? soapAssessment;
  final String? soapPlan;
  final DateTime? soapLockedAt;
  // Diagnosis tab
  final String? primaryIcdCode;
  final String? primaryIcdDescription;
  final String? secondaryDiagnosesJson;
  final String? proceduresJson;
  /// FK to `Appointment` used for scheduled follow-up (Prisma).
  final String? followUpAppointmentId;
  final Appointment? followUpAppointment;
  /// Legacy follow-up fields (may still be returned by older APIs).
  final String? followUpDate;
  final String? followUpInstructions;
  final String? referral;

  /// Booking that started this visit (`appointment` on GET /encounters/:id).
  final Appointment? visitAppointment;

  /// Rows from `diagnoses` when the API returns a list.
  final List<EncounterDiagnosisSnapshot> linkedDiagnoses;

  /// Present when `GET /encounters/:id?expand=specialtyModules` (or `expand=*`).
  final List<EncounterSpecialtyModuleModel>? specialtyModules;

  /// Present when `GET /encounters/:id?expand=clinicalSections` (or `expand=*`).
  final List<EncounterClinicalSectionRowModel>? clinicalSections;

  /// Post-completion edit metadata from GET /encounters/:id.
  final EncounterEditMeta? editMeta;

  /// Staff who created this encounter (nested `createdBy`).
  final EncounterEditHistoryStaff? createdBy;

  /// Last staff who updated clerking on this encounter.
  final EncounterEditHistoryStaff? updatedBy;

  /// Linked admission when expanded on GET /encounters/:id.
  final EncounterAdmissionSnapshot? admission;

  /// True when linked to an ACTIVE admission (shared inpatient chart).
  bool get isSharedInpatient =>
      editMeta?.isSharedInpatientEncounter == true;

  /// True when status is completed (API `COMPLETED` or legacy `done`).
  bool get isCompleted {
    final s = status.toUpperCase();
    return s == 'COMPLETED' || s == 'DONE';
  }

  /// True when this encounter is an emergency department visit.
  bool get isEmergency {
    final t = encounterType?.trim().toUpperCase();
    return t == 'EMERGENCY';
  }

  /// Treating clinician label for UI (nested doctor, flat name, or id fallback).
  String get doctorLabel {
    final name = doctorDisplayName?.trim();
    if (name != null && name.isNotEmpty) return 'Dr $name';
    if (doctorId.trim().isNotEmpty) return doctorId.trim();
    return '—';
  }

  factory EncounterModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v != null) ? v.toString() : '';

    DateTime? parseDt(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    // Prefer nested `doctor` / flat doctorName — never fall back to `createdBy`.
    String? doctorName;
    final doctorObj = json['doctor'];
    if (doctorObj is Map) {
      doctorName = formatStaffName(Map<String, dynamic>.from(doctorObj));
    }
    doctorName ??= () {
      final flat = json['doctorName']?.toString().trim();
      return (flat != null && flat.isNotEmpty) ? flat : null;
    }();
    final nestedDoctorId = doctorObj is Map
        ? (doctorObj['id'] ?? doctorObj['staffId'])?.toString()
        : null;
    final doctorId = str(json['doctorId']).isNotEmpty
        ? str(json['doctorId'])
        : str(nestedDoctorId);

    return EncounterModel(
      id: str(json['id']),
      patientId: str(json['patientId']),
      appointmentId: json['appointmentId']?.toString(),
      doctorId: doctorId,
      doctorDisplayName: doctorName,
      status: (json['status']?.toString()) ?? 'open',
      startedAt: parseDt(json['startedAt'] ?? json['startTime']) ??
          DateTime.now(),
      closedAt: parseDt(json['closedAt'] ?? json['endTime']),
      visitType: json['visitType'] as String?,
      encounterType: json['encounterType'] as String?,
      admissionId: json['admissionId']?.toString(),
      triageNotes: json['triageNotes'] as String?,
      insurance: json['insurance'] as String?,
      chiefComplaint: json['chiefComplaint'] as String?,
      hpi: json['hpi'] as String?,
      pmh: json['pmh'] as String?,
      surgicalHistory: json['surgicalHistory'] as String?,
      drugHistory: json['drugHistory'] as String?,
      allergyHistory: json['allergyHistory'] as String?,
      familyHistory: json['familyHistory'] as String?,
      socialHistory: json['socialHistory'] as String?,
      examinationNotes: json['examinationNotes'] as String?,
      soapSubjective: json['soapSubjective'] as String?,
      soapObjective: json['soapObjective'] as String?,
      soapAssessment: json['soapAssessment'] as String?,
      soapPlan: json['soapPlan'] as String?,
      soapLockedAt: json['soapLockedAt'] != null
          ? DateTime.tryParse(json['soapLockedAt'] as String)
          : null,
      primaryIcdCode: json['primaryIcdCode'] as String?,
      primaryIcdDescription: json['primaryIcdDescription'] as String?,
      secondaryDiagnosesJson: json['secondaryDiagnosesJson'] as String?,
      proceduresJson: json['proceduresJson'] as String?,
      followUpAppointmentId: json['followUpAppointmentId']?.toString(),
      followUpAppointment: _parseFollowUpAppointment(json['followUpAppointment']),
      followUpDate: json['followUpDate'] as String?,
      followUpInstructions: json['followUpInstructions'] as String?,
      referral: json['referral'] as String?,
      visitAppointment: json['appointment'] is Map
          ? Appointment.fromJson(
              Map<String, dynamic>.from(json['appointment'] as Map),
            )
          : null,
      linkedDiagnoses: _parseLinkedDiagnoses(json['diagnoses']),
      specialtyModules: _parseSpecialtyModules(json['specialtyModules']),
      clinicalSections: _parseClinicalSections(json['clinicalSections']),
      editMeta: json['editMeta'] is Map
          ? EncounterEditMeta.fromJson(
              Map<String, dynamic>.from(json['editMeta'] as Map),
            )
          : null,
      createdBy: json['createdBy'] is Map
          ? EncounterEditHistoryStaff.fromJson(
              Map<String, dynamic>.from(json['createdBy'] as Map),
            )
          : null,
      updatedBy: json['updatedBy'] is Map
          ? EncounterEditHistoryStaff.fromJson(
              Map<String, dynamic>.from(json['updatedBy'] as Map),
            )
          : null,
      admission: json['admission'] is Map
          ? EncounterAdmissionSnapshot.fromJson(
              Map<String, dynamic>.from(json['admission'] as Map),
            )
          : null,
    );
  }

  static List<EncounterSpecialtyModuleModel>? _parseSpecialtyModules(
    dynamic raw,
  ) {
    if (raw == null) return null;
    if (raw is! List<dynamic>) return null;
    final out = <EncounterSpecialtyModuleModel>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        out.add(EncounterSpecialtyModuleModel.fromJson(e));
      } else if (e is Map) {
        out.add(
          EncounterSpecialtyModuleModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        );
      }
    }
    return out;
  }

  static List<EncounterClinicalSectionRowModel>? _parseClinicalSections(
    dynamic raw,
  ) {
    if (raw == null) return null;
    if (raw is! List<dynamic>) return null;
    final out = <EncounterClinicalSectionRowModel>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        out.add(EncounterClinicalSectionRowModel.fromJson(e));
      } else if (e is Map) {
        out.add(
          EncounterClinicalSectionRowModel.fromJson(
            Map<String, dynamic>.from(e),
          ),
        );
      }
    }
    return out;
  }

  static List<EncounterDiagnosisSnapshot> _parseLinkedDiagnoses(dynamic raw) {
    if (raw is! List<dynamic>) return const [];
    final out = <EncounterDiagnosisSnapshot>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      out.add(
        EncounterDiagnosisSnapshot(
          primaryIcdCode: m['primaryIcdCode']?.toString(),
          primaryIcdDescription: m['primaryIcdDescription']?.toString(),
          secondaryDiagnosesJson: m['secondaryDiagnosesJson']?.toString(),
        ),
      );
    }
    return out;
  }

  static Appointment? _parseFollowUpAppointment(dynamic raw) {
    if (raw is Map) {
      return Appointment.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    if (appointmentId != null) 'appointmentId': appointmentId,
    'doctorId': doctorId,
    if (doctorDisplayName != null) 'doctorDisplayName': doctorDisplayName,
    'status': status,
    'startedAt': startedAt.toIso8601String(),
    if (closedAt != null) 'closedAt': closedAt!.toIso8601String(),
    if (visitType != null) 'visitType': visitType,
    if (encounterType != null) 'encounterType': encounterType,
    if (admissionId != null) 'admissionId': admissionId,
    if (triageNotes != null) 'triageNotes': triageNotes,
    if (insurance != null) 'insurance': insurance,
    if (chiefComplaint != null) 'chiefComplaint': chiefComplaint,
    if (hpi != null) 'hpi': hpi,
    if (pmh != null) 'pmh': pmh,
    if (surgicalHistory != null) 'surgicalHistory': surgicalHistory,
    if (drugHistory != null) 'drugHistory': drugHistory,
    if (allergyHistory != null) 'allergyHistory': allergyHistory,
    if (familyHistory != null) 'familyHistory': familyHistory,
    if (socialHistory != null) 'socialHistory': socialHistory,
    if (examinationNotes != null) 'examinationNotes': examinationNotes,
    if (soapSubjective != null) 'soapSubjective': soapSubjective,
    if (soapObjective != null) 'soapObjective': soapObjective,
    if (soapAssessment != null) 'soapAssessment': soapAssessment,
    if (soapPlan != null) 'soapPlan': soapPlan,
    if (soapLockedAt != null) 'soapLockedAt': soapLockedAt!.toIso8601String(),
    if (primaryIcdCode != null) 'primaryIcdCode': primaryIcdCode,
    if (primaryIcdDescription != null)
      'primaryIcdDescription': primaryIcdDescription,
    if (secondaryDiagnosesJson != null)
      'secondaryDiagnosesJson': secondaryDiagnosesJson,
    if (proceduresJson != null) 'proceduresJson': proceduresJson,
    if (followUpAppointmentId != null)
      'followUpAppointmentId': followUpAppointmentId,
    if (followUpDate != null) 'followUpDate': followUpDate,
    if (followUpInstructions != null)
      'followUpInstructions': followUpInstructions,
    if (referral != null) 'referral': referral,
  };

  EncounterModel copyWith({
    String? doctorDisplayName,
    String? chiefComplaint,
    String? hpi,
    String? pmh,
    String? surgicalHistory,
    String? drugHistory,
    String? allergyHistory,
    String? familyHistory,
    String? socialHistory,
    String? examinationNotes,
    String? soapSubjective,
    String? soapObjective,
    String? soapAssessment,
    String? soapPlan,
    DateTime? soapLockedAt,
    String? primaryIcdCode,
    String? primaryIcdDescription,
    String? secondaryDiagnosesJson,
    String? proceduresJson,
    String? followUpAppointmentId,
    Appointment? followUpAppointment,
    String? followUpDate,
    String? followUpInstructions,
    String? referral,
    Appointment? visitAppointment,
    List<EncounterDiagnosisSnapshot>? linkedDiagnoses,
    List<EncounterSpecialtyModuleModel>? specialtyModules,
    List<EncounterClinicalSectionRowModel>? clinicalSections,
    EncounterEditMeta? editMeta,
    EncounterEditHistoryStaff? createdBy,
    EncounterEditHistoryStaff? updatedBy,
    EncounterAdmissionSnapshot? admission,
  }) {
    return EncounterModel(
      id: id,
      patientId: patientId,
      appointmentId: appointmentId,
      doctorId: doctorId,
      doctorDisplayName: doctorDisplayName ?? this.doctorDisplayName,
      status: status,
      startedAt: startedAt,
      closedAt: closedAt,
      visitType: visitType,
      insurance: insurance,
      chiefComplaint: chiefComplaint ?? this.chiefComplaint,
      hpi: hpi ?? this.hpi,
      pmh: pmh ?? this.pmh,
      surgicalHistory: surgicalHistory ?? this.surgicalHistory,
      drugHistory: drugHistory ?? this.drugHistory,
      allergyHistory: allergyHistory ?? this.allergyHistory,
      familyHistory: familyHistory ?? this.familyHistory,
      socialHistory: socialHistory ?? this.socialHistory,
      examinationNotes: examinationNotes ?? this.examinationNotes,
      soapSubjective: soapSubjective ?? this.soapSubjective,
      soapObjective: soapObjective ?? this.soapObjective,
      soapAssessment: soapAssessment ?? this.soapAssessment,
      soapPlan: soapPlan ?? this.soapPlan,
      soapLockedAt: soapLockedAt ?? this.soapLockedAt,
      primaryIcdCode: primaryIcdCode ?? this.primaryIcdCode,
      primaryIcdDescription:
          primaryIcdDescription ?? this.primaryIcdDescription,
      secondaryDiagnosesJson:
          secondaryDiagnosesJson ?? this.secondaryDiagnosesJson,
      proceduresJson: proceduresJson ?? this.proceduresJson,
      followUpAppointmentId:
          followUpAppointmentId ?? this.followUpAppointmentId,
      followUpAppointment: followUpAppointment ?? this.followUpAppointment,
      followUpDate: followUpDate ?? this.followUpDate,
      followUpInstructions: followUpInstructions ?? this.followUpInstructions,
      referral: referral ?? this.referral,
      visitAppointment: visitAppointment ?? this.visitAppointment,
      linkedDiagnoses: linkedDiagnoses ?? this.linkedDiagnoses,
      specialtyModules: specialtyModules ?? this.specialtyModules,
      clinicalSections: clinicalSections ?? this.clinicalSections,
      editMeta: editMeta ?? this.editMeta,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      admission: admission ?? this.admission,
    );
  }
}

