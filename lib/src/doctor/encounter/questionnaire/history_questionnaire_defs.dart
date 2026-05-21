import 'encounter_question_models.dart';

const _other = QuestionDef(
  id: 'other',
  label: 'Other / additional details',
  type: QuestionType.text,
  maxLines: 3,
  isOther: true,
  hint: 'Free text not covered above',
);

/// Default history sections for the encounter History tab.
final List<EncounterSectionDef> historyQuestionnaireSections = [
  EncounterSectionDef(
    id: 'chiefComplaint',
    title: 'Chief Complaint',
    subtitle: 'Primary reason for visit',
    questions: [
      const QuestionDef(
        id: 'mainComplaint',
        label: 'Main complaint',
        type: QuestionType.text,
        hint: 'e.g. chest pain, fever, headache',
      ),
      QuestionDef(
        id: 'onset',
        label: 'Onset',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'sudden', label: 'Sudden'),
          QuestionOption(value: 'gradual', label: 'Gradual'),
          QuestionOption(value: 'chronic', label: 'Chronic'),
        ],
      ),
      const QuestionDef(
        id: 'duration',
        label: 'Duration',
        type: QuestionType.text,
        hint: 'e.g. 3 days, 2 weeks',
      ),
      QuestionDef(
        id: 'severity',
        label: 'Severity',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'mild', label: 'Mild'),
          QuestionOption(value: 'moderate', label: 'Moderate'),
          QuestionOption(value: 'severe', label: 'Severe'),
        ],
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'hpi',
    title: 'History of Present Illness (HPI)',
    subtitle: 'Details of the current illness',
    questions: [
      QuestionDef(
        id: 'onset',
        label: 'Onset',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'sudden', label: 'Sudden'),
          QuestionOption(value: 'gradual', label: 'Gradual'),
        ],
      ),
      const QuestionDef(
        id: 'duration',
        label: 'Duration',
        type: QuestionType.text,
        hint: 'How long symptoms have been present',
      ),
      const QuestionDef(
        id: 'location',
        label: 'Location',
        type: QuestionType.text,
        hint: 'Site of symptom',
      ),
      const QuestionDef(
        id: 'character',
        label: 'Character',
        type: QuestionType.text,
        hint: 'e.g. sharp, dull, burning',
      ),
      const QuestionDef(
        id: 'radiation',
        label: 'Radiation',
        type: QuestionType.text,
        hint: 'Does pain/symptom spread?',
      ),
      QuestionDef(
        id: 'timing',
        label: 'Timing',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'constant', label: 'Constant'),
          QuestionOption(value: 'intermittent', label: 'Intermittent'),
          QuestionOption(value: 'nocturnal', label: 'Worse at night'),
        ],
      ),
      QuestionDef(
        id: 'severity',
        label: 'Severity',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'mild', label: 'Mild'),
          QuestionOption(value: 'moderate', label: 'Moderate'),
          QuestionOption(value: 'severe', label: 'Severe'),
        ],
      ),
      const QuestionDef(
        id: 'aggravating',
        label: 'Aggravating factors',
        type: QuestionType.text,
      ),
      const QuestionDef(
        id: 'relieving',
        label: 'Relieving factors',
        type: QuestionType.text,
      ),
      QuestionDef(
        id: 'associated',
        label: 'Associated symptoms',
        type: QuestionType.multiChoice,
        options: const [
          QuestionOption(value: 'fever', label: 'Fever'),
          QuestionOption(value: 'cough', label: 'Cough'),
          QuestionOption(value: 'nausea', label: 'Nausea/vomiting'),
          QuestionOption(value: 'dyspnea', label: 'Shortness of breath'),
          QuestionOption(value: 'weight_loss', label: 'Weight loss'),
          QuestionOption(value: 'fatigue', label: 'Fatigue'),
        ],
      ),
      const QuestionDef(
        id: 'priorEpisodes',
        label: 'Prior similar episodes',
        type: QuestionType.yesNo,
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'pmh',
    title: 'Past Medical History (PMH)',
    subtitle: 'Chronic and past medical conditions',
    questions: [
      const QuestionDef(
        id: 'hypertension',
        label: 'Hypertension',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'hypertensionDetail',
        label: 'Hypertension details',
        type: QuestionType.text,
        visibleWhen: VisibleWhen(questionId: 'hypertension', equalsBool: true),
      ),
      const QuestionDef(
        id: 'diabetes',
        label: 'Diabetes mellitus',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'diabetesDetail',
        label: 'Diabetes details',
        type: QuestionType.text,
        visibleWhen: VisibleWhen(questionId: 'diabetes', equalsBool: true),
      ),
      const QuestionDef(
        id: 'asthmaCopd',
        label: 'Asthma / COPD',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'cardiac',
        label: 'Cardiac disease',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'renal',
        label: 'Renal disease',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'psychiatric',
        label: 'Psychiatric illness',
        type: QuestionType.yesNo,
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'surgicalHistory',
    title: 'Surgical History',
    questions: [
      const QuestionDef(
        id: 'priorSurgery',
        label: 'Prior surgery',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'procedures',
        label: 'Procedures and year(s)',
        type: QuestionType.text,
        maxLines: 2,
        visibleWhen: VisibleWhen(questionId: 'priorSurgery', equalsBool: true),
      ),
      const QuestionDef(
        id: 'complications',
        label: 'Surgical complications',
        type: QuestionType.yesNo,
        visibleWhen: VisibleWhen(questionId: 'priorSurgery', equalsBool: true),
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'drugHistory',
    title: 'Drug History',
    questions: [
      const QuestionDef(
        id: 'onRegularMeds',
        label: 'On regular medications',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'medicationList',
        label: 'Current medications',
        type: QuestionType.text,
        maxLines: 3,
        visibleWhen: VisibleWhen(questionId: 'onRegularMeds', equalsBool: true),
      ),
      QuestionDef(
        id: 'adherence',
        label: 'Adherence',
        type: QuestionType.singleChoice,
        visibleWhen: VisibleWhen(questionId: 'onRegularMeds', equalsBool: true),
        options: const [
          QuestionOption(value: 'good', label: 'Good'),
          QuestionOption(value: 'partial', label: 'Partial'),
          QuestionOption(value: 'poor', label: 'Poor'),
        ],
      ),
      const QuestionDef(
        id: 'otcHerbal',
        label: 'OTC / herbal use',
        type: QuestionType.text,
        maxLines: 2,
      ),
      const QuestionDef(
        id: 'recentChanges',
        label: 'Recent dose or drug changes',
        type: QuestionType.text,
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'allergyHistory',
    title: 'Allergy History',
    questions: [
      const QuestionDef(
        id: 'nkda',
        label: 'No known drug allergies (NKDA)',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'drugAllergy',
        label: 'Drug allergy',
        type: QuestionType.yesNo,
        visibleWhen: VisibleWhen(questionId: 'nkda', equalsBool: false),
      ),
      const QuestionDef(
        id: 'drugAllergyDetail',
        label: 'Drug allergy (agent and reaction)',
        type: QuestionType.text,
        visibleWhen: VisibleWhen(questionId: 'drugAllergy', equalsBool: true),
      ),
      const QuestionDef(
        id: 'foodAllergy',
        label: 'Food allergy',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'foodAllergyDetail',
        label: 'Food allergy details',
        type: QuestionType.text,
        visibleWhen: VisibleWhen(questionId: 'foodAllergy', equalsBool: true),
      ),
      const QuestionDef(
        id: 'environmentalAllergy',
        label: 'Environmental allergy',
        type: QuestionType.yesNo,
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'familyHistory',
    title: 'Family History',
    subtitle: 'Relevant conditions in first-degree relatives',
    questions: [
      QuestionDef(
        id: 'conditions',
        label: 'Family conditions',
        type: QuestionType.multiChoice,
        options: const [
          QuestionOption(value: 'dm', label: 'Diabetes'),
          QuestionOption(value: 'htn', label: 'Hypertension'),
          QuestionOption(value: 'cancer', label: 'Cancer'),
          QuestionOption(value: 'cardiac', label: 'Cardiac disease'),
          QuestionOption(value: 'sudden_death', label: 'Sudden death'),
          QuestionOption(value: 'stroke', label: 'Stroke'),
        ],
      ),
      const QuestionDef(
        id: 'details',
        label: 'Details (who, age, condition)',
        type: QuestionType.text,
        maxLines: 2,
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'socialHistory',
    title: 'Social History',
    questions: [
      const QuestionDef(
        id: 'smoking',
        label: 'Current smoker',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'packYears',
        label: 'Pack-years',
        type: QuestionType.number,
        hint: 'e.g. 10',
        visibleWhen: VisibleWhen(questionId: 'smoking', equalsBool: true),
      ),
      const QuestionDef(
        id: 'smokingYears',
        label: 'Years smoking',
        type: QuestionType.number,
        visibleWhen: VisibleWhen(questionId: 'smoking', equalsBool: true),
      ),
      const QuestionDef(
        id: 'exSmoker',
        label: 'Ex-smoker',
        type: QuestionType.yesNo,
        visibleWhen: VisibleWhen(questionId: 'smoking', equalsBool: false),
      ),
      const QuestionDef(
        id: 'alcohol',
        label: 'Alcohol use',
        type: QuestionType.yesNo,
      ),
      QuestionDef(
        id: 'alcoholFrequency',
        label: 'Alcohol frequency',
        type: QuestionType.singleChoice,
        visibleWhen: VisibleWhen(questionId: 'alcohol', equalsBool: true),
        options: const [
          QuestionOption(value: 'occasional', label: 'Occasional'),
          QuestionOption(value: 'regular', label: 'Regular'),
          QuestionOption(value: 'heavy', label: 'Heavy'),
        ],
      ),
      const QuestionDef(
        id: 'alcoholUnits',
        label: 'Units per week',
        type: QuestionType.number,
        visibleWhen: VisibleWhen(questionId: 'alcohol', equalsBool: true),
      ),
      const QuestionDef(
        id: 'occupation',
        label: 'Occupation',
        type: QuestionType.text,
      ),
      QuestionDef(
        id: 'maritalStatus',
        label: 'Marital status',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'single', label: 'Single'),
          QuestionOption(value: 'married', label: 'Married'),
          QuestionOption(value: 'divorced', label: 'Divorced'),
          QuestionOption(value: 'widowed', label: 'Widowed'),
        ],
      ),
      QuestionDef(
        id: 'exercise',
        label: 'Exercise',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'sedentary', label: 'Sedentary'),
          QuestionOption(value: 'moderate', label: 'Moderate'),
          QuestionOption(value: 'active', label: 'Active'),
        ],
      ),
      _other,
    ],
  ),
];

/// API field name for each history section id.
const Map<String, String> historySectionApiFields = {
  'chiefComplaint': 'chiefComplaint',
  'hpi': 'hpi',
  'pmh': 'pmh',
  'surgicalHistory': 'surgicalHistory',
  'drugHistory': 'drugHistory',
  'allergyHistory': 'allergyHistory',
  'familyHistory': 'familyHistory',
  'socialHistory': 'socialHistory',
};
