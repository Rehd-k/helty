import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/utils/lab_ast_display.dart';

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

  group('lab AST display', () {
    LabAstResult row(String name, int position, String label, String code) {
      return LabAstResult(
        id: name,
        orderItemId: 'item',
        antibiotic: LabAntibiotic(id: name, name: name, position: position),
        resultOption: LabAstResultOption(id: code, label: label, code: code),
      );
    }

    test('sorts by antibiotic position then name', () {
      final sorted = sortedLabAstResults([
        row('Ciprofloxacin', 2, 'Resistant', 'R'),
        row('Amoxicillin', 0, 'Sensitive', 'S'),
      ]);
      expect(sorted.map((e) => e.antibiotic.name), [
        'Amoxicillin',
        'Ciprofloxacin',
      ]);
    });

    test('parses a pasted culture susceptibility block', () {
      const raw =
          'Yielded moderate growth of Escherichia coli after 24 hours of incubation.\n\n'
          'ANTIBIOTIC SUSCEPTIBILITY\r\n\r\nANTIBIOTIC USED\n\t       \r\n'
          'Levofloxacin\t\t\r 3+            \n'
          'Azithromycin\t\t\rR\n'
          'Rifampicin\t\t\rR\n'
          'Cefuroxime\t\t\rR\t\t\r\n'
          'Erythromycim\t\t\rR\n'
          'Gentamycin\t\t\rR\n'
          'Ciprofloxacin\t\t\rR\n'
          'Amoxicillin\t\t\rR\n'
          'Streptomycin\t\t\r2+\n'
          'Ceftriaxone/Tazobactam\t2+\n'
          '\t\r\n'
          'R = RESISTANCE\r\n'
          'S= SENSITIVITY\r\n';

      final report = parseEmbeddedAstReport(raw);
      expect(report, isNotNull);
      expect(
        report!.narrative,
        'Yielded moderate growth of Escherichia coli after 24 hours of incubation.',
      );
      expect(report.rows.map((row) => '${row.antibiotic}=${row.result}'), [
        'Levofloxacin=3+',
        'Azithromycin=R',
        'Rifampicin=R',
        'Cefuroxime=R',
        'Erythromycim=R',
        'Gentamycin=R',
        'Ciprofloxacin=R',
        'Amoxicillin=R',
        'Streptomycin=2+',
        'Ceftriaxone/Tazobactam=2+',
      ]);
      expect(report.legend.map((item) => '${item.code}=${item.meaning}'), [
        'R=Resistance',
        'S=Sensitivity',
      ]);
      expect(classifyAstToken('R'), LabAstInterpretation.resistant);
      expect(classifyAstToken('3+'), LabAstInterpretation.sensitive);
      expect(parseEmbeddedAstReport('Haemoglobin 13.2'), isNull);
    });

    test('formats result text and legend from reported codes', () {
      final sensitive = row('Amoxicillin', 0, 'Sensitive', 'S');
      expect(labAstResultText(sensitive.resultOption), 'Sensitive (S)');
      expect(classifyLabAstResult(sensitive.resultOption),
          LabAstInterpretation.sensitive);
      expect(
        labAstResultLegend([sensitive, row('Cipro', 1, 'Resistant', 'R')]),
        'R Resistant | S Sensitive',
      );
    });
  });
}
