import 'package:helty/src/app/org_config.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'classic_navy_theme.dart';
import 'clean_clinical_theme.dart';
import 'diagnostics_strip_theme.dart';
import 'formal_letterhead_theme.dart';

/// Persisted template identifiers for lab / diagnostic PDF reports.
enum ReportPdfTemplateId {
  classicNavy,
  cleanClinical,
  formalLetterhead,
  diagnosticsStrip;

  String get storageKey => name;

  String get displayName => switch (this) {
        ReportPdfTemplateId.classicNavy => 'Classic Navy',
        ReportPdfTemplateId.cleanClinical => 'Clean Clinical',
        ReportPdfTemplateId.formalLetterhead => 'Formal Letterhead',
        ReportPdfTemplateId.diagnosticsStrip => 'Diagnostics Strip',
      };

  String get description => switch (this) {
        ReportPdfTemplateId.classicNavy =>
          'Navy gradient header with gold accent — current hospital look.',
        ReportPdfTemplateId.cleanClinical =>
          'White letterhead with a thin accent bar and stacked contacts.',
        ReportPdfTemplateId.formalLetterhead =>
          'Centered traditional medical letterhead with dual rules.',
        ReportPdfTemplateId.diagnosticsStrip =>
          'Compact header plus a strip of service taglines.',
      };

  static ReportPdfTemplateId fromStorage(String? raw) {
    return ReportPdfTemplateId.values.firstWhere(
      (e) => e.storageKey == raw,
      orElse: () => ReportPdfTemplateId.classicNavy,
    );
  }

  static const List<ReportPdfTemplateId> all = ReportPdfTemplateId.values;
}

/// Shared visual chrome for lab and radiology patient reports.
abstract class ReportPdfTheme {
  OrgConfig get org => OrgConfig.instance;

  PdfColor get primary;
  PdfColor get primaryDark;
  PdfColor get accent;
  PdfColor get surface;
  PdfColor get surfaceCard;
  PdfColor get border;
  PdfColor get textMuted;

  String get defaultSubtitle;

  pw.Widget header({
    required pw.ImageProvider logo,
    String? subtitle,
  });

  pw.Widget continuationHeader(String subtitle);

  pw.Widget reportBanner(String title);

  pw.Widget pageFooter(String generatedStr, pw.Context context);

  pw.Widget signatureSection({
    List<String> titles = const ['Med Lab Scientist', 'HOD Med Lab'],
  });

  pw.Widget resultsSummaryHeader({
    String title = 'Results summary',
    String subtitle =
        'Parameters listed below reflect values released on this report.',
  });

  pw.Widget infoCard({
    required String title,
    required List<pw.Widget> rows,
  }) {
    return pw.Expanded(
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
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    color: primary,
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 8.5,
                    letterSpacing: 1.1,
                  ),
                ),
                pw.SizedBox(width: 8),
                pw.Expanded(child: pw.Container(height: 1, color: border)),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              width: 36,
              height: 3,
              decoration: pw.BoxDecoration(
                color: accent,
                borderRadius: pw.BorderRadius.circular(2),
              ),
            ),
            pw.SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }

  pw.Widget kv(String label, String value, {bool emphasize = false}) {
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

  /// Contact lines from [OrgConfig] (semicolon-joined when multiple).
  List<pw.Widget> contactLines({
    PdfColor? textColor,
    double fontSize = 7.5,
  }) {
    final color = textColor ?? textMuted;
    final lines = <String>[
      if (org.addressesLine.isNotEmpty) org.addressesLine,
      if (org.phonesLine.isNotEmpty) 'Tel: ${org.phonesLine}',
      if (org.emailsLine.isNotEmpty) 'Email: ${org.emailsLine}',
      if (org.website.trim().isNotEmpty) org.website.trim(),
    ];
    return lines
        .map(
          (line) => pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              line,
              style: pw.TextStyle(fontSize: fontSize, color: color),
            ),
          ),
        )
        .toList();
  }

  pw.Widget defaultSignatureSection({
    List<String> titles = const ['Med Lab Scientist', 'HOD Med Lab'],
  }) {
    final blocks = titles.isEmpty
        ? const ['Authorized signature']
        : titles;
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 32),
      padding: const pw.EdgeInsets.only(top: 18),
      decoration: pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: border, width: 0.65)),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            if (i > 0) pw.SizedBox(width: 36),
            pw.Expanded(child: _signatureBlock(blocks[i])),
          ],
        ],
      ),
    );
  }

  pw.Widget _signatureBlock(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          'Signature',
          style: pw.TextStyle(
            fontSize: 7.5,
            color: textMuted,
            letterSpacing: 0.4,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 52,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: border, width: 0.75),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 1.2, color: primaryDark),
        pw.SizedBox(height: 8),
        pw.Text(
          title,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: primary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  static ReportPdfTheme forId(ReportPdfTemplateId id) {
    return switch (id) {
      ReportPdfTemplateId.classicNavy => ClassicNavyTheme(),
      ReportPdfTemplateId.cleanClinical => CleanClinicalTheme(),
      ReportPdfTemplateId.formalLetterhead => FormalLetterheadTheme(),
      ReportPdfTemplateId.diagnosticsStrip => DiagnosticsStripTheme(),
    };
  }
}
