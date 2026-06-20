import 'medication_request_model.dart';

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
    this.invoiceItemId,
    this.invoiceItem,
    this.doctor,
    this.medicationRequests = const [],
    this.prescribedDrugName,
    this.prescribedDrugId,
    this.prescribedDrug,
    this.drug,
    this.substitutedByPharmacist,
    this.substitutedAt,
  });

  final String id;
  final String encounterId;
  final String drugId;
  final String drugName;
  final String? dose;
  final String? frequency;
  final String? duration;
  /// Total units per administration course (clinical), when provided by API.
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
  final String? invoiceItemId;
  final MedicationOrderInvoiceItemRef? invoiceItem;
  final MedicationRequestStaffRef? doctor;
  final List<MedicationRequestModel> medicationRequests;
  final String? prescribedDrugName;
  final String? prescribedDrugId;
  final MedicationRequestDrugRef? prescribedDrug;
  final MedicationRequestDrugRef? drug;
  final MedicationRequestStaffRef? substitutedByPharmacist;
  final DateTime? substitutedAt;

  /// Best timestamp for sorting and display when [startDateTime] is absent.
  DateTime? get displayDateTime => startDateTime ?? createdAt;

  bool get wasSubstituted =>
      substitutedByPharmacist != null ||
      (prescribedDrugId != null &&
          prescribedDrugId!.isNotEmpty &&
          prescribedDrugId != drugId);

  String get prescribedDrugLabel =>
      prescribedDrugName?.trim().isNotEmpty == true
      ? prescribedDrugName!.trim()
      : (prescribedDrug?.displayName.trim().isNotEmpty == true
            ? prescribedDrug!.displayName
            : drugName);

  String get currentDrugLabel =>
      drug?.displayName.trim().isNotEmpty == true
      ? drug!.displayName
      : drugName;

  bool get isLegacyBilledAtPrescribe =>
      (invoiceItemId != null && invoiceItemId!.isNotEmpty) ||
      (invoiceItem?.isPresent ?? false);

  bool get canRequestMedication {
    if (drugId.trim().isEmpty) return false;
    if (isLegacyBilledAtPrescribe) return false;
    final s = status.trim();
    return s == 'Prescribed' || s == 'Pending Dispense';
  }

  factory MedicationOrderModel.fromJson(Map<String, dynamic> json) {
    String str(dynamic v) => (v != null) ? v.toString() : '';
    final q = json['quantity'];
    final quantity = q == null
        ? null
        : (q is num ? q.toInt() : int.tryParse(q.toString()));

    Map<String, dynamic>? map(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : null;

    final invoiceRaw = map(json['invoiceItem']);
    final doctorRaw = map(json['doctor']);
    final drugRaw = map(json['drug']);
    final prescribedDrugRaw = map(json['prescribedDrug']);
    final substitutedRaw = map(json['substitutedByPharmacist']);
    final requestsRaw = json['medicationRequests'];
    final requests = requestsRaw is List
        ? requestsRaw
            .whereType<Map>()
            .map(
              (e) => MedicationRequestModel.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList()
        : <MedicationRequestModel>[];

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
      status: (json['status']?.toString()) ?? 'Prescribed',
      administrationStatus: MedicationAdministrationStatusX.fromApi(
        json['administrationStatus']?.toString(),
      ),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
      invoiceItemId: json['invoiceItemId']?.toString(),
      invoiceItem: invoiceRaw != null
          ? MedicationOrderInvoiceItemRef.fromJson(invoiceRaw)
          : null,
      doctor: doctorRaw != null
          ? MedicationRequestStaffRef.fromJson(doctorRaw)
          : null,
      medicationRequests: requests,
      prescribedDrugName: json['prescribedDrugName']?.toString(),
      prescribedDrugId: json['prescribedDrugId']?.toString() ??
          prescribedDrugRaw?['id']?.toString(),
      prescribedDrug: prescribedDrugRaw != null
          ? MedicationRequestDrugRef.fromJson(prescribedDrugRaw)
          : null,
      drug: drugRaw != null ? MedicationRequestDrugRef.fromJson(drugRaw) : null,
      substitutedByPharmacist: substitutedRaw != null
          ? MedicationRequestStaffRef.fromJson(substitutedRaw)
          : null,
      substitutedAt: DateTime.tryParse(
        json['substitutedAt']?.toString() ?? '',
      ),
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
