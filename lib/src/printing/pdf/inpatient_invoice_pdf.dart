import 'package:flutter/services.dart' show rootBundle;
import 'package:helty/src/billings/inpatient_charge_models.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

String _formatPdfDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}

/// Builds the inpatient bill invoice PDF for print / share.
Future<List<int>> buildInpatientInvoicePdf({
  required PdfPageFormat format,
  required String patientDisplayId,
  required String invoiceDisplayId,
  required String patientName,
  required List<ChargeItem> charges,
  required double totalCharges,
  required double totalPayments,
  required double balanceDue,
  required double walletBalance,
}) async {
  final logoBytes = await rootBundle.load('assets/imsh.png');
  final logo = pw.MemoryImage(logoBytes.buffer.asUint8List());

  final doc = pw.Document();
  final generatedAt = DateTime.now();
  final displayPatientName = patientName.trim().isEmpty
      ? 'Unknown patient'
      : patientName.trim();
  final difference = totalCharges - totalPayments;
  final grouped = <ChargeCategory, List<ChargeItem>>{
    ChargeCategory.daily: [],
    ChargeCategory.pharmacy: [],
    ChargeCategory.lab: [],
    ChargeCategory.supplies: [],
    ChargeCategory.other: [],
  };
  for (final c in charges) {
    if (c.category == ChargeCategory.radiology) {
      grouped[ChargeCategory.lab]!.add(c);
    } else if (c.category == ChargeCategory.surgery) {
      grouped[ChargeCategory.other]!.add(c);
    } else {
      grouped.putIfAbsent(c.category, () => []).add(c);
    }
  }

  double sectionDue(List<ChargeItem> items) =>
      items.fold(0.0, (sum, item) => sum + item.lineAmountDue);
  double sectionTotal(List<ChargeItem> items) =>
      items.fold(0.0, (sum, item) => sum + item.displayLineTotal);
  double sectionPaid(List<ChargeItem> items) =>
      items.fold(0.0, (sum, item) => sum + item.amountPaid);

  pw.Widget kv(String label, String value, {bool strong = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 92,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 9.5,
                fontWeight:
                    strong ? pw.FontWeight.bold : pw.FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget section(String title, List<ChargeItem> items) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#EEF2FF'),
            border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1')),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColor.fromHex('#1E3A8A'),
            ),
          ),
        ),
        if (items.isEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(6, 8, 6, 12),
            child: pw.Text(
              'No charges in this category.',
              style: pw.TextStyle(
                color: PdfColors.grey600,
                fontSize: 9,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          )
        else
          pw.Column(
            children: [
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(
                  color: PdfColor.fromHex('#E2E8F0'),
                  width: 0.5,
                ),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3.2),
                  1: const pw.FlexColumnWidth(0.8),
                  2: const pw.FlexColumnWidth(1.4),
                  3: const pw.FlexColumnWidth(1.4),
                  4: const pw.FlexColumnWidth(1.3),
                  5: const pw.FlexColumnWidth(1.3),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                    ),
                    children:
                        [
                              'Description',
                              'Qty',
                              'Unit',
                              'Line Total',
                              'Paid',
                              'Due',
                            ]
                            .map(
                              (h) => pw.Padding(
                                padding: const pw.EdgeInsets.all(6),
                                child: pw.Text(
                                  h,
                                  style: pw.TextStyle(
                                    fontWeight: pw.FontWeight.bold,
                                    fontSize: 8.5,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  ...items.map(
                    (item) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item.description,
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            '${item.quantity}',
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item.amount.toFinancial(isMoney: true),
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item.displayLineTotal.toFinancial(isMoney: true),
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item.amountPaid.toFinancial(isMoney: true),
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            item.lineAmountDue.toFinancial(isMoney: true),
                            style: const pw.TextStyle(fontSize: 8.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 5),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Subtotal: ${sectionTotal(items).toFinancial(isMoney: true)}   '
                  'Paid: ${sectionPaid(items).toFinancial(isMoney: true)}   '
                  'Due: ${sectionDue(items).toFinancial(isMoney: true)}',
                  style: pw.TextStyle(
                    fontSize: 8.8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
            ],
          ),
      ],
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.fromLTRB(26, 24, 26, 28),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          'Page ${ctx.pageNumber} of ${ctx.pagesCount}',
          style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ),
      build: (context) => [
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey300),
            ),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 58,
                height: 58,
                padding: const pw.EdgeInsets.all(2),
                child: pw.Image(logo, fit: pw.BoxFit.contain),
              ),
              pw.SizedBox(width: 10),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'INPATIENT BILL INVOICE',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0F172A'),
                      ),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'Detailed charges and payment summary',
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
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8FAFC'),
                  border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    kv('Patient Name', displayPatientName, strong: true),
                    kv('Patient ID', patientDisplayId, strong: true),
                    kv('Invoice ID', invoiceDisplayId),
                    kv('Generated', _formatPdfDate(generatedAt)),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8FAFC'),
                  border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    kv(
                      'Total Charges',
                      totalCharges.toFinancial(isMoney: true),
                      strong: true,
                    ),
                    kv(
                      'Total Paid',
                      totalPayments.toFinancial(isMoney: true),
                    ),
                    kv('Total Owed', balanceDue.toFinancial(isMoney: true)),
                    kv('Difference', difference.toFinancial(isMoney: true)),
                    kv(
                      'Wallet Balance',
                      walletBalance.toFinancial(isMoney: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 14),
        section(
          chargeCategoryLabel(ChargeCategory.daily),
          grouped[ChargeCategory.daily] ?? const [],
        ),
        section(
          chargeCategoryLabel(ChargeCategory.pharmacy),
          grouped[ChargeCategory.pharmacy] ?? const [],
        ),
        section(
          chargeCategoryLabel(ChargeCategory.lab),
          grouped[ChargeCategory.lab] ?? const [],
        ),
        section(
          chargeCategoryLabel(ChargeCategory.supplies),
          grouped[ChargeCategory.supplies] ?? const [],
        ),
        section(
          chargeCategoryLabel(ChargeCategory.other),
          grouped[ChargeCategory.other] ?? const [],
        ),
      ],
    ),
  );
  return doc.save();
}
