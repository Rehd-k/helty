import 'package:flutter/services.dart' show rootBundle;
import 'package:helty/src/app/org_config.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/utils/lab_reference_evaluation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

final _ink = PdfColor.fromHex('#334155');
final _inkStrong = PdfColor.fromHex('#0F172A');
final _title = PdfColor.fromHex('#1E293B');
final _muted = PdfColor.fromHex('#64748B');
final _label = PdfColor.fromHex('#94A3B8');
final _line = PdfColor.fromHex('#E2E8F0');
final _bannerFill = PdfColor.fromHex('#EFF6FF');
final _bannerBorder = PdfColor.fromHex('#DBEAFE');
final _contact = PdfColor.fromHex('#1D4ED8');
final _cardFill = PdfColor.fromHex('#F8FAFC');
final _high = PdfColor.fromHex('#DC2626');
final _highBg = PdfColor.fromHex('#FEE2E2');
final _accent = PdfColor.fromHex('#1D4ED8');
final _accentSoft = PdfColor.fromHex('#DBEAFE');
final _teal = PdfColor.fromHex('#0F766E');
final _tealSoft = PdfColor.fromHex('#CCFBF1');
final _violet = PdfColor.fromHex('#6D28D9');
final _violetSoft = PdfColor.fromHex('#EDE9FE');
final _amber = PdfColor.fromHex('#B45309');
final _amberSoft = PdfColor.fromHex('#FFFBEB');
final _amberLine = PdfColor.fromHex('#FCD34D');

final _side = pw.BorderSide(color: _line, width: 0.7);
final _hairlineSide = pw.BorderSide(color: _line, width: 0.4);

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
    required this.requestDate,
    required this.barcode,
    required this.ageSex,
    required this.accessionDate,
    required this.collectionDate,
    required this.reportDate,
    required this.referredBy,
    required this.patientId,
    required this.qrData,
    required this.generatedLabel,
    required this.entries,
  });

  final String patientName;
  final String requisitionLabel;
  final String requestDate;
  final String barcode;
  final String ageSex;
  final String accessionDate;
  final String collectionDate;
  final String reportDate;
  final String? referredBy;
  final String? patientId;
  final String qrData;
  final String generatedLabel;
  final List<_LabPdfEntry> entries;

  factory _LabReportFacts.build({
    required LabOrderPatient? patient,
    required List<LabOrder> orders,
    required List<_LabPdfEntry> entries,
    required String requisitionLabel,
    required DateTime generatedOn,
  }) {
    final org = OrgConfig.instance;
    final website = org.website.trim();
    final qrData = website.isEmpty
        ? requisitionLabel
        : '$website\n$requisitionLabel';
    final patientId = patient?.patientId?.trim();
    return _LabReportFacts(
      patientName: _patientName(patient),
      requisitionLabel: requisitionLabel,
      requestDate: _formatDates(orders.map((order) => order.createdAt)),
      barcode: _barcodeLabel(entries.map((entry) => entry.item)),
      ageSex: _ageSex(patient),
      accessionDate: _formatDates(orders.map((order) => order.createdAt)),
      collectionDate: _formatDates(
        entries.map((entry) => entry.item.sample?.collectionTime),
      ),
      reportDate: DateFormatter.dateTime24(generatedOn),
      referredBy: _referredBy(orders.map((order) => order.doctor)),
      patientId: patientId == null || patientId.isEmpty ? null : patientId,
      qrData: qrData,
      generatedLabel: DateFormatter.dateTime24(generatedOn),
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

String _barcodeLabel(Iterable<LabOrderItem> items) {
  final labels = <String>[];
  final seen = <String>{};
  for (final item in items) {
    final code = item.sample?.barcode?.trim();
    if (code == null || code.isEmpty) continue;
    if (seen.add(code)) labels.add(code);
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

String? _referredBy(Iterable<LabOrderStaff?> doctors) {
  final names = <String>[];
  final seen = <String>{};
  for (final doctor in doctors) {
    if (doctor == null || !doctor.isPhysician) continue;
    final name = doctor.capitalizedDisplayName.trim().isNotEmpty
        ? doctor.capitalizedDisplayName.trim()
        : doctor.displayName.trim();
    if (name.isEmpty || !seen.add(name)) continue;
    names.add(name);
  }
  if (names.isEmpty) return null;
  return names.join(', ');
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
                      fontSize: 13,
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
                        fontSize: 8,
                        color: _muted,
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
                        fontSize: 8,
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
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: inks[i % inks.length],
            ),
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
      pw.Text(
        label.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 7,
          fontWeight: pw.FontWeight.bold,
          color: _label,
          letterSpacing: 0.4,
        ),
      ),
      pw.SizedBox(height: 2),
      pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
        ),
      ),
    ],
  );
}

pw.Widget _requisitionBanner(_LabReportFacts facts) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(top: 14, bottom: 4),
    padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: pw.BoxDecoration(
      color: _bannerFill,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: _bannerBorder, width: 0.8),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _labeledValue('Requisition Number', facts.requisitionLabel),
        ),
        pw.SizedBox(width: 16),
        pw.Expanded(child: _labeledValue('Request Date', facts.requestDate)),
      ],
    ),
  );
}

pw.Widget _infoPair(
  String leftLabel,
  String leftValue,
  String rightLabel,
  String rightValue,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 10),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _labeledValue(leftLabel, leftValue)),
        pw.SizedBox(width: 18),
        pw.Expanded(child: _labeledValue(rightLabel, rightValue)),
      ],
    ),
  );
}

pw.Widget _patientGrid(_LabReportFacts facts) {
  final extra = <pw.Widget>[];
  if (facts.referredBy != null && facts.patientId != null) {
    extra.add(
      _infoPair(
        'Referred By',
        facts.referredBy!,
        'Patient ID',
        facts.patientId!,
      ),
    );
  } else if (facts.referredBy != null || facts.patientId != null) {
    extra.add(
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 10),
        child: _labeledValue(
          facts.referredBy == null ? 'Patient ID' : 'Referred By',
          facts.referredBy ?? facts.patientId!,
        ),
      ),
    );
  }

  return pw.Padding(
    padding: const pw.EdgeInsets.only(top: 12),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        _infoPair(
          'Patient Name',
          facts.patientName,
          'Barcode Number',
          facts.barcode,
        ),
        _infoPair(
          'Age / Sex',
          facts.ageSex,
          'Accession Date & Time',
          facts.accessionDate,
        ),
        _infoPair(
          'Collection Date',
          facts.collectionDate,
          'Report Date & Time',
          facts.reportDate,
        ),
        ...extra,
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
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 10.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1E3A8A'),
                ),
              ),
            ),
          ],
        ),
        if (requisitionShortId != null)
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 2),
            child: pw.Text(
              'Requisition #$requisitionShortId',
              style: pw.TextStyle(fontSize: 7.5, color: _muted),
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
        fontSize: 8.5,
        color: _muted,
        fontStyle: pw.FontStyle.italic,
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
      0: pw.FlexColumnWidth(3),
      1: pw.FlexColumnWidth(1),
      2: pw.FlexColumnWidth(2),
    },
    children: [
      pw.TableRow(
        decoration: pw.BoxDecoration(color: _tealSoft),
        children: [
          _paddedText(
            'TEST',
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: _teal,
              letterSpacing: 0.5,
            ),
          ),
          _paddedText(
            'RESULT',
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: _teal,
              letterSpacing: 0.5,
            ),
          ),
          _paddedText(
            'REFERENCE',
            align: pw.TextAlign.right,
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: _teal,
              letterSpacing: 0.5,
            ),
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
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: outOfRange ? _high : _inkStrong,
        ),
      ),
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Flexible(
              child: pw.Text(
                result.value,
                style: pw.TextStyle(
                  fontSize: 9.5,
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
                    fontSize: 7,
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
        style: pw.TextStyle(fontSize: 8, color: _muted),
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
        left: pw.BorderSide(color: _amberLine, width: 0.8),
        right: pw.BorderSide(color: _amberLine, width: 0.8),
        bottom: pw.BorderSide(color: _amberLine, width: 0.8),
      ),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'SCIENTIST NOTES',
          style: pw.TextStyle(
            fontSize: 7,
            fontWeight: pw.FontWeight.bold,
            color: _amber,
            letterSpacing: 0.5,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          notes,
          style: pw.TextStyle(fontSize: 9, color: _ink, lineSpacing: 1.3),
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
      columnWidths: const {0: pw.FlexColumnWidth(3), 1: pw.FlexColumnWidth(2)},
      children: [
        pw.TableRow(
          decoration: pw.BoxDecoration(color: _cardFill),
          children: [
            _paddedText(
              'ANTIBIOTIC',
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: _muted,
                letterSpacing: 0.4,
              ),
            ),
            _paddedText(
              'RESULT',
              align: pw.TextAlign.right,
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: _muted,
                letterSpacing: 0.4,
              ),
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
                style: const pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.grey900,
                ),
              ),
              _paddedText(
                label,
                align: pw.TextAlign.right,
                style: pw.TextStyle(
                  fontSize: 9,
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
          style: pw.TextStyle(fontSize: 7.5, color: _muted, letterSpacing: 0.4),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          height: 46,
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: _line, width: 0.7),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(height: 1, color: _inkStrong),
        pw.SizedBox(height: 6),
        pw.Text(
          title,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _inkStrong,
          ),
        ),
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
          style: pw.TextStyle(
            fontSize: 10,
            color: _muted,
            fontStyle: pw.FontStyle.italic,
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
      border: pw.Border(bottom: pw.BorderSide(color: _line, width: 0.6)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Text(
            facts.patientName,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _inkStrong,
            ),
          ),
        ),
        pw.SizedBox(width: 12),
        pw.Text(
          facts.requisitionLabel,
          style: pw.TextStyle(fontSize: 8, color: _muted),
        ),
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
            style: pw.TextStyle(fontSize: 7, color: _muted),
          ),
        ),
        pw.Text(
          'Page ${context.pageNumber} of ${context.pagesCount} | $generatedStr',
          style: pw.TextStyle(fontSize: 7.5, color: _muted),
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
        _requisitionBanner(facts),
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
      orders: [order],
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

  final orders = <LabOrder>[];
  final seenOrderIds = <String>{};
  final requisitionLabels = <String>[];
  for (final entry in printable) {
    if (!seenOrderIds.add(entry.order.id)) continue;
    orders.add(entry.order);
    requisitionLabels.add('#${_labOrderShortId(entry.order.id)}');
  }
  final showOrderRef = seenOrderIds.length > 1;

  return _saveLabReportPdf(
    format: format,
    facts: _LabReportFacts.build(
      patient: patient,
      orders: orders,
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
