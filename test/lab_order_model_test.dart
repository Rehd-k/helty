import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/models/lab_order_model.dart';

void main() {
  group('LabOrderModel', () {
    test('parses referenceEvaluation on nested result lines', () {
      final order = LabOrderModel.fromJson({
        'id': 'req-1',
        'encounterId': 'enc-1',
        'catalogTestId': 'cat-1',
        'testType': 'Full Blood Count',
        'status': 'Completed',
        'labOrder': {
          'items': [
            {
              'results': [
                {
                  'value': '130',
                  'fieldId': 'wbc',
                  'field': {
                    'label': 'WBC',
                    'unit': '10^9/L',
                    'referenceRange': '4.0 - 11.0',
                    'position': 0,
                  },
                  'referenceEvaluation': {
                    'inRange': false,
                    'flag': 'HIGH',
                    'parsedValue': 130,
                    'referenceRange': '4.0 - 11.0',
                  },
                },
                {
                  'value': '7.5',
                  'fieldId': 'hgb',
                  'field': {
                    'label': 'Haemoglobin',
                    'unit': 'g/dL',
                    'referenceRange': '12.0 - 16.0',
                    'position': 1,
                  },
                  'referenceEvaluation': {
                    'inRange': true,
                    'flag': null,
                  },
                },
              ],
            },
          ],
        },
      });

      final lines = order.resultLines;
      expect(lines, isNotNull);
      expect(lines!.length, 2);

      final wbc = lines[0];
      expect(wbc.label, 'WBC');
      expect(wbc.value, '130');
      expect(wbc.unit, '10^9/L');
      expect(wbc.referenceRange, '4.0 - 11.0');
      expect(wbc.referenceEvaluation, isNotNull);
      expect(wbc.referenceEvaluation!.isAbnormal, isTrue);
      expect(wbc.referenceEvaluation!.flag, ReferenceFlag.high);

      final hgb = lines[1];
      expect(hgb.label, 'Haemoglobin');
      expect(hgb.referenceEvaluation, isNotNull);
      expect(hgb.referenceEvaluation!.isAbnormal, isFalse);
    });

    test('parses result lines without referenceEvaluation', () {
      final order = LabOrderModel.fromJson({
        'id': 'req-2',
        'encounterId': 'enc-2',
        'catalogTestId': 'cat-2',
        'testType': 'Urinalysis',
        'status': 'Completed',
        'labOrder': {
          'items': [
            {
              'results': [
                {
                  'value': 'Clear',
                  'fieldId': 'appearance',
                  'field': {
                    'label': 'Appearance',
                    'position': 0,
                  },
                },
              ],
            },
          ],
        },
      });

      final lines = order.resultLines;
      expect(lines, isNotNull);
      expect(lines!.single.referenceEvaluation, isNull);
    });
  });
}
