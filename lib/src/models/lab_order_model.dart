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

  factory LabOrderModel.fromJson(Map<String, dynamic> json) => LabOrderModel(
        id: json['id'] as String,
        encounterId: json['encounterId'] as String,
        catalogTestId: json['catalogTestId'] as String,
        testName: json['testName'] as String,
        priority: json['priority'] as String?,
        clinicalNotes: json['clinicalNotes'] as String?,
        status: json['status'] as String? ?? 'Ordered',
        resultValues: json['resultValues'] != null
            ? Map<String, String>.from(json['resultValues'] as Map)
            : null,
      );
}
