import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/models/hmo_models.dart';

void main() {
  group('HmoServicePriceRow', () {
    test('fromJson reads cost as fullCost alias', () {
      final row = HmoServicePriceRow.fromJson({
        'serviceId': '550e8400-e29b-41d4-a716-446655440000',
        'cost': 5000,
      });

      expect(row.fullCost, 5000);
      expect(row.hmoPays, 5000);
      expect(row.patientPays, 0);
      expect(row.hasConfiguredSplit, isFalse);
    });

    test('fromJson reads explicit split fields', () {
      final row = HmoServicePriceRow.fromJson({
        'serviceId': '550e8400-e29b-41d4-a716-446655440000',
        'fullCost': 5000,
        'hmoPays': 4000,
        'patientPays': 1000,
      });

      expect(row.fullCost, 5000);
      expect(row.hmoPays, 4000);
      expect(row.patientPays, 1000);
      expect(row.hasConfiguredSplit, isTrue);
    });

    test('toUpsertJson uses cost shorthand when no split', () {
      final row = HmoServicePriceRow(
        serviceId: 'abc',
        fullCost: 3500,
        hmoPays: 3500,
        patientPays: 0,
      );

      expect(row.toUpsertJson(), {'serviceId': 'abc', 'cost': 3500});
    });

    test('toUpsertJson uses full split when configured', () {
      final row = HmoServicePriceRow(
        serviceId: 'abc',
        fullCost: 5000,
        hmoPays: 4000,
        patientPays: 1000,
      );

      expect(
        row.toUpsertJson(),
        {
          'serviceId': 'abc',
          'fullCost': 5000,
          'hmoPays': 4000,
          'patientPays': 1000,
        },
      );
    });
  });
}
