import 'dart:convert';

import 'package:helty/src/doctor/templates/encounter_template_fields.dart';
import 'package:helty/src/models/encounter_model.dart';

class EncounterTemplateStaffRef {
  const EncounterTemplateStaffRef({
    required this.id,
    this.firstName,
    this.lastName,
    this.staffId,
  });

  final String id;
  final String? firstName;
  final String? lastName;
  final String? staffId;

  factory EncounterTemplateStaffRef.fromJson(Map<String, dynamic> json) {
    return EncounterTemplateStaffRef(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      staffId: json['staffId'] as String?,
    );
  }

  String? get displayName {
    final name = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    return name.isEmpty ? null : name;
  }
}

class EncounterTemplateModel {
  const EncounterTemplateModel({
    required this.id,
    required this.name,
    this.description,
    this.encounterType,
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
    this.visitType,
    this.primaryIcdCode,
    this.primaryIcdDescription,
    this.secondaryDiagnosesJson,
    this.proceduresJson,
    this.specialtyModulesJson,
    this.clinicalSectionsJson,
    this.followUpDate,
    this.followUpInstructions,
    this.referral,
    this.doctorId,
    this.createdById,
    this.updatedById,
    this.createdAt,
    this.updatedAt,
    this.doctor,
    this.createdBy,
    this.updatedBy,
  });

  final String id;
  final String name;
  final String? description;
  final String? encounterType;
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
  final String? visitType;
  final String? primaryIcdCode;
  final String? primaryIcdDescription;
  final String? secondaryDiagnosesJson;
  final String? proceduresJson;
  final String? specialtyModulesJson;
  final String? clinicalSectionsJson;
  final String? followUpDate;
  final String? followUpInstructions;
  final String? referral;
  final String? doctorId;
  final String? createdById;
  final String? updatedById;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final EncounterTemplateStaffRef? doctor;
  final EncounterTemplateStaffRef? createdBy;
  final EncounterTemplateStaffRef? updatedBy;

  int get populatedFieldCount {
    var count = 0;
    for (final key in [
      ...kEncounterTemplateClinicalKeys,
      ...kEncounterTemplateDiagnosisKeys,
      'specialtyModulesJson',
      'clinicalSectionsJson',
    ]) {
      if (!encounterTemplateFieldIsEmpty(_valueForKey(key))) count++;
    }
    return count;
  }

  dynamic _valueForKey(String key) {
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
      case 'visitType':
        return visitType;
      case 'followUpDate':
        return followUpDate;
      case 'followUpInstructions':
        return followUpInstructions;
      case 'referral':
        return referral;
      case 'proceduresJson':
        return proceduresJson;
      case 'primaryIcdCode':
        return primaryIcdCode;
      case 'primaryIcdDescription':
        return primaryIcdDescription;
      case 'secondaryDiagnosesJson':
        return secondaryDiagnosesJson;
      case 'specialtyModulesJson':
        return specialtyModulesJson;
      case 'clinicalSectionsJson':
        return clinicalSectionsJson;
      default:
        return null;
    }
  }

  String? getField(String key) {
    final v = _valueForKey(key);
    return v?.toString();
  }

  Map<String, dynamic> toClinicalJson({bool includeEmpty = false}) {
    final out = <String, dynamic>{};
    void put(String key, String? value) {
      if (value == null && !includeEmpty) return;
      if (!includeEmpty && value != null && value.trim().isEmpty) return;
      out[key] = value;
    }

    put('chiefComplaint', chiefComplaint);
    put('hpi', hpi);
    put('pmh', pmh);
    put('surgicalHistory', surgicalHistory);
    put('drugHistory', drugHistory);
    put('allergyHistory', allergyHistory);
    put('familyHistory', familyHistory);
    put('socialHistory', socialHistory);
    put('examinationNotes', examinationNotes);
    put('soapSubjective', soapSubjective);
    put('soapObjective', soapObjective);
    put('soapAssessment', soapAssessment);
    put('soapPlan', soapPlan);
    put('triageNotes', triageNotes);
    put('visitType', visitType);
    put('primaryIcdCode', primaryIcdCode);
    put('primaryIcdDescription', primaryIcdDescription);
    put('secondaryDiagnosesJson', secondaryDiagnosesJson);
    put('proceduresJson', proceduresJson);
    put('specialtyModulesJson', specialtyModulesJson);
    put('clinicalSectionsJson', clinicalSectionsJson);
    put('followUpDate', followUpDate);
    put('followUpInstructions', followUpInstructions);
    put('referral', referral);
    return out;
  }

  Map<String, dynamic> toCreateJson() {
    final out = <String, dynamic>{
      'name': name.trim(),
      if (description != null && description!.trim().isNotEmpty)
        'description': description!.trim(),
      if (encounterType != null && encounterType!.trim().isNotEmpty)
        'encounterType': encounterType!.trim().toUpperCase(),
      ...toClinicalJson(),
    };
    return out;
  }

  Map<String, dynamic> toPatchJson() {
    final out = <String, dynamic>{};
    if (name.trim().isNotEmpty) out['name'] = name.trim();
    if (description != null) {
      out['description'] = description!.trim().isEmpty ? null : description!.trim();
    }
    if (encounterType != null) {
      out['encounterType'] = encounterType!.trim().isEmpty
          ? null
          : encounterType!.trim().toUpperCase();
    }
    out.addAll(toClinicalJson(includeEmpty: true));
    return out;
  }

  static Map<String, dynamic> clinicalFieldsFromEncounter(EncounterModel enc) {
    String? modulesJson;
    if (enc.specialtyModules != null && enc.specialtyModules!.isNotEmpty) {
      modulesJson = jsonEncode(
        enc.specialtyModules!
            .map((m) => m.toSyncBody())
            .toList(growable: false),
      );
    }

    String? sectionsJson;
    if (enc.clinicalSections != null && enc.clinicalSections!.isNotEmpty) {
      sectionsJson = jsonEncode(
        enc.clinicalSections!
            .map(
              (s) => {
                'specialty': s.specialty,
                'sectionKey': s.sectionKey,
                'schemaVersion': s.schemaVersion,
                'data': s.data,
              },
            )
            .toList(growable: false),
      );
    }

    return {
      if (enc.encounterType != null && enc.encounterType!.trim().isNotEmpty)
        'encounterType': enc.encounterType!.trim().toUpperCase(),
      if (enc.chiefComplaint != null && enc.chiefComplaint!.trim().isNotEmpty)
        'chiefComplaint': enc.chiefComplaint,
      if (enc.hpi != null && enc.hpi!.trim().isNotEmpty) 'hpi': enc.hpi,
      if (enc.pmh != null && enc.pmh!.trim().isNotEmpty) 'pmh': enc.pmh,
      if (enc.surgicalHistory != null && enc.surgicalHistory!.trim().isNotEmpty)
        'surgicalHistory': enc.surgicalHistory,
      if (enc.drugHistory != null && enc.drugHistory!.trim().isNotEmpty)
        'drugHistory': enc.drugHistory,
      if (enc.allergyHistory != null && enc.allergyHistory!.trim().isNotEmpty)
        'allergyHistory': enc.allergyHistory,
      if (enc.familyHistory != null && enc.familyHistory!.trim().isNotEmpty)
        'familyHistory': enc.familyHistory,
      if (enc.socialHistory != null && enc.socialHistory!.trim().isNotEmpty)
        'socialHistory': enc.socialHistory,
      if (enc.examinationNotes != null &&
          enc.examinationNotes!.trim().isNotEmpty)
        'examinationNotes': enc.examinationNotes,
      if (enc.soapSubjective != null && enc.soapSubjective!.trim().isNotEmpty)
        'soapSubjective': enc.soapSubjective,
      if (enc.soapObjective != null && enc.soapObjective!.trim().isNotEmpty)
        'soapObjective': enc.soapObjective,
      if (enc.soapAssessment != null && enc.soapAssessment!.trim().isNotEmpty)
        'soapAssessment': enc.soapAssessment,
      if (enc.soapPlan != null && enc.soapPlan!.trim().isNotEmpty)
        'soapPlan': enc.soapPlan,
      if (enc.triageNotes != null && enc.triageNotes!.trim().isNotEmpty)
        'triageNotes': enc.triageNotes,
      if (enc.visitType != null && enc.visitType!.trim().isNotEmpty)
        'visitType': enc.visitType,
      if (enc.primaryIcdCode != null && enc.primaryIcdCode!.trim().isNotEmpty)
        'primaryIcdCode': enc.primaryIcdCode,
      if (enc.primaryIcdDescription != null &&
          enc.primaryIcdDescription!.trim().isNotEmpty)
        'primaryIcdDescription': enc.primaryIcdDescription,
      if (enc.secondaryDiagnosesJson != null &&
          enc.secondaryDiagnosesJson!.trim().isNotEmpty)
        'secondaryDiagnosesJson': enc.secondaryDiagnosesJson,
      if (enc.proceduresJson != null && enc.proceduresJson!.trim().isNotEmpty)
        'proceduresJson': enc.proceduresJson,
      if (modulesJson != null) 'specialtyModulesJson': modulesJson,
      if (sectionsJson != null) 'clinicalSectionsJson': sectionsJson,
      if (enc.followUpDate != null && enc.followUpDate!.trim().isNotEmpty)
        'followUpDate': enc.followUpDate,
      if (enc.followUpInstructions != null &&
          enc.followUpInstructions!.trim().isNotEmpty)
        'followUpInstructions': enc.followUpInstructions,
      if (enc.referral != null && enc.referral!.trim().isNotEmpty)
        'referral': enc.referral,
    };
  }

  factory EncounterTemplateModel.fromJson(Map<String, dynamic> json) {
    EncounterTemplateStaffRef? parseStaff(dynamic raw) {
      if (raw is Map<String, dynamic>) {
        return EncounterTemplateStaffRef.fromJson(raw);
      }
      if (raw is Map) {
        return EncounterTemplateStaffRef.fromJson(
          Map<String, dynamic>.from(raw),
        );
      }
      return null;
    }

    DateTime? parseDt(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());

    return EncounterTemplateModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description'] as String?,
      encounterType: json['encounterType'] as String?,
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
      triageNotes: json['triageNotes'] as String?,
      visitType: json['visitType'] as String?,
      primaryIcdCode: json['primaryIcdCode'] as String?,
      primaryIcdDescription: json['primaryIcdDescription'] as String?,
      secondaryDiagnosesJson: json['secondaryDiagnosesJson'] as String?,
      proceduresJson: json['proceduresJson'] as String?,
      specialtyModulesJson: json['specialtyModulesJson'] as String?,
      clinicalSectionsJson: json['clinicalSectionsJson'] as String?,
      followUpDate: json['followUpDate'] as String?,
      followUpInstructions: json['followUpInstructions'] as String?,
      referral: json['referral'] as String?,
      doctorId: json['doctorId']?.toString(),
      createdById: json['createdById']?.toString(),
      updatedById: json['updatedById']?.toString(),
      createdAt: parseDt(json['createdAt']),
      updatedAt: parseDt(json['updatedAt']),
      doctor: parseStaff(json['doctor']),
      createdBy: parseStaff(json['createdBy']),
      updatedBy: parseStaff(json['updatedBy']),
    );
  }

  EncounterTemplateModel copyWith({
    String? id,
    String? name,
    String? description,
    String? encounterType,
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
    String? triageNotes,
    String? visitType,
    String? primaryIcdCode,
    String? primaryIcdDescription,
    String? secondaryDiagnosesJson,
    String? proceduresJson,
    String? specialtyModulesJson,
    String? clinicalSectionsJson,
    String? followUpDate,
    String? followUpInstructions,
    String? referral,
  }) {
    return EncounterTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      encounterType: encounterType ?? this.encounterType,
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
      triageNotes: triageNotes ?? this.triageNotes,
      visitType: visitType ?? this.visitType,
      primaryIcdCode: primaryIcdCode ?? this.primaryIcdCode,
      primaryIcdDescription:
          primaryIcdDescription ?? this.primaryIcdDescription,
      secondaryDiagnosesJson:
          secondaryDiagnosesJson ?? this.secondaryDiagnosesJson,
      proceduresJson: proceduresJson ?? this.proceduresJson,
      specialtyModulesJson: specialtyModulesJson ?? this.specialtyModulesJson,
      clinicalSectionsJson: clinicalSectionsJson ?? this.clinicalSectionsJson,
      followUpDate: followUpDate ?? this.followUpDate,
      followUpInstructions: followUpInstructions ?? this.followUpInstructions,
      referral: referral ?? this.referral,
      doctorId: doctorId,
      createdById: createdById,
      updatedById: updatedById,
      createdAt: createdAt,
      updatedAt: updatedAt,
      doctor: doctor,
      createdBy: createdBy,
      updatedBy: updatedBy,
    );
  }
}

class EncounterTemplateListResult {
  const EncounterTemplateListResult({
    required this.templates,
    required this.total,
  });

  final List<EncounterTemplateModel> templates;
  final int total;
}

class EncounterTemplateDeleteResult {
  const EncounterTemplateDeleteResult({
    required this.id,
    required this.name,
    required this.deleted,
  });

  final String id;
  final String name;
  final bool deleted;

  factory EncounterTemplateDeleteResult.fromJson(Map<String, dynamic> json) {
    return EncounterTemplateDeleteResult(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      deleted: json['deleted'] == true,
    );
  }
}
