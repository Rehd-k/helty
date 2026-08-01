import 'package:flutter/services.dart' show rootBundle;
import 'package:helty/src/app/org_config.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/investigations/models/investigation_models.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

enum InvestigationsReportMode {
  detail,
  summaryByTest,
  summaryByDepartment,
}

Future<List<int>> buildInvestigationsReportPdf({
  required PdfPageFormat format,
  required String title,
  required String? subtitle,
  required InvestigationsReportMode mode,
  List<InvestigationListRow> detailRows = const [],
  InvestigationSummary? summary,
  num? totalAmount,
  int? totalCount,
}) async {
  final logoBytes = await rootBundle.load(OrgConfig.instance.logoAsset);
  final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
  final generatedAt = AppTimezone.now();
  final generatedStr = DateFormatter.shortDate(generatedAt);

  final primary = PdfColor.fromHex('#0D3B66');
  final primaryDark = PdfColor.fromHex('#082845');
  final accent = PdfColor.fromHex('#D4AF37');
  final border = PdfColor.fromHex('#CBD5E1');
  final textMuted = PdfColor.fromHex('#64748B');
  final surface = PdfColor.fromHex('#F8FAFC');

  pw.Widget headerCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  pw.Widget bodyCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  pw.TableRow tableHeaderRow(List<String> headers) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(color: primary),
      children: headers.map(headerCell).toList(),
    );
  }

  pw.Widget buildDetailTable() {
    final headers = ['Patient', 'Test', 'Amount', 'Created'];
    final dataRows = detailRows.asMap().entries.map((entry) {
      final row = entry.value;
      final stripe = entry.key.isEven ? PdfColors.white : surface;
      return pw.TableRow(
        decoration: pw.BoxDecoration(color: stripe),
        children: [
          bodyCell(row.resolvedPatientName),
          bodyCell(row.testName),
          bodyCell(row.amount.toFinancial(isMoney: true)),
          bodyCell(
            row.createdAt != null
                ? DateFormatter.dateTime(row.createdAt!)
                : '—',
          ),
        ],
      );
    }).toList();

    final count = totalCount ?? detailRows.length;
    final amount = totalAmount ??
        detailRows.fold<num>(0, (sum, row) => sum + row.amount);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Table(
          border: pw.TableBorder.all(color: border, width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(2.4),
            1: const pw.FlexColumnWidth(2),
            2: const pw.FlexColumnWidth(1.2),
            3: const pw.FlexColumnWidth(1.8),
          },
          children: [
            tableHeaderRow(headers),
            if (dataRows.isEmpty)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Text(
                      'No investigations match the filter.',
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: textMuted,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ),
                  bodyCell(''),
                  bodyCell(''),
                  bodyCell(''),
                ],
              )
            else
              ...dataRows,
          ],
        ),
        if (dataRows.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              'Total: $count investigations · ${amount.toFinancial(isMoney: true)}',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: primary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  pw.Widget buildSummaryByTestTable() {
    final rows = summary?.byTestName ?? const [];
    return pw.Table(
      border: pw.TableBorder.all(color: border, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
      },
      children: [
        tableHeaderRow(['Test', 'Count', 'Amount']),
        ...rows.asMap().entries.map((entry) {
          final row = entry.value;
          final stripe = entry.key.isEven ? PdfColors.white : surface;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: stripe),
            children: [
              bodyCell(row.testName),
              bodyCell('${row.count}'),
              bodyCell(row.amount.toFinancial(isMoney: true)),
            ],
          );
        }),
      ],
    );
  }

  pw.Widget buildSummaryByDepartmentTable() {
    final rows = summary?.byDepartment ?? const [];
    return pw.Table(
      border: pw.TableBorder.all(color: border, width: 0.5),
      columnWidths: {
        0: const pw.FlexColumnWidth(2.5),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
      },
      children: [
        tableHeaderRow(['Department', 'Count', 'Amount']),
        ...rows.asMap().entries.map((entry) {
          final row = entry.value;
          final stripe = entry.key.isEven ? PdfColors.white : surface;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: stripe),
            children: [
              bodyCell(row.departmentName),
              bodyCell('${row.count}'),
              bodyCell(row.amount.toFinancial(isMoney: true)),
            ],
          );
        }),
      ],
    );
  }

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.fromLTRB(32, 28, 32, 36),
      footer: (context) => pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'IBOM Multispeciality Hospital',
            style: pw.TextStyle(fontSize: 7, color: textMuted),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount} · Generated $generatedStr',
            style: pw.TextStyle(fontSize: 7, color: textMuted),
          ),
        ],
      ),
      build: (context) => [
        pw.Container(
          decoration: pw.BoxDecoration(
            gradient: pw.LinearGradient(
              colors: [primaryDark, primary],
              begin: pw.Alignment.topLeft,
              end: pw.Alignment.bottomRight,
            ),
            borderRadius: pw.BorderRadius.circular(12),
          ),
          child: pw.Column(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.fromLTRB(16, 14, 16, 12),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Image(logo, width: 44, height: 44),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'IBOM MULTISPECIALITY HOSPITAL',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Laboratory investigations report',
                            style: pw.TextStyle(
                              color: PdfColor.fromHex('#E2E8F0'),
                              fontSize: 8.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              pw.Container(width: double.infinity, height: 3, color: accent),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: primary,
          ),
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text(
            subtitle,
            style: pw.TextStyle(fontSize: 9, color: textMuted),
          ),
        ],
        pw.SizedBox(height: 14),
        switch (mode) {
          InvestigationsReportMode.detail => buildDetailTable(),
          InvestigationsReportMode.summaryByTest => buildSummaryByTestTable(),
          InvestigationsReportMode.summaryByDepartment =>
            buildSummaryByDepartmentTable(),
        },
      ],
    ),
  );

  return doc.save();
}
