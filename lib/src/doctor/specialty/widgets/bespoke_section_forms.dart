import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'clinical_form_shared.dart';

/// Returns a widget if [sectionKey] has a bespoke template; otherwise `null` (use catalog fallback).
Widget? buildBespokeSectionForm({
  required String sectionKey,
  required Map<String, dynamic> data,
  required void Function(Map<String, dynamic>) onChanged,
  required bool readOnly,
}) {
  switch (sectionKey) {
    case 'cardiology.ecg':
      return _multiTextCard(
        title: 'ECG',
        subtitle: 'Rhythm, rate, and interpretation',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('rhythm', 'Rhythm', false),
          _Ff('rateBpm', 'Rate (bpm)', false),
          _Ff('interpretation', 'Interpretation', true),
        ],
        extra: AttachmentUrlsEditor(
          data: data,
          onChanged: onChanged,
          readOnly: readOnly,
        ),
      );
    case 'cardiology.echocardiogram':
      return _multiTextCard(
        title: 'Echocardiogram',
        subtitle: 'LV function, valves, summary',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('lvefPercent', 'LVEF (%) if known', false),
          _Ff('wallMotion', 'Wall motion', true),
          _Ff('valves', 'Valves', true),
          _Ff('summary', 'Summary', true),
        ],
        extra: AttachmentUrlsEditor(
          data: data,
          onChanged: onChanged,
          readOnly: readOnly,
        ),
      );
    case 'cardiology.risk_scores':
      return _riskScoresForm(data, onChanged, readOnly);
    case 'neurology.exam':
      return _multiTextCard(
        title: 'Neurological examination',
        subtitle: 'Mental status, cranial nerves, motor, sensory, reflexes, gait',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('mentalStatus', 'Mental status', true),
          _Ff('cranialNerves', 'Cranial nerves', true),
          _Ff('motor', 'Motor', true),
          _Ff('sensory', 'Sensory', true),
          _Ff('reflexes', 'Reflexes', true),
          _Ff('gait', 'Gait / coordination', true),
        ],
      );
    case 'neurology.stroke_assessment':
      return _nihssForm(data, onChanged, readOnly);
    case 'dermatology.lesion_gallery':
      return _multiTextCard(
        title: 'Lesion gallery',
        subtitle: 'Document lesions; attach clinical photos via URLs',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('lesionDescription', 'Lesion description', true),
          _Ff('distribution', 'Distribution', false),
          _Ff('dermatoscopy', 'Dermoscopy notes', true),
        ],
        extra: AttachmentUrlsEditor(
          data: data,
          onChanged: onChanged,
          readOnly: readOnly,
        ),
      );
    case 'dermatology.skin_assessment':
      return _multiTextCard(
        title: 'Skin assessment',
        subtitle: 'Texture, color, integrity, wounds',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('inspection', 'Inspection', true),
          _Ff('palpation', 'Palpation', true),
          _Ff('staging', 'Staging / classification', false),
        ],
      );
    case 'pediatrics.growth':
      return _multiTextCard(
        title: 'Growth',
        subtitle: 'Percentiles, crossing, parental heights',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('weightPercentile', 'Weight percentile', false),
          _Ff('heightPercentile', 'Height percentile', false),
          _Ff('bmiPercentile', 'BMI percentile', false),
          _Ff('headCircumference', 'Head circumference (cm)', false),
          _Ff('notes', 'Notes', true),
        ],
      );
    case 'pediatrics.vitals_pediatric':
      return _multiTextCard(
        title: 'Pediatric vitals',
        subtitle: 'Age-appropriate ranges and concerns',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('heartRate', 'Heart rate', false),
          _Ff('respiratoryRate', 'Respiratory rate', false),
          _Ff('bloodPressure', 'Blood pressure', false),
          _Ff('temperature', 'Temperature', false),
          _Ff('spo2', 'SpO₂', false),
          _Ff('painScore', 'Pain score', false),
          _Ff('notes', 'Notes', true),
        ],
      );
    case 'obgyn.pregnancy_summary':
      return _multiTextCard(
        title: 'Pregnancy summary (visit note)',
        subtitle: 'Lightweight summary; canonical antenatal data lives in Obstetrics module',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('gestationWeeks', 'Gestation (weeks)', false),
          _Ff('maternalStatus', 'Maternal status', true),
          _Ff('fetalMovement', 'Fetal movement', false),
          _Ff('plan', 'Plan', true),
        ],
      );
    case 'orthopedics.fracture':
      return _multiTextCard(
        title: 'Fracture',
        subtitle: 'Bone, classification, neurovascular status',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('site', 'Site', false),
          _Ff('classification', 'Classification (e.g. AO/Garden)', false),
          _Ff('openClosed', 'Open / closed', false),
          _Ff('neurovascular', 'Neurovascular exam', true),
          _Ff('plan', 'Plan', true),
        ],
        extra: AttachmentUrlsEditor(
          data: data,
          onChanged: onChanged,
          readOnly: readOnly,
        ),
      );
    case 'orthopedics.mobility':
      return _multiTextCard(
        title: 'Mobility',
        subtitle: 'Weight bearing, assistive devices, ROM',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('weightBearing', 'Weight bearing status', false),
          _Ff('assistiveDevice', 'Assistive device', false),
          _Ff('rom', 'Range of motion', true),
          _Ff('functionalScore', 'Functional score / comment', false),
        ],
      );
    case 'psychiatry.mse':
      return _multiTextCard(
        title: 'Mental status examination',
        subtitle: 'Appearance through insight / judgment',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('appearance', 'Appearance', false),
          _Ff('behavior', 'Behavior', false),
          _Ff('speech', 'Speech', false),
          _Ff('moodAffect', 'Mood / affect', true),
          _Ff('thoughtProcess', 'Thought process', true),
          _Ff('thoughtContent', 'Thought content', true),
          _Ff('perception', 'Perception', false),
          _Ff('cognition', 'Cognition / orientation', true),
          _Ff('insightJudgment', 'Insight / judgment', true),
        ],
      );
    case 'psychiatry.safety':
      return _multiTextCard(
        title: 'Safety assessment',
        subtitle: 'Suicide / homicide / self-harm / protective factors',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('suicidalIdeation', 'Suicidal ideation', true),
          _Ff('homicidalIdeation', 'Homicidal ideation', true),
          _Ff('selfHarm', 'Self-harm / intent', true),
          _Ff('protectiveFactors', 'Protective factors', true),
          _Ff('collateral', 'Collateral / contacts', true),
          _Ff('plan', 'Safety plan', true),
        ],
      );
    case 'ophthalmology.visual_acuity':
      return _multiTextCard(
        title: 'Visual acuity',
        subtitle: 'Distance / near, correction, pinhole',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('odDistance', 'OD distance', false),
          _Ff('osDistance', 'OS distance', false),
          _Ff('odNear', 'OD near', false),
          _Ff('osNear', 'OS near', false),
          _Ff('correction', 'Correction (ph / glasses)', false),
          _Ff('notes', 'Notes', true),
        ],
      );
    case 'ophthalmology.fundus':
      return _multiTextCard(
        title: 'Fundus',
        subtitle: 'Disc, vessels, macula, periphery',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('od', 'OD', true),
          _Ff('os', 'OS', true),
          _Ff('cupDiscRatio', 'Cup-disc (if recorded)', false),
        ],
        extra: AttachmentUrlsEditor(
          data: data,
          onChanged: onChanged,
          readOnly: readOnly,
        ),
      );
    case 'ent.exam':
      return _multiTextCard(
        title: 'ENT examination',
        subtitle: 'Otoscopy, rhinoscopy, oral cavity, neck',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('ears', 'Ears', true),
          _Ff('nose', 'Nose', true),
          _Ff('throat', 'Throat / oral', true),
          _Ff('neck', 'Neck', true),
          _Ff('cranialNervesEnt', 'Relevant cranial nerves', false),
        ],
      );
    case 'urology.luts':
      return _multiTextCard(
        title: 'LUTS (lower urinary tract symptoms)',
        subtitle: 'IPSS-style narrative or scores',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('voiding', 'Voiding symptoms', true),
          _Ff('storage', 'Storage symptoms', true),
          _Ff('incontinence', 'Incontinence', true),
          _Ff('ipssScore', 'IPSS total (if scored)', false),
          _Ff('pvr', 'Post-void residual (if known)', false),
        ],
      );
    case 'nephrology.ckd':
      return _multiTextCard(
        title: 'CKD focus',
        subtitle: 'Stage, eGFR trend, albuminuria, complications',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('stage', 'CKD stage', false),
          _Ff('egfr', 'eGFR', false),
          _Ff('uacr', 'UACR / proteinuria', false),
          _Ff('bpTarget', 'BP target', false),
          _Ff('complications', 'Complications', true),
          _Ff('plan', 'Plan', true),
        ],
      );
    case 'endocrinology.diabetes':
      return _multiTextCard(
        title: 'Diabetes',
        subtitle: 'A1c, hypoglycemia, complications, therapy',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('hba1c', 'HbA1c (%)', false),
          _Ff('fastingGlucose', 'Glucose (fasting / random)', false),
          _Ff('therapy', 'Therapy (diet / OHA / insulin)', true),
          _Ff('hypoglycemia', 'Hypoglycemia risk', false),
          _Ff('complications', 'Complications screening', true),
        ],
      );
    case 'endocrinology.thyroid':
      return _multiTextCard(
        title: 'Thyroid',
        subtitle: 'Symptoms, exam, labs, plan',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('symptoms', 'Symptoms', true),
          _Ff('exam', 'Thyroid exam', true),
          _Ff('tsh', 'TSH', false),
          _Ff('freeT4', 'Free T4', false),
          _Ff('antibodies', 'Antibodies / other labs', false),
          _Ff('plan', 'Plan', true),
        ],
      );
    case 'gi.history':
      return _multiTextCard(
        title: 'GI history',
        subtitle: 'Symptoms, red flags, prior workup',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('chiefGi', 'Chief GI symptoms', true),
          _Ff('stool', 'Stool / bleeding', true),
          _Ff('weightChange', 'Weight change', false),
          _Ff('priorInvestigations', 'Prior investigations', true),
        ],
      );
    case 'gi.exam':
      return _multiTextCard(
        title: 'GI examination',
        subtitle: 'Abdomen, organomegaly, signs',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('inspection', 'Inspection', false),
          _Ff('auscultation', 'Auscultation', false),
          _Ff('palpation', 'Palpation', true),
          _Ff('perRectal', 'Per rectal (if performed)', true),
        ],
      );
    case 'pulmonology.spirometry_summary':
      return _multiTextCard(
        title: 'Spirometry summary',
        subtitle: 'FEV1, FVC, ratios, bronchodilator response',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('fev1', 'FEV1', false),
          _Ff('fvc', 'FVC', false),
          _Ff('ratio', 'FEV1/FVC', false),
          _Ff('percentPredicted', '% predicted', false),
          _Ff('bronchodilatorResponse', 'Bronchodilator response', true),
          _Ff('interpretation', 'Interpretation', true),
        ],
      );
    case 'pulmonology.resp_exam':
      return _multiTextCard(
        title: 'Respiratory examination',
        subtitle: 'Inspection, percussion, auscultation, sats',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('inspection', 'Inspection', false),
          _Ff('percussion', 'Percussion', false),
          _Ff('auscultation', 'Auscultation', true),
          _Ff('spo2', 'SpO₂ / oxygen', false),
        ],
      );
    case 'hematology.cbc_focus':
      return _multiTextCard(
        title: 'CBC focus',
        subtitle: 'Key cell lines and morphology notes',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('hemoglobin', 'Hemoglobin', false),
          _Ff('wbc', 'WBC', false),
          _Ff('platelets', 'Platelets', false),
          _Ff('mcv', 'MCV', false),
          _Ff('differential', 'Differential / morphology', true),
        ],
      );
    case 'oncology.treatment_status':
      return _multiTextCard(
        title: 'Oncology treatment status',
        subtitle: 'Regimen, cycle, toxicity, response',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('diagnosisSummary', 'Diagnosis summary', true),
          _Ff('regimen', 'Current regimen', true),
          _Ff('cycleDay', 'Cycle / day', false),
          _Ff('toxicity', 'Toxicity (CTCAE)', true),
          _Ff('response', 'Response assessment', true),
        ],
      );
    case 'radiology.clinical_correlation':
      return _multiTextCard(
        title: 'Clinical correlation',
        subtitle: 'Question, relevant history, correlation with imaging',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('clinicalQuestion', 'Clinical question', true),
          _Ff('relevantHistory', 'Relevant history', true),
          _Ff('correlation', 'Correlation statement', true),
        ],
      );
    case 'anesthesia.preop':
      return _multiTextCard(
        title: 'Pre-operative anesthesia',
        subtitle: 'Airway, ASA, optimization, plan',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('asaClass', 'ASA class', false),
          _Ff('airway', 'Airway assessment', true),
          _Ff('comorbidities', 'Comorbidities', true),
          _Ff('medications', 'Medications to hold / continue', true),
          _Ff('plan', 'Anesthetic plan', true),
        ],
      );
    case 'anesthesia.acute_pain':
      return _multiTextCard(
        title: 'Acute pain',
        subtitle: 'Regional / multimodal plan, follow-up',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('painScores', 'Pain scores / location', true),
          _Ff('regionalTechnique', 'Regional technique', true),
          _Ff('multimodal', 'Multimodal regimen', true),
          _Ff('followUp', 'Follow-up', false),
        ],
      );
    case 'em.triage':
      return _multiTextCard(
        title: 'Emergency triage',
        subtitle: 'Chief complaint, ESI / acuity, vitals, red flags',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('chiefComplaint', 'Chief complaint', true),
          _Ff('esiLevel', 'ESI level (1–5)', false),
          _Ff('vitalsSummary', 'Vitals summary', true),
          _Ff('redFlags', 'Red flags', true),
          _Ff('interventions', 'Immediate interventions', true),
        ],
      );
    case 'em.disposition':
      return _multiTextCard(
        title: 'Emergency disposition',
        subtitle: 'Admit, discharge, transfer; follow-up',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('disposition', 'Disposition', false),
          _Ff('diagnosisSummary', 'Diagnosis summary', true),
          _Ff('instructions', 'Patient instructions', true),
          _Ff('followUp', 'Follow-up', true),
        ],
      );
    case 'fm.preventive':
      return _multiTextCard(
        title: 'Preventive care',
        subtitle: 'Screenings, immunizations, counseling',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('screeningsDue', 'Screenings due / done', true),
          _Ff('immunizations', 'Immunizations', true),
          _Ff('counseling', 'Counseling (diet, exercise, substance)', true),
        ],
      );
    case 'im.problem_list':
      return _multiTextCard(
        title: 'Problem list',
        subtitle: 'Active problems, stability, today\'s focus',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('activeProblems', 'Active problems', true),
          _Ff('unstableIssues', 'Unstable issues', true),
          _Ff('todaysFocus', 'Today\'s focus', true),
        ],
      );
    case 'surgery.preop_note':
      return _multiTextCard(
        title: 'Pre-operative surgical note',
        subtitle: 'Indication, consent, site marking, risk discussion',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('indication', 'Indication', true),
          _Ff('procedurePlanned', 'Procedure planned', false),
          _Ff('consent', 'Consent', false),
          _Ff('siteMarking', 'Site marking / timeout', false),
          _Ff('riskDiscussion', 'Risk discussion', true),
        ],
      );
    case 'neurosurg.intracranial_pressure':
      return _multiTextCard(
        title: 'Intracranial pressure / neuro monitoring',
        subtitle: 'ICP, CPP, drains, imaging correlation',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('icp', 'ICP', false),
          _Ff('cpp', 'CPP', false),
          _Ff('drainDevice', 'Drain / EVD settings', true),
          _Ff('imaging', 'Imaging summary', true),
          _Ff('plan', 'Plan', true),
        ],
      );
    case 'plastics.reconstructive':
      return _multiTextCard(
        title: 'Reconstructive assessment',
        subtitle: 'Defect, options, staging',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('defectDescription', 'Defect description', true),
          _Ff('reconstructiveOptions', 'Options discussed', true),
          _Ff('staging', 'Staging / timing', true),
        ],
        extra: AttachmentUrlsEditor(
          data: data,
          onChanged: onChanged,
          readOnly: readOnly,
        ),
      );
    case 'pathology.correlation':
      return _multiTextCard(
        title: 'Pathology correlation',
        subtitle: 'Specimen, clinical question, gross/micro',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('specimenId', 'Specimen / accession', false),
          _Ff('clinicalQuestion', 'Clinical question', true),
          _Ff('correlation', 'Clinicopathologic correlation', true),
        ],
      );
    case 'id.antimicrobial':
      return _multiTextCard(
        title: 'Antimicrobial stewardship',
        subtitle: 'Drug, indication, duration, de-escalation',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('agent', 'Agent / route', true),
          _Ff('indication', 'Indication', true),
          _Ff('duration', 'Duration / stop date', false),
          _Ff('deEscalation', 'De-escalation plan', true),
          _Ff('allergies', 'Allergies', false),
        ],
      );
    case 'rheum.joint_exam':
      return _multiTextCard(
        title: 'Joint examination',
        subtitle: 'Tender / swollen joints, pattern, DAS28 notes',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('tenderJoints', 'Tender joints', true),
          _Ff('swollenJoints', 'Swollen joints', true),
          _Ff('pattern', 'Pattern', false),
          _Ff('das28', 'DAS28 / score notes', false),
          _Ff('functionalImpact', 'Functional impact', true),
        ],
      );
    case 'icu.daily':
      return _multiTextCard(
        title: 'ICU daily',
        subtitle: 'Overnight events, lines, ventilation, balance, plan',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('overnightEvents', 'Overnight events', true),
          _Ff('linesTubes', 'Lines / tubes', true),
          _Ff('ventilation', 'Ventilation / oxygenation', true),
          _Ff('fluidsInOut', 'Fluids / I/O', true),
          _Ff('labsImaging', 'Labs / imaging', true),
          _Ff('plan', 'Plan', true),
        ],
      );
    case 'pmr.functional':
      return _multiTextCard(
        title: 'Functional status (PM&R)',
        subtitle: 'ADLs, mobility aids, therapy goals',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('adl', 'ADLs', true),
          _Ff('mobility', 'Mobility / transfers', true),
          _Ff('assistiveDevices', 'Assistive devices', true),
          _Ff('therapyGoals', 'Therapy goals', true),
        ],
      );
    case 'allergy.history':
      return _multiTextCard(
        title: 'Allergy / immunology history',
        subtitle: 'Triggers, reactions, testing, biologics',
        data: data,
        onChanged: onChanged,
        readOnly: readOnly,
        fields: const [
          _Ff('environmental', 'Environmental', true),
          _Ff('food', 'Food', true),
          _Ff('drug', 'Drug', true),
          _Ff('insect', 'Venom / insect', true),
          _Ff('testing', 'Skin test / labs', true),
          _Ff('immunotherapy', 'Immunotherapy', true),
        ],
      );
    default:
      return null;
  }
}

class _Ff {
  const _Ff(this.key, this.label, this.multiline);
  final String key;
  final String label;
  final bool multiline;
}

Widget _multiTextCard({
  required String title,
  String? subtitle,
  required Map<String, dynamic> data,
  required void Function(Map<String, dynamic>) onChanged,
  required bool readOnly,
  required List<_Ff> fields,
  Widget? extra,
}) {
  return ClinicalSectionCard(
    title: title,
    subtitle: subtitle,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final f in fields) ...[
          ClinicalLabeledField(
            label: f.label,
            child: TextFormField(
              initialValue: data[f.key]?.toString() ?? '',
              readOnly: readOnly,
              maxLines: f.multiline ? 4 : 1,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              onChanged: readOnly
                  ? null
                  : (v) {
                      final next = Map<String, dynamic>.from(data);
                      next[f.key] = v;
                      onChanged(next);
                    },
            ),
          ),
          const Gap(14),
        ],
        if (extra != null) extra,
      ],
    ),
  );
}

Widget _riskScoresForm(
  Map<String, dynamic> data,
  void Function(Map<String, dynamic>) onChanged,
  bool readOnly,
) {
  void setKey(String k, String v) {
    final next = Map<String, dynamic>.from(data);
    next[k] = v;
    onChanged(next);
  }

  int? heartScore() {
    final t = int.tryParse(data['heartTotal']?.toString() ?? '');
    return t;
  }

  return ClinicalSectionCard(
    title: 'Cardiac risk scores',
    subtitle: 'HEART score inputs (0–10); totals computed for audit',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'HEART — History (0–2)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        _heartDropdown(
          'heartHistory',
          data,
          setKey,
          readOnly,
          const ['0', '1', '2'],
        ),
        const Gap(12),
        Text(
          'HEART — ECG (0–2)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        _heartDropdown(
          'heartEcg',
          data,
          setKey,
          readOnly,
          const ['0', '1', '2'],
        ),
        const Gap(12),
        Text(
          'HEART — Age (0–2)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        _heartDropdown('heartAge', data, setKey, readOnly, const ['0', '1', '2']),
        const Gap(12),
        Text(
          'HEART — Risk factors (0–2)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        _heartDropdown(
          'heartRiskFactors',
          data,
          setKey,
          readOnly,
          const ['0', '1', '2'],
        ),
        const Gap(12),
        Text(
          'HEART — Troponin (0–3)',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        _heartDropdown(
          'heartTroponin',
          data,
          setKey,
          readOnly,
          const ['0', '1', '2', '3'],
        ),
        const Gap(16),
        FilledButton.tonalIcon(
          onPressed: readOnly
              ? null
              : () {
                  var sum = 0;
                  for (final k in [
                    'heartHistory',
                    'heartEcg',
                    'heartAge',
                    'heartRiskFactors',
                    'heartTroponin',
                  ]) {
                    sum += int.tryParse(data[k]?.toString() ?? '0') ?? 0;
                  }
                  final next = Map<String, dynamic>.from(data);
                  next['heartTotal'] = sum;
                  onChanged(next);
                },
          icon: const Icon(Icons.calculate_outlined, size: 20),
          label: Text(
            'HEART total: ${heartScore() ?? "—"} (tap to recompute)',
          ),
        ),
        const Gap(16),
          ClinicalLabeledField(
            label: 'ASCVD / other notes',
            child: TextFormField(
              initialValue: data['otherRiskNotes']?.toString() ?? '',
              readOnly: readOnly,
              maxLines: 3,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
              ),
              onChanged: readOnly
                  ? null
                  : (v) {
                      final next = Map<String, dynamic>.from(data);
                      next['otherRiskNotes'] = v;
                      onChanged(next);
                    },
            ),
          ),
      ],
    ),
  );
}

Widget _heartDropdown(
  String key,
  Map<String, dynamic> data,
  void Function(String k, String v) setKey,
  bool readOnly,
  List<String> items,
) {
  final cur = data[key]?.toString();
  return DropdownButtonFormField<String>(
    key: ValueKey('$key-$cur'),
    initialValue: items.contains(cur) ? cur : null,
    decoration: InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
    ),
    items: items
        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
        .toList(),
    onChanged: readOnly ? null : (v) => setKey(key, v ?? '0'),
  );
}

Widget _nihssForm(
  Map<String, dynamic> data,
  void Function(Map<String, dynamic>) onChanged,
  bool readOnly,
) {
  final items = <(String key, String label, List<int> opts)>[
    ('nihss_loc', '1a Level of consciousness', [0, 1, 2, 3]),
    ('nihss_locQuestions', '1b LOC questions', [0, 1, 2]),
    ('nihss_locCommands', '1c LOC commands', [0, 1, 2]),
    ('nihss_gaze', '2 Best gaze', [0, 1, 2]),
    ('nihss_visual', '3 Visual fields', [0, 1, 2, 3]),
    ('nihss_facial', '4 Facial palsy', [0, 1, 2, 3]),
    ('nihss_armL', '5a Motor arm left', [0, 1, 2, 3, 4]),
    ('nihss_armR', '5b Motor arm right', [0, 1, 2, 3, 4]),
    ('nihss_legL', '6a Motor leg left', [0, 1, 2, 3, 4]),
    ('nihss_legR', '6b Motor leg right', [0, 1, 2, 3, 4]),
    ('nihss_ataxia', '7 Limb ataxia', [0, 1, 2]),
    ('nihss_sensory', '8 Sensory', [0, 1, 2]),
    ('nihss_language', '9 Best language', [0, 1, 2, 3]),
    ('nihss_dysarthria', '10 Dysarthria', [0, 1, 2]),
    ('nihss_neglect', '11 Extinction / neglect', [0, 1, 2]),
  ];

  int computeTotal(Map<String, dynamic> m) {
    var sum = 0;
    for (final t in items) {
      sum += int.tryParse(m[t.$1]?.toString() ?? '0') ?? 0;
    }
    return sum;
  }

  int? total() => computeTotal(data);

  return ClinicalSectionCard(
    title: 'Stroke assessment (NIHSS-style)',
    subtitle: 'Item scores; total for serial comparison',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in items)
          ScoreDropdownTile(
            label: e.$2,
            value: int.tryParse(data[e.$1]?.toString() ?? ''),
            items: e.$3,
            readOnly: readOnly,
            onChanged: readOnly
                ? (_) {}
                : (v) {
                    final next = Map<String, dynamic>.from(data);
                    if (v != null) next[e.$1] = v;
                    next['nihssTotal'] = computeTotal(next);
                    onChanged(next);
                  },
          ),
        const Gap(8),
        Text(
          'NIHSS total: ${total() ?? "—"}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const Gap(12),
        ClinicalLabeledField(
          label: 'Additional notes',
          child: TextFormField(
            initialValue: data['strokeNotes']?.toString() ?? '',
            readOnly: readOnly,
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
            ),
            onChanged: readOnly
                ? null
                : (v) {
                    final next = Map<String, dynamic>.from(data);
                    next['strokeNotes'] = v;
                    onChanged(next);
                  },
          ),
        ),
      ],
    ),
  );
}
