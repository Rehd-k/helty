import 'encounter_question_models.dart';

const _other = QuestionDef(
  id: 'other',
  label: 'Other / additional details',
  type: QuestionType.text,
  maxLines: 3,
  isOther: true,
  hint: 'Free text not covered above',
);

/// Structured operative-note sections for theatre / encounter OP notes.
final List<EncounterSectionDef> operativeNoteQuestionnaireSections = [
  EncounterSectionDef(
    id: 'procedure',
    title: 'Procedure',
    subtitle: 'What was performed',
    questions: [
      const QuestionDef(
        id: 'name',
        label: 'Procedure performed',
        type: QuestionType.text,
        hint: 'e.g. Open appendectomy',
      ),
      QuestionDef(
        id: 'laterality',
        label: 'Laterality',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'na', label: 'Not applicable'),
          QuestionOption(value: 'left', label: 'Left'),
          QuestionOption(value: 'right', label: 'Right'),
          QuestionOption(value: 'bilateral', label: 'Bilateral'),
        ],
      ),
      QuestionDef(
        id: 'urgency',
        label: 'Urgency',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'elective', label: 'Elective'),
          QuestionOption(value: 'urgent', label: 'Urgent'),
          QuestionOption(value: 'emergency', label: 'Emergency'),
        ],
      ),
      QuestionDef(
        id: 'asa',
        label: 'ASA grade',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: '1', label: 'I'),
          QuestionOption(value: '2', label: 'II'),
          QuestionOption(value: '3', label: 'III'),
          QuestionOption(value: '4', label: 'IV'),
          QuestionOption(value: '5', label: 'V'),
        ],
      ),
      const QuestionDef(
        id: 'indication',
        label: 'Indication',
        type: QuestionType.text,
        maxLines: 3,
        hint: 'Clinical reason for surgery',
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'team',
    title: 'Surgical team',
    subtitle: 'Who was in theatre',
    questions: [
      const QuestionDef(
        id: 'surgeon',
        label: 'Surgeon',
        type: QuestionType.text,
      ),
      const QuestionDef(
        id: 'assistant',
        label: 'Assistant(s)',
        type: QuestionType.text,
      ),
      const QuestionDef(
        id: 'anaesthetist',
        label: 'Anaesthetist',
        type: QuestionType.text,
      ),
      const QuestionDef(
        id: 'scrub',
        label: 'Scrub nurse',
        type: QuestionType.text,
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'diagnoses',
    title: 'Diagnoses',
    subtitle: 'Pre- and post-operative',
    questions: [
      const QuestionDef(
        id: 'preop',
        label: 'Pre-operative diagnosis',
        type: QuestionType.text,
        maxLines: 2,
      ),
      const QuestionDef(
        id: 'postopSame',
        label: 'Post-operative diagnosis same as pre-operative',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'postop',
        label: 'Post-operative diagnosis',
        type: QuestionType.text,
        maxLines: 2,
        visibleWhen: VisibleWhen(questionId: 'postopSame', equalsBool: false),
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'consent',
    title: 'Consent and checklist',
    questions: [
      const QuestionDef(
        id: 'consentObtained',
        label: 'Informed consent obtained',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'siteMarked',
        label: 'Site marked',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'signIn',
        label: 'WHO sign-in completed',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'timeOut',
        label: 'WHO time-out completed',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'signOut',
        label: 'WHO sign-out completed',
        type: QuestionType.yesNo,
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'anaesthesia',
    title: 'Anaesthesia',
    questions: [
      QuestionDef(
        id: 'type',
        label: 'Anaesthesia type',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'ga', label: 'General'),
          QuestionOption(value: 'spinal', label: 'Spinal'),
          QuestionOption(value: 'epidural', label: 'Epidural'),
          QuestionOption(value: 'regional', label: 'Regional'),
          QuestionOption(value: 'local', label: 'Local'),
          QuestionOption(value: 'sedation', label: 'Sedation'),
          QuestionOption(value: 'combined', label: 'Combined'),
        ],
      ),
      QuestionDef(
        id: 'airway',
        label: 'Airway',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'ett', label: 'Endotracheal tube'),
          QuestionOption(value: 'lma', label: 'LMA'),
          QuestionOption(value: 'spontaneous', label: 'Spontaneous / none'),
          QuestionOption(value: 'other', label: 'Other'),
        ],
      ),
      const QuestionDef(
        id: 'antibiotics',
        label: 'Prophylactic antibiotics given',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'antibioticDetail',
        label: 'Antibiotic details',
        type: QuestionType.text,
        hint: 'Drug, dose, time',
        visibleWhen: VisibleWhen(questionId: 'antibiotics', equalsBool: true),
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'preparation',
    title: 'Preparation',
    subtitle: 'Position, prep, and incision',
    questions: [
      QuestionDef(
        id: 'position',
        label: 'Patient position',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'supine', label: 'Supine'),
          QuestionOption(value: 'prone', label: 'Prone'),
          QuestionOption(value: 'lithotomy', label: 'Lithotomy'),
          QuestionOption(value: 'lateral', label: 'Lateral'),
          QuestionOption(value: 'trendelenburg', label: 'Trendelenburg'),
          QuestionOption(value: 'other', label: 'Other'),
        ],
      ),
      const QuestionDef(
        id: 'skinPrep',
        label: 'Skin preparation',
        type: QuestionType.text,
        hint: 'e.g. chlorhexidine, povidone-iodine',
      ),
      const QuestionDef(
        id: 'incision',
        label: 'Incision',
        type: QuestionType.text,
        hint: 'Type, site, length',
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'findings',
    title: 'Findings',
    subtitle: 'Intraoperative findings',
    questions: [
      const QuestionDef(
        id: 'intraop',
        label: 'Intraoperative findings',
        type: QuestionType.text,
        maxLines: 4,
      ),
      const QuestionDef(
        id: 'unexpected',
        label: 'Unexpected findings',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'unexpectedDetail',
        label: 'Unexpected findings details',
        type: QuestionType.text,
        maxLines: 3,
        visibleWhen: VisibleWhen(questionId: 'unexpected', equalsBool: true),
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'details',
    title: 'Procedure details',
    subtitle: 'Steps, implants, specimens, drains',
    questions: [
      const QuestionDef(
        id: 'steps',
        label: 'Procedure / technique',
        type: QuestionType.text,
        maxLines: 6,
        hint: 'Key operative steps',
      ),
      const QuestionDef(
        id: 'implants',
        label: 'Implants / devices used',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'implantDetail',
        label: 'Implant details',
        type: QuestionType.text,
        hint: 'Type, size, laterality, serial',
        visibleWhen: VisibleWhen(questionId: 'implants', equalsBool: true),
      ),
      const QuestionDef(
        id: 'specimens',
        label: 'Specimens sent',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'specimenDetail',
        label: 'Specimen details',
        type: QuestionType.text,
        hint: 'What was sent and where',
        visibleWhen: VisibleWhen(questionId: 'specimens', equalsBool: true),
      ),
      const QuestionDef(
        id: 'drains',
        label: 'Drains placed',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'drainDetail',
        label: 'Drain details',
        type: QuestionType.text,
        hint: 'Type, site, number',
        visibleWhen: VisibleWhen(questionId: 'drains', equalsBool: true),
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'closure',
    title: 'Haemostasis and closure',
    questions: [
      QuestionDef(
        id: 'haemostasis',
        label: 'Haemostasis',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'satisfactory', label: 'Satisfactory'),
          QuestionOption(value: 'diathermy', label: 'Diathermy'),
          QuestionOption(value: 'ligation', label: 'Ligation / clips'),
          QuestionOption(value: 'packing', label: 'Packing'),
          QuestionOption(value: 'other', label: 'Other'),
        ],
      ),
      const QuestionDef(
        id: 'layers',
        label: 'Closure layers',
        type: QuestionType.text,
        hint: 'e.g. peritoneum, fascia, subcuticular skin',
      ),
      const QuestionDef(
        id: 'sutures',
        label: 'Suture / staple materials',
        type: QuestionType.text,
      ),
      const QuestionDef(
        id: 'dressing',
        label: 'Dressing',
        type: QuestionType.text,
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'counts',
    title: 'Counts and blood loss',
    questions: [
      const QuestionDef(
        id: 'swabCount',
        label: 'Swab count correct',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'instrumentCount',
        label: 'Instrument count correct',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'needleCount',
        label: 'Needle count correct',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'ebl',
        label: 'Estimated blood loss',
        type: QuestionType.text,
        hint: 'e.g. 150 ml',
      ),
      const QuestionDef(
        id: 'transfusion',
        label: 'Transfusion given',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'transfusionDetail',
        label: 'Transfusion details',
        type: QuestionType.text,
        visibleWhen: VisibleWhen(questionId: 'transfusion', equalsBool: true),
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'complications',
    title: 'Complications',
    questions: [
      const QuestionDef(
        id: 'occurred',
        label: 'Intraoperative complications',
        type: QuestionType.yesNo,
      ),
      QuestionDef(
        id: 'types',
        label: 'Complication type',
        type: QuestionType.multiChoice,
        visibleWhen: const VisibleWhen(
          questionId: 'occurred',
          equalsBool: true,
        ),
        options: const [
          QuestionOption(value: 'bleeding', label: 'Bleeding'),
          QuestionOption(value: 'injury', label: 'Organ / structure injury'),
          QuestionOption(value: 'conversion', label: 'Conversion'),
          QuestionOption(value: 'anaesthetic', label: 'Anaesthetic'),
          QuestionOption(value: 'other', label: 'Other'),
        ],
      ),
      const QuestionDef(
        id: 'management',
        label: 'Immediate management',
        type: QuestionType.text,
        maxLines: 3,
        visibleWhen: VisibleWhen(questionId: 'occurred', equalsBool: true),
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'outcome',
    title: 'Outcome',
    subtitle: 'Condition at end of procedure',
    questions: [
      QuestionDef(
        id: 'condition',
        label: 'Patient condition at end',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'stable', label: 'Stable'),
          QuestionOption(value: 'critical', label: 'Critical'),
          QuestionOption(value: 'unstable', label: 'Unstable'),
        ],
      ),
      QuestionDef(
        id: 'destination',
        label: 'Destination',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'recovery', label: 'Recovery'),
          QuestionOption(value: 'ward', label: 'Ward'),
          QuestionOption(value: 'icu', label: 'ICU / HDU'),
          QuestionOption(value: 'other', label: 'Other'),
        ],
      ),
      const QuestionDef(
        id: 'postopInstructions',
        label: 'Post-operative instructions',
        type: QuestionType.text,
        maxLines: 4,
      ),
      _other,
    ],
  ),
];

const Map<String, String> operativeNoteSectionLabels = {
  'procedure': 'Procedure',
  'team': 'Team',
  'diagnoses': 'Diagnoses',
  'consent': 'Consent',
  'anaesthesia': 'Anaesthesia',
  'preparation': 'Preparation',
  'findings': 'Findings',
  'details': 'Procedure details',
  'closure': 'Closure',
  'counts': 'Counts',
  'complications': 'Complications',
  'outcome': 'Outcome',
};
