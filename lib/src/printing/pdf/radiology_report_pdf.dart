import 'package:flutter/services.dart' show rootBundle;
import 'package:helty/src/app/org_config.dart';
import 'package:helty/src/printing/pdf/report_template_preference.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/ui/radiology_ui_helpers.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Builds a radiology order PDF using the selected report template.
Future<List<int>> buildRadiologyOrderReportPdf(
  RadiologyOrder order, {
  PdfPageFormat format = PdfPageFormat.a4,
}) async {
  final logoImageBytes = await rootBundle.load(OrgConfig.instance.logoAsset);
  final logoImage = pw.MemoryImage(logoImageBytes.buffer.asUint8List());
  final theme = await resolveSelectedReportPdfTheme();

  final generatedStr = DateTime.now().toIso8601String().split('T').first;
  final orderDateStr = order.createdAt != null && order.createdAt!.isNotEmpty
      ? order.createdAt!.split('T').first
      : '—';

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
      header: (context) {
        if (context.pageNumber == 1) return pw.SizedBox();
        return theme.continuationHeader(
          'Imaging report · #${_shortId(order.id)}',
        );
      },
      footer: (context) => theme.pageFooter(generatedStr, context),
      build: (context) => [
        theme.header(
          logo: logoImage,
          subtitle: 'Radiology · Imaging report',
        ),
        pw.SizedBox(height: 18),
        theme.reportBanner('Imaging Report'),
        pw.SizedBox(height: 18),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            theme.infoCard(
              title: 'PATIENT',
              rows: [
                theme.kv(
                  'Full name',
                  (order.patient?.displayName ?? 'N/A').toUpperCase(),
                  emphasize: true,
                ),
                theme.kv('Patient ID', order.patient?.id ?? order.patientId),
                theme.kv('Order date', orderDateStr),
                theme.kv('Report date', generatedStr),
              ],
            ),
            pw.SizedBox(width: 14),
            theme.infoCard(
              title: 'ORDER',
              rows: [
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    children: [
                      pw.Text(
                        'Status',
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          color: theme.textMuted,
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pdfOrderStatusPill(order.status),
                    ],
                  ),
                ),
                theme.kv(
                  'Order no.',
                  '#${_shortId(order.id)}',
                  emphasize: true,
                ),
                theme.kv(
                  'Items',
                  '${order.items.length} study${order.items.length == 1 ? '' : 'ies'}',
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
        theme.resultsSummaryHeader(
          title: 'Studies',
          subtitle: 'Imaging findings released on this report.',
        ),
        pw.SizedBox(height: 10),
        ...order.items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: theme.border, width: 0.65),
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
                        color: theme.primary,
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
                              color: theme.primary,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            'Priority: ${item.priority.name} · '
                            'Item status: ${itemStatusLabel(item.status)}',
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: theme.textMuted,
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
        theme.signatureSection(
          titles: const ['Radiologist', 'Reporting Officer'],
        ),
      ],
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
