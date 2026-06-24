import 'package:helty/src/core/utils/api_decimal.dart';
import 'package:helty/src/models/admission_model.dart';
import 'package:helty/src/paitients/patient_model.dart';

/// Invoice summary nested under admission `billing` (clearance queue / errors).
class AdmissionBillingInvoiceSummary {
  const AdmissionBillingInvoiceSummary({
    required this.id,
    this.invoiceNumber,
    required this.status,
    required this.totalAmount,
    required this.amountPaid,
    required this.balance,
  });

  final String id;
  final String? invoiceNumber;
  final String status;
  final double totalAmount;
  final double amountPaid;
  final double balance;

  factory AdmissionBillingInvoiceSummary.fromJson(Map<String, dynamic> json) {
    return AdmissionBillingInvoiceSummary(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString(),
      status: json['status']?.toString() ?? '',
      totalAmount: parseApiDecimal(json['totalAmount']),
      amountPaid: parseApiDecimal(json['amountPaid']),
      balance: parseApiDecimal(json['balance']),
    );
  }
}

/// Billing snapshot on admissions awaiting clearance.
class AdmissionBillingSummary {
  const AdmissionBillingSummary({
    this.invoices = const [],
    required this.totalBalance,
    required this.allPaid,
  });

  final List<AdmissionBillingInvoiceSummary> invoices;
  final double totalBalance;
  final bool allPaid;

  factory AdmissionBillingSummary.fromJson(Map<String, dynamic> json) {
    final invoicesRaw = json['invoices'];
    final invoices = invoicesRaw is List
        ? invoicesRaw
              .whereType<Map>()
              .map(
                (e) => AdmissionBillingInvoiceSummary.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
        : <AdmissionBillingInvoiceSummary>[];

    return AdmissionBillingSummary(
      invoices: invoices,
      totalBalance: parseApiDecimal(json['totalBalance']),
      allPaid: json['allPaid'] == true,
    );
  }
}

/// Admission row from `GET /admissions/pending-billing-clearance`.
class PendingBillingClearanceAdmission {
  const PendingBillingClearanceAdmission({
    required this.id,
    this.admissionDate,
    this.dischargeDateTime,
    this.outcome,
    this.dischargeSummary,
    this.room,
    this.wardEntity,
    this.bed,
    this.attendingDoctor,
    this.clinicallyDischargedBy,
    required this.patient,
    required this.billing,
  });

  final String id;
  final DateTime? admissionDate;
  final DateTime? dischargeDateTime;
  final String? outcome;
  final String? dischargeSummary;
  final String? room;
  final Map<String, dynamic>? wardEntity;
  final Map<String, dynamic>? bed;
  final AttendingDoctorSummary? attendingDoctor;
  final AttendingDoctorSummary? clinicallyDischargedBy;
  final Patient patient;
  final AdmissionBillingSummary billing;

  String get wardName => wardEntity?['name']?.toString().trim() ?? '';

  String get patientDisplayName {
    final fn = patient.firstName.trim();
    final sn = patient.surname.trim();
    if (fn.isEmpty && sn.isEmpty) return patient.patientId;
    return '$fn $sn'.trim();
  }

  String get patientHospitalId => patient.patientId;

  String get attendingDoctorName =>
      attendingDoctor?.displayName.isNotEmpty == true
      ? attendingDoctor!.displayName
      : '—';

  /// First unpaid invoice, or first invoice if all paid.
  AdmissionBillingInvoiceSummary? get primaryInvoice {
    if (billing.invoices.isEmpty) return null;
    for (final inv in billing.invoices) {
      if (inv.balance > 0) return inv;
    }
    return billing.invoices.first;
  }

  factory PendingBillingClearanceAdmission.fromJson(Map<String, dynamic> json) {
    DateTime? parseDt(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    final patientRaw = json['patient'];
    final patientMap = patientRaw is Map
        ? Map<String, dynamic>.from(patientRaw)
        : <String, dynamic>{'id': json['patientId']?.toString() ?? ''};

    AttendingDoctorSummary? parseDoctor(dynamic raw) {
      if (raw is Map) {
        return AttendingDoctorSummary.fromJson(Map<String, dynamic>.from(raw));
      }
      return null;
    }

    final wardEntityRaw = json['wardEntity'];
    final bedRaw = json['bed'];

    final billingRaw = json['billing'];
    final billing = billingRaw is Map
        ? AdmissionBillingSummary.fromJson(Map<String, dynamic>.from(billingRaw))
        : const AdmissionBillingSummary(totalBalance: 0, allPaid: false);

    return PendingBillingClearanceAdmission(
      id: json['id']?.toString() ?? '',
      admissionDate: parseDt(json['admissionDate']),
      dischargeDateTime: parseDt(json['dischargeDateTime']),
      outcome: json['outcome']?.toString(),
      dischargeSummary: json['dischargeSummary']?.toString(),
      room: json['room']?.toString(),
      wardEntity: wardEntityRaw is Map
          ? Map<String, dynamic>.from(wardEntityRaw)
          : null,
      bed: bedRaw is Map ? Map<String, dynamic>.from(bedRaw) : null,
      attendingDoctor: parseDoctor(json['attendingDoctor']),
      clinicallyDischargedBy: parseDoctor(json['clinicallyDischargedBy']),
      patient: Patient.fromJson(patientMap),
      billing: billing,
    );
  }
}

/// Paginated response from `GET /admissions/pending-billing-clearance`.
class PendingBillingClearancePage {
  const PendingBillingClearancePage({
    required this.admissions,
    required this.total,
    required this.skip,
    required this.take,
  });

  final List<PendingBillingClearanceAdmission> admissions;
  final int total;
  final int skip;
  final int take;

  factory PendingBillingClearancePage.fromJson(Map<String, dynamic> json) {
    final admissionsRaw = json['admissions'];
    final admissions = admissionsRaw is List
        ? admissionsRaw
              .whereType<Map>()
              .map(
                (e) => PendingBillingClearanceAdmission.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
        : <PendingBillingClearanceAdmission>[];

    return PendingBillingClearancePage(
      admissions: admissions,
      total: (json['total'] as num?)?.toInt() ?? admissions.length,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      take: (json['take'] as num?)?.toInt() ?? admissions.length,
    );
  }
}

/// Admission lifecycle status helpers.
extension AdmissionStatusX on String {
  String get normalized => trim().toUpperCase();

  bool get isActiveAdmission {
    final s = normalized;
    return s == 'ACTIVE' || s == 'ADMITTED' || s == 'ADMITED';
  }

  bool get isPendingBillingClearance =>
      normalized == 'PENDING_BILLING_CLEARANCE';

  bool get isDischarged => normalized == 'DISCHARGED';

  bool get isDeceased => normalized == 'DECEASED';
}
