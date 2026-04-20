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
  });

  final String id;
  final String? fluidType;
  final String? volume;
  final String? rate;
  final DateTime? startTime;
  final DateTime? expectedEndTime;
  final String? status;

  static String _str(dynamic v) => v?.toString() ?? '';

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory IvFluidOrderModel.fromJson(Map<String, dynamic> json) {
    return IvFluidOrderModel(
      id: _str(json['id']),
      fluidType: json['fluidType']?.toString() ?? json['fluid_type']?.toString(),
      volume: json['volume']?.toString(),
      rate: json['rate']?.toString(),
      startTime: _dt(json['startTime'] ?? json['start_time']),
      expectedEndTime: _dt(json['expectedEndTime'] ?? json['expected_end_time']),
      status: json['status']?.toString(),
    );
  }
}
