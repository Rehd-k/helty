import 'package:flutter/services.dart' show rootBundle;
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/ui/radiology_ui_helpers.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds a radiology order PDF using the same visual language as the lab report.
Future<List<int>> buildRadiologyOrderReportPdf(
  RadiologyOrder order, {
  PdfPageFormat format = PdfPageFormat.a4,
}) async {
  final logoImageBytes = await rootBundle.load('assets/imsh.png');
  final logoImage = pw.MemoryImage(logoImageBytes.buffer.asUint8List());

  final primary = PdfColor.fromHex('#0D3B66');
  final primaryDark = PdfColor.fromHex('#082845');
  final accent = PdfColor.fromHex('#D4AF37');
  final surface = PdfColor.fromHex('#F8FAFC');
  final border = PdfColor.fromHex('#CBD5E1');
  final textMuted = PdfColor.fromHex('#64748B');

  final generatedStr =
      DateTime.now().toIso8601String().split('T').first;
  final orderDateStr = order.createdAt != null && order.createdAt!.isNotEmpty
      ? order.createdAt!.split('T').first
      : '—';

  pw.Widget pdfKv(String label, String value, {bool emphasize = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 86,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 8.5, color: textMuted),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight:
                    emphasize ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: PdfColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget pdfOrderStatusPill(RadiologyOrderStatus status) {
    final colors = _radiologyOrderPdfColors(status);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: colors.background,
        borderRadius: pw.BorderRadius.circular(20),
        border: pw.Border.all(color: colors.border, width: 0.5),
      ),
      child: pw.Text(
        orderStatusLabel(status).toUpperCase(),
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: colors.foreground,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.fromLTRB(38, 34, 38, 40),
      build: (context) => [
        pw.Container(
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [primaryDark, primary],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
            borderRadius: pw.BorderRadius.circular(14),
            border: pw.Border.all(color: accent, width: 0.75),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(20, 18, 20, 16),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(6),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.white,
                    borderRadius: pw.BorderRadius.circular(12),
                    border: pw.Border.all(
                      color: PdfColor.fromInt(0x80D4AF37),
                      width: 0.5,
                    ),
                  ),
                  child: pw.Image(logoImage, width: 52, height: 52),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'IBOM MULTISPECIALIST HOSPITAL',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Radiology · Imaging report',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#E2E8F0'),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(height: 18),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: pw.BoxDecoration(
                  color: surface,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: border, width: 0.65),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'PATIENT',
                      style: pw.TextStyle(
                        color: primary,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8.5,
                        letterSpacing: 1.1,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pdfKv(
                      'Full name',
                      (order.patient?.displayName ?? 'N/A').toUpperCase(),
                      emphasize: true,
                    ),
                    pdfKv('Patient ID', order.patient?.id ?? order.patientId),
                    pdfKv('Order date', orderDateStr),
                    pdfKv('Report date', generatedStr),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: pw.BoxDecoration(
                  color: surface,
                  borderRadius: pw.BorderRadius.circular(12),
                  border: pw.Border.all(color: border, width: 0.65),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'ORDER',
                      style: pw.TextStyle(
                        color: primary,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 8.5,
                        letterSpacing: 1.1,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(bottom: 8),
                      child: pw.Row(
                        children: [
                          pw.Text(
                            'Status',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: textMuted,
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pdfOrderStatusPill(order.status),
                        ],
                      ),
                    ),
                    pdfKv(
                      'Order no.',
                      '#${_shortId(order.id)}',
                      emphasize: true,
                    ),
                    pdfKv(
                      'Items',
                      '${order.items.length} study${order.items.length == 1 ? '' : 'ies'}',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        pw.Text(
          'Studies',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: primary,
          ),
        ),
        pw.SizedBox(height: 10),
        ...order.items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: border, width: 0.65),
              borderRadius: pw.BorderRadius.circular(12),
              color: PdfColors.white,
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: 26,
                      height: 26,
                      alignment: pw.Alignment.center,
                      decoration: pw.BoxDecoration(
                        color: primary,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Text(
                        index.toString().padLeft(2, '0'),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 10),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            '${item.scanType.displayLabel}${item.bodyPart != null && item.bodyPart!.isNotEmpty ? ' · ${item.bodyPart}' : ''}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 11,
                              color: primary,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Priority: ${item.priority.name} · '
                            'Item status: ${itemStatusLabel(item.status)}',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  reportPreviewText(item.report),
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    color: PdfColors.grey900,
                    lineSpacing: 1.2,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      footer: (context) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 12),
        padding: const pw.EdgeInsets.only(top: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: border, width: 0.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Confidential medical record.',
              style: pw.TextStyle(fontSize: 7, color: textMuted),
            ),
            pw.Text(
              'Page ${context.pageNumber} / ${context.pagesCount}',
              style: pw.TextStyle(fontSize: 8, color: textMuted),
            ),
          ],
        ),
      ),
    ),
  );
  return doc.save();
}

String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

class _PdfRadiologyOrderColors {
  const _PdfRadiologyOrderColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final PdfColor background;
  final PdfColor border;
  final PdfColor foreground;
}

_PdfRadiologyOrderColors _radiologyOrderPdfColors(RadiologyOrderStatus status) {
  switch (status) {
    case RadiologyOrderStatus.PENDING:
      return _PdfRadiologyOrderColors(
        background: PdfColor.fromHex('#FEF9C3'),
        border: PdfColor.fromHex('#EAB308'),
        foreground: PdfColor.fromHex('#854D0E'),
      );
    case RadiologyOrderStatus.ACTIVE:
      return _PdfRadiologyOrderColors(
        background: PdfColor.fromHex('#E0F2FE'),
        border: PdfColor.fromHex('#38BDF8'),
        foreground: PdfColor.fromHex('#075985'),
      );
    case RadiologyOrderStatus.COMPLETED:
      return _PdfRadiologyOrderColors(
        background: PdfColor.fromHex('#DCFCE7'),
        border: PdfColor.fromHex('#4ADE80'),
        foreground: PdfColor.fromHex('#166534'),
      );
    case RadiologyOrderStatus.CANCELLED:
      return _PdfRadiologyOrderColors(
        background: PdfColor.fromHex('#FEE2E2'),
        border: PdfColor.fromHex('#F87171'),
        foreground: PdfColor.fromHex('#991B1B'),
      );
  }
}
