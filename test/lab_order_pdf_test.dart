import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/app/org_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/printing/pdf/lab_order_pdf.dart';
import 'package:pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AppTimezone.initialize();
    OrgConfig.debugSet(OrgConfig.defaults());
  });
  tearDown(OrgConfig.debugReset);

  test('builds printable lab report pdfs from order data', () async {
    final patient = LabOrderPatient(
      id: 'p1',
      firstName: 'Akanimo',
      surname: 'Udonkang',
      patientId: 'PT-100',
      gender: 'MALE',
      dob: DateTime.utc(1981, 1, 1),
    );
    final doctor = LabOrderStaff(
      id: 'd1',
      firstName: 'Ada',
      lastName: 'Okoro',
      accountType: AccountType.physician,
    );
    final renal = _item(
      id: 'i1',
      orderId: '230181703abcdef',
      name: 'RENAL FUNCTION TEST',
      barcode: '230181703',
      astRequested: true,
      scientistNotes: 'Slight hemolysis. Interpret creatinine with caution.',
      results: const [
        _Result('f1', '4.5', inRange: true),
        _Result('f2', '980', inRange: false, flag: ReferenceFlag.high),
        _Result('f3', '131', inRange: false, flag: ReferenceFlag.low),
        _Result('f1', '9', hidden: true),
      ],
    );
    final empty = LabOrderItem(
      id: 'i2',
      orderId: '230181703abcdef',
      testVersion: const LabOrderItemTestVersion(
        id: 'tv2',
        test: LabOrderItemTest(id: 't2', name: 'LIVER FUNCTION TESTS'),
      ),
    );
    final order = LabOrder(
      id: '230181703abcdef',
      status: LabOrderStatus.verified,
      createdAt: DateTime.utc(2026, 7, 7, 15, 34),
      patient: patient,
      doctor: doctor,
      items: [renal, empty],
    );
    final other = LabOrder(
      id: '99887766zzzz',
      status: LabOrderStatus.completed,
      createdAt: DateTime.utc(2026, 7, 8, 9, 5),
      patient: patient,
      items: [
        _item(
          id: 'i3',
          orderId: '99887766zzzz',
          name: 'BIOCHEMISTRY URINE',
          barcode: '99887766',
          results: const [_Result('f1', '1.2', inRange: true)],
        ),
      ],
    );

    final bytes = await buildLabOrderPdf(order, PdfPageFormat.a4);
    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');

    final combined = await buildLabPatientItemsPdf(
      patient: patient,
      entries: [
        (order: order, item: renal),
        (order: order, item: empty),
        (order: other, item: other.items.first),
      ],
      format: PdfPageFormat.a4,
    );
    expect(String.fromCharCodes(combined.take(5)), '%PDF-');

    final none = await buildLabPatientItemsPdf(
      patient: patient,
      entries: [(order: order, item: empty)],
      format: PdfPageFormat.a4,
    );
    expect(none, isEmpty);
  });

  test('clean clinical keeps the letterhead layout', () async {
    SharedPreferences.setMockInitialValues({
      'pdf_report_template_id': 'cleanClinical',
    });
    final patient = LabOrderPatient(
      id: 'p2',
      firstName: 'Ada',
      surname: 'Okoro',
      gender: 'FEMALE',
    );
    final item = _item(
      id: 'i9',
      orderId: 'order-9',
      name: 'LIVER FUNCTION TESTS',
      barcode: '100200',
      scientistNotes: 'Repeat if symptomatic.',
      results: const [_Result('f1', '4.5', inRange: true)],
    );
    final order = LabOrder(
      id: 'order-9',
      status: LabOrderStatus.completed,
      createdAt: DateTime.utc(2026, 7, 8, 9),
      patient: patient,
      items: [item],
    );

    final bytes = await buildLabOrderPdf(order, PdfPageFormat.a4);
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
  });
}

class _Result {
  const _Result(
    this.fieldId,
    this.value, {
    this.inRange,
    this.flag,
    this.hidden = false,
  });

  final String fieldId;
  final String value;
  final bool? inRange;
  final ReferenceFlag? flag;
  final bool hidden;
}

LabOrderItem _item({
  required String id,
  required String orderId,
  required String name,
  required String barcode,
  required List<_Result> results,
  bool astRequested = false,
  String? scientistNotes,
}) {
  return LabOrderItem(
    id: id,
    orderId: orderId,
    astRequested: astRequested,
    scientistNotes: scientistNotes,
    astResults: astRequested
        ? [
            LabAstResult(
              id: 'ast1',
              orderItemId: id,
              antibiotic: const LabAntibiotic(
                id: 'ab1',
                name: 'Ciprofloxacin',
                code: 'CIP',
              ),
              resultOption: const LabAstResultOption(
                id: 'opt1',
                label: 'Sensitive',
                code: 'S',
              ),
            ),
          ]
        : const [],
    testVersion: LabOrderItemTestVersion(
      id: 'tv-$id',
      test: LabOrderItemTest(id: 't-$id', name: name),
      fields: const [
        LabTestField(
          id: 'f1',
          testVersionId: 'tv',
          label: 'SERUM UREA',
          fieldType: LabFieldType.number,
          unit: 'mmol/L',
          referenceRange: '2.5 - 6.4',
        ),
        LabTestField(
          id: 'f2',
          testVersionId: 'tv',
          label: 'CREATININE SERUM',
          fieldType: LabFieldType.number,
          unit: 'umol/L',
          referenceRange: '57 - 113',
        ),
        LabTestField(
          id: 'f3',
          testVersionId: 'tv',
          label: 'SODIUM SERUM',
          fieldType: LabFieldType.number,
          unit: 'mmol/L',
          referenceRange: '135 - 145',
        ),
      ],
    ),
    sample: LabSample(
      id: 's-$id',
      orderItemId: id,
      sampleType: 'Serum',
      collectedBy: 'staff',
      collectionTime: DateTime.utc(2026, 7, 7, 15, 30),
      barcode: barcode,
    ),
    results: [
      for (final result in results)
        LabResult(
          id: 'r-${result.fieldId}-${result.value}',
          orderItemId: id,
          fieldId: result.fieldId,
          value: result.value,
          hiddenFromReport: result.hidden,
          referenceEvaluation: result.inRange == null
              ? null
              : ReferenceEvaluation(
                  inRange: result.inRange,
                  flag: result.flag,
                  referenceRange: '2.5 - 6.4',
                ),
        ),
    ],
  );
}
