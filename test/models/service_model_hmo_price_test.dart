import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/models/service_model.dart';

void main() {
  group('ServiceModel HMO pricing', () {
    const hmoId = 'ccffbae8-1caa-426e-8940-609d56b09b13';

    test('fromJson parses hmoPrices', () {
      final model = ServiceModel.fromJson({
        'id': 'a73de70d-07fd-4740-891a-d94c0483e53e',
        'name': 'CONSULTATION OP - GP',
        'cost': 15000,
        'searviceCode': 'OTOC000002',
        'hmoPrices': [
          {
            'id': '9ead02ec-0aea-4d95-8fd9-8d866ede99f8',
            'hmoId': hmoId,
            'hmoName': 'CBN',
            'hmoCode': '12092',
            'cost': 35000,
          },
        ],
      });

      expect(model.cost, 15000);
      expect(model.serviceCode, 'OTOC000002');
      expect(model.hmoPrices.length, 1);
      expect(model.hmoPrices.first.hmoId, hmoId);
      expect(model.hmoPrices.first.cost, 35000);
      expect(model.hmoPrices.first.hmoName, 'CBN');
    });

    test('costForHmo returns HMO tariff when hmoId matches', () {
      final model = ServiceModel.fromJson({
        'id': 'svc-1',
        'name': 'Lab Test',
        'cost': 15000,
        'hmoPrices': [
          {'hmoId': hmoId, 'cost': 35000},
        ],
      });

      expect(model.costForHmo(hmoId), 35000);
    });

    test('costForHmo falls back to standard cost when no match', () {
      final model = ServiceModel.fromJson({
        'id': 'svc-1',
        'name': 'Lab Test',
        'cost': 15000,
        'hmoPrices': [
          {'hmoId': hmoId, 'cost': 35000},
        ],
      });

      expect(model.costForHmo('other-hmo-id'), 15000);
      expect(model.costForHmo(null), 15000);
      expect(model.costForHmo(''), 15000);
    });

    test('costForHmo falls back when hmoPrices is empty', () {
      final model = ServiceModel.fromJson({
        'id': 'svc-1',
        'name': 'Lab Test',
        'cost': 15000,
      });

      expect(model.costForHmo(hmoId), 15000);
    });

    test('fromJson resolves purchaseItem.itemName on invoice line', () {
      final model = ServiceModel.fromJson({
        'id': 'line-uuid',
        'quantity': 1,
        'unitPrice': 1500,
        'purchaseItemId': '6deeca29-c8c3-474f-aa39-2b060e63daa0',
        'purchaseItem': {
          'id': '6deeca29-c8c3-474f-aa39-2b060e63daa0',
          'itemName': 'Pregnancy Stip',
        },
      });

      expect(model.name, 'Pregnancy Stip');
      expect(model.serviceId, '6deeca29-c8c3-474f-aa39-2b060e63daa0');
      expect(model.cost, 1500);
    });
  });
}
