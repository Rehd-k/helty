import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/lab/models/lab_models.dart';

void main() {
  group('LabAntibiotic', () {
    test('fromJson and toJson round-trip', () {
      const json = {
        'id': 'abx-1',
        'name': 'Amoxicillin',
        'code': 'AMX',
        'isActive': true,
        'position': 0,
      };
      final model = LabAntibiotic.fromJson(json);
      expect(model.id, 'abx-1');
      expect(model.name, 'Amoxicillin');
      expect(model.code, 'AMX');
      expect(model.isActive, isTrue);
      expect(model.position, 0);
      expect(model.toJson()['name'], 'Amoxicillin');
    });
  });

  group('LabAstResultOption', () {
    test('fromJson parses label and code', () {
      final model = LabAstResultOption.fromJson({
        'id': 'opt-1',
        'label': 'Sensitive',
        'code': 'S',
        'isActive': true,
        'position': 1,
      });
      expect(model.label, 'Sensitive');
      expect(model.code, 'S');
      expect(model.position, 1);
    });
  });

  group('LabOrderItem', () {
    test('fromJson parses astRequested and astResults on detail', () {
      final item = LabOrderItem.fromJson({
        'id': 'item-1',
        'orderId': 'order-1',
        'astRequested': true,
        'astResults': [
          {
            'id': 'ast-1',
            'orderItemId': 'item-1',
            'antibiotic': {
              'id': 'abx-1',
              'name': 'Amoxicillin',
              'code': 'AMX',
              'isActive': true,
              'position': 0,
            },
            'resultOption': {
              'id': 'opt-1',
              'label': 'Sensitive',
              'code': 'S',
              'isActive': true,
              'position': 0,
            },
            'enteredBy': {
              'id': 'staff-1',
              'firstName': 'Jane',
              'lastName': 'Doe',
            },
          },
        ],
      });

      expect(item.astRequested, isTrue);
      expect(item.astResults, hasLength(1));
      expect(item.astResults.first.antibiotic.name, 'Amoxicillin');
      expect(item.astResults.first.resultOption.code, 'S');
      expect(item.astResults.first.enteredBy?.displayName, 'Jane Doe');
    });

    test('fromJson defaults astRequested false without astResults', () {
      final item = LabOrderItem.fromJson({
        'id': 'item-2',
        'orderId': 'order-1',
        'astRequested': false,
      });

      expect(item.astRequested, isFalse);
      expect(item.astResults, isEmpty);
    });

    test('fromJson omits astRequested defaults to false', () {
      final item = LabOrderItem.fromJson({
        'id': 'item-3',
        'orderId': 'order-1',
      });

      expect(item.astRequested, isFalse);
      expect(item.astResults, isEmpty);
    });
  });

  group('LabOrderItemInput', () {
    test('toJson includes astRequested', () {
      const input = LabOrderItemInput(
        testVersionId: 'ver-1',
        astRequested: true,
      );
      expect(input.toJson(), {
        'testVersionId': 'ver-1',
        'astRequested': true,
      });
    });
  });
}
