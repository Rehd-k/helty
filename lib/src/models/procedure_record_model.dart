import 'staff_attribution.dart';

/// Row from GET `/admissions/:admissionId/procedure-records`.
class ProcedureRecordModel {
  const ProcedureRecordModel({
    required this.id,
    this.admissionId,
    this.nurseId,
    this.procedureType,
    this.description,
    this.outcome,
    this.complications,
    this.recordedAt,
    this.createdAt,
    this.nurseDisplayName,
  });

  final String id;
  final String? admissionId;
  final String? nurseId;
  final String? procedureType;
  final String? description;
  final String? outcome;
  final String? complications;
  final DateTime? recordedAt;
  final DateTime? createdAt;
  final String? nurseDisplayName;

  static String _str(dynamic v) => v?.toString() ?? '';

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory ProcedureRecordModel.fromJson(Map<String, dynamic> json) {
    final nurseName = staffDisplayNameFromJson(json);
    return ProcedureRecordModel(
      id: _str(json['id']),
      admissionId: json['admissionId']?.toString(),
      nurseId: json['nurseId']?.toString(),
      procedureType: json['procedureType']?.toString(),
      description: json['description']?.toString(),
      outcome: json['outcome']?.toString(),
      complications: json['complications']?.toString(),
      recordedAt: _dt(json['recordedAt'] ?? json['recorded_at']),
      createdAt: _dt(json['createdAt'] ?? json['created_at']),
      nurseDisplayName: nurseName.isEmpty ? null : nurseName,
    );
  }
}
