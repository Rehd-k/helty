import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/models/admission_billing_clearance_models.dart';

void main() {
  group('AdmissionBillingInvoiceSummary', () {
    test('parses coveredAmount from API payload', () {
      final invoice = AdmissionBillingInvoiceSummary.fromJson({
        'id': 'invoice-uuid',
        'invoiceNumber': 'ZS70S124BC',
        'status': 'PENDING',
        'totalAmount': '5000.00',
        'amountPaid': '0.00',
        'coveredAmount': '5000.00',
        'balance': '0.00',
      });

      expect(invoice.totalAmount, 5000);
      expect(invoice.amountPaid, 0);
      expect(invoice.coveredAmount, 5000);
      expect(invoice.balance, 0);
      expect(invoice.settlementLabel, 'Settled (coverage)');
    });

    test('settlementLabel for unpaid invoice', () {
      final invoice = AdmissionBillingInvoiceSummary.fromJson({
        'id': 'inv-1',
        'status': 'PENDING',
        'totalAmount': '100.00',
        'amountPaid': '0.00',
        'coveredAmount': '0.00',
        'balance': '100.00',
      });

      expect(invoice.settlementLabel, 'Unpaid');
    });

    test('settlementLabel for partial cash payment', () {
      final invoice = AdmissionBillingInvoiceSummary.fromJson({
        'id': 'inv-1',
        'status': 'PARTIALLY_PAID',
        'totalAmount': '100.00',
        'amountPaid': '40.00',
        'coveredAmount': '0.00',
        'balance': '60.00',
      });

      expect(invoice.settlementLabel, 'Partial');
    });

    test('settlementLabel for cash-paid invoice', () {
      final invoice = AdmissionBillingInvoiceSummary.fromJson({
        'id': 'inv-1',
        'status': 'PAID',
        'totalAmount': '100.00',
        'amountPaid': '100.00',
        'coveredAmount': '0.00',
        'balance': '0.00',
      });

      expect(invoice.settlementLabel, 'Paid (cash)');
    });

    test('settlementLabel for mixed cash and coverage settlement', () {
      final invoice = AdmissionBillingInvoiceSummary.fromJson({
        'id': 'inv-1',
        'status': 'PARTIALLY_PAID',
        'totalAmount': '100.00',
        'amountPaid': '40.00',
        'coveredAmount': '60.00',
        'balance': '0.00',
      });

      expect(invoice.settlementLabel, 'Settled');
    });

    test('defaults coveredAmount to zero when absent', () {
      final invoice = AdmissionBillingInvoiceSummary.fromJson({
        'id': 'inv-1',
        'status': 'PENDING',
        'totalAmount': '50.00',
        'amountPaid': '0.00',
        'balance': '50.00',
      });

      expect(invoice.coveredAmount, 0);
    });
  });

  group('AdmissionBillingSummary', () {
    test('aggregates totals and detects coverage', () {
      final summary = AdmissionBillingSummary.fromJson({
        'invoices': [
          {
            'id': 'inv-1',
            'invoiceNumber': 'INV-001',
            'status': 'PARTIALLY_PAID',
            'totalAmount': '100.00',
            'amountPaid': '40.00',
            'coveredAmount': '30.00',
            'balance': '30.00',
          },
          {
            'id': 'inv-2',
            'invoiceNumber': 'INV-002',
            'status': 'PENDING',
            'totalAmount': '200.00',
            'amountPaid': '0.00',
            'coveredAmount': '0.00',
            'balance': '200.00',
          },
        ],
        'totalBalance': '230.00',
        'allPaid': false,
      });

      expect(summary.totalAmount, 300);
      expect(summary.totalAmountPaid, 40);
      expect(summary.totalCoveredAmount, 30);
      expect(summary.hasCoverage, isTrue);
      expect(summary.clearanceStatusLabel, 'Partial payment');
    });

    test('clearanceStatusLabel when ready to clear', () {
      final summary = AdmissionBillingSummary.fromJson({
        'invoices': [
          {
            'id': 'inv-1',
            'invoiceNumber': 'INV-001',
            'status': 'PENDING',
            'totalAmount': '5000.00',
            'amountPaid': '0.00',
            'coveredAmount': '5000.00',
            'balance': '0.00',
          },
        ],
        'totalBalance': '0.00',
        'allPaid': true,
      });

      expect(summary.clearanceStatusLabel, 'Ready to clear');
      expect(summary.allPaid, isTrue);
    });
  });

  group('PendingBillingClearancePage', () {
    test('parses nested billing payload from doc example', () {
      final page = PendingBillingClearancePage.fromJson({
        'admissions': [
          {
            'id': 'admission-uuid',
            'dischargeDateTime': '2026-07-09T14:30:00.000Z',
            'outcome': 'Duly Discharged',
            'room': 'B-12',
            'wardEntity': {'id': 'ward-uuid', 'name': 'Medical Ward'},
            'attendingDoctor': {
              'id': 'doc-uuid',
              'firstName': 'Jane',
              'lastName': 'Doe',
              'staffId': 'DR001',
            },
            'patient': {
              'id': 'patient-uuid',
              'patientId': 'PAT12345',
              'firstName': 'Ada',
              'lastName': 'Okafor',
            },
            'billing': {
              'invoices': [
                {
                  'id': 'invoice-uuid',
                  'invoiceNumber': 'ZS70S124BC',
                  'status': 'PENDING',
                  'totalAmount': '5000.00',
                  'amountPaid': '0.00',
                  'coveredAmount': '5000.00',
                  'balance': '0.00',
                },
              ],
              'totalBalance': '0.00',
              'allPaid': true,
            },
          },
        ],
        'total': 1,
        'skip': 0,
        'take': 20,
      });

      expect(page.total, 1);
      expect(page.admissions, hasLength(1));

      final admission = page.admissions.first;
      expect(admission.invoiceNumbersDisplay, 'ZS70S124BC');
      expect(admission.hasCoverage, isTrue);
      expect(admission.billing.allPaid, isTrue);
      expect(admission.billing.invoices.first.coveredAmount, 5000);
    });
  });
}
