import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/models/consultation_credit_utils.dart';

void main() {
  group('deriveConsultationLineFromInvoiceItem', () {
    test('consumable when visits remain and not expired', () {
      final future = DateTime.now().add(const Duration(days: 10));
      final derived = deriveConsultationLineFromInvoiceItem(
        {
          'name': 'General Consultation',
          'consultationVisitsConsumed': 0,
          'consultationCreditExpiresAt': future.toIso8601String(),
          'settled': false,
        },
        now: DateTime.now(),
      );

      expect(derived, isNotNull);
      expect(derived!.visitsRemaining, 2);
      expect(derived.consumable, isTrue);
      expect(derived.expired, isFalse);
    });

    test('not consumable when expired', () {
      final past = DateTime.now().subtract(const Duration(days: 1));
      final derived = deriveConsultationLineFromInvoiceItem(
        {
          'name': 'General Consultation',
          'consultationVisitsConsumed': 0,
          'consultationCreditExpiresAt': past.toIso8601String(),
        },
        now: DateTime.now(),
      );

      expect(derived!.expired, isTrue);
      expect(derived.consumable, isFalse);
    });

    test('not consumable when settled', () {
      final future = DateTime.now().add(const Duration(days: 5));
      final derived = deriveConsultationLineFromInvoiceItem(
        {
          'name': 'General Consultation',
          'consultationVisitsConsumed': 2,
          'consultationCreditExpiresAt': future.toIso8601String(),
          'settled': true,
        },
        now: DateTime.now(),
      );

      expect(derived!.settled, isTrue);
      expect(derived.visitsRemaining, 0);
      expect(derived.consumable, isFalse);
    });

    test('not consumable when invoice has active encounter', () {
      final future = DateTime.now().add(const Duration(days: 5));
      final derived = deriveConsultationLineFromInvoiceItem(
        {
          'name': 'General Consultation',
          'consultationVisitsConsumed': 0,
          'consultationCreditExpiresAt': future.toIso8601String(),
        },
        encounterId: 'enc-1',
        now: DateTime.now(),
      );

      expect(derived!.consumable, isFalse);
    });
  });

  group('mapOutpatientStartError', () {
    test('maps known backend messages', () {
      expect(
        mapOutpatientStartError(
          'No paid consultation invoice is on file for this patient.',
        ),
        contains('billing'),
      );
      expect(
        mapOutpatientStartError(
          'The consultation payment has expired (valid for 14 days after payment).',
        ),
        contains('expired'),
      );
    });

    test('passes through unknown messages', () {
      expect(mapOutpatientStartError('Custom error'), 'Custom error');
    });
  });

  group('primaryConsultationLineFromInvoice', () {
    test('returns first consumable line in item order', () {
      final future = DateTime.now().add(const Duration(days: 7));
      final line = primaryConsultationLineFromInvoice({
        'status': 'PAID',
        'encounterId': null,
        'invoiceItems': [
          {
            'name': 'Used up',
            'consultationVisitsConsumed': 2,
            'consultationCreditExpiresAt': future.toIso8601String(),
            'settled': true,
          },
          {
            'name': 'Return visit',
            'consultationVisitsConsumed': 1,
            'consultationCreditExpiresAt': future.toIso8601String(),
            'settled': false,
          },
        ],
      });

      expect(line?.name, 'Return visit');
      expect(line?.consumable, isTrue);
      expect(line?.visitsRemaining, 1);
    });
  });
}
