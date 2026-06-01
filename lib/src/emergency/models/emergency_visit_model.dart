import 'package:helty/src/emergency/models/ed_enums.dart';
import 'package:helty/src/models/encounter_model.dart';

/// Assigned doctor summary on ED board rows.
class EdAssignedDoctor {
  const EdAssignedDoctor({
    required this.id,
    this.firstName,
    this.lastName,
  });

  final String id;
  final String? firstName;
  final String? lastName;

  String get displayName {
    final parts = <String>[
      if (firstName != null && firstName!.trim().isNotEmpty) firstName!.trim(),
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!.trim(),
    ];
    return parts.isEmpty ? id : parts.join(' ');
  }

  factory EdAssignedDoctor.fromJson(Map<String, dynamic> json) {
    return EdAssignedDoctor(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
    );
  }
}

/// ED queue row — wraps `EmergencyVisit` (PROPOSED) or maps from `Encounter`.
class EmergencyVisitModel {
  const EmergencyVisitModel({
    required this.id,
    required this.encounterId,
    required this.patientId,
    this.patientName,
    this.chiefComplaint,
    this.arrivalAt,
    this.arrivalMode = EdArrivalMode.walkIn,
    this.workflowStatus = EdWorkflowStatus.registered,
    this.esiLevel,
    this.assignedDoctor,
    this.assignedDoctorId,
    this.admissionId,
    this.triageCompletedAt,
    this.disposition,
    this.dispositionAt,
    this.dispositionNotes,
    this.transferDestination,
    this.waitMinutes,
    this.encounter,
  });

  final String id;
  final String encounterId;
  final String patientId;
  final String? patientName;
  final String? chiefComplaint;
  final DateTime? arrivalAt;
  final EdArrivalMode arrivalMode;
  final EdWorkflowStatus workflowStatus;
  final int? esiLevel;
  final EdAssignedDoctor? assignedDoctor;
  final String? assignedDoctorId;
  final String? admissionId;
  final DateTime? triageCompletedAt;
  final EdDisposition? disposition;
  final DateTime? dispositionAt;
  final String? dispositionNotes;
  final String? transferDestination;
  final int? waitMinutes;
  final EncounterModel? encounter;

  int get computedWaitMinutes {
    if (waitMinutes != null) return waitMinutes!;
    if (arrivalAt == null) return 0;
    return DateTime.now().difference(arrivalAt!).inMinutes;
  }

  factory EmergencyVisitModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    EdAssignedDoctor? doctor;
    final doctorRaw = json['assignedDoctor'];
    if (doctorRaw is Map) {
      doctor = EdAssignedDoctor.fromJson(Map<String, dynamic>.from(doctorRaw));
    }

    EncounterModel? enc;
    final encRaw = json['encounter'];
    if (encRaw is Map) {
      enc = EncounterModel.fromJson(Map<String, dynamic>.from(encRaw));
    }

    return EmergencyVisitModel(
      id: json['id']?.toString() ?? json['encounterId']?.toString() ?? '',
      encounterId: json['encounterId']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      patientName: json['patientName']?.toString(),
      chiefComplaint: json['chiefComplaint']?.toString(),
      arrivalAt: parseDt(json['arrivalAt']),
      arrivalMode: EdArrivalMode.fromString(json['arrivalMode']?.toString()),
      workflowStatus: EdWorkflowStatus.fromString(
        json['workflowStatus']?.toString(),
      ),
      esiLevel: () {
        final v = json['esiLevel'];
        if (v == null) return null;
        if (v is int) return v;
        return int.tryParse(v.toString());
      }(),
      assignedDoctor: doctor,
      assignedDoctorId: json['assignedDoctorId']?.toString() ?? doctor?.id,
      admissionId: json['admissionId']?.toString(),
      triageCompletedAt: parseDt(json['triageCompletedAt']),
      disposition: json['disposition'] != null
          ? EdDisposition.fromString(json['disposition']?.toString())
          : null,
      dispositionAt: parseDt(json['dispositionAt']),
      dispositionNotes: json['dispositionNotes']?.toString(),
      transferDestination: json['transferDestination']?.toString(),
      waitMinutes: () {
        final v = json['waitMinutes'];
        if (v == null) return null;
        if (v is int) return v;
        return int.tryParse(v.toString());
      }(),
      encounter: enc,
    );
  }

  /// Interim mapping from GET /encounters (no EmergencyVisit wrapper).
  factory EmergencyVisitModel.fromEncounter(
    EncounterModel enc, {
    String? patientName,
    int? esiLevel,
    EdWorkflowStatus? workflowStatus,
  }) {
    EdWorkflowStatus status = workflowStatus ?? EdWorkflowStatus.registered;
    if (enc.isCompleted) {
      status = enc.admissionId != null
          ? EdWorkflowStatus.admitted
          : EdWorkflowStatus.discharged;
    }

    return EmergencyVisitModel(
      id: enc.id,
      encounterId: enc.id,
      patientId: enc.patientId,
      patientName: patientName,
      chiefComplaint: enc.chiefComplaint,
      arrivalAt: enc.startedAt,
      workflowStatus: status,
      esiLevel: esiLevel,
      assignedDoctorId: enc.doctorId,
      admissionId: enc.admissionId,
      encounter: enc,
    );
  }

  EmergencyVisitModel copyWith({
    EdWorkflowStatus? workflowStatus,
    int? esiLevel,
    DateTime? triageCompletedAt,
    String? admissionId,
  }) {
    return EmergencyVisitModel(
      id: id,
      encounterId: encounterId,
      patientId: patientId,
      patientName: patientName,
      chiefComplaint: chiefComplaint,
      arrivalAt: arrivalAt,
      arrivalMode: arrivalMode,
      workflowStatus: workflowStatus ?? this.workflowStatus,
      esiLevel: esiLevel ?? this.esiLevel,
      assignedDoctor: assignedDoctor,
      assignedDoctorId: assignedDoctorId,
      admissionId: admissionId ?? this.admissionId,
      triageCompletedAt: triageCompletedAt ?? this.triageCompletedAt,
      disposition: disposition,
      dispositionAt: dispositionAt,
      dispositionNotes: dispositionNotes,
      transferDestination: transferDestination,
      waitMinutes: waitMinutes,
      encounter: encounter,
    );
  }
}

class EmergencyVisitListResult {
  const EmergencyVisitListResult({
    required this.visits,
    this.total = 0,
    this.skip = 0,
    this.take = 50,
  });

  final List<EmergencyVisitModel> visits;
  final int total;
  final int skip;
  final int take;
}

/// Result of registering a new ED visit.
class EmergencyRegisterResult {
  const EmergencyRegisterResult({
    required this.emergencyVisit,
    required this.encounter,
    this.reusedExistingEncounter = false,
  });

  final EmergencyVisitModel emergencyVisit;
  final EncounterModel encounter;

  /// True when interim `POST /encounters` returned 200 (ongoing EMERGENCY reused).
  final bool reusedExistingEncounter;
}

/// Payload for disposition submission.
class EdDispositionPayload {
  const EdDispositionPayload({
    required this.disposition,
    this.dispositionNotes,
    this.dischargeSummary,
    this.followUpInstructions,
    this.transferDestination,
  });

  final EdDisposition disposition;
  final String? dispositionNotes;
  final String? dischargeSummary;
  final String? followUpInstructions;
  final String? transferDestination;

  Map<String, dynamic> toJson() => {
    'disposition': disposition.apiValue,
    if (dispositionNotes != null && dispositionNotes!.isNotEmpty)
      'dispositionNotes': dispositionNotes,
    if (dischargeSummary != null && dischargeSummary!.isNotEmpty)
      'dischargeSummary': dischargeSummary,
    if (followUpInstructions != null && followUpInstructions!.isNotEmpty)
      'followUpInstructions': followUpInstructions,
    if (transferDestination != null && transferDestination!.isNotEmpty)
      'transferDestination': transferDestination,
  };
}

/// Payload for ED admit orchestration.
class EdAdmitPayload {
  const EdAdmitPayload({
    required this.wardId,
    required this.bedId,
    required this.attendingDoctorId,
    this.reason,
    this.primaryNurseId,
  });

  final String wardId;
  final String bedId;
  final String attendingDoctorId;
  final String? reason;
  final String? primaryNurseId;

  Map<String, dynamic> toJson() => {
    'wardId': wardId,
    'bedId': bedId,
    'attendingDoctorId': attendingDoctorId,
    if (reason != null && reason!.isNotEmpty) 'reason': reason,
    if (primaryNurseId != null && primaryNurseId!.isNotEmpty)
      'primaryNurseId': primaryNurseId,
  };
}
