/// Row from GET `/admissions/:admissionId/nursing-notes`.
class NursingNoteModel {
  const NursingNoteModel({
    required this.id,
    this.noteType,
    this.content,
    this.createdAt,
    this.authorName,
  });

  final String id;
  final String? noteType;
  final String? content;
  final DateTime? createdAt;
  final String? authorName;

  static String _str(dynamic v) => v?.toString() ?? '';

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory NursingNoteModel.fromJson(Map<String, dynamic> json) {
    return NursingNoteModel(
      id: _str(json['id']),
      noteType: json['noteType']?.toString() ?? json['note_type']?.toString(),
      content: json['content']?.toString() ?? json['text']?.toString(),
      createdAt: _dt(json['createdAt'] ?? json['created_at']),
      authorName: json['authorName']?.toString() ??
          json['author']?.toString() ??
          json['recordedBy']?.toString(),
    );
  }
}
