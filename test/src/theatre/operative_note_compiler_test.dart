import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/doctor/encounter/questionnaire/operative_note_compiler.dart';
import 'package:helty/src/theatre/models/theatre_models.dart';

void main() {
  group('operative note compiler', () {
    test('serializes and restores questionnaire answers', () {
      final original = emptyOperativeNoteAnswers();
      original['procedure'] = {
        'name': 'Appendectomy',
        'laterality': 'na',
        'urgency': 'emergency',
      };
      original['findings'] = {'intraop': 'Inflamed appendix', 'unexpected': false};

      final encoded = serializeOperativeNoteAnswers(original);
      final restored = parseOperativeNoteAnswers(encoded);

      expect(restored['procedure']?['name'], 'Appendectomy');
      expect(restored['findings']?['intraop'], 'Inflamed appendix');
      expect(compileOperativeNoteNarrative(answers: restored), contains('Appendectomy'));
    });

    test('prefills procedure and team', () {
      final answers = prefillOperativeNoteAnswers(
        procedureName: 'Hernia repair',
        surgeon: 'Dr A',
        anaesthetist: 'Dr B',
      );
      expect(answers['procedure']?['name'], 'Hernia repair');
      expect(answers['team']?['surgeon'], 'Dr A');
      expect(answers['team']?['anaesthetist'], 'Dr B');
    });
  });

  group('SurgeryRequestStatus.allowsOperativeNotes', () {
    test('only in progress and completed', () {
      expect(SurgeryRequestStatus.requested.allowsOperativeNotes, isFalse);
      expect(SurgeryRequestStatus.scheduled.allowsOperativeNotes, isFalse);
      expect(SurgeryRequestStatus.inProgress.allowsOperativeNotes, isTrue);
      expect(SurgeryRequestStatus.completed.allowsOperativeNotes, isTrue);
      expect(SurgeryRequestStatus.billed.allowsOperativeNotes, isFalse);
    });
  });
}
