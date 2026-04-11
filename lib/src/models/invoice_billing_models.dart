/// When the invoice is linked to a single active billing transaction (`billingLink` on API).
class BillingInvoiceBillingLink {
  BillingInvoiceBillingLink({
    this.linkedTransactionId,
    this.discountAmount = 0,
    this.insuranceCovered = 0,
  });

  final String? linkedTransactionId;
  final double discountAmount;
  final double insuranceCovered;

  factory BillingInvoiceBillingLink.fromJson(Map<String, dynamic> json) {
    return BillingInvoiceBillingLink(
      linkedTransactionId: _nullableString(json['linkedTransactionId']),
      discountAmount: _asDouble(json['discountAmount']),
      insuranceCovered: _asDouble(json['insuranceCovered']),
    );
  }
}

class BillingInvoiceDetail {
  BillingInvoiceDetail({
    required this.id,
    required this.patientId,
    required this.status,
    required this.totalAmount,
    required this.amountPaid,
    required this.amountDue,
    required this.netAmountDue,
    required this.invoiceItems,
    required this.payments,
    this.staffId,
    this.encounterId,
    this.createdAt,
    this.updatedAt,
    this.billingLink,
  });

  final String id;
  final String patientId;
  final String status;
  final double totalAmount;
  final double amountPaid;
  final double amountDue;

  /// Patient-facing balance when discounts/insurance apply; falls back to [amountDue] if omitted.
  final double netAmountDue;
  final String? staffId;
  final String? encounterId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final BillingInvoiceBillingLink? billingLink;
  final List<BillingInvoiceItem> invoiceItems;
  final List<BillingInvoicePayment> payments;

  factory BillingInvoiceDetail.fromJson(Map<String, dynamic> json) {
    final payload = _unwrapMap(json);
    final itemsRaw = payload['invoiceItems'] ?? payload['items'];
    final paymentsRaw = payload['payments'];
    final amountDue = _asDouble(payload['amountDue']);
    final netRaw = payload['netAmountDue'];
    final netAmountDue = netRaw != null
        ? _asDouble(netRaw)
        : amountDue;

    BillingInvoiceBillingLink? billingLink;
    final linkRaw = payload['billingLink'];
    if (linkRaw is Map) {
      billingLink = BillingInvoiceBillingLink.fromJson(
        Map<String, dynamic>.from(linkRaw),
      );
    }

    return BillingInvoiceDetail(
      id: _asString(payload['id']),
      patientId: _asString(payload['patientId']),
      status: _asString(payload['status'], fallback: 'PENDING'),
      totalAmount: _asDouble(payload['totalAmount']),
      amountPaid: _asDouble(payload['amountPaid']),
      amountDue: amountDue,
      netAmountDue: netAmountDue,
      staffId: _nullableString(payload['staffId']),
      encounterId: _nullableString(payload['encounterId']),
      createdAt: _asDate(payload['createdAt']),
      updatedAt: _asDate(payload['updatedAt']),
      billingLink: billingLink,
      invoiceItems: itemsRaw is List
          ? itemsRaw
                .whereType<Map>()
                .map(
                  (e) =>
                      BillingInvoiceItem.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : <BillingInvoiceItem>[],
      payments: paymentsRaw is List
          ? paymentsRaw
                .whereType<Map>()
                .map(
                  (e) => BillingInvoicePayment.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : <BillingInvoicePayment>[],
    );
  }
}

/// Matches pharmacy queue / invoice line display rules for nested `drug`.
String? _billingDrugDisplayName(Map<String, dynamic>? drug) {
  if (drug == null) return null;
  final generic = drug['genericName']?.toString().trim() ?? '';
  final brand = drug['brandName']?.toString().trim() ?? '';
  if (generic.isNotEmpty && brand.isNotEmpty && generic != brand) {
    return '$generic ($brand)';
  }
  final s = generic.isNotEmpty ? generic : brand;
  return s.isEmpty ? null : s;
}

class BillingInvoiceItem {
  BillingInvoiceItem({
    required this.id,
    required this.serviceId,
    required this.quantity,
    required this.unitPrice,
    required this.isRecurringDaily,
    required this.usageSegments,
    required this.lineTotal,
    required this.lineItemAmountPaid,
    required this.lineAmountDue,
    this.serviceName,
    this.serviceCategoryName,
    this.serviceDepartmentName,
    this.drugId,
    this.drugDisplayName,
    this.customDescription,
  });

  final String id;
  final String serviceId;
  final String? serviceName;

  /// From nested `service.category.name` when present (used for lab vs other grouping).
  final String? serviceCategoryName;

  /// From nested `service.department.name` when present.
  final String? serviceDepartmentName;

  /// Catalog drug id when this line is a medication (`drugId` or nested `drug.id`).
  final String? drugId;

  /// Human-readable drug label from nested `drug` (generic / brand).
  final String? drugDisplayName;

  /// Optional free-text line description from API.
  final String? customDescription;

  final int quantity;
  final double unitPrice;
  final bool isRecurringDaily;
  final List<BillingUsageSegment> usageSegments;

  /// Server: line total (legacy invoices may omit; derived from unit × qty).
  final double lineTotal;

  /// Allocated payments on this line only (`GET /invoices/:id` → `amountPaid` on item).
  final double lineItemAmountPaid;

  /// Remaining due on this line for `allocate-item-payments` caps.
  final double lineAmountDue;

  /// Invoice line title for UI and payments (custom → drug → service → id).
  String get displayLabel {
    final custom = customDescription?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final drug = drugDisplayName?.trim();
    if (drug != null && drug.isNotEmpty) return drug;
    final svc = serviceName?.trim();
    if (svc != null && svc.isNotEmpty) return svc;
    final sid = serviceId.trim();
    if (sid.isNotEmpty) return sid;
    return 'Line item';
  }

  bool get isDrugLine {
    final d = drugId?.trim() ?? '';
    if (d.isNotEmpty) return true;
    final name = drugDisplayName?.trim() ?? '';
    return name.isNotEmpty;
  }

  factory BillingInvoiceItem.fromJson(Map<String, dynamic> json) {
    final service = json['service'];
    final serviceMap = service is Map
        ? Map<String, dynamic>.from(service)
        : null;
    final drugRaw = json['drug'];
    final drugMap = drugRaw is Map
        ? Map<String, dynamic>.from(drugRaw)
        : null;
    final category = serviceMap?['category'];
    final department = serviceMap?['department'];
    final drugDisplay = _billingDrugDisplayName(drugMap);
    final drugIdResolved = _nullableString(json['drugId'] ?? drugMap?['id']);
    final segmentsRaw = json['usageSegments'];
    final quantity = _asInt(json['quantity'], fallback: 1);
    final unitPrice = _asDouble(json['unitPrice'] ?? json['priceAtTime']);
    final lineTotal = _asDouble(
      json['lineTotal'],
      fallback: unitPrice * quantity,
    );
    final lineItemAmountPaid = _asDouble(json['amountPaid']);
    final computedDue = lineTotal - lineItemAmountPaid;
    final lineAmountDue = json.containsKey('lineAmountDue')
        ? _asDouble(json['lineAmountDue'])
        : (computedDue > 0 ? computedDue : 0.0);
    return BillingInvoiceItem(
      id: _asString(json['id']),
      serviceId: _asString(json['serviceId'] ?? serviceMap?['id']),
      serviceName: _nullableString(serviceMap?['name'] ?? json['name']),
      serviceCategoryName: category is Map
          ? _nullableString(category['name'])
          : null,
      serviceDepartmentName: department is Map
          ? _nullableString(department['name'])
          : null,
      drugId: drugIdResolved,
      drugDisplayName: drugDisplay,
      customDescription: _nullableString(json['customDescription']),
      quantity: quantity,
      unitPrice: unitPrice,
      isRecurringDaily: _asBool(json['isRecurringDaily']),
      lineTotal: lineTotal,
      lineItemAmountPaid: lineItemAmountPaid,
      lineAmountDue: lineAmountDue < 0 ? 0.0 : lineAmountDue,
      usageSegments: segmentsRaw is List
          ? segmentsRaw
                .whereType<Map>()
                .map(
                  (e) => BillingUsageSegment.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : <BillingUsageSegment>[],
    );
  }
}

class BillingUsageSegment {
  BillingUsageSegment({required this.id, required this.startAt, this.endAt});

  final String id;
  final DateTime? startAt;
  final DateTime? endAt;

  bool get isActive => endAt == null;

  factory BillingUsageSegment.fromJson(Map<String, dynamic> json) {
    return BillingUsageSegment(
      id: _asString(json['id']),
      startAt: _asDate(json['startAt']),
      endAt: _asDate(json['endAt']),
    );
  }
}

class BillingInvoicePayment {
  BillingInvoicePayment({
    required this.id,
    required this.amount,
    required this.source,
    this.reference,
    this.createdAt,
  });

  final String id;
  final double amount;
  final String source;
  final String? reference;
  final DateTime? createdAt;

  factory BillingInvoicePayment.fromJson(Map<String, dynamic> json) {
    return BillingInvoicePayment(
      id: _asString(json['id']),
      amount: _asDouble(json['amount']),
      source: _asString(json['source'], fallback: 'CASH'),
      reference: _nullableString(json['reference']),
      createdAt: _asDate(json['createdAt']),
    );
  }
}

class BillingWallet {
  BillingWallet({
    required this.id,
    required this.patientId,
    required this.balance,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String patientId;
  final double balance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory BillingWallet.fromJson(Map<String, dynamic> json) {
    final payload = _unwrapMap(json);
    return BillingWallet(
      id: _asString(payload['id']),
      patientId: _asString(payload['patientId']),
      balance: _asDouble(payload['balance']),
      createdAt: _asDate(payload['createdAt']),
      updatedAt: _asDate(payload['updatedAt']),
    );
  }
}

class BillingWalletTransaction {
  BillingWalletTransaction({
    required this.id,
    required this.walletId,
    required this.type,
    required this.amount,
    this.reference,
    this.invoiceId,
    this.createdAt,
  });

  final String id;
  final String walletId;
  final String type;
  final double amount;
  final String? reference;
  final String? invoiceId;
  final DateTime? createdAt;

  factory BillingWalletTransaction.fromJson(Map<String, dynamic> json) {
    return BillingWalletTransaction(
      id: _asString(json['id']),
      walletId: _asString(json['walletId']),
      type: _asString(json['type'], fallback: 'DEBIT'),
      amount: _asDouble(json['amount']),
      reference: _nullableString(json['reference']),
      invoiceId: _nullableString(json['invoiceId']),
      createdAt: _asDate(json['createdAt']),
    );
  }
}

class AddInvoiceItemPayload {
  AddInvoiceItemPayload({
    this.serviceId,
    this.drugId,
    required this.unitPrice,
    this.quantity = 1,
    this.isRecurringDaily = false,
    this.startedAt,
  }) : assert(
         (serviceId?.trim().isNotEmpty ?? false) ||
             (drugId?.trim().isNotEmpty ?? false),
         'Provide serviceId or drugId',
       );

  /// Catalog service UUID (not human-readable service codes).
  final String? serviceId;
  final String? drugId;
  final double unitPrice;
  final int quantity;
  final bool isRecurringDaily;

  /// When [isRecurringDaily] is true, start of the daily usage window (no future dates).
  final DateTime? startedAt;

  Map<String, dynamic> toJson() => {
    if (serviceId?.trim().isNotEmpty ?? false) 'serviceId': serviceId,
    if (drugId?.trim().isNotEmpty ?? false) 'drugId': drugId,
    'unitPrice': unitPrice,
    'quantity': quantity,
    'isRecurringDaily': isRecurringDaily,
    if (startedAt != null)
      'recurringSegmentStartAt': startedAt!.toUtc().toIso8601String(),
  };
}

/// Caller intent for [PayBill] line-item checkout (maps to allocate-item-payments).
class InvoiceItemAllocationInput {
  const InvoiceItemAllocationInput({
    required this.invoiceItemId,
    required this.amount,
  });

  final String invoiceItemId;
  final double amount;
}

/// Single line allocation in `POST /invoices/:id/allocate-item-payments`.
class InvoiceItemAllocationDto {
  InvoiceItemAllocationDto({required this.invoiceItemId, required this.amount});

  final String invoiceItemId;
  final double amount;

  Map<String, dynamic> toJson() => {
    'invoiceItemId': invoiceItemId,
    'amount': amount,
  };
}

/// Request body for allocate-item-payments (`TransactionPaymentMethod` on server).
class AllocateInvoiceItemPaymentsPayload {
  AllocateInvoiceItemPaymentsPayload({
    required this.staffId,
    required this.amount,
    required this.method,
    required this.allocations,
    this.reference,
    this.notes,
    this.bankAccountNumber,
    this.billingTransactionId,
  });

  final String staffId;
  final double amount;
  final String method;
  final List<InvoiceItemAllocationDto> allocations;
  final String? reference;
  final String? notes;
  final String? bankAccountNumber;
  final String? billingTransactionId;

  Map<String, dynamic> toJson() => {
    'staffId': staffId,
    'amount': amount,
    'method': method,
    'allocations': allocations.map((e) => e.toJson()).toList(),
    if (reference != null && reference!.isNotEmpty) 'reference': reference,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
    if (bankAccountNumber != null && bankAccountNumber!.trim().isNotEmpty)
      'bankAccountNumber': bankAccountNumber,
    if (billingTransactionId != null && billingTransactionId!.trim().isNotEmpty)
      'billingTransactionId': billingTransactionId,
  };
}

class RecordPaymentPayload {
  RecordPaymentPayload({
    required this.amount,
    required this.source,
    this.method,
    this.reference,
    this.notes,
    this.bankAccountNumber,
  });

  final double amount;
  final String source;
  final String? method;
  final String? reference;
  final String? notes;
  final String? bankAccountNumber;

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'source': source,
    if (method != null && method!.trim().isNotEmpty) 'method': method,
    if (reference != null && reference!.isNotEmpty) 'reference': reference,
    if (notes != null) 'notes': notes,
    if (bankAccountNumber != null && bankAccountNumber!.trim().isNotEmpty)
      'bankAccountNumber': bankAccountNumber,
  };
}

class WalletDepositPayload {
  WalletDepositPayload({required this.amount, this.reference, this.staffId});

  final double amount;
  final String? reference;
  final String? staffId;

  Map<String, dynamic> toJson() => {
    'amount': amount,
    if (reference != null && reference!.isNotEmpty) 'reference': reference,
    if (staffId != null && staffId!.trim().isNotEmpty) 'staffId': staffId,
  };
}

class DischargeAdmissionPayload {
  DischargeAdmissionPayload({required this.dischargeDate});

  final DateTime dischargeDate;

  Map<String, dynamic> toJson() => {
    'dischargeDate': dischargeDate.toUtc().toIso8601String(),
  };
}

Map<String, dynamic> _unwrapMap(Map<String, dynamic> json) {
  final nested = json['data'] ?? json['result'] ?? json['invoice'] ?? json;
  if (nested is Map<String, dynamic>) return nested;
  return json;
}

String _asString(dynamic value, {String fallback = ''}) =>
    value == null ? fallback : value.toString();

String? _nullableString(dynamic value) {
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty ? null : text;
}

double _asDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

int _asInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return fallback;
}

DateTime? _asDate(dynamic value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
