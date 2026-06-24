import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

import '../models/lab_models.dart';

/// Parses a numeric result value; returns null for non-numeric text.
double? parseLabResultNumericValue(String value) {
  final cleaned = value.trim().replaceAll(',', '');
  if (cleaned.isEmpty) return null;
  return double.tryParse(cleaned);
}

/// Client-side comparison when the API omits [ReferenceEvaluation].
ReferenceEvaluation? computeLabReferenceEvaluation({
  required String value,
  String? referenceRange,
}) {
  final range = referenceRange?.trim();
  if (range == null || range.isEmpty) return null;

  final parsedValue = parseLabResultNumericValue(value);
  if (parsedValue == null) return null;

  final minMax = RegExp(r'^([\d.]+)\s*[-–]\s*([\d.]+)$').firstMatch(range);
  if (minMax != null) {
    final min = double.tryParse(minMax.group(1)!);
    final max = double.tryParse(minMax.group(2)!);
    if (min == null || max == null) return null;
    if (parsedValue >= min && parsedValue <= max) {
      return ReferenceEvaluation(
        inRange: true,
        parsedValue: parsedValue,
        referenceRange: range,
      );
    }
    return ReferenceEvaluation(
      inRange: false,
      flag: parsedValue < min ? ReferenceFlag.low : ReferenceFlag.high,
      parsedValue: parsedValue,
      referenceRange: range,
    );
  }

  final upperOnly = RegExp(r'^[<≤]\s*([\d.]+)$').firstMatch(range);
  if (upperOnly != null) {
    final bound = double.tryParse(upperOnly.group(1)!);
    if (bound == null) return null;
    final inclusive = range.startsWith('≤');
    final inRange = inclusive ? parsedValue <= bound : parsedValue < bound;
    if (inRange) {
      return ReferenceEvaluation(
        inRange: true,
        parsedValue: parsedValue,
        referenceRange: range,
      );
    }
    return ReferenceEvaluation(
      inRange: false,
      flag: ReferenceFlag.high,
      parsedValue: parsedValue,
      referenceRange: range,
    );
  }

  final lowerOnly = RegExp(r'^[>≥]\s*([\d.]+)$').firstMatch(range);
  if (lowerOnly != null) {
    final bound = double.tryParse(lowerOnly.group(1)!);
    if (bound == null) return null;
    final inclusive = range.startsWith('≥');
    final inRange = inclusive ? parsedValue >= bound : parsedValue > bound;
    if (inRange) {
      return ReferenceEvaluation(
        inRange: true,
        parsedValue: parsedValue,
        referenceRange: range,
      );
    }
    return ReferenceEvaluation(
      inRange: false,
      flag: ReferenceFlag.low,
      parsedValue: parsedValue,
      referenceRange: range,
    );
  }

  return null;
}

/// Prefer server evaluation; fall back to local numeric comparison.
ReferenceEvaluation? resolveLabReferenceEvaluation({
  required String value,
  String? referenceRange,
  ReferenceEvaluation? serverEvaluation,
}) {
  if (serverEvaluation != null) return serverEvaluation;
  return computeLabReferenceEvaluation(
    value: value,
    referenceRange: referenceRange,
  );
}

/// Whether the result should be highlighted as outside reference range.
bool labResultIsAbnormal(ReferenceEvaluation? eval) =>
    eval?.isAbnormal ?? false;

/// Short label for UI (e.g. "↓ Below range").
String? labReferenceFlagLabel(ReferenceEvaluation? eval) {
  if (eval?.inRange != false) return null;
  switch (eval!.flag) {
    case ReferenceFlag.low:
      return '↓ Below range';
    case ReferenceFlag.high:
      return '↑ Above range';
    case null:
      return 'Outside reference range';
  }
}

/// Compact label for tight layouts (e.g. table rows).
String? labReferenceFlagShortLabel(ReferenceEvaluation? eval) {
  if (eval?.inRange != false) return null;
  switch (eval!.flag) {
    case ReferenceFlag.low:
      return 'LOW';
    case ReferenceFlag.high:
      return 'HIGH';
    case null:
      return null;
  }
}

/// Text color for a result value; null = default theme color.
Color? labReferenceValueColor(ThemeData theme, ReferenceEvaluation? eval) {
  if (!labResultIsAbnormal(eval)) return null;
  return theme.colorScheme.error;
}

/// PDF result cell text with optional abnormal suffix.
String labPdfResultValueText(LabResult result) {
  return labPdfResultValueTextFor(result.value, result.referenceEvaluation);
}

/// PDF result cell text from a resolved evaluation.
String labPdfResultValueTextFor(String value, ReferenceEvaluation? eval) {
  final flag = labReferenceFlagShortLabel(eval);
  if (flag == null) return value;
  final arrow = eval?.flag == ReferenceFlag.low ? '↓' : '↑';
  return '$value $arrow $flag';
}

/// PDF color for abnormal result values.
PdfColor? labPdfReferenceValueColor(
  ReferenceEvaluation? eval, {
  PdfColor? abnormalColor,
}) {
  if (!labResultIsAbnormal(eval)) return null;
  return abnormalColor ?? PdfColor.fromHex('#DC2626');
}
