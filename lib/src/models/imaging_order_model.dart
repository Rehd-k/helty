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
  final String status; // Ordered, InProgress, Completed, Reported

  factory ImagingOrderModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v != null) ? v.toString() : '';
    return ImagingOrderModel(
      id: str(json['id']),
      encounterId: str(json['encounterId']),
      catalogId: str(json['catalogId']),
      studyName: str(json['studyName']),
      area: json['area']?.toString(),
      contrast: json['contrast'] == true,
      urgency: json['urgency']?.toString(),
      notesToRadiologist: json['notesToRadiologist']?.toString(),
      status: (json['status']?.toString()) ?? 'Ordered',
    );
  }
}
