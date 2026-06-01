import 'staff_attribution.dart';

/// Row from GET `/admissions/:admissionId/handover-reports`.
class HandoverReportModel {
  const HandoverReportModel({
    required this.id,
    this.shiftType,
    this.summary,
    this.content,
    this.notes,
    this.createdAt,
    this.recorderDisplayName,
  });

  final String id;
  final String? shiftType;
  final String? summary;
  final String? content;
  final String? notes;
  final DateTime? createdAt;
  final String? recorderDisplayName;

  static String _str(dynamic v) => v?.toString() ?? '';

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory HandoverReportModel.fromJson(Map<String, dynamic> json) {
    final recorder = staffDisplayNameFromJson(json);
    return HandoverReportModel(
      id: _str(json['id']),
      shiftType: json['shiftType']?.toString() ?? json['shift_type']?.toString(),
      summary: json['summary']?.toString(),
      content: json['content']?.toString() ?? json['narrative']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: _dt(json['createdAt'] ?? json['created_at']),
      recorderDisplayName: recorder.isEmpty ? null : recorder,
    );
  }

  String get displayBody =>
      (summary != null && summary!.trim().isNotEmpty)
          ? summary!
          : (content ?? notes ?? '');
}
