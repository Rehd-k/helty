import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/models/receivables_models.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppTimezone.initialize();
  });

  group('ReceivableItem.fromJson', () {
    test('parses nested hmo, coverage value, patient, and invoice', () {
      final item = ReceivableItem.fromJson({
        'id': 'f85a3b11-1ac1-4749-aeba-87111c7becc3',
        'invoiceId': 'e2e5862f-e562-4623-8ec5-9e24e1600ec5',
        'scope': 'INVOICE',
        'kind': 'HMO',
        'hmoId': 'b413ccf4-2a71-409a-b9a7-e14b634871f1',
        'mode': 'PERCENT',
        'value': {'s': 1, 'e': 2, 'd': [100]},
        'amount': {'s': 1, 'e': 3, 'd': [3182]},
        'status': 'APPLIED',
        'createdAt': '2026-06-30T11:40:35.012Z',
        'hmo': {
          'id': 'b413ccf4-2a71-409a-b9a7-e14b634871f1',
          'name': 'AxA',
        },
        'invoice': {
          'id': 'e2e5862f-e562-4623-8ec5-9e24e1600ec5',
          'invoiceID': 'S3DNYF5S2R',
          'status': 'PAID',
          'createdAt': '2026-06-30T11:37:42.511Z',
          'patient': {
            'id': 'c5d10a53-ce5f-4c37-8314-da109802bc95',
            'patientId': 'F1EPB7SB',
            'firstName': 'Ken',
            'otherName': 'Names',
            'surname': 'Chigozie',
          },
          'invoiceItems': [
            {
              'id': '2a644296-12a9-4768-a58c-4bad16deb355',
              'quantity': 2,
              'unitPrice': {'s': 1, 'e': 1, 'd': [16]},
              'purchaseItem': {'itemName': 'Pregnancy Stip'},
            },
            {
              'id': 'a6f76520-375b-43b8-9331-d1e5b278e521',
              'quantity': 2,
              'unitPrice': {'s': 1, 'e': 2, 'd': [825]},
              'purchaseItem': {'itemName': 'Crepe Bandage 10 inch'},
            },
          ],
        },
      });

      expect(item.coverageId, 'f85a3b11-1ac1-4749-aeba-87111c7becc3');
      expect(item.payerName, 'AxA');
      expect(item.payerId, 'b413ccf4-2a71-409a-b9a7-e14b634871f1');
      expect(item.coverageValue, 100);
      expect(item.coverageLabel, '100%');
      expect(item.scope, 'INVOICE');
      expect(item.status, 'APPLIED');
      expect(item.amount, 3182);
      expect(item.outstandingAmount, 3182);
      expect(item.invoiceHumanId, 'S3DNYF5S2R');
      expect(item.invoiceStatus, 'PAID');
      expect(item.patientPublicId, 'F1EPB7SB');
      expect(item.patientDisplayName, 'Ken Names Chigozie');
      expect(item.remittanceSummaryLine, contains('AxA'));
      expect(item.invoiceLines, hasLength(2));
      expect(item.invoiceLines.first.displayName, 'Pregnancy Stip');
      expect(item.invoiceLines.first.quantity, 2);
      expect(item.invoiceLines.first.unitPrice, 16);
      expect(item.invoiceLines.first.lineTotal, 32);
      expect(item.invoiceLinesTotal, 32 + 1650);
    });

    test('coverageLabel formats fixed mode', () {
      final item = ReceivableItem.fromJson({
        'id': 'cov-1',
        'mode': 'FIXED',
        'value': 2500,
        'amount': 2500,
      });

      expect(item.coverageValue, 2500);
      expect(item.coverageLabel, 'Fixed 2500.0');
    });
  });
}
