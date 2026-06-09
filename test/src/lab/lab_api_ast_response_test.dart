import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/services/lab_api_service.dart';

void main() {
  group('LabApiService AST list response parsing', () {
    test('parses bare JSON array', () {
      final list = LabApiService.jsonObjectListFromResponseForTest([
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
        },
      ]);
      expect(list, hasLength(1));
      final row = LabAstResult.fromJson(list.first);
      expect(row.antibiotic.name, 'Amoxicillin');
    });

    test('parses wrapped { data: [...] } object', () {
      final list = LabApiService.jsonObjectListFromResponseForTest({
        'data': [
          {
            'id': 'ast-2',
            'orderItemId': 'item-1',
            'antibiotic': {
              'id': 'abx-2',
              'name': 'Ciprofloxacin',
              'code': 'CIP',
              'isActive': true,
              'position': 1,
            },
            'resultOption': {
              'id': 'opt-2',
              'label': 'Resistant',
              'code': 'R',
              'isActive': true,
              'position': 2,
            },
          },
        ],
      });
      expect(list, hasLength(1));
      expect(list.first['id'], 'ast-2');
    });

    test('parses AST envelope { orderItemId, results: [...] }', () {
      final list = LabApiService.jsonObjectListFromResponseForTest({
        'orderItemId': 'item-1',
        'astRequested': true,
        'results': [
          {
            'id': 'ast-3',
            'orderItemId': 'item-1',
            'antibiotic': {
              'id': 'abx-3',
              'name': 'Gentamicin',
              'code': null,
              'isActive': true,
              'position': 2,
            },
            'resultOption': {
              'id': 'opt-3',
              'label': 'Sensitive',
              'code': 'S',
              'isActive': true,
              'position': 0,
            },
          },
        ],
      });
      expect(list, hasLength(1));
      expect(list.first['id'], 'ast-3');
    });

    test('returns empty list for AST envelope with empty results', () {
      final list = LabApiService.jsonObjectListFromResponseForTest({
        'orderItemId': 'item-1',
        'astRequested': true,
        'results': [],
      });
      expect(list, isEmpty);
    });

    test('returns empty list for null body', () {
      expect(LabApiService.jsonObjectListFromResponseForTest(null), isEmpty);
    });
  });
}
