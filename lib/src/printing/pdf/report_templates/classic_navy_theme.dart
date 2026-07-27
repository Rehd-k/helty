import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'report_pdf_theme.dart';

/// Navy gradient header with gold accent (legacy IMSH look).
class ClassicNavyTheme extends ReportPdfTheme {
  @override
  PdfColor get primary => PdfColor.fromHex('#0D3B66');

  @override
  PdfColor get primaryDark => PdfColor.fromHex('#082845');

  @override
  PdfColor get accent => PdfColor.fromHex('#D4AF37');

  @override
  PdfColor get surface => PdfColor.fromHex('#F8FAFC');

  @override
  PdfColor get surfaceCard => PdfColor.fromHex('#F1F5F9');

  @override
  PdfColor get border => PdfColor.fromHex('#CBD5E1');

  @override
  PdfColor get textMuted => PdfColor.fromHex('#64748B');

  @override
  String get defaultSubtitle => 'Clinical laboratory · Quality-assured diagnostics';

  @override
  pw.Widget header({
    required pw.ImageProvider logo,
    String? subtitle,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [primaryDark, primary],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(14),
        border: pw.Border.all(color: accent, width: 0.75),
        boxShadow: [
          pw.BoxShadow(
            color: PdfColor.fromInt(0x300D3B66),
            offset: const PdfPoint(0, 6),
            blurRadius: 12,
          ),
        ],
      ),
      child: pw.Column(
        children: [
          pw.Padding(
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
                  child: pw.Image(logo, width: 52, height: 52),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        org.name.toUpperCase(),
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 15,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        subtitle ?? defaultSubtitle,
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#E2E8F0'),
                          fontSize: 9,
                          letterSpacing: 0.2,
                        ),
                      ),
                      ...contactLines(
                        textColor: PdfColor.fromHex('#CBD5E1'),
                        fontSize: 7,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          pw.Container(width: double.infinity, height: 4, color: accent),
        ],
      ),
    );
  }

  @override
  pw.Widget continuationHeader(String subtitle) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: border, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            org.name.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: primary,
              letterSpacing: 0.3,
            ),
          ),
          pw.Text(
            subtitle,
            style: pw.TextStyle(fontSize: 8, color: textMuted),
          ),
        ],
      ),
    );
  }

  @override
  pw.Widget reportBanner(String title) {
    return pw.Center(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        decoration: pw.BoxDecoration(
          color: surfaceCard,
          borderRadius: pw.BorderRadius.circular(24),
          border: pw.Border.all(color: border, width: 0.65),
        ),
        child: pw.Row(
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            pw.Container(
              width: 6,
              height: 6,
              decoration: pw.BoxDecoration(
                color: accent,
                shape: pw.BoxShape.circle,
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: primary,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  pw.Widget pageFooter(String generatedStr, pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: border, width: 0.5)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              'Confidential medical record. If you are not the intended '
              'recipient, contact ${org.name} immediately.',
              style: pw.TextStyle(
                fontSize: 7,
                color: textMuted,
                lineSpacing: 1.2,
              ),
            ),
          ),
          pw.SizedBox(width: 16),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'Page ${context.pageNumber} of ${context.pagesCount}',
                style: pw.TextStyle(
                  fontSize: 8,
                  color: textMuted,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Generated $generatedStr',
                style: pw.TextStyle(fontSize: 7, color: textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  pw.Widget signatureSection({
    List<String> titles = const ['Med Lab Scientist', 'HOD Med Lab'],
  }) =>
      defaultSignatureSection(titles: titles);

  @override
  pw.Widget resultsSummaryHeader({
    String title = 'Results summary',
    String subtitle =
        'Parameters listed below reflect values released on this report.',
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(left: 10, bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: accent, width: 3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: primary,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            subtitle,
            style: pw.TextStyle(fontSize: 8.5, color: textMuted),
          ),
        ],
      ),
    );
  }
}
