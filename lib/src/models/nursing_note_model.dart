import 'staff_attribution.dart';

/// Row from GET `/admissions/:admissionId/nursing-notes`.
class NursingNoteModel {
  const NursingNoteModel({
    required this.id,
    this.noteType,
    this.content,
    this.nurseId,
    this.createdAt,
    this.updatedAt,
    this.authorName,
  });

  final String id;
  final String? noteType;
  final String? content;
  final String? nurseId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? authorName;

  static String _str(dynamic v) => v?.toString() ?? '';

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory NursingNoteModel.fromJson(Map<String, dynamic> json) {
    final nested = staffDisplayNameFromJson(json);
    final flat = json['authorName']?.toString() ??
        json['author']?.toString() ??
        json['recordedBy']?.toString();
    final author = nested.isNotEmpty
        ? nested
        : (flat != null && flat.isNotEmpty ? flat : null);
    final nurseMap = json['nurse'] is Map
        ? Map<String, dynamic>.from(json['nurse'] as Map)
        : null;
    return NursingNoteModel(
      id: _str(json['id']),
      noteType: json['noteType']?.toString() ?? json['note_type']?.toString(),
      content: json['content']?.toString() ?? json['text']?.toString(),
      nurseId: json['nurseId']?.toString() ??
          json['nurse_id']?.toString() ??
          nurseMap?['id']?.toString(),
      createdAt: _dt(json['createdAt'] ?? json['created_at']),
      updatedAt: _dt(json['updatedAt'] ?? json['updated_at']),
      authorName: author,
    );
  }
}
