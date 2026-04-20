class MedicationOrderModel {
  const MedicationOrderModel({
    required this.id,
    required this.encounterId,
    required this.drugId,
    required this.drugName,
    this.dose,
    this.frequency,
    this.duration,
    this.quantity,
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
  /// Total units to dispense (tablets/capsules/ml per course), when provided by API.
  final int? quantity;
  final String? route;
  final String? specialInstructions;
  final String status;

  factory MedicationOrderModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v != null) ? v.toString() : '';
    final q = json['quantity'];
    final quantity = q == null
        ? null
        : (q is num ? q.toInt() : int.tryParse(q.toString()));
    return MedicationOrderModel(
      id: str(json['id']),
      encounterId: str(json['encounterId']),
      drugId: str(json['drugId']),
      drugName: str(json['drugName']),
      dose: json['dose']?.toString(),
      frequency: json['frequency']?.toString(),
      duration: json['duration']?.toString(),
      quantity: quantity,
      route: json['route']?.toString(),
      specialInstructions: json['specialInstructions']?.toString(),
      status: (json['status']?.toString()) ?? 'Pending Dispense',
    );
  }
}
