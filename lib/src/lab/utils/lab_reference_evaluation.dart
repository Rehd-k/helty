import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';

import '../models/lab_models.dart';

/// Whether the result should be highlighted as outside reference range.
bool labResultIsAbnormal(ReferenceEvaluation? eval) => eval?.isAbnormal ?? false;

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
Color? labReferenceValueColor(
  ThemeData theme,
  ReferenceEvaluation? eval,
) {
  if (!labResultIsAbnormal(eval)) return null;
  return theme.colorScheme.error;
}

/// PDF result cell text with optional abnormal suffix.
String labPdfResultValueText(LabResult result) {
  final value = result.value;
  final flag = labReferenceFlagShortLabel(result.referenceEvaluation);
  if (flag == null) return value;
  final arrow = result.referenceEvaluation?.flag == ReferenceFlag.low
      ? '↓'
      : '↑';
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
