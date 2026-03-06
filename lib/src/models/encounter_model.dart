/// Outpatient encounter (visit) linked to Patient and optional Appointment.
/// Optional documentation fields for History, Examination, and Notes tabs.
class EncounterModel {
  const EncounterModel({
    required this.id,
    required this.patientId,
    this.appointmentId,
    required this.doctorId,
    required this.status,
    required this.startedAt,
    this.closedAt,
    this.visitType,
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
    this.followUpDate,
    this.followUpInstructions,
    this.referral,
  });

  final String id;
  final String patientId;
  final String? appointmentId;
  final String doctorId;
  final String status;
  final DateTime startedAt;
  final DateTime? closedAt;
  final String? visitType;
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
  final String? followUpDate;
  final String? followUpInstructions;
  final String? referral;

  factory EncounterModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v != null) ? v.toString() : '';

    return EncounterModel(
      id: str(json['id']),
      patientId: str(json['patientId']),
      appointmentId: json['appointmentId']?.toString(),
      doctorId: str(json['doctorId']),
      status: (json['status']?.toString()) ?? 'open',
      startedAt: json['startedAt'] != null
          ? DateTime.tryParse(json['startedAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      closedAt: json['closedAt'] != null
          ? DateTime.tryParse(json['closedAt'].toString())
          : null,
      visitType: json['visitType'] as String?,
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
      followUpDate: json['followUpDate'] as String?,
      followUpInstructions: json['followUpInstructions'] as String?,
      referral: json['referral'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    if (appointmentId != null) 'appointmentId': appointmentId,
    'doctorId': doctorId,
    'status': status,
    'startedAt': startedAt.toIso8601String(),
    if (closedAt != null) 'closedAt': closedAt!.toIso8601String(),
    if (visitType != null) 'visitType': visitType,
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
    if (followUpDate != null) 'followUpDate': followUpDate,
    if (followUpInstructions != null)
      'followUpInstructions': followUpInstructions,
    if (referral != null) 'referral': referral,
  };

  EncounterModel copyWith({
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
    String? followUpDate,
    String? followUpInstructions,
    String? referral,
  }) {
    return EncounterModel(
      id: id,
      patientId: patientId,
      appointmentId: appointmentId,
      doctorId: doctorId,
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
      followUpDate: followUpDate ?? this.followUpDate,
      followUpInstructions: followUpInstructions ?? this.followUpInstructions,
      referral: referral ?? this.referral,
    );
  }
}
