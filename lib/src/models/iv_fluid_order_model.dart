import 'staff_attribution.dart';

/// Row from GET `/admissions/:admissionId/iv-fluid-orders`.
class IvFluidOrderModel {
  const IvFluidOrderModel({
    required this.id,
    this.fluidType,
    this.volume,
    this.rate,
    this.startTime,
    this.expectedEndTime,
    this.status,
    this.recorderDisplayName,
    this.latestSiteCondition,
  });

  final String id;
  final String? fluidType;
  final String? volume;
  final String? rate;
  final DateTime? startTime;
  final DateTime? expectedEndTime;
  final String? status;
  final String? recorderDisplayName;
  final String? latestSiteCondition;

  static String _str(dynamic v) => v?.toString() ?? '';

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static String? _latestSiteFromMonitorings(dynamic raw) {
    if (raw is! List || raw.isEmpty) return null;
    final first = raw.first;
    if (first is! Map) return null;
    final site = first['insertionSiteCondition'] ??
        first['insertion_site_condition'];
    final s = site?.toString().trim() ?? '';
    return s.isEmpty ? null : s;
  }

  factory IvFluidOrderModel.fromJson(Map<String, dynamic> json) {
    final recorder = staffDisplayNameFromJson(json);
    return IvFluidOrderModel(
      id: _str(json['id']),
      fluidType: json['fluidType']?.toString() ?? json['fluid_type']?.toString(),
      volume: json['volume']?.toString(),
      rate: json['rate']?.toString(),
      startTime: _dt(json['startTime'] ?? json['start_time']),
      expectedEndTime: _dt(json['expectedEndTime'] ?? json['expected_end_time']),
      status: json['status']?.toString(),
      recorderDisplayName: recorder.isEmpty ? null : recorder,
      latestSiteCondition: _latestSiteFromMonitorings(json['monitorings']),
    );
  }
}
