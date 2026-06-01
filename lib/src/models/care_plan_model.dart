import 'staff_attribution.dart';

/// Row from GET `/admissions/:admissionId/care-plans`.
class CarePlanModel {
  const CarePlanModel({
    required this.id,
    this.problem,
    this.goal,
    this.interventions,
    this.evaluation,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.recorderDisplayName,
  });

  final String id;
  final String? problem;
  final String? goal;
  final String? interventions;
  final String? evaluation;
  final String? status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? recorderDisplayName;

  static String _str(dynamic v) => v?.toString() ?? '';

  static DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  factory CarePlanModel.fromJson(Map<String, dynamic> json) {
    final recorder = staffDisplayNameFromJson(json);
    return CarePlanModel(
      id: _str(json['id']),
      problem: json['problem']?.toString() ?? json['title']?.toString(),
      goal: json['goal']?.toString(),
      interventions: json['interventions']?.toString(),
      evaluation: json['evaluation']?.toString(),
      status: json['status']?.toString(),
      createdAt: _dt(json['createdAt'] ?? json['created_at']),
      updatedAt: _dt(json['updatedAt'] ?? json['updated_at']),
      recorderDisplayName: recorder.isEmpty ? null : recorder,
    );
  }
}
