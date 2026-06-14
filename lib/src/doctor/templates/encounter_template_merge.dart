import 'package:helty/src/doctor/templates/encounter_template_fields.dart';
import 'package:helty/src/models/encounter_model.dart';
import 'package:helty/src/models/encounter_template_model.dart';

enum EncounterTemplateMergeMode {
  replaceAll,
  fillEmptyOnly,
}

Map<String, dynamic> encounterToClinicalMap(EncounterModel enc) {
  return {
    'chiefComplaint': enc.chiefComplaint,
    'hpi': enc.hpi,
    'pmh': enc.pmh,
    'surgicalHistory': enc.surgicalHistory,
    'drugHistory': enc.drugHistory,
    'allergyHistory': enc.allergyHistory,
    'familyHistory': enc.familyHistory,
    'socialHistory': enc.socialHistory,
    'examinationNotes': enc.examinationNotes,
    'soapSubjective': enc.soapSubjective,
    'soapObjective': enc.soapObjective,
    'soapAssessment': enc.soapAssessment,
    'soapPlan': enc.soapPlan,
    'triageNotes': enc.triageNotes,
    'visitType': enc.visitType,
    'followUpDate': enc.followUpDate,
    'followUpInstructions': enc.followUpInstructions,
    'referral': enc.referral,
    'proceduresJson': enc.proceduresJson,
    'primaryIcdCode': enc.primaryIcdCode,
    'primaryIcdDescription': enc.primaryIcdDescription,
    'secondaryDiagnosesJson': enc.secondaryDiagnosesJson,
  };
}

Map<String, dynamic> templateToClinicalMap(EncounterTemplateModel template) {
  return template.toClinicalJson(includeEmpty: false);
}

bool encounterHasClinicalData(EncounterModel enc) {
  final map = encounterToClinicalMap(enc);
  for (final key in kEncounterTemplateClinicalKeys) {
    if (!encounterTemplateFieldIsEmpty(map[key])) return true;
  }
  for (final key in kEncounterTemplateDiagnosisKeys) {
    if (!encounterTemplateFieldIsEmpty(map[key])) return true;
  }
  if (enc.specialtyModules != null && enc.specialtyModules!.isNotEmpty) {
    return true;
  }
  if (enc.clinicalSections != null && enc.clinicalSections!.isNotEmpty) {
    return true;
  }
  return false;
}

Map<String, dynamic> mergeTemplateIntoEncounterMaps({
  required Map<String, dynamic> current,
  required Map<String, dynamic> template,
  required EncounterTemplateMergeMode mode,
  Iterable<String> fields = kEncounterTemplateClinicalKeys,
}) {
  final next = Map<String, dynamic>.from(current);
  for (final key in fields) {
    final fromTemplate = template[key];
    if (encounterTemplateFieldIsEmpty(fromTemplate)) continue;

    if (mode == EncounterTemplateMergeMode.replaceAll) {
      next[key] = fromTemplate;
      continue;
    }

    final existing = next[key];
    if (encounterTemplateFieldIsEmpty(existing)) {
      next[key] = fromTemplate;
    }
  }
  return next;
}

Map<String, dynamic> mergeDiagnosisFields({
  required EncounterModel current,
  required EncounterTemplateModel template,
  required EncounterTemplateMergeMode mode,
}) {
  return mergeTemplateIntoEncounterMaps(
    current: encounterToClinicalMap(current),
    template: templateToClinicalMap(template),
    mode: mode,
    fields: kEncounterTemplateDiagnosisKeys,
  );
}

Map<String, dynamic> mergeClinicalPatch({
  required EncounterModel current,
  required EncounterTemplateModel template,
  required EncounterTemplateMergeMode mode,
}) {
  final merged = mergeTemplateIntoEncounterMaps(
    current: encounterToClinicalMap(current),
    template: templateToClinicalMap(template),
    mode: mode,
  );
  final patch = <String, dynamic>{};
  for (final key in kEncounterTemplateClinicalKeys) {
    if (merged.containsKey(key)) {
      patch[key] = merged[key];
    }
  }
  return patch;
}

bool templateHasDiagnosis(EncounterTemplateModel template) {
  return !encounterTemplateFieldIsEmpty(template.primaryIcdCode) ||
      !encounterTemplateFieldIsEmpty(template.primaryIcdDescription) ||
      !encounterTemplateFieldIsEmpty(template.secondaryDiagnosesJson);
}

bool templateHasSpecialtyData(EncounterTemplateModel template) {
  return !encounterTemplateFieldIsEmpty(template.specialtyModulesJson) ||
      !encounterTemplateFieldIsEmpty(template.clinicalSectionsJson);
}
