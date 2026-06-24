/// Row from GET `/admissions/:admissionId/alerts`.
class AdmissionAlertModel {
  const AdmissionAlertModel({
    required this.id,
    this.severity,
    this.title,
    this.message,
    this.type,
    this.medicationOrderId,
    this.dueAt,
    this.metadata,
    this.resolvedAt,
    this.createdAt,
  });

  final String id;
  final String? severity;
  final String? title;
  final String? message;
  final String? type;
  final String? medicationOrderId;
  final DateTime? dueAt;
  final Map<String, dynamic>? metadata;
  final DateTime? resolvedAt;
  final DateTime? createdAt;

  bool get isResolved => resolvedAt != null;

  bool get isMedicationAlert {
    final t = type?.toUpperCase() ?? '';
    return t.startsWith('MEDICATION_');
  }

  String get medicationDrugName {
    final fromMeta = metadata?['drugName'] ?? metadata?['drug_name'];
    if (fromMeta != null && fromMeta.toString().trim().isNotEmpty) {
      return fromMeta.toString();
    }
    return title ?? 'Medication';
  }

  static String _str(dynamic v) => v?.toString() ?? '';

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory AdmissionAlertModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? meta;
    final metaRaw = json['metadata'];
    if (metaRaw is Map) {
      meta = Map<String, dynamic>.from(metaRaw);
    }
    return AdmissionAlertModel(
      id: _str(json['id']),
      severity: json['severity']?.toString(),
      title: json['title']?.toString() ?? json['type']?.toString(),
      message: json['message']?.toString() ?? json['description']?.toString(),
      type: json['type']?.toString(),
      medicationOrderId: json['medicationOrderId']?.toString() ??
          json['medication_order_id']?.toString(),
      dueAt: _dt(json['dueAt'] ?? json['due_at']),
      metadata: meta,
      resolvedAt: _dt(json['resolvedAt'] ?? json['resolved_at']),
      createdAt: _dt(json['createdAt'] ?? json['created_at']),
    );
  }
}
