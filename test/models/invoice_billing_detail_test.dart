import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/billings/inpatient_charge_models.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/models/service_model.dart';

void main() {
  group('BillingInvoiceDetail.fromJson', () {
    test('parses HMO patient context and invoice totals', () {
      final detail = BillingInvoiceDetail.fromJson({
        'id': 'f6791efd-912a-489d-bd66-35f96e0f6058',
        'invoiceID': 'FRAW5XN6JC',
        'patientId': 'c5d10a53-ce5f-4c37-8314-da109802bc95',
        'status': 'PENDING',
        'totalAmount': {'s': 1, 'e': 3, 'd': [3648]},
        'amountPaid': {'s': 1, 'e': 0, 'd': [0]},
        'coveredAmount': {'s': 1, 'e': 0, 'd': [0]},
        'effectivePayable': {'s': 1, 'e': 3, 'd': [3648]},
        'amountDue': {'s': 1, 'e': 3, 'd': [3648]},
        'netAmountDue': '3648',
        'patient': {
          'id': 'c5d10a53-ce5f-4c37-8314-da109802bc95',
          'patientId': 'F1EPB7SB',
          'firstName': 'Ken',
          'surname': 'Chigozie',
          'hmoProvider': {
            'id': 'b413ccf4-2a71-409a-b9a7-e14b634871f1',
            'name': 'AxA',
            'defaultCoveragePercent': {'s': 1, 'e': 2, 'd': [100]},
          },
        },
        'invoiceItems': [],
        'payments': [],
        'coverages': [],
        'refunds': [],
      });

      expect(detail.invoiceDisplayId, 'FRAW5XN6JC');
      expect(detail.totalAmount, 3648);
      expect(detail.effectivePayable, 3648);
      expect(detail.netAmountDue, 3648);
      expect(detail.amountDue, 3648);
      expect(detail.patientHmoName, 'AxA');
      expect(detail.patientHmoDefaultCoveragePercent, 100);
    });
  });

  group('BillingInvoiceItem.fromJson', () {
    test('parses service line with createdBy and line financial fields', () {
      final item = BillingInvoiceItem.fromJson({
        'id': '02929eb9-8390-467b-92e1-330f9d5d2252',
        'serviceId': 'fa826387-8337-4a22-9642-c8ab4874f32e',
        'quantity': 1,
        'unitPrice': {'s': 1, 'e': 3, 'd': [1200]},
        'amountPaid': {'s': 1, 'e': 0, 'd': [0]},
        'lineTotal': {'s': 1, 'e': 3, 'd': [1200]},
        'lineCovered': {'s': 1, 'e': 0, 'd': [0]},
        'lineEffectiveDue': {'s': 1, 'e': 3, 'd': [1200]},
        'lineAmountDue': {'s': 1, 'e': 3, 'd': [1200]},
        'service': {
          'id': 'fa826387-8337-4a22-9642-c8ab4874f32e',
          'name': '1 VICRL',
          'category': {'name': 'General/Other Services'},
        },
        'createdBy': {
          'id': '813c427c-6356-49aa-8ff6-0c366dd35c58',
          'firstName': 'billing',
          'lastName': 'mine',
        },
        'createdAt': '2026-06-13T13:45:29.123Z',
        'usageSegments': [],
      });

      expect(item.displayLabel, '1 VICRL');
      expect(item.lineTotal, 1200);
      expect(item.lineAmountDue, 1200);
      expect(item.createdByName, 'billing mine');
      expect(item.createdAt, isNotNull);
      expect(item.isPurchaseItemLine, isFalse);
    });

    test('parses purchase line with nested purchaseItem', () {
      final item = BillingInvoiceItem.fromJson({
        'id': 'a8c55b93-887a-434a-86f1-be98aa721627',
        'purchaseItemId': '3331ecb3-a2d1-4051-b14a-390c0c33f3ce',
        'purchasesLocationId': 'a0269b80-b6d3-471d-9fb6-e874854d10de',
        'quantity': 2,
        'unitPrice': {'s': 1, 'e': 3, 'd': [1200]},
        'lineTotal': {'s': 1, 'e': 3, 'd': [2400]},
        'lineCovered': {'s': 1, 'e': 0, 'd': [0]},
        'lineEffectiveDue': {'s': 1, 'e': 3, 'd': [2400]},
        'lineAmountDue': {'s': 1, 'e': 3, 'd': [2400]},
        'purchaseItem': {
          'id': '3331ecb3-a2d1-4051-b14a-390c0c33f3ce',
          'itemName': 'Surgical Gloves',
        },
        'createdBy': {
          'firstName': 'doctor',
          'lastName': 'test',
        },
        'usageSegments': [],
      });

      expect(item.isPurchaseItemLine, isTrue);
      expect(item.displayLabel, 'Surgical Gloves');
      expect(item.purchaseItemId, '3331ecb3-a2d1-4051-b14a-390c0c33f3ce');
      expect(item.purchasesLocationId, 'a0269b80-b6d3-471d-9fb6-e874854d10de');
      expect(item.lineTotal, 2400);
      expect(item.createdByName, 'doctor test');
    });

    test('uses Purchase item fallback label when name is missing', () {
      final item = BillingInvoiceItem.fromJson({
        'id': 'line-1',
        'purchaseItemId': '3331ecb3-a2d1-4051-b14a-390c0c33f3ce',
        'purchasesLocationId': 'a0269b80-b6d3-471d-9fb6-e874854d10de',
        'quantity': 1,
        'unitPrice': 16,
        'usageSegments': [],
      });

      expect(item.displayLabel, 'Purchase item');
    });

    test('parses createdAtLocal for line display date', () {
      final item = BillingInvoiceItem.fromJson({
        'id': '8007b8d8-2532-4be0-b0b1-2d4f9889a2e0',
        'serviceId': 'cd6d0f54-1f83-4f34-915e-505aaea34507',
        'quantity': 1,
        'unitPrice': 12300,
        'createdAt': '2026-06-30T12:39:11.250Z',
        'createdAtLocal': '2026-06-30T13:39:11.250+01:00',
        'usageSegments': [],
      });

      expect(item.createdAtLocal, isNotNull);
      expect(item.createdAtLocal!.day, 30);
      expect(item.createdAtLocal!.month, 6);
      expect(item.createdAtLocal!.year, 2026);
    });
  });

  group('chargeCategoryForBillingItem', () {
    test('maps purchase lines to supplies', () {
      final item = BillingInvoiceItem.fromJson({
        'id': 'line-1',
        'purchaseItemId': '3331ecb3-a2d1-4051-b14a-390c0c33f3ce',
        'purchasesLocationId': 'a0269b80-b6d3-471d-9fb6-e874854d10de',
        'quantity': 1,
        'unitPrice': 16,
        'usageSegments': [],
      });

      expect(
        chargeCategoryForBillingItem(item),
        ChargeCategory.supplies,
      );
      expect(
        chargeCategoryLabel(ChargeCategory.supplies),
        'Supplies & Purchases',
      );
    });

    test('maps consumable lines to supplies', () {
      final item = BillingInvoiceItem.fromJson({
        'id': 'line-1',
        'consumableId': 'abc-123',
        'storeLocationId': 'loc-1',
        'quantity': 1,
        'unitPrice': 50,
        'usageSegments': [],
      });

      expect(
        chargeCategoryForBillingItem(item),
        ChargeCategory.supplies,
      );
    });
  });

  group('chargesFromBillingDetail', () {
    test('uses item createdAtLocal instead of invoice createdAt', () {
      final detail = BillingInvoiceDetail.fromJson({
        'id': '95d9ef62-1abe-46c4-87c1-261fd2d66509',
        'invoiceID': '283A77P938',
        'patientId': 'dc08bc32-24ed-42a0-b4a7-6062ec40e2b3',
        'status': 'PENDING',
        'totalAmount': 12405,
        'amountPaid': 0,
        'createdAt': '2026-06-21T23:22:53.534Z',
        'invoiceItems': [
          {
            'id': 'traction-line',
            'serviceId': 'cd6d0f54-1f83-4f34-915e-505aaea34507',
            'quantity': 1,
            'unitPrice': 12300,
            'lineTotal': 12300,
            'amountPaid': 0,
            'lineAmountDue': 12300,
            'createdAt': '2026-06-30T12:39:11.250Z',
            'createdAtLocal': '2026-06-30T13:39:11.250+01:00',
            'service': {'name': 'BED SIDE TRACTION'},
            'usageSegments': [],
          },
          {
            'id': 'drug-line',
            'drugId': '00885d23-c2f0-487f-819a-b186b77a0c8b',
            'quantity': 1,
            'unitPrice': 105,
            'lineTotal': 105,
            'amountPaid': 0,
            'lineAmountDue': 105,
            'createdAt': '2026-06-21T23:22:53.689Z',
            'createdAtLocal': '2026-06-22T00:22:53.689+01:00',
            'drug': {'genericName': 'PYRIDOSTIGMINE 60 MG TABS'},
            'usageSegments': [],
          },
        ],
        'payments': [],
        'coverages': [],
        'refunds': [],
      });

      final charges = chargesFromBillingDetail(detail);

      expect(charges.length, 2);
      expect(charges[0].date.day, 30);
      expect(charges[0].date.month, 6);
      expect(charges[1].date.day, 22);
      expect(charges[1].date.month, 6);
    });
  });

  group('chargeSectionTotals', () {
    test('sums displayLineTotal, amountPaid, and lineAmountDue', () {
      final items = [
        ChargeItem(
          id: 'a',
          invoiceLineItemId: 'line-a',
          description: 'A',
          amount: 100,
          date: DateTime(2026, 6, 1),
          category: ChargeCategory.other,
          lineTotal: 1000,
          amountPaid: 200,
          lineAmountDue: 800,
        ),
        ChargeItem(
          id: 'b',
          invoiceLineItemId: 'line-b',
          description: 'B',
          amount: 50,
          date: DateTime(2026, 6, 2),
          category: ChargeCategory.pharmacy,
          lineTotal: 500,
          amountPaid: 100,
          lineAmountDue: 400,
        ),
      ];

      expect(chargeSectionTotal(items), 1500);
      expect(chargeSectionPaid(items), 300);
      expect(chargeSectionDue(items), 1200);
    });
  });

  group('ServiceModel displayLineTotal', () {
    test('prefers server lineTotal over cost x qty', () {
      final model = ServiceModel(
        id: 'line-1',
        name: 'Surgical Gloves',
        serviceId: '3331ecb3-a2d1-4051-b14a-390c0c33f3ce',
        cost: 1200,
        qty: 2,
        lineTotal: 2400,
      );

      expect(model.displayLineTotal, 2400);
    });
  });
}
