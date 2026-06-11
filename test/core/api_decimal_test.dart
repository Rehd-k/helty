import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/core/utils/api_decimal.dart';

void main() {
  group('parseApiDecimal', () {
    test('parses plain num and String', () {
      expect(parseApiDecimal(15850), 15850);
      expect(parseApiDecimal(10.5), 10.5);
      expect(parseApiDecimal('9100'), 9100);
      expect(parseApiDecimal('12.75'), 12.75);
    });

    test('parses Prisma decimal.js objects from payments payload', () {
      expect(parseApiDecimal({'s': 1, 'e': 4, 'd': [15850]}), 15850);
      expect(parseApiDecimal({'s': 1, 'e': 3, 'd': [9100]}), 9100);
      expect(parseApiDecimal({'s': 1, 'e': 3, 'd': [2500]}), 2500);
      expect(parseApiDecimal({'s': 1, 'e': 1, 'd': [75]}), 75);
      expect(parseApiDecimal({'s': 1, 'e': 3, 'd': [1050]}), 1050);
      expect(parseApiDecimal({'s': 1, 'e': 3, 'd': [2000]}), 2000);
      expect(parseApiDecimal({'s': 1, 'e': 3, 'd': [1200]}), 1200);
    });

    test('line items sum matches payment amount', () {
      final linePaid = [
        {'s': 1, 'e': 3, 'd': [9100]},
        {'s': 1, 'e': 3, 'd': [2500]},
        {'s': 1, 'e': 3, 'd': [1050]},
        {'s': 1, 'e': 3, 'd': [2000]},
        {'s': 1, 'e': 3, 'd': [1200]},
      ].map(parseApiDecimal).fold<double>(0, (a, b) => a + b);

      expect(linePaid, 15850);
      expect(parseApiDecimal({'s': 1, 'e': 4, 'd': [15850]}), linePaid);
    });

    test('parses negative sign', () {
      expect(parseApiDecimal({'s': -1, 'e': 3, 'd': [2500]}), -2500);
    });

    test('parses fractional decimal.js values', () {
      expect(parseApiDecimal({'s': 1, 'e': 1, 'd': [1050]}), 10.50);
    });

    test('returns fallback for null and unknown shapes', () {
      expect(parseApiDecimal(null), 0);
      expect(parseApiDecimal(null, fallback: 99), 99);
      expect(parseApiDecimal({'foo': 'bar'}), 0);
      expect(parseApiDecimal({'s': 1, 'e': 1}), 0);
    });
  });

  group('tryParseApiDecimal', () {
    test('returns null for null and unknown shapes', () {
      expect(tryParseApiDecimal(null), isNull);
      expect(tryParseApiDecimal({'foo': 'bar'}), isNull);
    });

    test('parses decimal.js objects', () {
      expect(tryParseApiDecimal({'s': 1, 'e': 3, 'd': [9100]}), 9100);
    });
  });

  group('isDecimalJsMap', () {
    test('detects Prisma decimal shape', () {
      expect(isDecimalJsMap({'s': 1, 'e': 4, 'd': [15850]}), isTrue);
      expect(isDecimalJsMap({'id': 'x', 'name': 'test'}), isFalse);
      expect(isDecimalJsMap({'s': 1, 'e': 1}), isFalse);
    });
  });

  group('normalizeApiDecimals', () {
    test('normalizes nested payments payload', () {
      final input = {
        'payments': [
          {
            'id': 'pay-1',
            'amount': {'s': 1, 'e': 4, 'd': [15850]},
            'invoice': {
              'invoiceID': 'HOJ2OSPJGJ',
              'invoiceItems': [
                {
                  'unitPrice': {'s': 1, 'e': 3, 'd': [9100]},
                  'amountPaid': {'s': 1, 'e': 3, 'd': [9100]},
                },
                {
                  'unitPrice': {'s': 1, 'e': 3, 'd': [2500]},
                  'amountPaid': {'s': 1, 'e': 3, 'd': [2500]},
                },
              ],
            },
          },
        ],
        'staffSummary': [
          {
            'paymentCount': 1,
            'totalAmount': {'s': 1, 'e': 4, 'd': [15850]},
          },
        ],
      };

      final normalized = normalizeApiDecimals(input) as Map;

      final payment = (normalized['payments'] as List).first as Map;
      expect(payment['amount'], 15850.0);
      expect(payment['id'], 'pay-1');

      final items =
          ((payment['invoice'] as Map)['invoiceItems'] as List).cast<Map>();
      expect(items[0]['unitPrice'], 9100.0);
      expect(items[0]['amountPaid'], 9100.0);
      expect(items[1]['unitPrice'], 2500.0);

      final summary = (normalized['staffSummary'] as List).first as Map;
      expect(summary['totalAmount'], 15850.0);
      expect(summary['paymentCount'], 1);
    });

    test('leaves non-decimal maps unchanged', () {
      final input = {
        'patient': {'firstName': 'Victor', 'surname': 'Mathew'},
        'status': 'PAID',
      };

      expect(normalizeApiDecimals(input), input);
    });

    test('normalizes mixed lists', () {
      final input = [
        {'s': 1, 'e': 1, 'd': [75]},
        'text',
        42,
        {'keep': true},
      ];

      final normalized = normalizeApiDecimals(input) as List;
      expect(normalized[0], 75.0);
      expect(normalized[1], 'text');
      expect(normalized[2], 42);
      expect(normalized[3], {'keep': true});
    });
  });
}
