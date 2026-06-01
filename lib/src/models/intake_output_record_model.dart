import 'staff_attribution.dart';

/// Row from GET `/admissions/:admissionId/intake-output-records`.
class IntakeOutputRecordModel {
  const IntakeOutputRecordModel({
    required this.id,
    this.type,
    this.category,
    this.amountMl,
    this.recordedAt,
    this.notes,
    this.createdAt,
    this.nurseId,
    this.nurseDisplayName,
  });

  final String id;
  final String? type;
  final String? category;
  final double? amountMl;
  final DateTime? recordedAt;
  final String? notes;
  final DateTime? createdAt;
  final String? nurseId;
  final String? nurseDisplayName;

  static String _str(dynamic v) => v?.toString() ?? '';

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static double? _dbl(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  factory IntakeOutputRecordModel.fromJson(Map<String, dynamic> json) {
    final nurseName = staffDisplayNameFromJson(json);
    return IntakeOutputRecordModel(
      id: _str(json['id']),
      type: json['type']?.toString(),
      category: json['category']?.toString(),
      amountMl: _dbl(json['amountMl'] ?? json['amount_ml'] ?? json['amount']),
      recordedAt: _dt(json['recordedAt'] ?? json['recorded_at'] ?? json['time']),
      notes: json['notes']?.toString(),
      createdAt: _dt(json['createdAt'] ?? json['created_at']),
      nurseId: json['nurseId']?.toString() ?? json['nurse_id']?.toString(),
      nurseDisplayName: nurseName.isEmpty ? null : nurseName,
    );
  }
}
