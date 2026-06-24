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

    test('computeLabReferenceEvaluation parses min-max range', () {
      final high = computeLabReferenceEvaluation(
        value: '130',
        referenceRange: '4.0 - 11.0',
      );
      expect(high?.isAbnormal, isTrue);
      expect(high?.flag, ReferenceFlag.high);

      final inRange = computeLabReferenceEvaluation(
        value: '7.5',
        referenceRange: '4.0 - 11.0',
      );
      expect(inRange?.isAbnormal, isFalse);

      final low = computeLabReferenceEvaluation(
        value: '2.0',
        referenceRange: '4.0 - 11.0',
      );
      expect(low?.isAbnormal, isTrue);
      expect(low?.flag, ReferenceFlag.low);
    });

    test('computeLabReferenceEvaluation parses upper and lower bounds', () {
      expect(
        computeLabReferenceEvaluation(value: '6', referenceRange: '< 5')
            ?.flag,
        ReferenceFlag.high,
      );
      expect(
        computeLabReferenceEvaluation(value: '3', referenceRange: '< 5')
            ?.inRange,
        isTrue,
      );
      expect(
        computeLabReferenceEvaluation(value: '8', referenceRange: '> 10')
            ?.flag,
        ReferenceFlag.low,
      );
      expect(
        computeLabReferenceEvaluation(value: '12', referenceRange: '> 10')
            ?.inRange,
        isTrue,
      );
    });

    test('computeLabReferenceEvaluation returns null for text values', () {
      expect(
        computeLabReferenceEvaluation(
          value: 'Clear',
          referenceRange: '4.0 - 11.0',
        ),
        isNull,
      );
      expect(
        computeLabReferenceEvaluation(value: '7.5', referenceRange: null),
        isNull,
      );
    });

    test('resolveLabReferenceEvaluation prefers server evaluation', () {
      const server = ReferenceEvaluation(inRange: true);
      expect(
        resolveLabReferenceEvaluation(
          value: '130',
          referenceRange: '4.0 - 11.0',
          serverEvaluation: server,
        ),
        server,
      );
    });

    test('resolveLabReferenceEvaluation falls back to client compute', () {
      final eval = resolveLabReferenceEvaluation(
        value: '130',
        referenceRange: '4.0 - 11.0',
        serverEvaluation: null,
      );
      expect(eval?.isAbnormal, isTrue);
      expect(eval?.flag, ReferenceFlag.high);
    });
  });
}
