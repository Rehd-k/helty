import 'package:helty/src/core/utils/api_decimal.dart';
import 'package:helty/src/models/admission_model.dart';
import 'package:helty/src/paitients/patient_model.dart';

const _moneyEpsilon = 0.005;

/// Invoice summary nested under admission `billing` (clearance queue / errors).
class AdmissionBillingInvoiceSummary {
  const AdmissionBillingInvoiceSummary({
    required this.id,
    this.invoiceNumber,
    required this.status,
    required this.totalAmount,
    required this.amountPaid,
    this.coveredAmount = 0,
    required this.balance,
  });

  final String id;
  final String? invoiceNumber;
  final String status;
  final double totalAmount;
  final double amountPaid;
  final double coveredAmount;
  final double balance;

  /// Doc-recommended settlement badge for a single invoice.
  String get settlementLabel {
    if (balance > _moneyEpsilon) {
      return amountPaid > _moneyEpsilon ? 'Partial' : 'Unpaid';
    }
    if (amountPaid > _moneyEpsilon && coveredAmount > _moneyEpsilon) {
      return 'Settled';
    }
    if (amountPaid > _moneyEpsilon) return 'Paid (cash)';
    if (coveredAmount > _moneyEpsilon) return 'Settled (coverage)';
    return 'Settled';
  }

  factory AdmissionBillingInvoiceSummary.fromJson(Map<String, dynamic> json) {
    return AdmissionBillingInvoiceSummary(
      id: json['id']?.toString() ?? '',
      invoiceNumber: json['invoiceNumber']?.toString(),
      status: json['status']?.toString() ?? '',
      totalAmount: parseApiDecimal(json['totalAmount']),
      amountPaid: parseApiDecimal(json['amountPaid']),
      coveredAmount: parseApiDecimal(json['coveredAmount']),
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

  double get totalAmount =>
      invoices.fold(0.0, (sum, inv) => sum + inv.totalAmount);

  double get totalAmountPaid =>
      invoices.fold(0.0, (sum, inv) => sum + inv.amountPaid);

  double get totalCoveredAmount =>
      invoices.fold(0.0, (sum, inv) => sum + inv.coveredAmount);

  bool get hasCoverage => invoices.any((inv) => inv.coveredAmount > _moneyEpsilon);

  /// Row-level clearance status for the queue UI.
  String get clearanceStatusLabel {
    if (allPaid && totalBalance <= _moneyEpsilon) return 'Ready to clear';
    if (totalBalance > _moneyEpsilon) {
      return totalAmountPaid > _moneyEpsilon ? 'Partial payment' : 'Payment required';
    }
    return 'Payment required';
  }

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
    final name = patient.displayName;
    if (name != 'Unknown') return name;
    return patient.patientId;
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
      if (inv.balance > _moneyEpsilon) return inv;
    }
    return billing.invoices.first;
  }

  String get invoiceNumbersDisplay {
    final numbers = billing.invoices
        .map((inv) => inv.invoiceNumber?.trim())
        .whereType<String>()
        .where((n) => n.isNotEmpty)
        .toList(growable: false);
    if (numbers.isEmpty) return '—';
    return numbers.join(', ');
  }

  bool get hasCoverage => billing.hasCoverage;

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

/// Paginated response from `GET /admissions/pending-nurses-clearance`.
class PendingNursesClearancePage {
  const PendingNursesClearancePage({
    required this.admissions,
    required this.total,
    required this.skip,
    required this.take,
  });

  final List<AdmissionModel> admissions;
  final int total;
  final int skip;
  final int take;

  factory PendingNursesClearancePage.fromJson(Map<String, dynamic> json) {
    final admissionsRaw = json['admissions'];
    final admissions = admissionsRaw is List
        ? admissionsRaw
              .whereType<Map>()
              .map((e) {
                final map = Map<String, dynamic>.from(e);
                // Queue payload may omit top-level patientId / status.
                final patient = map['patient'];
                if ((map['patientId'] == null ||
                        map['patientId'].toString().isEmpty) &&
                    patient is Map &&
                    patient['id'] != null) {
                  map['patientId'] = patient['id'].toString();
                }
                map['status'] ??= 'PENDING_BILLING_CLEARANCE';
                return AdmissionModel.fromJson(map);
              })
              .toList()
        : <AdmissionModel>[];

    return PendingNursesClearancePage(
      admissions: admissions,
      total: (json['total'] as num?)?.toInt() ?? admissions.length,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      take: (json['take'] as num?)?.toInt() ?? admissions.length,
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
