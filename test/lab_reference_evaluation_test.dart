import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/utils/lab_reference_evaluation.dart';

void main() {
  group('lab_reference_evaluation', () {
    test('in-range result is not abnormal', () {
      const eval = ReferenceEvaluation(inRange: true, flag: null);
      expect(labResultIsAbnormal(eval), isFalse);
      expect(labReferenceFlagLabel(eval), isNull);
    });

    test('null evaluation is not abnormal', () {
      expect(labResultIsAbnormal(null), isFalse);
      expect(labReferenceFlagLabel(null), isNull);
    });

    test('HIGH flag produces above-range label', () {
      const eval = ReferenceEvaluation(
        inRange: false,
        flag: ReferenceFlag.high,
      );
      expect(labResultIsAbnormal(eval), isTrue);
      expect(labReferenceFlagLabel(eval), '↑ Above range');
      expect(labReferenceFlagShortLabel(eval), 'HIGH');
    });

    test('LOW flag produces below-range label', () {
      const eval = ReferenceEvaluation(
        inRange: false,
        flag: ReferenceFlag.low,
      );
      expect(labReferenceFlagLabel(eval), '↓ Below range');
      expect(labReferenceFlagShortLabel(eval), 'LOW');
    });

    test('value color is error only when abnormal', () {
      final theme = ThemeData.light();
      const abnormal = ReferenceEvaluation(inRange: false, flag: ReferenceFlag.high);
      expect(
        labReferenceValueColor(theme, abnormal),
        theme.colorScheme.error,
      );
      expect(labReferenceValueColor(theme, const ReferenceEvaluation(inRange: true)), isNull);
    });

    test('PDF result text appends flag for abnormal values', () {
      final result = LabResult(
        id: '1',
        orderItemId: 'o',
        fieldId: 'f',
        value: '130',
        referenceEvaluation: const ReferenceEvaluation(
          inRange: false,
          flag: ReferenceFlag.high,
        ),
      );
      expect(labPdfResultValueText(result), '130 ↑ HIGH');
    });
  });
}
