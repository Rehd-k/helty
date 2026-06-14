/// Shared field keys and encounter-type labels for encounter templates.
library;
const kEncounterTemplateClinicalKeys = <String>[
  'chiefComplaint',
  'hpi',
  'pmh',
  'surgicalHistory',
  'drugHistory',
  'allergyHistory',
  'familyHistory',
  'socialHistory',
  'examinationNotes',
  'soapSubjective',
  'soapObjective',
  'soapAssessment',
  'soapPlan',
  'triageNotes',
  'visitType',
  'followUpDate',
  'followUpInstructions',
  'referral',
  'proceduresJson',
];

const kEncounterTemplateDiagnosisKeys = <String>[
  'primaryIcdCode',
  'primaryIcdDescription',
  'secondaryDiagnosesJson',
];

const kEncounterTemplateJsonKeys = <String>[
  'secondaryDiagnosesJson',
  'proceduresJson',
  'specialtyModulesJson',
  'clinicalSectionsJson',
];

/// API encounterType values with UI labels.
const kEncounterTemplateTypes = <String, String>{
  'OUTPATIENT': 'Outpatient',
  'EMERGENCY': 'Emergency',
  'INPATIENT_REVIEW': 'Inpatient review',
  'TELEMEDICINE': 'Telemedicine',
  'FOLLOW_UP': 'Follow-up',
};

String encounterTemplateTypeLabel(String? type) {
  if (type == null || type.trim().isEmpty) return 'Any type';
  return kEncounterTemplateTypes[type.trim().toUpperCase()] ?? type;
}

bool encounterTemplateFieldIsEmpty(dynamic value) {
  if (value == null) return true;
  if (value is String) return value.trim().isEmpty;
  return false;
}
