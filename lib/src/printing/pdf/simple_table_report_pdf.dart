import 'package:flutter/services.dart' show rootBundle;
import 'package:helty/src/app/org_config.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Simple tabular report PDF used by hospital reporting hub screens.
Future<List<int>> buildSimpleTableReportPdf({
  required PdfPageFormat format,
  required String title,
  required String subtitle,
  required List<String> headers,
  required List<List<String>> rows,
}) async {
  final logoBytes = await rootBundle.load(OrgConfig.instance.logoAsset);
  final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());
  final doc = pw.Document();

  final cols = headers.isEmpty ? ['Value'] : headers;
  final data = rows.isEmpty
      ? <List<String>>[
          List.filled(cols.length, '—'),
        ]
      : rows
            .map(
              (r) => List<String>.generate(
                cols.length,
                (i) => i < r.length ? r[i] : '',
              ),
            )
            .toList();

  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      maxPages: 200,
      margin: const pw.EdgeInsets.fromLTRB(24, 24, 24, 28),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        pw.Row(
          children: [
            pw.SizedBox(
              width: 48,
              height: 48,
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    subtitle,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 14),
        pw.TableHelper.fromTextArray(
          headers: cols,
          data: data,
          headerStyle: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 8.5,
            color: PdfColors.white,
          ),
          headerDecoration: const pw.BoxDecoration(
            color: PdfColors.blueGrey800,
          ),
          cellStyle: const pw.TextStyle(fontSize: 8),
          cellAlignment: pw.Alignment.centerLeft,
          headerAlignment: pw.Alignment.centerLeft,
          border: pw.TableBorder.all(
            color: PdfColors.grey300,
            width: 0.4,
          ),
        ),
      ],
    ),
  );

  return doc.save();
}
