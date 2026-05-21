import 'encounter_question_models.dart';

const _other = QuestionDef(
  id: 'other',
  label: 'Other / additional details',
  type: QuestionType.text,
  maxLines: 3,
  isOther: true,
  hint: 'Free text not covered above',
);

/// Default examination sections for the encounter Examination tab.
final List<EncounterSectionDef> examinationQuestionnaireSections = [
  EncounterSectionDef(
    id: 'general',
    title: 'General Appearance',
    questions: [
      QuestionDef(
        id: 'generalState',
        label: 'General state',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'well', label: 'Well'),
          QuestionOption(value: 'ill', label: 'Ill'),
          QuestionOption(value: 'toxic', label: 'Toxic'),
        ],
      ),
      QuestionDef(
        id: 'distress',
        label: 'Distress',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'none', label: 'None'),
          QuestionOption(value: 'mild', label: 'Mild'),
          QuestionOption(value: 'moderate', label: 'Moderate'),
          QuestionOption(value: 'severe', label: 'Severe'),
        ],
      ),
      const QuestionDef(
        id: 'alert',
        label: 'Alert and oriented',
        type: QuestionType.yesNo,
      ),
      QuestionDef(
        id: 'hydration',
        label: 'Hydration',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'normal', label: 'Normal'),
          QuestionOption(value: 'dehydrated', label: 'Dehydrated'),
        ],
      ),
      const QuestionDef(
        id: 'cachexia',
        label: 'Cachexia / wasting',
        type: QuestionType.yesNo,
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'cvs',
    title: 'Cardiovascular',
    questions: [
      QuestionDef(
        id: 'heartSounds',
        label: 'Heart sounds',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'normal', label: 'Normal'),
          QuestionOption(value: 'muffled', label: 'Muffled'),
          QuestionOption(value: 'added', label: 'Added sounds'),
        ],
      ),
      QuestionDef(
        id: 'murmur',
        label: 'Murmur',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'none', label: 'None'),
          QuestionOption(value: 'systolic', label: 'Systolic'),
          QuestionOption(value: 'diastolic', label: 'Diastolic'),
        ],
      ),
      QuestionDef(
        id: 'jvp',
        label: 'JVP',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'not_raised', label: 'Not raised'),
          QuestionOption(value: 'raised', label: 'Raised'),
        ],
      ),
      QuestionDef(
        id: 'peripheralEdema',
        label: 'Peripheral edema',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'none', label: 'None'),
          QuestionOption(value: 'mild', label: 'Mild'),
          QuestionOption(value: 'moderate', label: 'Moderate'),
          QuestionOption(value: 'severe', label: 'Severe'),
        ],
      ),
      QuestionDef(
        id: 'pulses',
        label: 'Peripheral pulses',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'normal', label: 'Normal'),
          QuestionOption(value: 'diminished', label: 'Diminished'),
          QuestionOption(value: 'absent', label: 'Absent'),
        ],
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'resp',
    title: 'Respiratory',
    questions: [
      QuestionDef(
        id: 'respiratoryEffort',
        label: 'Respiratory effort',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'normal', label: 'Normal'),
          QuestionOption(value: 'increased', label: 'Increased'),
          QuestionOption(value: 'labored', label: 'Labored'),
        ],
      ),
      QuestionDef(
        id: 'airEntry',
        label: 'Air entry',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'equal', label: 'Equal bilaterally'),
          QuestionOption(value: 'reduced', label: 'Reduced'),
        ],
      ),
      QuestionDef(
        id: 'addedSounds',
        label: 'Added sounds',
        type: QuestionType.multiChoice,
        options: const [
          QuestionOption(value: 'none', label: 'None'),
          QuestionOption(value: 'wheeze', label: 'Wheeze'),
          QuestionOption(value: 'crackles', label: 'Crackles'),
          QuestionOption(value: 'bronchial', label: 'Bronchial breathing'),
        ],
      ),
      const QuestionDef(
        id: 'cough',
        label: 'Cough noted on exam',
        type: QuestionType.yesNo,
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'abdomen',
    title: 'Abdomen',
    questions: [
      QuestionDef(
        id: 'contour',
        label: 'Contour',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'soft', label: 'Soft, non-distended'),
          QuestionOption(value: 'distended', label: 'Distended'),
          QuestionOption(value: 'rigid', label: 'Rigid'),
        ],
      ),
      const QuestionDef(
        id: 'tenderness',
        label: 'Tenderness',
        type: QuestionType.text,
        hint: 'Site and severity if present',
      ),
      const QuestionDef(
        id: 'organomegaly',
        label: 'Organomegaly',
        type: QuestionType.text,
        hint: 'Liver, spleen, etc.',
      ),
      QuestionDef(
        id: 'bowelSounds',
        label: 'Bowel sounds',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'normal', label: 'Normal'),
          QuestionOption(value: 'hyperactive', label: 'Hyperactive'),
          QuestionOption(value: 'absent', label: 'Absent'),
        ],
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'cns',
    title: 'CNS',
    questions: [
      const QuestionDef(
        id: 'oriented',
        label: 'Oriented to person, place, time',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'cranialNerves',
        label: 'Cranial nerves',
        type: QuestionType.text,
        hint: 'Normal or findings',
      ),
      const QuestionDef(
        id: 'motor',
        label: 'Motor',
        type: QuestionType.text,
      ),
      const QuestionDef(
        id: 'sensory',
        label: 'Sensory',
        type: QuestionType.text,
      ),
      const QuestionDef(
        id: 'reflexes',
        label: 'Reflexes',
        type: QuestionType.text,
      ),
      const QuestionDef(
        id: 'gait',
        label: 'Gait / coordination',
        type: QuestionType.text,
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'msk',
    title: 'Musculoskeletal',
    questions: [
      const QuestionDef(
        id: 'gait',
        label: 'Gait',
        type: QuestionType.text,
      ),
      const QuestionDef(
        id: 'rom',
        label: 'Range of motion',
        type: QuestionType.text,
      ),
      const QuestionDef(
        id: 'swelling',
        label: 'Swelling',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'deformity',
        label: 'Deformity',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'tenderness',
        label: 'Tenderness',
        type: QuestionType.text,
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'ent',
    title: 'ENT',
    questions: [
      const QuestionDef(
        id: 'heent',
        label: 'HEENT inspection',
        type: QuestionType.text,
      ),
      const QuestionDef(
        id: 'throat',
        label: 'Throat / oropharynx',
        type: QuestionType.text,
      ),
      const QuestionDef(
        id: 'lymphadenopathy',
        label: 'Cervical lymphadenopathy',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'hearing',
        label: 'Hearing',
        type: QuestionType.text,
      ),
      _other,
    ],
  ),
  EncounterSectionDef(
    id: 'skin',
    title: 'Skin',
    questions: [
      const QuestionDef(
        id: 'rash',
        label: 'Rash',
        type: QuestionType.yesNo,
      ),
      const QuestionDef(
        id: 'rashDetail',
        label: 'Rash description',
        type: QuestionType.text,
        visibleWhen: VisibleWhen(questionId: 'rash', equalsBool: true),
      ),
      const QuestionDef(
        id: 'lesions',
        label: 'Lesions / ulcers',
        type: QuestionType.text,
      ),
      QuestionDef(
        id: 'color',
        label: 'Color',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'normal', label: 'Normal'),
          QuestionOption(value: 'pale', label: 'Pale'),
          QuestionOption(value: 'jaundiced', label: 'Jaundiced'),
          QuestionOption(value: 'cyanosed', label: 'Cyanosed'),
        ],
      ),
      QuestionDef(
        id: 'turgor',
        label: 'Turgor',
        type: QuestionType.singleChoice,
        options: const [
          QuestionOption(value: 'normal', label: 'Normal'),
          QuestionOption(value: 'reduced', label: 'Reduced'),
        ],
      ),
      const QuestionDef(
        id: 'wounds',
        label: 'Wounds / dressings',
        type: QuestionType.text,
      ),
      _other,
    ],
  ),
];

/// Short label used when building examinationNotes blob.
const Map<String, String> examinationSectionNoteLabels = {
  'general': 'General',
  'cvs': 'CVS',
  'resp': 'Resp',
  'abdomen': 'Abdomen',
  'cns': 'CNS',
  'msk': 'MSK',
  'ent': 'ENT',
  'skin': 'Skin',
};
