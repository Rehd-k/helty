/// Archived (scanned) historical encounter groups and documents.
class ArchivedEncounterUploader {
  const ArchivedEncounterUploader({
    this.id,
    this.firstName,
    this.lastName,
  });

  final String? id;
  final String? firstName;
  final String? lastName;

  String get displayName {
    final parts = <String>[
      if (firstName != null && firstName!.trim().isNotEmpty) firstName!.trim(),
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!.trim(),
    ];
    return parts.isEmpty ? 'Staff' : parts.join(' ');
  }

  factory ArchivedEncounterUploader.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const ArchivedEncounterUploader();
    return ArchivedEncounterUploader(
      id: json['id'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
    );
  }
}

class ArchivedEncounterDocument {
  const ArchivedEncounterDocument({
    required this.id,
    required this.fileName,
    this.mimeType,
    this.fileSize,
    this.uploadedAt,
  });

  final String id;
  final String fileName;
  final String? mimeType;
  final int? fileSize;
  final DateTime? uploadedAt;

  bool get isImage {
    final m = mimeType?.toLowerCase() ?? '';
    return m.startsWith('image/');
  }

  bool get isPdf =>
      mimeType?.toLowerCase() == 'application/pdf' ||
      fileName.toLowerCase().endsWith('.pdf');

  factory ArchivedEncounterDocument.fromJson(Map<String, dynamic> json) {
    return ArchivedEncounterDocument(
      id: json['id'] as String? ?? '',
      fileName: json['fileName'] as String? ?? 'file',
      mimeType: json['mimeType'] as String?,
      fileSize: json['fileSize'] as int?,
      uploadedAt: _parseDate(json['uploadedAt']),
    );
  }
}

class PatientArchivedEncounter {
  const PatientArchivedEncounter({
    required this.id,
    required this.encounterOccurredAt,
    this.title,
    this.notes,
    this.createdAt,
    this.uploadedBy,
    this.documents = const [],
  });

  final String id;
  final DateTime encounterOccurredAt;
  final String? title;
  final String? notes;
  final DateTime? createdAt;
  final ArchivedEncounterUploader? uploadedBy;
  final List<ArchivedEncounterDocument> documents;

  factory PatientArchivedEncounter.fromJson(Map<String, dynamic> json) {
    final docsRaw = json['documents'];
    final docs = docsRaw is List
        ? docsRaw
            .whereType<Map>()
            .map((e) => ArchivedEncounterDocument.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <ArchivedEncounterDocument>[];

    return PatientArchivedEncounter(
      id: json['id'] as String? ?? '',
      encounterOccurredAt:
          _parseDate(json['encounterOccurredAt']) ?? DateTime.now(),
      title: json['title'] as String?,
      notes: json['notes'] as String?,
      createdAt: _parseDate(json['createdAt']),
      uploadedBy: json['uploadedBy'] is Map<String, dynamic>
          ? ArchivedEncounterUploader.fromJson(
              json['uploadedBy'] as Map<String, dynamic>,
            )
          : null,
      documents: docs,
    );
  }
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}
