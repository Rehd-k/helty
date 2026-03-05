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

  factory MedicationOrderModel.fromJson(Map<String, dynamic> json) =>
      MedicationOrderModel(
        id: json['id'] as String,
        encounterId: json['encounterId'] as String,
        drugId: json['drugId'] as String,
        drugName: json['drugName'] as String,
        dose: json['dose'] as String?,
        frequency: json['frequency'] as String?,
        duration: json['duration'] as String?,
        route: json['route'] as String?,
        specialInstructions: json['specialInstructions'] as String?,
        status: json['status'] as String? ?? 'Pending Dispense',
      );
}
