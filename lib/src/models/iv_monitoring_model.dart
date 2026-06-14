import 'staff_attribution.dart';

/// Row from GET `/admissions/:admissionId/iv-fluid-orders/:orderId/monitorings`.
class IvMonitoringModel {
  const IvMonitoringModel({
    required this.id,
    required this.admissionId,
    required this.ivOrderId,
    this.nurseId,
    this.currentRate,
    this.insertionSiteCondition,
    this.complications,
    this.reasonStopped,
    this.recordedAt,
    this.stoppedAt,
    this.createdAt,
    this.nurseDisplayName,
  });

  final String id;
  final String admissionId;
  final String ivOrderId;
  final String? nurseId;
  final int? currentRate;
  final String? insertionSiteCondition;
  final String? complications;
  final String? reasonStopped;
  final DateTime? recordedAt;
  final DateTime? stoppedAt;
  final DateTime? createdAt;
  final String? nurseDisplayName;

  static String _str(dynamic v) => v?.toString() ?? '';

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static int? _int(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  factory IvMonitoringModel.fromJson(Map<String, dynamic> json) {
    final nurse = staffDisplayNameFromJson(json);
    return IvMonitoringModel(
      id: _str(json['id']),
      admissionId: _str(json['admissionId'] ?? json['admission_id']),
      ivOrderId: _str(json['ivOrderId'] ?? json['iv_order_id']),
      nurseId: json['nurseId']?.toString() ?? json['nurse_id']?.toString(),
      currentRate: _int(json['currentRate'] ?? json['current_rate']),
      insertionSiteCondition: json['insertionSiteCondition']?.toString() ??
          json['insertion_site_condition']?.toString(),
      complications: json['complications']?.toString(),
      reasonStopped:
          json['reasonStopped']?.toString() ?? json['reason_stopped']?.toString(),
      recordedAt: _dt(json['recordedAt'] ?? json['recorded_at']),
      stoppedAt: _dt(json['stoppedAt'] ?? json['stopped_at']),
      createdAt: _dt(json['createdAt'] ?? json['created_at']),
      nurseDisplayName: nurse.isEmpty ? null : nurse,
    );
  }
}
