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
    this.admissionId,
    this.startDateTime,
    this.endDateTime,
    this.notes,
    required this.status,
    this.administrationStatus = MedicationAdministrationStatus.active,
    this.createdAt,
    this.updatedAt,
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
  final String? admissionId;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  final String? notes;
  final String status;
  final MedicationAdministrationStatus administrationStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Best timestamp for sorting and display when [startDateTime] is absent.
  DateTime? get displayDateTime => startDateTime ?? createdAt;

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
      admissionId: json['admissionId']?.toString(),
      startDateTime: DateTime.tryParse(json['startDateTime']?.toString() ?? ''),
      endDateTime: DateTime.tryParse(json['endDateTime']?.toString() ?? ''),
      notes: json['notes']?.toString(),
      status: (json['status']?.toString()) ?? 'Pending Dispense',
      administrationStatus: MedicationAdministrationStatusX.fromApi(
        json['administrationStatus']?.toString(),
      ),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }
}

enum MedicationAdministrationStatus { active, stopped }

extension MedicationAdministrationStatusX on MedicationAdministrationStatus {
  String get apiValue => this == MedicationAdministrationStatus.stopped
      ? 'STOPPED'
      : 'ACTIVE';

  String get label => this == MedicationAdministrationStatus.stopped
      ? 'Stopped'
      : 'Active';

  static MedicationAdministrationStatus fromApi(String? value) {
    if (value == null) return MedicationAdministrationStatus.active;
    switch (value.toUpperCase()) {
      case 'STOPPED':
        return MedicationAdministrationStatus.stopped;
      case 'ACTIVE':
      default:
        return MedicationAdministrationStatus.active;
    }
  }
}
