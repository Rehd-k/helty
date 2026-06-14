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
