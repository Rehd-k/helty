import 'staff_attribution.dart';

/// Row from GET `/admissions/:admissionId/wound-assessments`.
class WoundAssessmentModel {
  const WoundAssessmentModel({
    required this.id,
    this.admissionId,
    this.nurseId,
    this.woundLocation,
    this.woundSize,
    this.woundStage,
    this.exudate,
    this.odor,
    this.infectionSigns,
    this.photoUrl,
    this.recordedAt,
    this.nurseDisplayName,
  });

  final String id;
  final String? admissionId;
  final String? nurseId;
  final String? woundLocation;
  final String? woundSize;
  final String? woundStage;
  final String? exudate;
  final String? odor;
  final String? infectionSigns;
  final String? photoUrl;
  final DateTime? recordedAt;
  final String? nurseDisplayName;

  static String _str(dynamic v) => v?.toString() ?? '';

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory WoundAssessmentModel.fromJson(Map<String, dynamic> json) {
    final nurseName = staffDisplayNameFromJson(json);
    return WoundAssessmentModel(
      id: _str(json['id']),
      admissionId: json['admissionId']?.toString(),
      nurseId: json['nurseId']?.toString(),
      woundLocation: json['woundLocation']?.toString(),
      woundSize: json['woundSize']?.toString(),
      woundStage: json['woundStage']?.toString(),
      exudate: json['exudate']?.toString(),
      odor: json['odor']?.toString(),
      infectionSigns: json['infectionSigns']?.toString(),
      photoUrl: json['photoUrl']?.toString(),
      recordedAt: _dt(json['recordedAt'] ?? json['recorded_at']),
      nurseDisplayName: nurseName.isEmpty ? null : nurseName,
    );
  }
}
