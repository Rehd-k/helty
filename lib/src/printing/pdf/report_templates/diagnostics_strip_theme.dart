import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'report_pdf_theme.dart';

/// Compact header plus a horizontal strip of service taglines.
class DiagnosticsStripTheme extends ReportPdfTheme {
  @override
  PdfColor get primary => PdfColor.fromHex('#0B3D5C');

  @override
  PdfColor get primaryDark => PdfColor.fromHex('#062536');

  @override
  PdfColor get accent => PdfColor.fromHex('#F59E0B');

  @override
  PdfColor get surface => PdfColor.fromHex('#F8FAFC');

  @override
  PdfColor get surfaceCard => PdfColor.fromHex('#EEF2FF');

  @override
  PdfColor get border => PdfColor.fromHex('#CBD5E1');

  @override
  PdfColor get textMuted => PdfColor.fromHex('#64748B');

  @override
  String get defaultSubtitle => 'Diagnostics & imaging centre';

  @override
  pw.Widget header({
    required pw.ImageProvider logo,
    String? subtitle,
  }) {
    final taglines = org.taglines;
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Container(
          color: primaryDark,
          padding: const pw.EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(4),
                color: PdfColors.white,
                child: pw.Image(logo, width: 40, height: 40),
              ),
              pw.SizedBox(width: 12),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      org.name.toUpperCase(),
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 13,
                        fontWeight: pw.FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      subtitle ?? defaultSubtitle,
                      style: pw.TextStyle(
                        color: PdfColor.fromHex('#E2E8F0'),
                        fontSize: 8.5,
                      ),
                    ),
                    if (org.phonesLine.isNotEmpty ||
                        org.emailsLine.isNotEmpty)
                      pw.Padding(
                        padding: const pw.EdgeInsets.only(top: 3),
                        child: pw.Text(
                          [
                            if (org.addressesLine.isNotEmpty) org.addressesLine,
                            if (org.phonesLine.isNotEmpty) org.phonesLine,
                            if (org.emailsLine.isNotEmpty) org.emailsLine,
                            if (org.website.trim().isNotEmpty)
                              org.website.trim(),
                          ].join('  ·  '),
                          style: pw.TextStyle(
                            color: PdfColor.fromHex('#94A3B8'),
                            fontSize: 6.5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (taglines.isNotEmpty)
          pw.Container(
            color: accent,
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: pw.Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                for (final tag in taglines)
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0x33000000),
                      borderRadius: pw.BorderRadius.circular(3),
                    ),
                    child: pw.Text(
                      tag,
                      style: pw.TextStyle(
                        fontSize: 6.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  pw.Widget continuationHeader(String subtitle) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: accent, width: 1.5)),
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
      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: pw.BoxDecoration(
        color: surfaceCard,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: border, width: 0.5),
      ),
      child: pw.Text(
        title.toUpperCase(),
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          fontSize: 11,
          fontWeight: pw.FontWeight.bold,
          color: primary,
          letterSpacing: 1.8,
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
        border: pw.Border(top: pw.BorderSide(color: border, width: 0.5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          if (org.taglines.isNotEmpty)
            pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Text(
                org.taglinesLine,
                style: pw.TextStyle(fontSize: 6, color: textMuted),
                textAlign: pw.TextAlign.center,
              ),
            ),
          pw.Row(
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
