import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/utils/lab_reference_evaluation.dart';

/// One analyte line from [LabOrderModel.resultLines] (API: items[].results[].field).
class LabOrderResultLine {
  const LabOrderResultLine({
    required this.label,
    required this.value,
    this.unit,
    this.referenceRange,
    this.referenceEvaluation,
    this.position = 0,
  });

  final String label;
  final String value;
  final String? unit;
  final String? referenceRange;
  final ReferenceEvaluation? referenceEvaluation;
  final int position;

  String get valueWithUnit {
    final u = unit?.trim();
    if (u == null || u.isEmpty) return value;
    return '$value $u';
  }
}

class LabOrderModel {
  const LabOrderModel({
    required this.id,
    required this.encounterId,
    required this.catalogTestId,
    required this.testType,
    this.priority,
    this.clinicalNotes,
    required this.status,
    this.createdAt,
    this.resultValues,
    this.resultLines,
    this.printableLabOrderId,
  });

  final String id;
  final String encounterId;
  final String catalogTestId;
  final String testType;
  final String? priority;
  final String? clinicalNotes;
  final String status;
  final String? createdAt;
  final Map<String, String>? resultValues;

  /// Structured results from `invoiceItem.labOrder.items[].results[]` (or top-level `labOrder`).
  final List<LabOrderResultLine>? resultLines;

  /// Nested structured [LabOrder] id for PDF printing via lab module API.
  final String? printableLabOrderId;

  static Map<String, dynamic>? _nestedLabOrderMap(Map<String, dynamic> json) {
    final inv = json['invoiceItem'];
    if (inv is Map<String, dynamic>) {
      final lo = inv['labOrder'];
      if (lo is Map<String, dynamic>) return lo;
    }
    final lo = json['labOrder'];
    if (lo is Map<String, dynamic>) return lo;
    return null;
  }

  static String? _printableLabOrderIdFromJson(Map<String, dynamic> json) {
    final lo = _nestedLabOrderMap(json);
    final id = lo?['id']?.toString().trim();
    if (id != null && id.isNotEmpty) return id;
    return null;
  }

  static List<LabOrderResultLine>? _parseNestedItemResults(
    Map<String, dynamic> json,
  ) {
    final labOrderMap = _nestedLabOrderMap(json);
    if (labOrderMap == null) return null;

    final items = labOrderMap['items'];
    if (items is! List<dynamic>) return null;

    final lines = <LabOrderResultLine>[];
    for (final item in items) {
      if (item is! Map<String, dynamic>) continue;
      final results = item['results'];
      if (results is! List<dynamic>) continue;
      for (final r in results) {
        if (r is! Map<String, dynamic>) continue;
        final value = r['value']?.toString() ?? '';
        final field = r['field'];
        var label = r['fieldId']?.toString() ?? 'Result';
        String? unit;
        String? referenceRange;
        var position = 0;
        if (field is Map<String, dynamic>) {
          label = field['label']?.toString() ?? label;
          unit = field['unit']?.toString();
          referenceRange = field['referenceRange']?.toString();
          final pos = field['position'];
          if (pos is int) {
            position = pos;
          } else if (pos != null) {
            position = int.tryParse(pos.toString()) ?? 0;
          }
        }
        final evalRaw = r['referenceEvaluation'];
        final serverEvaluation = evalRaw is Map<String, dynamic>
            ? ReferenceEvaluation.fromJson(evalRaw)
            : null;
        final referenceEvaluation = resolveLabReferenceEvaluation(
          value: value,
          referenceRange: referenceRange,
          serverEvaluation: serverEvaluation,
        );
        lines.add(
          LabOrderResultLine(
            label: label,
            value: value,
            unit: unit,
            referenceRange: referenceRange,
            referenceEvaluation: referenceEvaluation,
            position: position,
          ),
        );
      }
    }
    if (lines.isEmpty) return null;
    lines.sort((a, b) => a.position.compareTo(b.position));
    return lines;
  }

  static String? _createdAtFromJson(Map<String, dynamic> json) {
    final direct = json['createdAt']?.toString();
    if (direct != null && direct.isNotEmpty) return direct;
    final lo = json['labOrder'];
    if (lo is Map<String, dynamic>) {
      final v = lo['createdAt']?.toString();
      if (v != null && v.isNotEmpty) return v;
    }
    final inv = json['invoiceItem'];
    if (inv is Map<String, dynamic>) {
      final lo2 = inv['labOrder'];
      if (lo2 is Map<String, dynamic>) {
        final v = lo2['createdAt']?.toString();
        if (v != null && v.isNotEmpty) return v;
      }
    }
    return null;
  }

  factory LabOrderModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v != null) ? v.toString() : '';
    final nestedLines = _parseNestedItemResults(json);
    return LabOrderModel(
      id: str(json['id']),
      encounterId: str(json['encounterId']),
      catalogTestId: str(json['catalogTestId']),
      testType: str(json['testType']),
      priority: json['priority']?.toString(),
      clinicalNotes: json['clinicalNotes']?.toString(),
      status: (json['status']?.toString()) ?? 'Ordered',
      createdAt: _createdAtFromJson(json),
      resultValues: json['resultValues'] != null && json['resultValues'] is Map
          ? Map<String, String>.from(
              (json['resultValues'] as Map).map(
                (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
              ),
            )
          : null,
      resultLines: nestedLines,
      printableLabOrderId: _printableLabOrderIdFromJson(json),
    );
  }
}
