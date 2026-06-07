import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/hmo/hmo_tariff_csv_parser.dart';

void main() {
  group('parseHmoTariffCsv', () {
    test('parses header row with serviceCode and cost', () {
      const csv = '''serviceCode,cost
LAB-FBC,3500
RAD-XRAY,12000''';

      final result = parseHmoTariffCsv(csv);
      expect(result.rows.length, 2);
      expect(result.validRows.length, 2);

      expect(result.rows[0].serviceCode, 'LAB-FBC');
      expect(result.rows[0].cost, 3500);
      expect(result.rows[0].error, isNull);

      expect(result.rows[1].serviceCode, 'RAD-XRAY');
      expect(result.rows[1].cost, 12000);
    });

    test('parses serviceId alias columns', () {
      const csv = '''service_id,price
550e8400-e29b-41d4-a716-446655440000,4200''';

      final result = parseHmoTariffCsv(csv);
      expect(result.validRows.length, 1);
      expect(
        result.rows.first.serviceId,
        '550e8400-e29b-41d4-a716-446655440000',
      );
      expect(result.rows.first.cost, 4200);
    });

    test('parses quoted cells with commas', () {
      const csv = '''serviceCode,cost
"LAB, FBC","3,500.00"''';

      final result = parseHmoTariffCsv(csv);
      expect(result.validRows.length, 1);
      expect(result.rows.first.serviceCode, 'LAB, FBC');
      expect(result.rows.first.cost, 3500);
    });

    test('parses two-column file without header', () {
      const csv = '''LAB-FBC,3500
RAD-XRAY,8500''';

      final result = parseHmoTariffCsv(csv);
      expect(result.validRows.length, 2);
      expect(result.rows.first.serviceCode, 'LAB-FBC');
    });

    test('marks invalid UUID as error', () {
      const csv = '''serviceId,cost
not-a-uuid,1000''';

      final result = parseHmoTariffCsv(csv);
      expect(result.validRows, isEmpty);
      expect(result.rows.first.error, contains('UUID'));
    });

    test('marks missing cost as error', () {
      const csv = '''serviceCode,cost
LAB-FBC,''';

      final result = parseHmoTariffCsv(csv);
      expect(result.validRows, isEmpty);
      expect(result.rows.first.error, isNotNull);
    });
  });
}
