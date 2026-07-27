import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'report_pdf_theme.dart';

/// White letterhead with thin accent bar and stacked contacts.
class CleanClinicalTheme extends ReportPdfTheme {
  @override
  PdfColor get primary => PdfColor.fromHex('#1E3A5F');

  @override
  PdfColor get primaryDark => PdfColor.fromHex('#0F2744');

  @override
  PdfColor get accent => PdfColor.fromHex('#0D9488');

  @override
  PdfColor get surface => PdfColor.fromHex('#FFFFFF');

  @override
  PdfColor get surfaceCard => PdfColor.fromHex('#F8FAFC');

  @override
  PdfColor get border => PdfColor.fromHex('#E2E8F0');

  @override
  PdfColor get textMuted => PdfColor.fromHex('#64748B');

  @override
  String get defaultSubtitle => 'Laboratory & diagnostic services';

  @override
  pw.Widget header({
    required pw.ImageProvider logo,
    String? subtitle,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(height: 5, color: accent),
        pw.SizedBox(height: 14),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Image(logo, width: 48, height: 48),
            pw.SizedBox(width: 14),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    org.name,
                    style: pw.TextStyle(
                      color: primary,
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    subtitle ?? defaultSubtitle,
                    style: pw.TextStyle(fontSize: 9, color: textMuted),
                  ),
                  ...contactLines(fontSize: 7.5),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Container(height: 1, color: border),
      ],
    );
  }

  @override
  pw.Widget continuationHeader(String subtitle) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: border, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            org.name,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: primary,
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
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 10),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: accent, width: 2),
        ),
      ),
      child: pw.Text(
        title.toUpperCase(),
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: primary,
          letterSpacing: 1.6,
        ),
      ),
    );
  }

  @override
  pw.Widget pageFooter(String generatedStr, pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 12),
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: border, width: 0.8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              'Confidential · ${org.name}',
              style: pw.TextStyle(fontSize: 7, color: textMuted),
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber}/${context.pagesCount} · $generatedStr',
            style: pw.TextStyle(fontSize: 7.5, color: textMuted),
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
    return pw.Column(
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
    );
  }
}
