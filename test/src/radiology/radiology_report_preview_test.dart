import 'package:flutter_test/flutter_test.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/ui/radiology_ui_helpers.dart';

RadiologyStudyReport _report({
  String id = 'rep-1',
  String? findings,
  String? impression,
  String? recommendations,
}) {
  return RadiologyStudyReport(
    id: id,
    orderItemId: 'item-1',
    signedById: 'staff-1',
    signedAt: '2026-09-10T12:00:00.000Z',
    findings: findings,
    impression: impression,
    recommendations: recommendations,
  );
}

void main() {
  group('reportPreviewText', () {
    test('uses findings when present', () {
      expect(
        reportPreviewText(_report(findings: 'Clear lung fields.')),
        'Clear lung fields.',
      );
    });

    test('list stub without findings shows saved-without-text', () {
      final report = RadiologyStudyReport.fromJson({
        'id': 'rep-stub',
        'signedAt': '2026-09-10T12:00:00.000Z',
      });
      expect(reportPreviewText(report), 'Report saved without text.');
    });

    test('extracts plain text from Quill delta impression', () {
      const delta =
          '[{"insert":"No acute process.\\n"},{"insert":"Follow up as needed.","attributes":{"bold":true}},{"insert":"\\n"}]';
      expect(
        reportPreviewText(_report(impression: delta)),
        'No acute process.\nFollow up as needed.',
      );
    });

    test('does not duplicate findings when impression is Quill delta', () {
      const delta = '[{"insert":"Clear lung fields.\\n"}]';
      expect(
        reportPreviewText(
          _report(findings: 'Clear lung fields.', impression: delta),
        ),
        'Clear lung fields.',
      );
    });

    test('null report says no report yet', () {
      expect(reportPreviewText(null), 'No report yet.');
    });
  });
}
