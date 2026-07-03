import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/pharmacy/models/pharmacy_refill_models.dart';

void main() {
  group('RefillRequestStatus', () {
    test('round-trips api values', () {
      for (final status in RefillRequestStatus.values) {
        expect(RefillRequestStatusX.fromApi(status.apiValue), status);
      }
    });

    test('defaults unknown values to pending', () {
      expect(RefillRequestStatusX.fromApi(null), RefillRequestStatus.pending);
      expect(
        RefillRequestStatusX.fromApi('SOMETHING_ELSE'),
        RefillRequestStatus.pending,
      );
    });
  });

  group('PrescriptionRefillRequest.fromJson', () {
    final sample = <String, dynamic>{
      'id': 'refill-uuid',
      'status': 'PENDING',
      'notes': 'Running low before trip',
      'createdAt': '2026-07-02T10:00:00.000Z',
      'patient': {
        'id': 'patient-uuid',
        'patientId': 'WB2YEP9K',
        'surname': 'Doe',
        'otherName': 'Jane',
      },
      'prescription': {
        'id': 'prescription-uuid',
        'drug': 'DIOVAN 160MG',
        'dosage': '160mg',
        'startDate': '2026-07-02T07:31:01.767Z',
        'endDate': '2026-07-09T07:31:01.767Z',
        'refillsAllowed': 2,
        'doctor': {'firstName': 'Amadi', 'lastName': 'Okafor'},
        'items': [
          {
            'id': 'item-uuid',
            'dosage': '160mg',
            'frequency': 'Twice daily (BD / BID)',
            'quantityDispensed': 14,
            'quantityPrescribed': 14,
            'instructions': 'After meals',
            'drug': {
              'id': 'drug-uuid',
              'brandName': 'DIOVAN 160MG',
              'genericName': 'Valsartan',
              'strength': '160mg',
            },
          },
        ],
      },
      'invoiceItem': null,
    };

    test('parses nested patient, prescription and items', () {
      final request = PrescriptionRefillRequest.fromJson(sample);

      expect(request.id, 'refill-uuid');
      expect(request.status, RefillRequestStatus.pending);
      expect(request.notes, 'Running low before trip');
      expect(request.patient?.patientId, 'WB2YEP9K');
      expect(request.patient?.displayName, 'Jane Doe');

      final prescription = request.prescription;
      expect(prescription?.refillsAllowed, 2);
      expect(prescription?.doctor?.displayName, 'Amadi Okafor');
      expect(prescription?.items, hasLength(1));

      final item = prescription?.firstItem;
      expect(item?.frequency, 'Twice daily (BD / BID)');
      expect(item?.drug?.displayName, 'Valsartan (DIOVAN 160MG)');
      expect(request.invoiceItem, isNull);
      expect(request.isBilled, isFalse);
    });

    test('exposes refillsRemaining and default bill quantity', () {
      final request = PrescriptionRefillRequest.fromJson(sample);
      expect(request.refillsRemaining, 2);
      expect(request.defaultBillQuantity, 14);
    });

    test('parses billed invoice item', () {
      final billed = Map<String, dynamic>.from(sample)
        ..['status'] = 'APPROVED'
        ..['invoiceItem'] = {
          'id': 'invoice-item-uuid',
          'invoiceId': 'invoice-uuid',
          'quantity': 14,
          'settled': false,
          'invoice': {'status': 'PENDING'},
        };

      final request = PrescriptionRefillRequest.fromJson(billed);
      expect(request.status, RefillRequestStatus.approved);
      expect(request.isBilled, isTrue);
      expect(request.invoiceItem?.invoiceId, 'invoice-uuid');
      expect(request.invoiceItem?.settled, isFalse);
      expect(request.invoiceItem?.invoiceStatus, 'PENDING');
    });
  });

  group('RefillBillResult.fromJson', () {
    test('parses invoice and invoice item', () {
      final result = RefillBillResult.fromJson({
        'refillRequest': {
          'id': 'refill-uuid',
          'status': 'APPROVED',
        },
        'invoice': {
          'id': 'invoice-uuid',
          'invoiceID': 'INV-2026-0042',
          'status': 'PENDING',
          'totalAmount': '35000.00',
        },
        'invoiceItem': {
          'id': 'invoice-item-uuid',
          'quantity': 14,
          'settled': false,
        },
      });

      expect(result.invoice.id, 'invoice-uuid');
      expect(result.invoice.invoiceDisplayId, 'INV-2026-0042');
      expect(result.invoice.totalAmount, 35000.0);
      expect(result.invoiceItem?.quantity, 14);
      expect(result.refillRequest?.status, RefillRequestStatus.approved);
    });
  });
}
