/// Edit metadata returned on GET /encounters/:id as `editMeta`.
class EncounterEditMeta {
  const EncounterEditMeta({
    this.hasEdits = false,
    this.editCount = 0,
    this.lastEditedAt,
    this.canEdit = false,
    this.requiresVersionedEdits = false,
  });

  final bool hasEdits;
  final int editCount;
  final DateTime? lastEditedAt;
  final bool canEdit;
  final bool requiresVersionedEdits;

  factory EncounterEditMeta.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const EncounterEditMeta();
    final last = json['lastEditedAt'];
    return EncounterEditMeta(
      hasEdits: json['hasEdits'] == true,
      editCount: json['editCount'] is int
          ? json['editCount'] as int
          : int.tryParse('${json['editCount']}') ?? 0,
      lastEditedAt: last == null ? null : DateTime.tryParse(last.toString()),
      canEdit: json['canEdit'] == true,
      requiresVersionedEdits: json['requiresVersionedEdits'] == true,
    );
  }
}

/// Staff summary on edit history rows.
class EncounterEditHistoryStaff {
  const EncounterEditHistoryStaff({
    required this.id,
    this.firstName,
    this.lastName,
    this.staffId,
  });

  final String id;
  final String? firstName;
  final String? lastName;
  final String? staffId;

  String get displayName {
    final parts = [
      if (firstName != null && firstName!.isNotEmpty) firstName,
      if (lastName != null && lastName!.isNotEmpty) lastName,
    ];
    if (parts.isNotEmpty) return parts.join(' ');
    return staffId ?? id;
  }

  factory EncounterEditHistoryStaff.fromJson(Map<String, dynamic> json) {
    return EncounterEditHistoryStaff(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
      staffId: json['staffId']?.toString(),
    );
  }
}

/// GET /encounters/:id/edit-history list row.
class EncounterEditHistorySummary {
  const EncounterEditHistorySummary({
    required this.id,
    required this.editedAt,
    this.reason,
    this.changedKeys = const [],
    this.editedBy,
  });

  final String id;
  final DateTime editedAt;
  final String? reason;
  final List<String> changedKeys;
  final EncounterEditHistoryStaff? editedBy;

  factory EncounterEditHistorySummary.fromJson(Map<String, dynamic> json) {
    final keys = json['changedKeys'];
    return EncounterEditHistorySummary(
      id: json['id']?.toString() ?? '',
      editedAt: DateTime.tryParse(json['editedAt']?.toString() ?? '') ??
          DateTime.now(),
      reason: json['reason']?.toString(),
      changedKeys: keys is List
          ? keys.map((e) => e.toString()).toList()
          : const [],
      editedBy: json['editedBy'] is Map
          ? EncounterEditHistoryStaff.fromJson(
              Map<String, dynamic>.from(json['editedBy'] as Map),
            )
          : null,
    );
  }
}

/// Diagnosis row inside a clinical snapshot.
class ClinicalDiagnosisSnapshot {
  const ClinicalDiagnosisSnapshot({
    required this.id,
    this.primaryIcdCode,
    this.primaryIcdDescription,
    this.secondaryDiagnosesJson,
  });

  final String id;
  final String? primaryIcdCode;
  final String? primaryIcdDescription;
  final dynamic secondaryDiagnosesJson;

  factory ClinicalDiagnosisSnapshot.fromJson(Map<String, dynamic> json) {
    return ClinicalDiagnosisSnapshot(
      id: json['id']?.toString() ?? '',
      primaryIcdCode: json['primaryIcdCode']?.toString(),
      primaryIcdDescription: json['primaryIcdDescription']?.toString(),
      secondaryDiagnosesJson: json['secondaryDiagnosesJson'],
    );
  }
}

/// Encounter field snapshot inside edit history detail.
class EncounterClinicalSnapshotFields {
  const EncounterClinicalSnapshotFields({
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
    this.triageNotes,
    this.proceduresJson,
  });

  final String? chiefComplaint;
  final String? hpi;
  final String? pmh;
  final String? surgicalHistory;
  final String? drugHistory;
  final String? allergyHistory;
  final String? familyHistory;
  final String? socialHistory;
  final String? examinationNotes;
  final String? soapSubjective;
  final String? soapObjective;
  final String? soapAssessment;
  final String? soapPlan;
  final String? triageNotes;
  final String? proceduresJson;

  factory EncounterClinicalSnapshotFields.fromJson(Map<String, dynamic> json) {
    String? str(dynamic v) => v?.toString();
    return EncounterClinicalSnapshotFields(
      chiefComplaint: str(json['chiefComplaint']),
      hpi: str(json['hpi']),
      pmh: str(json['pmh']),
      surgicalHistory: str(json['surgicalHistory']),
      drugHistory: str(json['drugHistory']),
      allergyHistory: str(json['allergyHistory']),
      familyHistory: str(json['familyHistory']),
      socialHistory: str(json['socialHistory']),
      examinationNotes: str(json['examinationNotes']),
      soapSubjective: str(json['soapSubjective']),
      soapObjective: str(json['soapObjective']),
      soapAssessment: str(json['soapAssessment']),
      soapPlan: str(json['soapPlan']),
      triageNotes: str(json['triageNotes']),
      proceduresJson: str(json['proceduresJson']),
    );
  }

  String? valueForKey(String key) {
    switch (key) {
      case 'chiefComplaint':
        return chiefComplaint;
      case 'hpi':
        return hpi;
      case 'pmh':
        return pmh;
      case 'surgicalHistory':
        return surgicalHistory;
      case 'drugHistory':
        return drugHistory;
      case 'allergyHistory':
        return allergyHistory;
      case 'familyHistory':
        return familyHistory;
      case 'socialHistory':
        return socialHistory;
      case 'examinationNotes':
        return examinationNotes;
      case 'soapSubjective':
        return soapSubjective;
      case 'soapObjective':
        return soapObjective;
      case 'soapAssessment':
        return soapAssessment;
      case 'soapPlan':
        return soapPlan;
      case 'triageNotes':
        return triageNotes;
      case 'proceduresJson':
        return proceduresJson;
      default:
        return null;
    }
  }

  static String labelForKey(String key) {
    switch (key) {
      case 'chiefComplaint':
        return 'Chief complaint';
      case 'hpi':
        return 'History of present illness';
      case 'pmh':
        return 'Past medical history';
      case 'surgicalHistory':
        return 'Surgical history';
      case 'drugHistory':
        return 'Drug history';
      case 'allergyHistory':
        return 'Allergy history';
      case 'familyHistory':
        return 'Family history';
      case 'socialHistory':
        return 'Social history';
      case 'examinationNotes':
        return 'Examination notes';
      case 'soapSubjective':
        return 'SOAP — Subjective';
      case 'soapObjective':
        return 'SOAP — Objective';
      case 'soapAssessment':
        return 'SOAP — Assessment';
      case 'soapPlan':
        return 'SOAP — Plan';
      case 'triageNotes':
        return 'Triage notes';
      case 'proceduresJson':
        return 'Procedures';
      default:
        if (key.startsWith('diagnoses.')) return 'Diagnosis';
        if (key.startsWith('specialtyModules.')) return 'Specialty modules';
        if (key.startsWith('clinicalSections.')) return 'Clinical section';
        return key;
    }
  }
}

/// Full clinical snapshot on edit history detail.
class ClinicalSnapshot {
  const ClinicalSnapshot({
    required this.encounter,
    this.diagnoses = const [],
    this.specialtyModules = const [],
    this.clinicalSections = const [],
  });

  final EncounterClinicalSnapshotFields encounter;
  final List<ClinicalDiagnosisSnapshot> diagnoses;
  final List<Map<String, dynamic>> specialtyModules;
  final List<Map<String, dynamic>> clinicalSections;

  factory ClinicalSnapshot.fromJson(Map<String, dynamic> json) {
    final enc = json['encounter'];
    final dx = json['diagnoses'];
    final sm = json['specialtyModules'];
    final cs = json['clinicalSections'];
    return ClinicalSnapshot(
      encounter: enc is Map
          ? EncounterClinicalSnapshotFields.fromJson(
              Map<String, dynamic>.from(enc),
            )
          : const EncounterClinicalSnapshotFields(),
      diagnoses: dx is List
          ? dx
              .whereType<Map>()
              .map(
                (e) => ClinicalDiagnosisSnapshot.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
      specialtyModules: sm is List
          ? sm
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
      clinicalSections: cs is List
          ? cs
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : const [],
    );
  }
}

/// GET /encounters/:id/edit-history/:historyId
class EncounterEditHistoryDetail {
  const EncounterEditHistoryDetail({
    required this.id,
    required this.editedAt,
    this.reason,
    this.changedKeys = const [],
    required this.snapshot,
    this.editedBy,
  });

  final String id;
  final DateTime editedAt;
  final String? reason;
  final List<String> changedKeys;
  final ClinicalSnapshot snapshot;
  final EncounterEditHistoryStaff? editedBy;

  factory EncounterEditHistoryDetail.fromJson(Map<String, dynamic> json) {
    final keys = json['changedKeys'];
    final snap = json['snapshot'];
    return EncounterEditHistoryDetail(
      id: json['id']?.toString() ?? '',
      editedAt: DateTime.tryParse(json['editedAt']?.toString() ?? '') ??
          DateTime.now(),
      reason: json['reason']?.toString(),
      changedKeys: keys is List
          ? keys.map((e) => e.toString()).toList()
          : const [],
      snapshot: snap is Map
          ? ClinicalSnapshot.fromJson(Map<String, dynamic>.from(snap))
          : const ClinicalSnapshot(
              encounter: EncounterClinicalSnapshotFields(),
            ),
      editedBy: json['editedBy'] is Map
          ? EncounterEditHistoryStaff.fromJson(
              Map<String, dynamic>.from(json['editedBy'] as Map),
            )
          : null,
    );
  }
}
