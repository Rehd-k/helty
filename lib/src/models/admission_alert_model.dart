/// Row from GET `/admissions/:admissionId/alerts`.
class AdmissionAlertModel {
  const AdmissionAlertModel({
    required this.id,
    this.severity,
    this.title,
    this.message,
    this.resolvedAt,
    this.createdAt,
  });

  final String id;
  final String? severity;
  final String? title;
  final String? message;
  final DateTime? resolvedAt;
  final DateTime? createdAt;

  bool get isResolved => resolvedAt != null;

  static String _str(dynamic v) => v?.toString() ?? '';

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory AdmissionAlertModel.fromJson(Map<String, dynamic> json) {
    return AdmissionAlertModel(
      id: _str(json['id']),
      severity: json['severity']?.toString(),
      title: json['title']?.toString() ?? json['type']?.toString(),
      message: json['message']?.toString() ?? json['description']?.toString(),
      resolvedAt: _dt(json['resolvedAt'] ?? json['resolved_at']),
      createdAt: _dt(json['createdAt'] ?? json['created_at']),
    );
  }
}
