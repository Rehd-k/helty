import 'package:helty/src/app/org_config.dart';
import 'package:helty/src/printing/pdf/org_pdf_logo.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/utils/lab_ast_display.dart';
import 'package:helty/src/lab/utils/lab_reference_evaluation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

final _ink = PdfColor.fromHex('#111111');
final _title = PdfColor.fromHex('#1E293B');
final _line = PdfColor.fromHex('#D1D5DB');
final _contact = PdfColor.fromHex('#1D4ED8');
final _high = PdfColor.fromHex('#DC2626');
final _accent = PdfColor.fromHex('#1D4ED8');
final _accentSoft = PdfColor.fromHex('#DBEAFE');
final _teal = PdfColor.fromHex('#0F766E');
final _tealSoft = PdfColor.fromHex('#CCFBF1');
final _violet = PdfColor.fromHex('#6D28D9');
final _violetSoft = PdfColor.fromHex('#EDE9FE');
final _amber = PdfColor.fromHex('#B45309');
final _amberSoft = PdfColor.fromHex('#FFFBEB');
final _testHead = PdfColor.fromHex('#1E3A8A');

final _side = pw.BorderSide(color: _line, width: 0.6);
final _hairlineSide = pw.BorderSide(color: _line, width: 0.4);

pw.TextStyle _type(double fontSize) => pw.TextStyle(
  fontSize: fontSize,
  fontWeight: pw.FontWeight.bold,
  color: _ink,
);

/// Whether a single result line should appear on a printed report.
bool _labResultIsPrintable(LabResult r) =>
    !r.hiddenFromReport && r.value.trim().isNotEmpty;

/// Whether an order item has results visible on a patient report.
bool labOrderItemHasPrintableResults(LabOrderItem item) =>
    item.results.any(_labResultIsPrintable);

typedef _LabPdfEntry = ({LabOrderItem item, String? requisitionShortId});

class _LabReportFacts {
  const _LabReportFacts({
    required this.patientName,
    required this.requisitionLabel,
    required this.ageSex,
    required this.collectionDate,
    required this.qrData,
    required this.generatedLabel,
    required this.doctorName,
    required this.entries,
  });

  final String patientName;
  final String requisitionLabel;
  final String ageSex;
  final String collectionDate;
  final String qrData;
  final String generatedLabel;
  final String doctorName;
  final List<_LabPdfEntry> entries;

  factory _LabReportFacts.build({
    required LabOrderPatient? patient,
    required List<_LabPdfEntry> entries,
    required String requisitionLabel,
    required DateTime generatedOn,
    String doctorName = '',
  }) {
    final org = OrgConfig.instance;
    final website = org.website.trim();
    final qrData = website.isEmpty
        ? requisitionLabel
        : '$website\n$requisitionLabel';
    return _LabReportFacts(
      patientName: _patientName(patient),
      requisitionLabel: requisitionLabel,
      ageSex: _ageSex(patient),
      collectionDate: _formatDates(
        entries.map((entry) => entry.item.sample?.collectionTime),
      ),
      qrData: qrData,
      generatedLabel: DateFormatter.dateTime24(generatedOn),
      doctorName: doctorName.trim(),
      entries: entries,
    );
  }
}

Future<pw.ImageProvider> _loadLabPdfLogo() => loadOrgPdfLogo();

String _labOrderShortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

String _patientName(LabOrderPatient? patient) {
  if (patient == null) return 'N/A';
  if (patient.capitalizedDisplayName.trim().isNotEmpty) {
    return patient.capitalizedDisplayName.trim();
  }
  if (patient.displayName.trim().isNotEmpty) return patient.displayName.trim();
  return 'N/A';
}

String _formatDates(Iterable<DateTime?> dates) {
  final labels = <String>[];
  final seen = <String>{};
  for (final date in dates) {
    if (date == null) continue;
    final label = DateFormatter.dateTime24(date);
    if (seen.add(label)) labels.add(label);
  }
  return labels.isEmpty ? '-' : labels.join(', ');
}

String _ageSex(LabOrderPatient? patient) {
  if (patient == null) return '-';
  final age = patient.dob == null
      ? null
      : DateFormatter.patientAgeFromDob(patient.dob!);
  final sex = _shortSex(patient.gender);
  if (age == null && sex == null) return '-';
  if (age == null) return sex!;
  if (sex == null) return age;
  return '$age / $sex';
}

String? _shortSex(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;
  switch (value.toUpperCase()) {
    case 'M':
    case 'MALE':
      return 'M';
    case 'F':
    case 'FEMALE':
      return 'F';
    default:
      return value;
  }
}

String _referenceLine(LabTestField? field, ReferenceEvaluation? eval) {
  final range = field?.referenceRange?.trim().isNotEmpty == true
      ? field!.referenceRange!.trim()
      : eval?.referenceRange?.trim();
  final unit = field?.unit?.trim();
  final rangeText = range?.trim() ?? '';
  final unitText = unit?.trim() ?? '';
  if (rangeText.isEmpty && unitText.isEmpty) return '-';
  if (rangeText.isEmpty) return unitText;
  if (unitText.isEmpty) return rangeText;
  if (rangeText.toLowerCase().contains(unitText.toLowerCase())) {
    return rangeText;
  }
  return '$rangeText $unitText';
}

String? _flagLetter(ReferenceEvaluation? eval) {
  if (eval?.inRange != false) return null;
  switch (eval!.flag) {
    case ReferenceFlag.high:
      return 'H';
    case ReferenceFlag.low:
      return 'L';
    case null:
      return null;
  }
}

PdfColor _astResultColor(LabAstResultOption option) {
  return switch (classifyLabAstResult(option)) {
    LabAstInterpretation.sensitive => PdfColor.fromHex('#166534'),
    LabAstInterpretation.resistant => PdfColor.fromHex('#B91C1C'),
    LabAstInterpretation.intermediate => PdfColor.fromHex('#B45309'),
    LabAstInterpretation.other => _ink,
  };
}

pw.Widget _reportHeader(pw.ImageProvider logo) {
  final org = OrgConfig.instance;
  final address = org.addresses
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join('\n');
  final contact = [
    if (org.emailsLine.isNotEmpty) org.emailsLine,
    if (org.phonesLine.isNotEmpty) org.phonesLine,
  ].join(' | ');

  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 12),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Container(
                height: 7,
                decoration: pw.BoxDecoration(
                  color: _accent,
                  borderRadius: const pw.BorderRadius.horizontal(
                    left: pw.Radius.circular(4),
                  ),
                ),
              ),
            ),
            pw.Expanded(child: pw.Container(height: 7, color: _teal)),
            pw.Expanded(
              child: pw.Container(
                height: 7,
                decoration: pw.BoxDecoration(
                  color: _violet,
                  borderRadius: const pw.BorderRadius.horizontal(
                    right: pw.Radius.circular(4),
                  ),
                ),
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              width: 118,
              height: 56,
              padding: const pw.EdgeInsets.all(6),
              decoration: pw.BoxDecoration(
                color: _accentSoft,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    org.name,
                    textAlign: pw.TextAlign.right,
                    style: _type(13).copyWith(color: _title),
                  ),
                  if (address.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      address,
                      textAlign: pw.TextAlign.right,
                      style: _type(8),
                    ),
                  ],
                  if (contact.isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    pw.Text(
                      contact,
                      textAlign: pw.TextAlign.right,
                      style: _type(8).copyWith(color: _contact),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (org.taglines.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          _taglineStrip(org.taglines),
        ],
      ],
    ),
  );
}

pw.Widget _taglineStrip(List<String> taglines) {
  final fills = [_accentSoft, _tealSoft, _violetSoft, _amberSoft];
  final inks = [_accent, _teal, _violet, _amber];
  return pw.Wrap(
    spacing: 6,
    runSpacing: 4,
    children: [
      for (var i = 0; i < taglines.length; i++)
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: pw.BoxDecoration(
            color: fills[i % fills.length],
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Text(
            taglines[i],
            style: _type(8).copyWith(color: inks[i % inks.length]),
          ),
        ),
    ],
  );
}

pw.Widget _sectionRule() {
  return pw.Container(height: 0.6, color: PdfColor.fromHex('#EEEEEE'));
}

pw.Widget _labeledValue(String label, String value) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(label.toUpperCase(), style: _type(7)),
      pw.SizedBox(height: 2),
      pw.Text(value, style: _type(9.5)),
    ],
  );
}

pw.Widget _patientGrid(_LabReportFacts facts) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 8),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              flex: 3,
              child: _labeledValue('Patient Name', facts.patientName),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              flex: 3,
              child: _labeledValue('Collection Date', facts.collectionDate),
            ),
            pw.SizedBox(width: 16),
            pw.Expanded(
              flex: 2,
              child: _labeledValue('Age / Sex', facts.ageSex),
            ),
          ],
        ),
        if (facts.doctorName.isNotEmpty) ...[
          pw.SizedBox(height: 8),
          _labeledValue('Doctor', facts.doctorName),
        ],
      ],
    ),
  );
}

pw.Widget _categoryBanner(String title, String? requisitionShortId) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 14),
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: pw.BoxDecoration(
      color: _accentSoft,
      borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(8)),
      border: pw.Border.all(color: PdfColor.fromHex('#BFDBFE'), width: 0.8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          children: [
            pw.Container(
              width: 4,
              height: 14,
              decoration: pw.BoxDecoration(
                color: _accent,
                borderRadius: pw.BorderRadius.circular(2),
              ),
            ),
            pw.SizedBox(width: 8),
            pw.Expanded(
              child: pw.Text(title, style: _type(10.5).copyWith(color: _testHead)),
            ),
          ],
        ),
        if (requisitionShortId != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              'Requisition #$requisitionShortId',
              style: _type(7.5).copyWith(color: _accent),
            ),
          ),
      ],
    ),
  );
}

String _emptyResultsMessage(LabOrderItem item) {
  if (item.results.isEmpty) {
    return 'No results have been entered for this test yet.';
  }
  if (item.results.every((result) => result.hiddenFromReport)) {
    return 'All result lines are hidden from the patient report.';
  }
  return 'No result values are available for this report.';
}

pw.Widget _openPanel(String message, {required bool closeBottom}) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: pw.BoxDecoration(
      border: pw.Border(
        left: _side,
        right: _side,
        bottom: closeBottom ? _side : pw.BorderSide.none,
      ),
    ),
    child: pw.Text(message, style: _type(8.5)),
  );
}

pw.TableBorder _tableBorder({required bool closeBottom}) {
  return pw.TableBorder(
    left: _side,
    right: _side,
    top: pw.BorderSide.none,
    bottom: closeBottom ? _side : pw.BorderSide.none,
    horizontalInside: _hairlineSide,
  );
}

pw.Widget _paddedText(
  String text, {
  pw.TextStyle? style,
  pw.TextAlign align = pw.TextAlign.left,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    child: pw.Text(text, textAlign: align, style: style),
  );
}

pw.Widget _resultsTable({
  required List<LabResult> reportResults,
  required Map<String, LabTestField> fieldMap,
  required bool closeBottom,
}) {
  return pw.Table(
    border: _tableBorder(closeBottom: closeBottom),
    columnWidths: const {
      0: pw.FlexColumnWidth(2.2),
      1: pw.FlexColumnWidth(4.5),
      2: pw.FlexColumnWidth(1.8),
    },
    children: [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: _tealSoft),
        children: [
          _paddedText('TEST', style: _type(7).copyWith(color: _teal)),
          _paddedText('RESULT', style: _type(7).copyWith(color: _teal)),
          _paddedText(
            'REFERENCE',
            align: pw.TextAlign.right,
            style: _type(7).copyWith(color: _teal),
          ),
        ],
      ),
      for (final result in reportResults)
        _resultRow(result, fieldMap[result.fieldId]),
    ],
  );
}

pw.TableRow _resultRow(LabResult result, LabTestField? mappedField) {
  final field = result.field ?? mappedField;
  final eval = resolveLabReferenceEvaluation(
    value: result.value,
    referenceRange: field?.referenceRange,
    serverEvaluation: result.referenceEvaluation,
  );
  final flag = _flagLetter(eval);
  final embedded = parseEmbeddedAstReport(result.value);
  final shown = embedded == null
      ? result.value
      : (embedded.narrative.isEmpty
            ? 'See antibiotic susceptibility'
            : embedded.narrative);

  return pw.TableRow(
    children: [
      _paddedText(field?.label ?? result.fieldId, style: _type(9)),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Flexible(child: pw.Text(shown, style: _type(9.5))),
            if (flag != null) ...[
              pw.SizedBox(width: 6),
              pw.Text(flag, style: _type(9.5).copyWith(color: _high)),
            ],
          ],
        ),
      ),
      _paddedText(
        _referenceLine(field, eval),
        align: pw.TextAlign.right,
        style: _type(8),
      ),
    ],
  );
}

pw.Widget _scientistNotesPanel(String notes) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 10),
    decoration: pw.BoxDecoration(
      border: pw.Border(
        left: _side,
        right: _side,
        bottom: _side,
      ),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('SCIENTIST NOTES', style: _type(7)),
        pw.SizedBox(height: 3),
        pw.Text(notes, style: _type(9)),
      ],
    ),
  );
}

List<pw.Widget> _astWidgets(LabOrderItem item, {required bool closeBottom}) {
  final results = sortedLabAstResults(item.astResults);
  if (results.isEmpty) {
    return [
      _categoryBanner('ANTIBIOTIC SUSCEPTIBILITY', null),
      _openPanel('AST pending', closeBottom: closeBottom),
    ];
  }

  final header = _type(8).copyWith(color: _teal);
  final legend = labAstResultLegend(results);
  final closeTable = closeBottom && legend == null;
  return [
    _categoryBanner('ANTIBIOTIC SUSCEPTIBILITY', null),
    pw.Table(
      border: pw.TableBorder(
        left: _side,
        right: _side,
        top: pw.BorderSide.none,
        bottom: closeTable ? _side : pw.BorderSide.none,
        horizontalInside: _hairlineSide,
        verticalInside: _hairlineSide,
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(4.2),
        1: pw.FlexColumnWidth(1.3),
        2: pw.FlexColumnWidth(2.8),
      },
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _tealSoft),
          children: [
            _paddedText('ANTIBIOTIC', style: header),
            _paddedText('CODE', style: header),
            _paddedText('RESULT', style: header),
          ],
        ),
        ...results.asMap().entries.map((entry) {
          final result = entry.value;
          final stripe = entry.key.isOdd
              ? PdfColor.fromHex('#F8FAFC')
              : PdfColors.white;
          return pw.TableRow(
            decoration: pw.BoxDecoration(color: stripe),
            children: [
              _paddedText(
                labAstAntibioticName(result.antibiotic),
                style: _type(9),
              ),
              _paddedText(
                labAstAntibioticCode(result.antibiotic),
                style: _type(9),
              ),
              _paddedText(
                labAstResultText(result.resultOption),
                style: _type(9).copyWith(
                  color: _astResultColor(result.resultOption),
                ),
              ),
            ],
          );
        }),
      ],
    ),
    if (legend != null)
      pw.Container(
        width: double.infinity,
        padding: const pw.EdgeInsets.fromLTRB(12, 6, 12, 8),
        decoration: pw.BoxDecoration(
          border: pw.Border(
            left: _side,
            right: _side,
            bottom: closeBottom ? _side : pw.BorderSide.none,
          ),
        ),
        child: pw.Text(legend, style: _type(7.5).copyWith(color: _teal)),
      ),
  ];
}

List<pw.Widget> _categoryWidgets(_LabPdfEntry entry) {
  final item = entry.item;
  final testName = item.testVersion?.test?.name ?? 'Test';
  final fields = item.fields ?? item.testVersion?.fields ?? [];
  final fieldMap = {for (final field in fields) field.id: field};
  final reportResults = item.results.where(_labResultIsPrintable).toList();
  final notes = item.scientistNotes?.trim() ?? '';
  final hasNotes = notes.isNotEmpty;
  final hasEmbedded = reportResults.any(
    (result) => parseEmbeddedAstReport(result.value) != null,
  );
  final attachAst =
      item.astRequested && (item.astResults.isNotEmpty || !hasEmbedded);
  final closeResults = !attachAst && !hasNotes;

  return [
    _categoryBanner(testName, entry.requisitionShortId),
    if (reportResults.isEmpty)
      _openPanel(_emptyResultsMessage(item), closeBottom: closeResults)
    else
      _resultsTable(
        reportResults: reportResults,
        fieldMap: fieldMap,
        closeBottom: closeResults,
      ),
    if (attachAst) ..._astWidgets(item, closeBottom: !hasNotes),
    ..._embeddedAstSections(reportResults),
    if (hasNotes) _scientistNotesPanel(notes),
  ];
}

List<pw.Widget> _embeddedAstSections(List<LabResult> results) {
  final sections = <pw.Widget>[];
  for (final result in results) {
    final report = parseEmbeddedAstReport(result.value);
    if (report == null) continue;
    sections.add(pw.SizedBox(height: 8));
    sections.add(_embeddedAstTable(report));
  }
  return sections;
}

pw.Widget _embeddedAstTable(EmbeddedAstReport report) {
  final header = _type(8).copyWith(color: _teal);
  final legend = report.legend.isEmpty
      ? null
      : report.legend.map((item) => '${item.code} = ${item.meaning}').join(' | ');
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.Table(
        border: pw.TableBorder(
          left: _side,
          right: _side,
          top: _side,
          bottom: legend == null ? _side : pw.BorderSide.none,
          horizontalInside: _hairlineSide,
          verticalInside: _hairlineSide,
        ),
        columnWidths: const {
          0: pw.FlexColumnWidth(4.2),
          1: pw.FlexColumnWidth(1.6),
        },
        children: [
          pw.TableRow(
            decoration: pw.BoxDecoration(color: _tealSoft),
            children: [
              _paddedText('ANTIBIOTIC', style: header),
              _paddedText('RESULT', style: header),
            ],
          ),
          ...report.rows.asMap().entries.map((entry) {
            final row = entry.value;
            final stripe = entry.key.isOdd
                ? PdfColor.fromHex('#F8FAFC')
                : PdfColors.white;
            return pw.TableRow(
              decoration: pw.BoxDecoration(color: stripe),
              children: [
                _paddedText(row.antibiotic, style: _type(9)),
                _paddedText(
                  row.result,
                  style: _type(9).copyWith(color: _astTokenColor(row.result)),
                ),
              ],
            );
          }),
        ],
      ),
      if (legend != null)
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.fromLTRB(12, 6, 12, 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(left: _side, right: _side, bottom: _side),
          ),
          child: pw.Text(legend, style: _type(7.5).copyWith(color: _teal)),
        ),
    ],
  );
}

PdfColor _astTokenColor(String token) {
  return switch (classifyAstToken(token)) {
    LabAstInterpretation.sensitive => PdfColor.fromHex('#166534'),
    LabAstInterpretation.resistant => PdfColor.fromHex('#B91C1C'),
    LabAstInterpretation.intermediate => PdfColor.fromHex('#B45309'),
    LabAstInterpretation.other => _ink,
  };
}

pw.Widget _signatureBlock(String title) {
  return pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text('Signature', style: _type(7.5)),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 46,
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: _line, width: 0.7),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 0.8, color: _ink),
        pw.SizedBox(height: 6),
        pw.Text(title, textAlign: pw.TextAlign.center, style: _type(9)),
      ],
    ),
  );
}

pw.Widget _signatureSection() {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 28),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _signatureBlock('Med Lab Scientist'),
        pw.SizedBox(width: 28),
        _signatureBlock('HOD Med Lab'),
      ],
    ),
  );
}

pw.Widget _endOfReport(String qrData) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 22),
    child: pw.Column(
      children: [
        pw.Text(
          'End of Report',
          textAlign: pw.TextAlign.center,
          style: _type(10),
        ),
        pw.SizedBox(height: 10),
        pw.Center(
          child: pw.BarcodeWidget(
            barcode: pw.Barcode.qrCode(),
            data: qrData,
            width: 68,
            height: 68,
            drawText: false,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _continuationHeader(_LabReportFacts facts) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 8),
    padding: const pw.EdgeInsets.only(bottom: 6),
    decoration: pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.6)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Text(facts.patientName, style: _type(9)),
        ),
        pw.SizedBox(width: 12),
        pw.Text(facts.requisitionLabel, style: _type(8)),
      ],
    ),
  );
}

pw.Widget _pageFooter(String generatedStr, pw.Context context) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 10),
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _line, width: 0.6)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Text(
            'Confidential medical record - ${OrgConfig.instance.name}',
            style: _type(7),
          ),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount} | $generatedStr',
          style: _type(7.5),
        ),
      ],
    ),
  );
}

Future<List<int>> _saveLabReportPdf({
  required PdfPageFormat format,
  required _LabReportFacts facts,
}) async {
  final logo = await _loadLabPdfLogo();
  final doc = pw.Document();
  doc.addPage(
    pw.MultiPage(
      pageFormat: format,
      maxPages: 200,
      margin: const pw.EdgeInsets.fromLTRB(36, 32, 36, 36),
      header: (context) {
        if (context.pageNumber == 1) return pw.SizedBox();
        return _continuationHeader(facts);
      },
      footer: (context) => _pageFooter(facts.generatedLabel, context),
      build: (context) => [
        _reportHeader(logo),
        _sectionRule(),
        _patientGrid(facts),
        ...facts.entries.expand(_categoryWidgets),
        _signatureSection(),
        _endOfReport(facts.qrData),
      ],
    ),
  );
  return doc.save();
}

/// Builds a laboratory order PDF for print / share.
Future<List<int>> buildLabOrderPdf(LabOrder order, PdfPageFormat format) async {
  final shortId = _labOrderShortId(order.id);
  final generatedOn = DateTime.now();
  return _saveLabReportPdf(
    format: format,
    facts: _LabReportFacts.build(
      patient: order.patient,
      entries: [
        for (final item in order.items) (item: item, requisitionShortId: null),
      ],
      requisitionLabel: '#$shortId',
      generatedOn: generatedOn,
      doctorName: order.printDoctorName,
    ),
  );
}

/// Combined PDF for selected tests from one patient (may span multiple orders).
Future<List<int>> buildLabPatientItemsPdf({
  required LabOrderPatient patient,
  required List<({LabOrder order, LabOrderItem item})> entries,
  required PdfPageFormat format,
}) async {
  final printable = entries
      .where((entry) => labOrderItemHasPrintableResults(entry.item))
      .toList();
  if (printable.isEmpty) return [];

  final seenOrderIds = <String>{};
  final requisitionLabels = <String>[];
  for (final entry in printable) {
    if (!seenOrderIds.add(entry.order.id)) continue;
    requisitionLabels.add('#${_labOrderShortId(entry.order.id)}');
  }
  final showOrderRef = seenOrderIds.length > 1;

  return _saveLabReportPdf(
    format: format,
    facts: _LabReportFacts.build(
      patient: patient,
      entries: [
        for (final entry in printable)
          (
            item: entry.item,
            requisitionShortId: showOrderRef
                ? _labOrderShortId(entry.order.id)
                : null,
          ),
      ],
      requisitionLabel: requisitionLabels.join(', '),
      doctorName: LabOrder.combinedPrintDoctorName(
        printable.map((entry) => entry.order),
      ),
      generatedOn: DateTime.now(),
    ),
  );
}
