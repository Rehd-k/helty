import 'package:helty/src/core/utils/api_decimal.dart';
import 'package:helty/src/core/utils/patient_display_name.dart';

/// Lifecycle status of a patient-initiated prescription refill request.
enum RefillRequestStatus {
  pending,
  approved,
  rejected,
  fulfilled,
  cancelled,
}

extension RefillRequestStatusX on RefillRequestStatus {
  String get apiValue {
    switch (this) {
      case RefillRequestStatus.pending:
        return 'PENDING';
      case RefillRequestStatus.approved:
        return 'APPROVED';
      case RefillRequestStatus.rejected:
        return 'REJECTED';
      case RefillRequestStatus.fulfilled:
        return 'FULFILLED';
      case RefillRequestStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case RefillRequestStatus.pending:
        return 'Pending';
      case RefillRequestStatus.approved:
        return 'Approved';
      case RefillRequestStatus.rejected:
        return 'Rejected';
      case RefillRequestStatus.fulfilled:
        return 'Fulfilled';
      case RefillRequestStatus.cancelled:
        return 'Cancelled';
    }
  }

  static RefillRequestStatus fromApi(String? value) {
    switch (value?.trim().toUpperCase()) {
      case 'APPROVED':
        return RefillRequestStatus.approved;
      case 'REJECTED':
        return RefillRequestStatus.rejected;
      case 'FULFILLED':
        return RefillRequestStatus.fulfilled;
      case 'CANCELLED':
        return RefillRequestStatus.cancelled;
      case 'PENDING':
      default:
        return RefillRequestStatus.pending;
    }
  }
}

class RefillPatientRef {
  const RefillPatientRef({
    required this.id,
    this.patientId,
    this.surname,
    this.otherName,
    this.apiDisplayName,
  });

  final String id;

  /// Hospital patient ID (e.g. `WB2YEP9K`).
  final String? patientId;
  final String? surname;
  final String? otherName;
  final String? apiDisplayName;

  String get displayName =>
      preferPatientFormattedName(displayName: apiDisplayName) ??
      patientDisplayNameFromJson({
        'firstName': otherName,
        'surname': surname,
      });

  factory RefillPatientRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const RefillPatientRef(id: '');
    }
    return RefillPatientRef(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString(),
      surname: json['surname']?.toString(),
      otherName: json['otherName']?.toString(),
      apiDisplayName: preferPatientFormattedName(
        patientName: json['patientName']?.toString(),
        name: json['name']?.toString(),
        displayName: json['displayName']?.toString(),
      ),
    );
  }
}

class RefillDoctorRef {
  const RefillDoctorRef({this.firstName, this.lastName});

  final String? firstName;
  final String? lastName;

  String? get displayName {
    final parts = [firstName, lastName]
        .map((p) => p?.trim())
        .where((p) => p != null && p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  factory RefillDoctorRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RefillDoctorRef();
    return RefillDoctorRef(
      firstName: json['firstName']?.toString(),
      lastName: json['lastName']?.toString(),
    );
  }
}

class RefillPrescriptionDrugRef {
  const RefillPrescriptionDrugRef({
    required this.id,
    this.brandName,
    this.genericName,
    this.strength,
  });

  final String id;
  final String? brandName;
  final String? genericName;
  final String? strength;

  String get displayName {
    final generic = genericName?.trim() ?? '';
    final brand = brandName?.trim() ?? '';
    if (generic.isNotEmpty && brand.isNotEmpty && generic != brand) {
      return '$generic ($brand)';
    }
    if (brand.isNotEmpty) return brand;
    if (generic.isNotEmpty) return generic;
    return '—';
  }

  factory RefillPrescriptionDrugRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RefillPrescriptionDrugRef(id: '');
    return RefillPrescriptionDrugRef(
      id: json['id']?.toString() ?? '',
      brandName: json['brandName']?.toString(),
      genericName: json['genericName']?.toString(),
      strength: json['strength']?.toString(),
    );
  }
}

class RefillPrescriptionItem {
  const RefillPrescriptionItem({
    required this.id,
    this.dosage,
    this.frequency,
    this.quantityDispensed,
    this.quantityPrescribed,
    this.instructions,
    this.drug,
  });

  final String id;
  final String? dosage;
  final String? frequency;
  final int? quantityDispensed;
  final int? quantityPrescribed;
  final String? instructions;
  final RefillPrescriptionDrugRef? drug;

  factory RefillPrescriptionItem.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RefillPrescriptionItem(id: '');
    final drugRaw = json['drug'];
    return RefillPrescriptionItem(
      id: json['id']?.toString() ?? '',
      dosage: json['dosage']?.toString(),
      frequency: json['frequency']?.toString(),
      quantityDispensed: _asInt(json['quantityDispensed']),
      quantityPrescribed: _asInt(json['quantityPrescribed']),
      instructions: json['instructions']?.toString(),
      drug: drugRaw is Map
          ? RefillPrescriptionDrugRef.fromJson(
              Map<String, dynamic>.from(drugRaw),
            )
          : null,
    );
  }
}

class RefillPrescriptionRef {
  const RefillPrescriptionRef({
    required this.id,
    this.drug,
    this.dosage,
    this.startDate,
    this.endDate,
    this.refillsAllowed,
    this.doctor,
    this.items = const [],
  });

  final String id;
  final String? drug;
  final String? dosage;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? refillsAllowed;
  final RefillDoctorRef? doctor;
  final List<RefillPrescriptionItem> items;

  RefillPrescriptionItem? get firstItem =>
      items.isNotEmpty ? items.first : null;

  bool get isExpired {
    final end = endDate;
    if (end == null) return false;
    return end.isBefore(DateTime.now());
  }

  factory RefillPrescriptionRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RefillPrescriptionRef(id: '');
    final itemsRaw = json['items'];
    final doctorRaw = json['doctor'];
    return RefillPrescriptionRef(
      id: json['id']?.toString() ?? '',
      drug: json['drug']?.toString(),
      dosage: json['dosage']?.toString(),
      startDate: _asDate(json['startDate']),
      endDate: _asDate(json['endDate']),
      refillsAllowed: _asInt(json['refillsAllowed']),
      doctor: doctorRaw is Map
          ? RefillDoctorRef.fromJson(Map<String, dynamic>.from(doctorRaw))
          : null,
      items: itemsRaw is List
          ? itemsRaw
              .whereType<Map>()
              .map(
                (e) => RefillPrescriptionItem.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
          : const [],
    );
  }
}

class RefillInvoiceItemRef {
  const RefillInvoiceItemRef({
    required this.id,
    this.invoiceId,
    this.quantity,
    this.settled = false,
    this.invoiceStatus,
  });

  final String id;
  final String? invoiceId;
  final int? quantity;
  final bool settled;
  final String? invoiceStatus;

  factory RefillInvoiceItemRef.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RefillInvoiceItemRef(id: '');
    final invoiceRaw = json['invoice'];
    final invoiceMap =
        invoiceRaw is Map ? Map<String, dynamic>.from(invoiceRaw) : null;
    return RefillInvoiceItemRef(
      id: json['id']?.toString() ?? '',
      invoiceId: json['invoiceId']?.toString() ?? invoiceMap?['id']?.toString(),
      quantity: _asInt(json['quantity']),
      settled: json['settled'] as bool? ?? false,
      invoiceStatus: invoiceMap?['status']?.toString(),
    );
  }
}

/// A patient-initiated prescription refill request row from
/// `GET /pharmacy/refill-requests`.
class PrescriptionRefillRequest {
  const PrescriptionRefillRequest({
    required this.id,
    required this.status,
    this.notes,
    this.pharmacyNotes,
    this.createdAt,
    this.patient,
    this.prescription,
    this.invoiceItem,
  });

  final String id;
  final RefillRequestStatus status;
  final String? notes;
  final String? pharmacyNotes;
  final DateTime? createdAt;
  final RefillPatientRef? patient;
  final RefillPrescriptionRef? prescription;
  final RefillInvoiceItemRef? invoiceItem;

  /// Refills remaining on the linked prescription (per doc dashboard field).
  int? get refillsRemaining => prescription?.refillsAllowed;

  /// Default dispense quantity: last dispensed, falling back to prescribed.
  int? get defaultBillQuantity {
    final item = prescription?.firstItem;
    if (item == null) return null;
    return item.quantityDispensed ?? item.quantityPrescribed;
  }

  bool get isBilled => invoiceItem != null;

  factory PrescriptionRefillRequest.fromJson(Map<String, dynamic> json) {
    final patientRaw = json['patient'];
    final prescriptionRaw = json['prescription'];
    final invoiceItemRaw = json['invoiceItem'];
    return PrescriptionRefillRequest(
      id: json['id']?.toString() ?? '',
      status: RefillRequestStatusX.fromApi(json['status']?.toString()),
      notes: json['notes']?.toString(),
      pharmacyNotes: json['pharmacyNotes']?.toString(),
      createdAt: _asDate(json['createdAt']),
      patient: patientRaw is Map
          ? RefillPatientRef.fromJson(Map<String, dynamic>.from(patientRaw))
          : null,
      prescription: prescriptionRaw is Map
          ? RefillPrescriptionRef.fromJson(
              Map<String, dynamic>.from(prescriptionRaw),
            )
          : null,
      invoiceItem: invoiceItemRaw is Map
          ? RefillInvoiceItemRef.fromJson(
              Map<String, dynamic>.from(invoiceItemRaw),
            )
          : null,
    );
  }
}

class RefillRequestListPage {
  const RefillRequestListPage({
    required this.data,
    required this.total,
    this.skip = 0,
    this.take = 20,
  });

  final List<PrescriptionRefillRequest> data;
  final int total;
  final int skip;
  final int take;
}

/// Minimal invoice summary returned by `POST /pharmacy/refill-requests/:id/bill`.
class RefillBillInvoice {
  const RefillBillInvoice({
    required this.id,
    this.invoiceDisplayId,
    this.status,
    this.totalAmount,
  });

  final String id;
  final String? invoiceDisplayId;
  final String? status;
  final double? totalAmount;

  factory RefillBillInvoice.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RefillBillInvoice(id: '');
    return RefillBillInvoice(
      id: json['id']?.toString() ?? '',
      invoiceDisplayId: json['invoiceID']?.toString(),
      status: json['status']?.toString(),
      totalAmount: tryParseApiDecimal(json['totalAmount']),
    );
  }
}

/// Response body of `POST /pharmacy/refill-requests/:id/bill`.
class RefillBillResult {
  const RefillBillResult({
    this.refillRequest,
    required this.invoice,
    this.invoiceItem,
  });

  final PrescriptionRefillRequest? refillRequest;
  final RefillBillInvoice invoice;
  final RefillInvoiceItemRef? invoiceItem;

  factory RefillBillResult.fromJson(Map<String, dynamic> json) {
    final refillRaw = json['refillRequest'];
    final invoiceRaw = json['invoice'];
    final invoiceItemRaw = json['invoiceItem'];
    return RefillBillResult(
      refillRequest: refillRaw is Map
          ? PrescriptionRefillRequest.fromJson(
              Map<String, dynamic>.from(refillRaw),
            )
          : null,
      invoice: invoiceRaw is Map
          ? RefillBillInvoice.fromJson(Map<String, dynamic>.from(invoiceRaw))
          : const RefillBillInvoice(id: ''),
      invoiceItem: invoiceItemRaw is Map
          ? RefillInvoiceItemRef.fromJson(
              Map<String, dynamic>.from(invoiceItemRaw),
            )
          : null,
    );
  }
}

int? _asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
