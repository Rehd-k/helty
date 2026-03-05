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

  factory ImagingOrderModel.fromJson(Map<String, dynamic> json) =>
      ImagingOrderModel(
        id: json['id'] as String,
        encounterId: json['encounterId'] as String,
        catalogId: json['catalogId'] as String,
        studyName: json['studyName'] as String,
        area: json['area'] as String?,
        contrast: json['contrast'] as bool? ?? false,
        urgency: json['urgency'] as String?,
        notesToRadiologist: json['notesToRadiologist'] as String?,
        status: json['status'] as String? ?? 'Ordered',
      );
}
