import 'package:flutter/services.dart' show rootBundle;
import 'package:helty/src/app/org_config.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/utils/lab_reference_evaluation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

final _ink = PdfColor.fromHex('#0F172A');
final _inkStrong = PdfColor.fromHex('#0F172A');
final _title = PdfColor.fromHex('#0F172A');
final _contact = PdfColor.fromHex('#1D4ED8');
final _high = PdfColor.fromHex('#DC2626');
final _highBg = PdfColor.fromHex('#FEE2E2');
final _accent = PdfColor.fromHex('#1D4ED8');
final _accentSoft = PdfColor.fromHex('#DBEAFE');
final _teal = PdfColor.fromHex('#0F766E');
final _violet = PdfColor.fromHex('#6D28D9');
final _amber = PdfColor.fromHex('#B45309');
final _amberSoft = PdfColor.fromHex('#FFFBEB');
final _amberLine = PdfColor.fromHex('#B45309');

final _side = pw.BorderSide(color: _ink, width: 0.6);
final _rowLine = pw.BorderSide(color: _ink, width: 0.6);

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
    required this.ageSex,
    required this.collectionDate,
    required this.reportDate,
    required this.qrData,
    required this.generatedLabel,
    required this.entries,
  });

  final String patientName;
  final String ageSex;
  final String collectionDate;
  final String reportDate;
  final String qrData;
  final String generatedLabel;
  final List<_LabPdfEntry> entries;

  factory _LabReportFacts.build({
    required LabOrderPatient? patient,
    required List<_LabPdfEntry> entries,
    required String requisitionLabel,
    required DateTime generatedOn,
  }) {
    final org = OrgConfig.instance;
    final website = org.website.trim();
    final qrData = website.isEmpty
        ? requisitionLabel
        : '$website\n$requisitionLabel';
    return _LabReportFacts(
      patientName: _patientName(patient),
      ageSex: _ageSex(patient),
      collectionDate: _formatDates(
        entries.map((entry) => entry.item.sample?.collectionTime),
      ),
      reportDate: DateFormatter.dateTime(generatedOn),
      qrData: qrData,
      generatedLabel: DateFormatter.dateTime(generatedOn),
      entries: entries,
    );
  }
}

Future<pw.ImageProvider> _loadLabPdfLogo() async {
  final logoImageBytes = await rootBundle.load(OrgConfig.instance.logoAsset);
  return pw.MemoryImage(logoImageBytes.buffer.asUint8List());
}

String _labOrderShortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

String _patientName(LabOrderPatient? patient) {
  if (patient == null) return 'N/A';
  final name = patient.capitalizedDisplayName.trim().isNotEmpty
      ? patient.capitalizedDisplayName.trim()
      : patient.displayName.trim();
  if (name.isEmpty) return 'N/A';
  return name.toUpperCase();
}

String _formatDates(Iterable<DateTime?> dates) {
  final labels = <String>[];
  final seen = <String>{};
  for (final date in dates) {
    if (date == null) continue;
    final label = DateFormatter.dateTime(date);
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

List<LabAstResult> _sortedAstResults(LabOrderItem item) {
  final list = List<LabAstResult>.from(item.astResults)
    ..sort((a, b) {
      final position = a.antibiotic.position.compareTo(b.antibiotic.position);
      return position != 0
          ? position
          : a.antibiotic.name.compareTo(b.antibiotic.name);
    });
  return list;
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
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: _title,
                    ),
                  ),
                  if (address.isNotEmpty) ...[
                    pw.SizedBox(height: 3),
                    pw.Text(
                      address,
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: _ink,
                        lineSpacing: 1.3,
                      ),
                    ),
                  ],
                  if (contact.isNotEmpty) ...[
                    pw.SizedBox(height: 5),
                    pw.Text(
                      contact,
                      textAlign: pw.TextAlign.right,
                      style: pw.TextStyle(
                        fontSize: 9,
                        color: _contact,
                        fontWeight: pw.FontWeight.bold,
                      ),
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
  final fills = [_accent, _teal, _violet, _amber];
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
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
    ],
  );
}

pw.Widget _sectionRule() {
  return pw.Container(height: 0.6, color: _ink);
}

pw.Widget _compactField(String label, String value) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(
        label.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
      pw.SizedBox(height: 1),
      _wordWrapText(
        value,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
    ],
  );
}

pw.Widget _patientStrip(_LabReportFacts facts) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 6, bottom: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(flex: 3, child: _compactField('Name', facts.patientName)),
        pw.SizedBox(width: 10),
        pw.Expanded(flex: 2, child: _compactField('Age / Sex', facts.ageSex)),
        pw.SizedBox(width: 10),
        pw.Expanded(
          flex: 3,
          child: _compactField('Collection Date', facts.collectionDate),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          flex: 4,
          child: _compactField('Reporting Date & Time', facts.reportDate),
        ),
      ],
    ),
  );
}

pw.Widget _categoryBanner(String title, String? requisitionShortId) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 14),
    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: pw.BoxDecoration(
      color: _accent,
      borderRadius: const pw.BorderRadius.vertical(top: pw.Radius.circular(8)),
      border: pw.Border.all(color: _ink, width: 0.6),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
        if (requisitionShortId != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              'Requisition #$requisitionShortId',
              style: pw.TextStyle(
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
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
    child: pw.Text(
      message,
      style: pw.TextStyle(
        fontSize: 12,
        fontWeight: pw.FontWeight.bold,
        color: _ink,
        lineSpacing: 1.25,
      ),
    ),
  );
}

pw.TableBorder _tableBorder({required bool closeBottom}) {
  return pw.TableBorder(
    left: _side,
    right: _side,
    top: pw.BorderSide.none,
    bottom: closeBottom ? _side : pw.BorderSide.none,
    horizontalInside: _rowLine,
  );
}

pw.Widget _wordWrapText(
  String text, {
  pw.TextStyle? style,
  pw.TextAlign align = pw.TextAlign.left,
}) {
  final words = text
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList();
  final alignment = switch (align) {
    pw.TextAlign.right => pw.WrapAlignment.end,
    pw.TextAlign.center => pw.WrapAlignment.center,
    _ => pw.WrapAlignment.start,
  };
  if (words.isEmpty) {
    return pw.Text('', style: style, textAlign: align);
  }
  return pw.Wrap(
    alignment: alignment,
    spacing: 3,
    runSpacing: 1,
    children: [for (final word in words) pw.Text(word, style: style)],
  );
}

pw.Widget _paddedText(
  String text, {
  pw.TextStyle? style,
  pw.TextAlign align = pw.TextAlign.left,
}) {
  return pw.Padding(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    child: _wordWrapText(text, style: style, align: align),
  );
}

pw.TextStyle get _tableHeaderStyle => pw.TextStyle(
  fontSize: 11,
  fontWeight: pw.FontWeight.bold,
  color: PdfColors.white,
);

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
        decoration: pw.BoxDecoration(color: _teal),
        children: [
          _paddedText('TEST', style: _tableHeaderStyle),
          _paddedText('RESULT', style: _tableHeaderStyle),
          _paddedText(
            'REFERENCE',
            align: pw.TextAlign.right,
            style: _tableHeaderStyle,
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
  final outOfRange = flag != null;
  final resultColor = outOfRange ? _high : _ink;

  return pw.TableRow(
    decoration: outOfRange ? pw.BoxDecoration(color: _highBg) : null,
    children: [
      _paddedText(
        field?.label ?? result.fieldId,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: outOfRange ? _high : _inkStrong,
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Expanded(
              child: _wordWrapText(
                result.value,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: resultColor,
                ),
              ),
            ),
            if (flag != null) ...[
              pw.SizedBox(width: 4),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(3),
                  border: pw.Border.all(color: _high, width: 0.6),
                ),
                child: pw.Text(
                  flag,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                    color: resultColor,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      _paddedText(
        _referenceLine(field, eval),
        align: pw.TextAlign.right,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
    ],
  );
}

pw.Widget _scientistNotesPanel(String notes) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.fromLTRB(12, 8, 12, 10),
    decoration: pw.BoxDecoration(
      color: _amberSoft,
      border: pw.Border(
        left: pw.BorderSide(color: _amberLine, width: 0.6),
        right: pw.BorderSide(color: _amberLine, width: 0.6),
        bottom: pw.BorderSide(color: _amberLine, width: 0.6),
      ),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SCIENTIST NOTES',
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        pw.SizedBox(height: 3),
        _wordWrapText(
          notes,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
      ],
    ),
  );
}

List<pw.Widget> _astWidgets(LabOrderItem item, {required bool closeBottom}) {
  final results = _sortedAstResults(item);
  if (results.isEmpty) {
    return [_openPanel('AST pending', closeBottom: closeBottom)];
  }

  return [
    pw.Table(
      border: _tableBorder(closeBottom: closeBottom),
      columnWidths: const {0: pw.FlexColumnWidth(2), 1: pw.FlexColumnWidth(3)},
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _teal),
          children: [
            _paddedText('ANTIBIOTIC', style: _tableHeaderStyle),
            _paddedText(
              'RESULT',
              align: pw.TextAlign.right,
              style: _tableHeaderStyle,
            ),
          ],
        ),
        ...results.map((result) {
          final code = result.antibiotic.code?.trim();
          final name = code != null && code.isNotEmpty
              ? '${result.antibiotic.name} ($code)'
              : result.antibiotic.name;
          final optionCode = result.resultOption.code?.trim();
          final label = optionCode != null && optionCode.isNotEmpty
              ? '${result.resultOption.label} ($optionCode)'
              : result.resultOption.label;
          return pw.TableRow(
            children: [
              _paddedText(
                name,
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
              _paddedText(
                label,
                align: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 13,
                  fontWeight: pw.FontWeight.bold,
                  color: _ink,
                ),
              ),
            ],
          );
        }),
      ],
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
  final closeResults = !item.astRequested && !hasNotes;

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
    if (item.astRequested) ..._astWidgets(item, closeBottom: !hasNotes),
    if (hasNotes) _scientistNotesPanel(notes),
  ];
}

pw.Widget _signatureBlock(String title) {
  return pw.Expanded(
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          'Signature',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 46,
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: _ink, width: 0.6),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 0.6, color: _inkStrong),
        pw.SizedBox(height: 6),
        pw.Text(
          title,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: _inkStrong,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _signatureSection() {
  final showHod = !OrgConfig.instance.taglinesFromEnv;
  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 28),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _signatureBlock('Med Lab Scientist'),
        if (showHod) ...[
          pw.SizedBox(width: 28),
          _signatureBlock('HOD Med Lab'),
        ] else
          pw.Expanded(child: pw.SizedBox()),
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
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
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
      border: pw.Border(bottom: pw.BorderSide(color: _ink, width: 0.6)),
    ),
    child: pw.Text(
      facts.patientName,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: _inkStrong,
      ),
    ),
  );
}

pw.Widget _pageFooter(String generatedStr, pw.Context context) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 10),
    padding: const pw.EdgeInsets.only(top: 8),
    decoration: pw.BoxDecoration(
      border: pw.Border(top: pw.BorderSide(color: _ink, width: 0.6)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Text(
            'Confidential medical record - ${OrgConfig.instance.name}',
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount} | $generatedStr',
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
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
        _patientStrip(facts),
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
      generatedOn: DateTime.now(),
    ),
  );
}
