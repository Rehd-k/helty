class MedicationOrderModel {
  const MedicationOrderModel({
    required this.id,
    required this.encounterId,
    required this.drugId,
    required this.drugName,
    this.dose,
    this.frequency,
    this.duration,
    this.route,
    this.specialInstructions,
    required this.status,
  });

  final String id;
  final String encounterId;
  final String drugId;
  final String drugName;
  final String? dose;
  final String? frequency;
  final String? duration;
  final String? route;
  final String? specialInstructions;
  final String status;

  factory MedicationOrderModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v != null) ? v.toString() : '';
    return MedicationOrderModel(
      id: str(json['id']),
      encounterId: str(json['encounterId']),
      drugId: str(json['drugId']),
      drugName: str(json['drugName']),
      dose: json['dose']?.toString(),
      frequency: json['frequency']?.toString(),
      duration: json['duration']?.toString(),
      route: json['route']?.toString(),
      specialInstructions: json['specialInstructions']?.toString(),
      status: (json['status']?.toString()) ?? 'Pending Dispense',
    );
  }
}
