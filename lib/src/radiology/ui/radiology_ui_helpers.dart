import 'package:flutter/material.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';

bool radiologyMimeIsGeneric(String? mimeType) {
  final mime = mimeType?.toLowerCase().trim() ?? '';
  return mime.isEmpty || mime == 'application/octet-stream';
}

bool radiologyImageIsLikelyPdf(RadiologyImage img) {
  final mime = img.mimeType?.toLowerCase() ?? '';
  if (!radiologyMimeIsGeneric(mime) && mime.contains('pdf')) return true;
  return img.fileName.toLowerCase().endsWith('.pdf');
}

bool radiologyImageIsLikelyRaster(RadiologyImage img) {
  if (radiologyImageIsLikelyPdf(img)) return false;
  final mime = img.mimeType?.toLowerCase() ?? '';
  if (!radiologyMimeIsGeneric(mime) &&
      mime.startsWith('image/') &&
      !mime.contains('svg')) {
    return true;
  }
  final name = img.fileName.toLowerCase();
  return name.endsWith('.jpg') ||
      name.endsWith('.jpeg') ||
      name.endsWith('.png') ||
      name.endsWith('.gif') ||
      name.endsWith('.webp') ||
      name.endsWith('.bmp') ||
      name.endsWith('.tif') ||
      name.endsWith('.tiff');
}

bool radiologyImageIsPreviewable(RadiologyImage img) =>
    radiologyImageIsLikelyPdf(img) || radiologyImageIsLikelyRaster(img);

String orderStatusLabel(RadiologyOrderStatus status) {
  switch (status) {
    case RadiologyOrderStatus.PENDING:
      return 'Pending';
    case RadiologyOrderStatus.ACTIVE:
      return 'Active';
    case RadiologyOrderStatus.COMPLETED:
      return 'Completed';
    case RadiologyOrderStatus.CANCELLED:
      return 'Cancelled';
  }
}

String itemStatusLabel(RadiologyOrderItemStatus status) {
  switch (status) {
    case RadiologyOrderItemStatus.PENDING:
      return 'Pending';
    case RadiologyOrderItemStatus.SCHEDULED:
      return 'Scheduled';
    case RadiologyOrderItemStatus.IN_PROGRESS:
      return 'In progress';
    case RadiologyOrderItemStatus.COMPLETED:
      return 'Completed';
    case RadiologyOrderItemStatus.REPORTED:
      return 'Reported';
    case RadiologyOrderItemStatus.CANCELLED:
      return 'Cancelled';
  }
}

Color orderStatusColor(ThemeData theme, RadiologyOrderStatus status) {
  switch (status) {
    case RadiologyOrderStatus.PENDING:
      return Colors.amber.shade700;
    case RadiologyOrderStatus.ACTIVE:
      return theme.colorScheme.primary;
    case RadiologyOrderStatus.COMPLETED:
      return Colors.green.shade700;
    case RadiologyOrderStatus.CANCELLED:
      return theme.colorScheme.error;
  }
}

Color priorityColor(RadiologyPriority priority) {
  switch (priority) {
    case RadiologyPriority.ROUTINE:
      return Colors.blueGrey;
    case RadiologyPriority.URGENT:
      return Colors.orange.shade700;
    case RadiologyPriority.EMERGENCY:
      return Colors.red.shade700;
  }
}

/// Plain-text preview for lists and PDF. Skips [RadiologyStudyReport.impression]
/// when it holds Quill delta JSON (stored alongside plain [findings]).
String reportPreviewText(RadiologyStudyReport? report) {
  if (report == null) return 'No report yet.';
  final findings = report.findings?.trim();
  final recommendations = report.recommendations?.trim();
  final impression = report.impression?.trim();
  bool looksLikeRichPayload(String s) {
    final t = s.trimLeft();
    return t.startsWith('[') || (t.startsWith('{') && t.contains('"insert"'));
  }
  final parts = <String>[
    if (findings != null && findings.isNotEmpty) findings,
    if (recommendations != null && recommendations.isNotEmpty) recommendations,
    if (impression != null &&
        impression.isNotEmpty &&
        !looksLikeRichPayload(impression))
      impression,
  ];
  if (parts.isEmpty) return 'Report saved without text.';
  return parts.join('\n\n');
}
