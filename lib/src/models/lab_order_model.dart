class LabOrderModel {
  const LabOrderModel({
    required this.id,
    required this.encounterId,
    required this.catalogTestId,
    required this.testName,
    this.priority,
    this.clinicalNotes,
    required this.status,
    this.resultValues,
  });

  final String id;
  final String encounterId;
  final String catalogTestId;
  final String testName;
  final String? priority;
  final String? clinicalNotes;
  final String status;
  final Map<String, String>? resultValues;

  factory LabOrderModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v != null) ? v.toString() : '';
    return LabOrderModel(
      id: str(json['id']),
      encounterId: str(json['encounterId']),
      catalogTestId: str(json['catalogTestId']),
      testName: str(json['testName']),
      priority: json['priority']?.toString(),
      clinicalNotes: json['clinicalNotes']?.toString(),
      status: (json['status']?.toString()) ?? 'Ordered',
      resultValues: json['resultValues'] != null && json['resultValues'] is Map
          ? Map<String, String>.from(
              (json['resultValues'] as Map).map(
                (k, v) => MapEntry(k.toString(), v?.toString() ?? ''),
              ),
            )
          : null,
    );
  }
}
