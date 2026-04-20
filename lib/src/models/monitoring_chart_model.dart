/// Row from GET `/admissions/:admissionId/monitoring-charts`.
class MonitoringChartModel {
  const MonitoringChartModel({
    required this.id,
    this.chartType,
    this.value,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? chartType;
  final Map<String, dynamic>? value;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  static String _str(dynamic v) => v?.toString() ?? '';

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory MonitoringChartModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? val;
    final raw = json['value'];
    if (raw is Map) {
      val = Map<String, dynamic>.from(raw);
    }

    return MonitoringChartModel(
      id: _str(json['id']),
      chartType:
          json['chartType']?.toString() ?? json['chart_type']?.toString(),
      value: val,
      createdAt: _dt(json['createdAt'] ?? json['created_at']),
      updatedAt: _dt(json['updatedAt'] ?? json['updated_at']),
    );
  }
}
