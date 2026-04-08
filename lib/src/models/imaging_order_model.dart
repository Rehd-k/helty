class ImagingOrderModel {
  const ImagingOrderModel({
    required this.id,
    required this.encounterId,
    required this.catalogId,
    required this.studyName,
    this.area,
    this.contrast = false,
    this.urgency,
    this.notesToRadiologist,
    this.resultValues,
    this.resultSummary,
    required this.status,
  });

  final String id;
  final String encounterId;
  final String catalogId;
  final String studyName;
  final String? area;
  final bool contrast;
  final String? urgency;
  final String? notesToRadiologist;
  final Map<String, dynamic>? resultValues;
  final String? resultSummary;
  final String status; // Ordered, InProgress, Completed, Reported

  factory ImagingOrderModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v != null) ? v.toString() : '';
    Map<String, dynamic>? mapOrNull(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    final resultMap =
        mapOrNull(json['resultValues']) ??
        mapOrNull(json['result']) ??
        mapOrNull(json['report']) ??
        mapOrNull(json['radiologyResult']);
    final summary =
        json['impression']?.toString() ??
        json['findings']?.toString() ??
        json['reportText']?.toString() ??
        json['resultSummary']?.toString();

    return ImagingOrderModel(
      id: str(json['id']),
      encounterId: str(json['encounterId']),
      catalogId: str(json['catalogId']),
      studyName: str(json['studyName']),
      area: json['area']?.toString(),
      contrast: json['contrast'] == true,
      urgency: json['urgency']?.toString(),
      notesToRadiologist: json['notesToRadiologist']?.toString(),
      resultValues: resultMap,
      resultSummary: summary,
      status: (json['status']?.toString()) ?? 'Ordered',
    );
  }
}
