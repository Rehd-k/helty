import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'report_pdf_theme.dart';

/// Centered traditional medical letterhead with dual horizontal rules.
class FormalLetterheadTheme extends ReportPdfTheme {
  @override
  PdfColor get primary => PdfColor.fromHex('#1A1A1A');

  @override
  PdfColor get primaryDark => PdfColor.fromHex('#111111');

  @override
  PdfColor get accent => PdfColor.fromHex('#4A5568');

  @override
  PdfColor get surface => PdfColor.fromHex('#FAFAFA');

  @override
  PdfColor get surfaceCard => PdfColor.fromHex('#F5F5F5');

  @override
  PdfColor get border => PdfColor.fromHex('#CBD5E1');

  @override
  PdfColor get textMuted => PdfColor.fromHex('#718096');

  @override
  String get defaultSubtitle => 'Official medical report';

  @override
  pw.Widget header({
    required pw.ImageProvider logo,
    String? subtitle,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Container(height: 1.5, color: primary),
        pw.SizedBox(height: 10),
        pw.Container(height: 0.6, color: primary),
        pw.SizedBox(height: 14),
        pw.Image(logo, width: 44, height: 44),
        pw.SizedBox(height: 10),
        pw.Text(
          org.name.toUpperCase(),
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            color: primary,
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          subtitle ?? defaultSubtitle,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 9,
            color: textMuted,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
        pw.SizedBox(height: 8),
        if (org.addressesLine.isNotEmpty)
          pw.Text(
            org.addressesLine,
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(fontSize: 7.5, color: textMuted),
          ),
        if (org.phonesLine.isNotEmpty || org.emailsLine.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              [
                if (org.phonesLine.isNotEmpty) 'Tel: ${org.phonesLine}',
                if (org.emailsLine.isNotEmpty) 'Email: ${org.emailsLine}',
              ].join('  ·  '),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 7.5, color: textMuted),
            ),
          ),
        if (org.website.trim().isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              org.website.trim(),
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 7.5, color: textMuted),
            ),
          ),
        pw.SizedBox(height: 14),
        pw.Container(height: 0.6, color: primary),
        pw.SizedBox(height: 10),
        pw.Container(height: 1.5, color: primary),
      ],
    );
  }

  @override
  pw.Widget continuationHeader(String subtitle) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: primary, width: 0.6)),
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
              letterSpacing: 0.5,
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
      child: pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: primary,
          letterSpacing: 2.5,
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
        border: pw.Border(top: pw.BorderSide(color: primary, width: 0.6)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              'Confidential medical record — ${org.name}',
              style: pw.TextStyle(fontSize: 7, color: textMuted),
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: textMuted),
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
          title.toUpperCase(),
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: primary,
            letterSpacing: 1,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Container(width: 48, height: 1, color: accent),
        pw.SizedBox(height: 4),
        pw.Text(
          subtitle,
          style: pw.TextStyle(fontSize: 8.5, color: textMuted),
        ),
      ],
    );
  }
}
