import 'package:flutter/services.dart' show rootBundle;
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/utils/lab_reference_evaluation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class _PdfStatusColors {
  const _PdfStatusColors({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final PdfColor background;
  final PdfColor border;
  final PdfColor foreground;
}

class _LabPdfPalette {
  _LabPdfPalette()
      : primary = PdfColor.fromHex('#0D3B66'),
        primaryDark = PdfColor.fromHex('#082845'),
        accent = PdfColor.fromHex('#D4AF37'),
        surface = PdfColor.fromHex('#F8FAFC'),
        surfaceCard = PdfColor.fromHex('#F1F5F9'),
        border = PdfColor.fromHex('#CBD5E1'),
        textMuted = PdfColor.fromHex('#64748B');

  final PdfColor primary;
  final PdfColor primaryDark;
  final PdfColor accent;
  final PdfColor surface;
  final PdfColor surfaceCard;
  final PdfColor border;
  final PdfColor textMuted;

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
                fontWeight: emphasize
                    ? pw.FontWeight.bold
                    : pw.FontWeight.normal,
                color: PdfColors.grey900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget statusPill(LabOrderStatus status) {
    final style = _labPdfStatusStyle(status);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: style.background,
        borderRadius: pw.BorderRadius.circular(20),
        border: pw.Border.all(color: style.border, width: 0.5),
      ),
      child: pw.Text(
        _labStatusLabel(status).toUpperCase(),
        style: pw.TextStyle(
          fontSize: 7.5,
          fontWeight: pw.FontWeight.bold,
          color: style.foreground,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  pw.Widget hospitalHeader(pw.ImageProvider logoImage) {
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
                  child: pw.Image(logoImage, width: 52, height: 52),
                ),
                pw.SizedBox(width: 16),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'IBOM MULTISPECIALITY HOSPITAL',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 17,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Clinical laboratory · Quality-assured diagnostics',
                        style: pw.TextStyle(
                          color: PdfColor.fromHex('#E2E8F0'),
                          fontSize: 9,
                          letterSpacing: 0.2,
                        ),
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

  pw.Widget reportBanner() {
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
              'LABORATORY REPORT',
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

  pw.Widget resultsSummaryHeader() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(left: 10, bottom: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(left: pw.BorderSide(color: accent, width: 3)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Results summary',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: primary,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Parameters listed below reflect values released on this report.',
            style: pw.TextStyle(fontSize: 8.5, color: textMuted),
          ),
        ],
      ),
    );
  }

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
              'recipient, contact IBOM  Multispeciality Hospital immediately.',
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
            'IBOM MULTISPECIALITY HOSPITAL',
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
}

/// Whether an order item has results visible on a patient report.
bool labOrderItemHasPrintableResults(LabOrderItem item) =>
    item.results.any((r) => !r.hiddenFromReport);

List<LabAstResult> _sortedAstResultsForPdf(LabOrderItem item) {
  final list = List<LabAstResult>.from(item.astResults)
    ..sort((a, b) {
      final pc = a.antibiotic.position.compareTo(b.antibiotic.position);
      return pc != 0 ? pc : a.antibiotic.name.compareTo(b.antibiotic.name);
    });
  return list;
}

pw.Widget _labBuildAstPdfSection(
  _LabPdfPalette palette,
  LabOrderItem item,
) {
  final results = _sortedAstResultsForPdf(item);
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.SizedBox(height: 12),
      pw.Text(
        'Antibiotic Susceptibility',
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: palette.primary,
        ),
      ),
      pw.SizedBox(height: 8),
      if (results.isEmpty)
        pw.Text(
          'AST pending',
          style: pw.TextStyle(
            fontSize: 9,
            color: palette.textMuted,
            fontStyle: pw.FontStyle.italic,
          ),
        )
      else
        pw.Table(
          border: pw.TableBorder(
            horizontalInside: pw.BorderSide(color: palette.border, width: 0.4),
            verticalInside: pw.BorderSide(color: palette.border, width: 0.35),
            left: pw.BorderSide(color: palette.border, width: 0.5),
            right: pw.BorderSide(color: palette.border, width: 0.5),
            top: pw.BorderSide(color: palette.border, width: 0.5),
            bottom: pw.BorderSide(color: palette.border, width: 0.5),
          ),
          columnWidths: const {
            0: pw.FlexColumnWidth(3),
            1: pw.FlexColumnWidth(2),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: palette.primary),
              children: [
                _labBuildTableHeaderCell('Antibiotic', light: true),
                _labBuildTableHeaderCell('Result', light: true),
              ],
            ),
            ...results.asMap().entries.map((e) {
              final rowIndex = e.key;
              final r = e.value;
              final abxName = r.antibiotic.code != null &&
                      r.antibiotic.code!.isNotEmpty
                  ? '${r.antibiotic.name} (${r.antibiotic.code})'
                  : r.antibiotic.name;
              final resultLabel = r.resultOption.code != null &&
                      r.resultOption.code!.isNotEmpty
                  ? '${r.resultOption.label} (${r.resultOption.code})'
                  : r.resultOption.label;
              final stripe =
                  rowIndex.isEven ? PdfColors.white : palette.surface;
              return pw.TableRow(
                decoration: pw.BoxDecoration(color: stripe),
                children: [
                  _labBuildTableCell(abxName),
                  _labBuildTableCell(resultLabel, isBold: true),
                ],
              );
            }),
          ],
        ),
    ],
  );
}

Future<pw.ImageProvider> _loadLabPdfLogo() async {
  final logoImageBytes = await rootBundle.load('assets/imsh.png');
  return pw.MemoryImage(logoImageBytes.buffer.asUint8List());
}

/// Builds PDF sections for one or more order items.
List<pw.Widget> _buildLabOrderItemPdfSections(
  _LabPdfPalette palette, {
  required List<({LabOrderItem item, int index, String? orderShortId})>
      entries,
}) {
  return entries.expand((entry) {
    final index = entry.index;
    final item = entry.item;
    final orderShortId = entry.orderShortId;
    final testName = item.testVersion?.test?.name ?? 'Test';
    final sampleType = item.testVersion?.test?.sampleType ?? '';
    final hasSample = item.sample != null;
    final fields = item.fields ?? item.testVersion?.fields ?? [];
    final fieldMap = {for (final f in fields) f.id: f};
    final reportResults =
        item.results.where((r) => !r.hiddenFromReport).toList();

    return [
      pw.Container(
        margin: const pw.EdgeInsets.only(bottom: 14),
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: palette.border, width: 0.65),
          boxShadow: [
            pw.BoxShadow(
              color: PdfColor.fromInt(0x0F0F172A),
              offset: const PdfPoint(0, 3),
              blurRadius: 8,
            ),
          ],
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: pw.BoxDecoration(
                    color: palette.surface,
                    borderRadius: const pw.BorderRadius.vertical(
                      top: pw.Radius.circular(11),
                    ),
                  ),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(
                        width: 28,
                        height: 28,
                        alignment: pw.Alignment.center,
                        decoration: pw.BoxDecoration(
                          color: palette.primary,
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
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              testName,
                              style: pw.TextStyle(
                                fontSize: 12,
                                fontWeight: pw.FontWeight.bold,
                                color: palette.primary,
                              ),
                            ),
                            if (orderShortId != null)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 2),
                                child: pw.Text(
                                  'Order #$orderShortId',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    color: palette.textMuted,
                                  ),
                                ),
                              ),
                            if (sampleType.isNotEmpty)
                              pw.Padding(
                                padding: const pw.EdgeInsets.only(top: 4),
                                child: pw.Row(
                                  children: [
                                    pw.Container(
                                      padding: const pw.EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: pw.BoxDecoration(
                                        color: palette.surfaceCard,
                                        borderRadius:
                                            pw.BorderRadius.circular(6),
                                        border: pw.Border.all(
                                          color: palette.border,
                                          width: 0.4,
                                        ),
                                      ),
                                      child: pw.Text(
                                        sampleType,
                                        style: pw.TextStyle(
                                          fontSize: 8,
                                          color: palette.textMuted,
                                        ),
                                      ),
                                    ),
                                    if (hasSample) ...[
                                      pw.SizedBox(width: 8),
                                      pw.Container(
                                        padding:
                                            const pw.EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: pw.BoxDecoration(
                                          color: PdfColor.fromHex('#DCFCE7'),
                                          borderRadius:
                                              pw.BorderRadius.circular(6),
                                          border: pw.Border.all(
                                            color: PdfColor.fromHex('#86EFAC'),
                                            width: 0.4,
                                          ),
                                        ),
                                        child: pw.Text(
                                          'SAMPLE COLLECTED',
                                          style: pw.TextStyle(
                                            fontSize: 7.5,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColor.fromHex('#166534'),
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                pw.Container(height: 0.5, color: palette.border),
              ],
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  if (reportResults.isEmpty)
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 16,
                      ),
                      decoration: pw.BoxDecoration(
                        color: palette.surface,
                        borderRadius: pw.BorderRadius.circular(10),
                        border: pw.Border.all(
                          color: palette.border,
                          width: 0.5,
                        ),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Container(
                            width: 3,
                            height: 36,
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromInt(0xB3D4AF37),
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                          ),
                          pw.SizedBox(width: 12),
                          pw.Expanded(
                            child: pw.Text(
                              item.results.isEmpty
                                  ? 'No results have been entered for this test yet.'
                                  : 'All result lines are hidden from the patient report.',
                              style: pw.TextStyle(
                                fontSize: 9,
                                color: palette.textMuted,
                                lineSpacing: 1.25,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    pw.Table(
                      border: pw.TableBorder(
                        horizontalInside: pw.BorderSide(
                          color: palette.border,
                          width: 0.4,
                        ),
                        verticalInside: pw.BorderSide(
                          color: palette.border,
                          width: 0.35,
                        ),
                        left: pw.BorderSide(color: palette.border, width: 0.5),
                        right: pw.BorderSide(color: palette.border, width: 0.5),
                        top: pw.BorderSide(color: palette.border, width: 0.5),
                        bottom:
                            pw.BorderSide(color: palette.border, width: 0.5),
                      ),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(3),
                        1: pw.FlexColumnWidth(2.2),
                        2: pw.FlexColumnWidth(1.8),
                        3: pw.FlexColumnWidth(2.2),
                      },
                      children: [
                        pw.TableRow(
                          decoration:
                              pw.BoxDecoration(color: palette.primary),
                          children: [
                            _labBuildTableHeaderCell('Parameter', light: true),
                            _labBuildTableHeaderCell('Result', light: true),
                            _labBuildTableHeaderCell('Unit', light: true),
                            _labBuildTableHeaderCell('Reference', light: true),
                          ],
                        ),
                        ...reportResults.asMap().entries.map((e) {
                          final rowIndex = e.key;
                          final r = e.value;
                          final field = r.field ?? fieldMap[r.fieldId];
                          final eval = r.referenceEvaluation;
                          final resultText = labPdfResultValueText(r);
                          final resultColor = labPdfReferenceValueColor(
                                eval,
                                abnormalColor: PdfColor.fromHex('#DC2626'),
                              ) ??
                              palette.primary;
                          final stripe = rowIndex.isEven
                              ? PdfColors.white
                              : palette.surface;
                          return pw.TableRow(
                            decoration: pw.BoxDecoration(color: stripe),
                            children: [
                              _labBuildTableCell(field?.label ?? r.fieldId),
                              _labBuildTableCell(
                                resultText,
                                isBold: true,
                                valueColor: resultColor,
                              ),
                              _labBuildTableCell(field?.unit ?? ''),
                              _labBuildTableCell(
                                field?.referenceRange ?? '',
                                muted: true,
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  if (item.astRequested)
                    _labBuildAstPdfSection(palette, item),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }).toList();
}

/// Builds a laboratory order PDF for print / share.
Future<List<int>> buildLabOrderPdf(LabOrder order, PdfPageFormat format) async {
  final logoImage = await _loadLabPdfLogo();
  final palette = _LabPdfPalette();

  final generatedOn = DateTime.now();
  final generatedStr = generatedOn.toIso8601String().split('T').first;
  final orderDateStr = order.createdAt != null
      ? order.createdAt!.toIso8601String().split('T').first
      : '—';

  final itemEntries = order.items.asMap().entries
      .map(
        (e) => (
          item: e.value,
          index: e.key + 1,
          orderShortId: null as String?,
        ),
      )
      .toList();

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.fromLTRB(38, 34, 38, 40),
      header: (context) {
        if (context.pageNumber == 1) return pw.SizedBox();
        return palette.continuationHeader(
          'Laboratory report · #${_labOrderShortId(order.id)}',
        );
      },
      footer: (context) => palette.pageFooter(generatedStr, context),
      build: (context) {
        return [
          palette.hospitalHeader(logoImage),
          pw.SizedBox(height: 20),
          palette.reportBanner(),
          pw.SizedBox(height: 18),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              palette.infoCard(
                title: 'PATIENT',
                rows: [
                  palette.kv(
                    'Full name',
                    order.patient?.capitalizedDisplayName.isNotEmpty == true
                        ? order.patient!.capitalizedDisplayName
                        : 'N/A',
                    emphasize: true,
                  ),
                  if (order.patient?.patientId?.trim().isNotEmpty == true)
                    palette.kv(
                      'Patient ID',
                      order.patient!.patientId!.trim(),
                    ),
                  palette.kv('Order date', orderDateStr),
                  palette.kv('Report date', generatedStr),
                ],
              ),
              pw.SizedBox(width: 14),
              palette.infoCard(
                title: 'ORDER',
                rows: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Text(
                          'Status',
                          style: pw.TextStyle(
                            fontSize: 8.5,
                            color: palette.textMuted,
                          ),
                        ),
                        pw.SizedBox(width: 10),
                        palette.statusPill(order.status),
                      ],
                    ),
                  ),
                  palette.kv(
                    'Order no.',
                    '#${_labOrderShortId(order.id)}',
                    emphasize: true,
                  ),
                  if (order.doctor != null)
                    palette.kv(
                      'Physician',
                      order.doctor!.capitalizedDisplayName.isNotEmpty
                          ? order.doctor!.capitalizedDisplayName
                          : order.doctor!.displayName,
                    ),
                  palette.kv(
                    'Items',
                    '${order.items.length} test${order.items.length == 1 ? '' : 's'}',
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          palette.resultsSummaryHeader(),
          pw.SizedBox(height: 12),
          ..._buildLabOrderItemPdfSections(palette, entries: itemEntries),
        ];
      },
    ),
  );
  return doc.save();
}

/// Combined PDF for selected tests from one patient (may span multiple orders).
Future<List<int>> buildLabPatientItemsPdf({
  required LabOrderPatient patient,
  required List<({LabOrder order, LabOrderItem item})> entries,
  required PdfPageFormat format,
}) async {
  final printable = entries
      .where((e) => labOrderItemHasPrintableResults(e.item))
      .toList();
  if (printable.isEmpty) return [];

  final logoImage = await _loadLabPdfLogo();
  final palette = _LabPdfPalette();

  final generatedOn = DateTime.now();
  final generatedStr = generatedOn.toIso8601String().split('T').first;

  final orderIds = printable.map((e) => e.order.id).toSet();
  final showOrderRef = orderIds.length > 1;
  final orderSummary = orderIds
      .map((id) => '#${_labOrderShortId(id)}')
      .join(', ');

  final itemEntries = printable.asMap().entries
      .map(
        (e) => (
          item: e.value.item,
          index: e.key + 1,
          orderShortId: showOrderRef
              ? _labOrderShortId(e.value.order.id)
              : null as String?,
        ),
      )
      .toList();

  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      margin: const pw.EdgeInsets.fromLTRB(38, 34, 38, 40),
      header: (context) {
        if (context.pageNumber == 1) return pw.SizedBox();
        return palette.continuationHeader(
          'Laboratory report · ${patient.capitalizedDisplayName.isNotEmpty ? patient.capitalizedDisplayName : patient.displayName}',
        );
      },
      footer: (context) => palette.pageFooter(generatedStr, context),
      build: (context) {
        return [
          palette.hospitalHeader(logoImage),
          pw.SizedBox(height: 20),
          palette.reportBanner(),
          pw.SizedBox(height: 18),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              palette.infoCard(
                title: 'PATIENT',
                rows: [
                  palette.kv(
                    'Full name',
                    patient.capitalizedDisplayName.isNotEmpty
                        ? patient.capitalizedDisplayName
                        : 'N/A',
                    emphasize: true,
                  ),
                  if (patient.patientId?.trim().isNotEmpty == true)
                    palette.kv('Patient ID', patient.patientId!.trim()),
                  palette.kv('Report date', generatedStr),
                ],
              ),
              pw.SizedBox(width: 14),
              palette.infoCard(
                title: 'ORDERS',
                rows: [
                  palette.kv(
                    'Order no.',
                    orderSummary,
                    emphasize: true,
                  ),
                  palette.kv(
                    'Tests',
                    '${printable.length} test${printable.length == 1 ? '' : 's'}',
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 22),
          palette.resultsSummaryHeader(),
          pw.SizedBox(height: 12),
          ..._buildLabOrderItemPdfSections(palette, entries: itemEntries),
        ];
      },
    ),
  );
  return doc.save();
}

_PdfStatusColors _labPdfStatusStyle(LabOrderStatus status) {
  switch (status) {
    case LabOrderStatus.pending:
      return _PdfStatusColors(
        background: PdfColor.fromHex('#FEF9C3'),
        border: PdfColor.fromHex('#EAB308'),
        foreground: PdfColor.fromHex('#854D0E'),
      );
    case LabOrderStatus.sampleCollected:
      return _PdfStatusColors(
        background: PdfColor.fromHex('#E0F2FE'),
        border: PdfColor.fromHex('#38BDF8'),
        foreground: PdfColor.fromHex('#075985'),
      );
    case LabOrderStatus.processing:
      return _PdfStatusColors(
        background: PdfColor.fromHex('#FFEDD5'),
        border: PdfColor.fromHex('#FB923C'),
        foreground: PdfColor.fromHex('#9A3412'),
      );
    case LabOrderStatus.completed:
      return _PdfStatusColors(
        background: PdfColor.fromHex('#DCFCE7'),
        border: PdfColor.fromHex('#4ADE80'),
        foreground: PdfColor.fromHex('#166534'),
      );
    case LabOrderStatus.verified:
      return _PdfStatusColors(
        background: PdfColor.fromHex('#EDE9FE'),
        border: PdfColor.fromHex('#A78BFA'),
        foreground: PdfColor.fromHex('#5B21B6'),
      );
  }
}

String _labOrderShortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

pw.Widget _labBuildTableHeaderCell(String text, {bool light = false}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    child: pw.Text(
      text.toUpperCase(),
      style: pw.TextStyle(
        fontWeight: pw.FontWeight.bold,
        fontSize: 8.5,
        letterSpacing: 0.6,
        color: light ? PdfColors.white : PdfColors.grey900,
      ),
    ),
  );
}

pw.Widget _labBuildTableCell(
  String text, {
  bool isBold = false,
  PdfColor? valueColor,
  bool muted = false,
}) {
  final color =
      valueColor ?? (muted ? PdfColor.fromHex('#64748B') : PdfColors.grey900);
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(vertical: 7, horizontal: 8),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 9.5,
        fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        color: color,
      ),
    ),
  );
}

String _labStatusLabel(LabOrderStatus s) {
  switch (s) {
    case LabOrderStatus.pending:
      return 'Pending';
    case LabOrderStatus.sampleCollected:
      return 'Sample collected';
    case LabOrderStatus.processing:
      return 'Processing';
    case LabOrderStatus.completed:
      return 'Completed';
    case LabOrderStatus.verified:
      return 'Verified';
  }
}
