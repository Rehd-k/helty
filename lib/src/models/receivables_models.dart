import 'package:helty/src/core/utils/api_decimal.dart';

import '../helper/date.formatter.dart';

/// Receivable line from `/receivables/hmo` or `/receivables/discount`.
///
/// API may nest `policy`, `invoice`, `invoice.patient`, and `payer`. Amount fields
/// are sometimes strings; [outstandingAmount] prefers `outstandingAmount` and
/// falls back to [amount] when omitted (for display and remittance line totals).
class ReceivableItem {
  ReceivableItem({
    required this.coverageId,
    required this.payerType,
    required this.amount,
    required this.outstandingAmount,
    this.status,
    this.payerId,
    this.payerName,
    this.invoiceId,
    this.createdAt,
    this.kind,
    this.reason,
    this.mode,
    this.valueStr,
    this.policyName,
    this.policyReason,
    this.invoiceHumanId,
    this.invoiceUuid,
    this.invoiceStatus,
    this.invoiceCreatedAt,
    this.patientFirstName,
    this.patientSurname,
    this.patientPublicId,
    this.payerFirstName,
    this.payerLastName,
    this.payerStaffId,
  });

  final String coverageId;
  final String payerType;
  final double amount;
  final double outstandingAmount;
  final String? status;
  final String? payerId;
  final String? payerName;
  final String? invoiceId;
  final DateTime? createdAt;

  final String? kind;
  final String? reason;
  final String? mode;
  final String? valueStr;
  final String? policyName;
  final String? policyReason;
  final String? invoiceHumanId;
  final String? invoiceUuid;
  final String? invoiceStatus;
  final DateTime? invoiceCreatedAt;
  final String? patientFirstName;
  final String? patientSurname;
  final String? patientPublicId;
  final String? payerFirstName;
  final String? payerLastName;
  final String? payerStaffId;

  /// Prefer invoice timestamp, then top-level `createdAt`.
  DateTime? get displayCreatedAt => invoiceCreatedAt ?? createdAt;

  String? get patientDisplayName {
    final a = patientFirstName ?? '';
    final b = patientSurname ?? '';
    final n = '$a $b'.trim();
    return n.isEmpty ? null : n;
  }

  /// Short line for remittance checkboxes (policy / kind + patient + date).
  String get remittanceSummaryLine {
    final parts = <String>[];
    if (policyName != null && policyName!.trim().isNotEmpty) {
      parts.add(policyName!.trim());
    } else if (kind != null && kind!.trim().isNotEmpty) {
      var head = kind!.trim();
      if (reason != null && reason!.trim().isNotEmpty) {
        head = '$head: ${reason!.trim()}';
      }
      parts.add(head);
    }
    final pn = patientDisplayName;
    if (pn != null) parts.add(pn);
    final pid = patientPublicId?.trim();
    if (pid != null && pid.isNotEmpty) parts.add(pid);
    final dt = displayCreatedAt;
    if (dt != null) {
      parts.add(DateFormatter.dateTime(dt));
    }
    return parts.isEmpty ? coverageId : parts.join(' · ');
  }

  factory ReceivableItem.fromJson(Map<String, dynamic> json) {
    final policy = json['policy'] is Map
        ? Map<String, dynamic>.from(json['policy'] as Map)
        : null;
    final invoice = json['invoice'] is Map
        ? Map<String, dynamic>.from(json['invoice'] as Map)
        : null;
    Map<String, dynamic>? patient;
    if (invoice != null) {
      final p = invoice['patient'];
      if (p is Map) patient = Map<String, dynamic>.from(p);
    }
    final payer = json['payer'] is Map
        ? Map<String, dynamic>.from(json['payer'] as Map)
        : null;

    final amount = _asDouble(json['amount']);
    final outstandingRaw = json['outstandingAmount'];
    final outstandingAmount = outstandingRaw != null
        ? _asDouble(outstandingRaw)
        : amount;

    final payerStaffTop = _nullableString(json['payerStaffId']);
    final payerFromMap = payer != null
        ? _nullableString(payer['staffId'] ?? payer['id'])
        : null;

    return ReceivableItem(
      coverageId: (json['coverageId'] ?? json['id'] ?? '').toString().trim(),
      payerType: (json['payerType'] ?? '').toString(),
      amount: amount,
      outstandingAmount: outstandingAmount,
      status: _nullableString(json['status']),
      payerId: _nullableString(
        json['payerId'] ??
            json['payerStaffId'] ??
            json['ownerStaffId'] ??
            json['hmoId'] ??
            payerFromMap,
      ),
      payerName: _nullableString(
        json['payerName'] ?? json['hmoName'] ?? json['ownerName'],
      ),
      invoiceId: _nullableString(json['invoiceId'] ?? invoice?['id']),
      createdAt: _asDate(json['createdAt']),
      kind: _nullableString(json['kind']),
      reason: _nullableString(json['reason']),
      mode: _nullableString(json['mode']),
      valueStr: json['value'] == null
          ? null
          : json['value'].toString().trim().isEmpty
          ? null
          : json['value'].toString().trim(),
      policyName: _nullableString(policy?['name']),
      policyReason: _nullableString(policy?['reason']),
      invoiceHumanId: _nullableString(
        invoice?['invoiceID'] ?? invoice?['invoiceId'],
      ),
      invoiceUuid: _nullableString(invoice?['id']),
      invoiceStatus: _nullableString(invoice?['status']),
      invoiceCreatedAt: _asDate(invoice?['createdAt']),
      patientFirstName: _nullableString(
        patient?['firstName'] ?? patient?['first_name'],
      ),
      patientSurname: _nullableString(
        patient?['surname'] ?? patient?['lastName'] ?? patient?['last_name'],
      ),
      patientPublicId: _nullableString(
        patient?['patientId'] ?? patient?['patient_id'],
      ),
      payerFirstName: _nullableString(
        payer?['firstName'] ?? payer?['first_name'],
      ),
      payerLastName: _nullableString(
        payer?['lastName'] ?? payer?['lastName'] ?? payer?['surname'],
      ),
      payerStaffId: payerStaffTop ?? payerFromMap,
    );
  }
}

class RemittanceLinePayload {
  RemittanceLinePayload({required this.coverageId, required this.amount});

  final String coverageId;
  final double amount;

  Map<String, dynamic> toJson() => {'coverageId': coverageId, 'amount': amount};
}

class RecordRemittancePayload {
  RecordRemittancePayload({
    required this.payerType,
    this.hmoId,
    this.payerStaffId,
    required this.amount,
    this.reference,
    this.notes,
    this.paidAt,
    required this.lines,
  });

  final String payerType;
  final String? hmoId;
  final String? payerStaffId;
  final double amount;
  final String? reference;
  final String? notes;
  final DateTime? paidAt;
  final List<RemittanceLinePayload> lines;

  Map<String, dynamic> toJson() => {
    'payerType': payerType,
    if (hmoId != null && hmoId!.trim().isNotEmpty) 'hmoId': hmoId,
    if (payerStaffId != null && payerStaffId!.trim().isNotEmpty)
      'payerStaffId': payerStaffId,
    'amount': amount,
    if (reference != null && reference!.trim().isNotEmpty)
      'reference': reference,
    if (notes != null && notes!.trim().isNotEmpty) 'notes': notes,
    if (paidAt != null) 'paidAt': paidAt!.toUtc().toIso8601String(),
    'lines': lines.map((e) => e.toJson()).toList(),
  };
}

double _asDouble(dynamic value, {double fallback = 0}) =>
    parseApiDecimal(value, fallback: fallback);

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}

class HmoCoverageAnalytics {
  HmoCoverageAnalytics({
    required this.totalAmountRaw,
    required this.totalAmount,
    required this.totalCount,
    required this.data,
  });

  final String totalAmountRaw;
  final double totalAmount;
  final int totalCount;
  final List<HmoCoverageEntry> data;

  factory HmoCoverageAnalytics.fromJson(Map<String, dynamic> json) {
    final rows =
        (json['data'] as List?)?.whereType<Map>().toList() ?? const <Map>[];
    final parsed =
        rows
            .map((e) => HmoCoverageEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList()
          ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    return HmoCoverageAnalytics(
      totalAmountRaw: (json['totalAmount'] ?? '0').toString(),
      totalAmount: _asDouble(json['totalAmount']),
      totalCount: _asInt(json['totalCount']),
      data: parsed,
    );
  }
}

class HmoCoverageEntry {
  HmoCoverageEntry({
    required this.hmoId,
    required this.hmoName,
    required this.totalAmountRaw,
    required this.totalAmount,
    required this.count,
  });

  final String? hmoId;
  final String hmoName;
  final String totalAmountRaw;
  final double totalAmount;
  final int count;

  factory HmoCoverageEntry.fromJson(Map<String, dynamic> json) {
    return HmoCoverageEntry(
      hmoId: _nullableString(json['hmoId']),
      hmoName: _nullableString(json['hmoName']) ?? 'Unknown HMO',
      totalAmountRaw: (json['totalAmount'] ?? '0').toString(),
      totalAmount: _asDouble(json['totalAmount']),
      count: _asInt(json['count']),
    );
  }
}

class DiscountCoverageAnalytics {
  DiscountCoverageAnalytics({
    required this.totalAmountRaw,
    required this.totalAmount,
    required this.byReason,
    required this.byPolicy,
  });

  final String totalAmountRaw;
  final double totalAmount;
  final List<DiscountByReasonEntry> byReason;
  final List<DiscountByPolicyEntry> byPolicy;

  factory DiscountCoverageAnalytics.fromJson(Map<String, dynamic> json) {
    final reasonRows =
        (json['byReason'] as List?)?.whereType<Map>().toList() ?? const <Map>[];
    final policyRows =
        (json['byPolicy'] as List?)?.whereType<Map>().toList() ?? const <Map>[];
    return DiscountCoverageAnalytics(
      totalAmountRaw: (json['totalAmount'] ?? '0').toString(),
      totalAmount: _asDouble(json['totalAmount']),
      byReason:
          reasonRows
              .map(
                (e) => DiscountByReasonEntry.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
            ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount)),
      byPolicy:
          policyRows
              .map(
                (e) => DiscountByPolicyEntry.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
            ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount)),
    );
  }
}

class DiscountByReasonEntry {
  DiscountByReasonEntry({
    required this.reason,
    required this.totalAmountRaw,
    required this.totalAmount,
    required this.count,
  });

  final String reason;
  final String totalAmountRaw;
  final double totalAmount;
  final int count;

  factory DiscountByReasonEntry.fromJson(Map<String, dynamic> json) {
    return DiscountByReasonEntry(
      reason: _nullableString(json['reason']) ?? 'Unknown',
      totalAmountRaw: (json['totalAmount'] ?? '0').toString(),
      totalAmount: _asDouble(json['totalAmount']),
      count: _asInt(json['count']),
    );
  }
}

class DiscountByPolicyEntry {
  DiscountByPolicyEntry({
    required this.policyId,
    required this.policyName,
    required this.reason,
    required this.totalAmountRaw,
    required this.totalAmount,
    required this.count,
  });

  final String? policyId;
  final String policyName;
  final String reason;
  final String totalAmountRaw;
  final double totalAmount;
  final int count;

  factory DiscountByPolicyEntry.fromJson(Map<String, dynamic> json) {
    return DiscountByPolicyEntry(
      policyId: _nullableString(json['policyId']),
      policyName: _nullableString(json['policyName']) ?? 'Unknown Policy',
      reason: _nullableString(json['reason']) ?? 'Unknown',
      totalAmountRaw: (json['totalAmount'] ?? '0').toString(),
      totalAmount: _asDouble(json['totalAmount']),
      count: _asInt(json['count']),
    );
  }
}

class RemittanceCollectionsAnalytics {
  RemittanceCollectionsAnalytics({
    required this.totalAmountRaw,
    required this.totalAmount,
    required this.totalCount,
    required this.byPayerType,
    required this.byHmo,
    required this.byStaff,
  });

  final String totalAmountRaw;
  final double totalAmount;
  final int totalCount;
  final List<PayerTypeCollectionEntry> byPayerType;
  final List<HmoCollectionEntry> byHmo;
  final List<StaffCollectionEntry> byStaff;

  factory RemittanceCollectionsAnalytics.fromJson(Map<String, dynamic> json) {
    final payerTypeRows =
        (json['byPayerType'] as List?)?.whereType<Map>().toList() ??
        const <Map>[];
    final hmoRows =
        (json['byHmo'] as List?)?.whereType<Map>().toList() ?? const <Map>[];
    final staffRows =
        (json['byStaff'] as List?)?.whereType<Map>().toList() ?? const <Map>[];
    return RemittanceCollectionsAnalytics(
      totalAmountRaw: (json['totalAmount'] ?? '0').toString(),
      totalAmount: _asDouble(json['totalAmount']),
      totalCount: _asInt(json['totalCount']),
      byPayerType:
          payerTypeRows
              .map(
                (e) => PayerTypeCollectionEntry.fromJson(
                  Map<String, dynamic>.from(e),
                ),
              )
              .toList()
            ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount)),
      byHmo:
          hmoRows
              .map(
                (e) =>
                    HmoCollectionEntry.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
            ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount)),
      byStaff:
          staffRows
              .map(
                (e) =>
                    StaffCollectionEntry.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
            ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount)),
    );
  }
}

class PayerTypeCollectionEntry {
  PayerTypeCollectionEntry({
    required this.payerType,
    required this.totalAmountRaw,
    required this.totalAmount,
    required this.count,
  });

  final String payerType;
  final String totalAmountRaw;
  final double totalAmount;
  final int count;

  factory PayerTypeCollectionEntry.fromJson(Map<String, dynamic> json) {
    return PayerTypeCollectionEntry(
      payerType: _nullableString(json['payerType']) ?? 'Unknown',
      totalAmountRaw: (json['totalAmount'] ?? '0').toString(),
      totalAmount: _asDouble(json['totalAmount']),
      count: _asInt(json['count']),
    );
  }
}

class HmoCollectionEntry {
  HmoCollectionEntry({
    required this.hmoId,
    required this.hmoName,
    required this.totalAmountRaw,
    required this.totalAmount,
    required this.count,
  });

  final String? hmoId;
  final String hmoName;
  final String totalAmountRaw;
  final double totalAmount;
  final int count;

  factory HmoCollectionEntry.fromJson(Map<String, dynamic> json) {
    return HmoCollectionEntry(
      hmoId: _nullableString(json['hmoId']),
      hmoName: _nullableString(json['hmoName']) ?? 'Unknown HMO',
      totalAmountRaw: (json['totalAmount'] ?? '0').toString(),
      totalAmount: _asDouble(json['totalAmount']),
      count: _asInt(json['count']),
    );
  }
}

class StaffCollectionEntry {
  StaffCollectionEntry({
    required this.payerStaffId,
    required this.payerStaffName,
    required this.payerStaffCode,
    required this.totalAmountRaw,
    required this.totalAmount,
    required this.count,
  });

  final String? payerStaffId;
  final String payerStaffName;
  final String? payerStaffCode;
  final String totalAmountRaw;
  final double totalAmount;
  final int count;

  factory StaffCollectionEntry.fromJson(Map<String, dynamic> json) {
    return StaffCollectionEntry(
      payerStaffId: _nullableString(json['payerStaffId']),
      payerStaffName:
          _nullableString(json['payerStaffName']) ?? 'Unknown Staff',
      payerStaffCode: _nullableString(json['payerStaffCode']),
      totalAmountRaw: (json['totalAmount'] ?? '0').toString(),
      totalAmount: _asDouble(json['totalAmount']),
      count: _asInt(json['count']),
    );
  }
}

class PeriodComparisonMetric {
  PeriodComparisonMetric({
    required this.currentValue,
    required this.previousValue,
  }) : absoluteChange = currentValue - previousValue,
       percentageChange = previousValue == 0
           ? null
           : ((currentValue - previousValue) / previousValue) * 100;

  final double currentValue;
  final double previousValue;
  final double absoluteChange;
  final double? percentageChange;

  String get trend {
    if (absoluteChange > 0) return 'up';
    if (absoluteChange < 0) return 'down';
    return 'flat';
  }
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}
