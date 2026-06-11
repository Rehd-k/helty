import 'package:helty/src/core/utils/api_decimal.dart';

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

/// Pending refund request summary on an invoice line (`activeRefundRequest`).
class BillingInvoiceItemActiveRefundRequest {
  BillingInvoiceItemActiveRefundRequest({
    required this.id,
    required this.status,
    required this.reason,
    this.submittedAt,
    this.requestedBy,
  });

  final String id;
  final String status;
  final String reason;
  final DateTime? submittedAt;
  final String? requestedBy;

  factory BillingInvoiceItemActiveRefundRequest.fromJson(
    Map<String, dynamic> json,
  ) {
    return BillingInvoiceItemActiveRefundRequest(
      id: _asString(json['id']),
      status: _asString(json['status'], fallback: 'pending'),
      reason: _asString(json['reason']),
      submittedAt: _asDate(json['submittedAt']),
      requestedBy: _nullableString(json['requestedBy']),
    );
  }
}

/// Historical cash refund on invoice root (`refunds[]` after approval).
class BillingInvoiceRefund {
  BillingInvoiceRefund({
    required this.id,
    required this.amount,
    this.createdAt,
    this.reason,
  });

  final String id;
  final double amount;
  final DateTime? createdAt;
  final String? reason;

  factory BillingInvoiceRefund.fromJson(Map<String, dynamic> json) {
    return BillingInvoiceRefund(
      id: _asString(json['id']),
      amount: _asDouble(json['amount'] ?? json['refundedAmount']),
      createdAt: _asDate(json['createdAt']),
      reason: _nullableString(json['reason']),
    );
  }
}

/// Full refund request row from `GET /invoices/:id/refund-requests`.
class BillingInvoiceRefundRequest {
  BillingInvoiceRefundRequest({
    required this.id,
    required this.status,
    required this.reason,
    this.invoiceItemId,
    this.lineDescription,
    this.requestedBy,
    this.submittedAt,
    this.resolvedAt,
    this.rejectReason,
  });

  final String id;
  final String status;
  final String reason;
  final String? invoiceItemId;
  final String? lineDescription;
  final String? requestedBy;
  final DateTime? submittedAt;
  final DateTime? resolvedAt;
  final String? rejectReason;

  factory BillingInvoiceRefundRequest.fromJson(Map<String, dynamic> json) {
    final itemRaw = json['invoiceItem'] ?? json['item'];
    final itemMap = itemRaw is Map
        ? Map<String, dynamic>.from(itemRaw)
        : null;
    return BillingInvoiceRefundRequest(
      id: _asString(json['id']),
      status: _asString(json['status'], fallback: 'pending'),
      reason: _asString(json['reason']),
      invoiceItemId: _nullableString(
        json['invoiceItemId'] ?? json['itemId'] ?? itemMap?['id'],
      ),
      lineDescription: _nullableString(
        json['lineDescription'] ??
            json['description'] ??
            itemMap?['description'],
      ),
      requestedBy: _nullableString(json['requestedBy']),
      submittedAt: _asDate(json['submittedAt']),
      resolvedAt: _asDate(json['resolvedAt'] ?? json['processedAt']),
      rejectReason: _nullableString(json['rejectReason'] ?? json['rejectionReason']),
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
    required this.coveredAmount,
    required this.effectivePayable,
    required this.invoiceItems,
    required this.payments,
    required this.coverages,
    this.refunds = const [],
    this.staffId,
    this.encounterId,
    this.createdAt,
    this.updatedAt,
    this.billingLink,
    this.patientHmoId,
    this.patientHmoName,
    this.patientHmoDefaultCoveragePercent,
    this.invoiceDisplayId,
    this.patientDisplayId,
  });

  final String id;
  final String patientId;

  /// Human-facing bill code (`invoiceID` from API), when present.
  final String? invoiceDisplayId;

  /// Hospital / MRN-style id from nested `patient.patientId`, when present.
  final String? patientDisplayId;
  final String status;
  final double totalAmount;
  final double amountPaid;
  final double amountDue;

  /// Patient-facing balance when discounts/insurance apply; falls back to [amountDue] if omitted.
  final double netAmountDue;
  final double coveredAmount;
  final double effectivePayable;
  final String? staffId;
  final String? encounterId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final BillingInvoiceBillingLink? billingLink;
  final String? patientHmoId;
  final String? patientHmoName;
  final double? patientHmoDefaultCoveragePercent;
  final List<BillingInvoiceItem> invoiceItems;
  final List<BillingInvoicePayment> payments;
  final List<InvoiceCoverage> coverages;
  final List<BillingInvoiceRefund> refunds;

  factory BillingInvoiceDetail.fromJson(Map<String, dynamic> json) {
    final payload = _unwrapMap(json);
    final itemsRaw = payload['invoiceItems'] ?? payload['items'];
    final paymentsRaw = payload['payments'];
    final amountDue = _asDouble(payload['amountDue']);
    final netRaw = payload['netAmountDue'];
    final netAmountDue = netRaw != null ? _asDouble(netRaw) : amountDue;
    final coveredAmount = _asDouble(payload['coveredAmount']);
    final effectivePayableRaw = payload['effectivePayable'];
    final effectivePayable = effectivePayableRaw != null
        ? _asDouble(effectivePayableRaw)
        : netAmountDue;

    BillingInvoiceBillingLink? billingLink;
    final linkRaw = payload['billingLink'];
    if (linkRaw is Map) {
      billingLink = BillingInvoiceBillingLink.fromJson(
        Map<String, dynamic>.from(linkRaw),
      );
    }
    final patientRaw = payload['patient'];
    final patientMap = patientRaw is Map<String, dynamic>
        ? patientRaw
        : (patientRaw is Map ? Map<String, dynamic>.from(patientRaw) : null);
    final patientHmoName = _patientHmoDisplayName(patientMap);
    final invoiceDisplayRaw = _nullableString(
      payload['invoiceID'] ?? payload['invoiceId'],
    );
    final patientDisplayRaw = patientMap != null
        ? _nullableString(patientMap['patientId'])
        : null;

    return BillingInvoiceDetail(
      id: _asString(payload['id']),
      patientId: _asString(payload['patientId']),
      invoiceDisplayId: invoiceDisplayRaw,
      patientDisplayId: patientDisplayRaw,
      status: _asString(payload['status'], fallback: 'PENDING'),
      totalAmount: _asDouble(payload['totalAmount']),
      amountPaid: _asDouble(payload['amountPaid']),
      amountDue: amountDue,
      netAmountDue: netAmountDue,
      coveredAmount: coveredAmount,
      effectivePayable: effectivePayable,
      staffId: _nullableString(payload['staffId']),
      encounterId: _nullableString(payload['encounterId']),
      createdAt: _asDate(payload['createdAt']),
      updatedAt: _asDate(payload['updatedAt']),
      billingLink: billingLink,
      patientHmoId: _patientHmoIdFromMap(payload, patientMap),
      patientHmoName: patientHmoName,
      patientHmoDefaultCoveragePercent: _patientHmoDefaultCoveragePercent(
        payload,
        patientMap,
      ),
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
      coverages: payload['coverages'] is List
          ? (payload['coverages'] as List)
                .whereType<Map>()
                .map(
                  (e) => InvoiceCoverage.fromJson(Map<String, dynamic>.from(e)),
                )
                .toList()
          : <InvoiceCoverage>[],
      refunds: payload['refunds'] is List
          ? (payload['refunds'] as List)
                .whereType<Map>()
                .map(
                  (e) => BillingInvoiceRefund.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
          : <BillingInvoiceRefund>[],
    );
  }
}

class InvoiceCoverage {
  InvoiceCoverage({
    required this.id,
    required this.kind,
    required this.scope,
    required this.status,
    required this.computedAmount,
    this.mode,
    this.value,
    this.percent,
    this.policyId,
    this.notes,
    this.payerType,
    this.hmoId,
    this.ownerStaffId,
    this.appliedById,
    this.appliedByName,
    this.createdAt,
  });

  final String id;
  final String kind;
  final String scope;
  final String status;
  final String? mode;
  final double? value;
  final double? percent;
  final double computedAmount;
  final String? policyId;
  final String? notes;
  final String? payerType;
  final String? hmoId;
  final String? ownerStaffId;
  final String? appliedById;
  final String? appliedByName;
  final DateTime? createdAt;

  factory InvoiceCoverage.fromJson(Map<String, dynamic> json) {
    final appliedByRaw = json['appliedBy'];
    final appliedBy = appliedByRaw is Map
        ? Map<String, dynamic>.from(appliedByRaw)
        : null;
    final staffName = _staffNameFromMap(appliedBy);
    return InvoiceCoverage(
      id: _asString(json['id']),
      kind: _asString(json['kind'], fallback: 'UNKNOWN'),
      scope: _asString(json['scope'], fallback: 'INVOICE'),
      status: _asString(json['status'], fallback: 'ACTIVE'),
      mode: _nullableString(json['mode']),
      value: json.containsKey('value') ? _asDouble(json['value']) : null,
      percent: json.containsKey('percent') ? _asDouble(json['percent']) : null,
      computedAmount: _asDouble(json['computedAmount'] ?? json['amount']),
      policyId: _nullableString(json['policyId']),
      notes: _nullableString(json['notes']),
      payerType: _nullableString(json['payerType']),
      hmoId: _nullableString(json['hmoId']),
      ownerStaffId: _nullableString(json['ownerStaffId']),
      appliedById: _nullableString(json['appliedById']),
      appliedByName: staffName.isEmpty
          ? _nullableString(json['appliedByName'])
          : staffName,
      createdAt: _asDate(json['createdAt']),
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
    required this.lineCovered,
    required this.lineEffectiveDue,
    required this.lineAmountDue,
    this.serviceName,
    this.serviceCategoryName,
    this.serviceDepartmentName,
    this.drugId,
    this.drugDisplayName,
    this.consumableId,
    this.storeLocationId,
    this.consumableDisplayName,
    this.purchaseItemId,
    this.purchasesLocationId,
    this.purchaseItemDisplayName,
    this.customDescription,
    this.refundable = false,
    this.refundPending = false,
    this.refundBlockReason,
    this.activeRefundRequest,
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

  /// Billable consumable line (`consumableId` + FIFO `storeLocationId`).
  final String? consumableId;
  final String? storeLocationId;
  final String? consumableDisplayName;

  /// Purchases catalog line (`purchaseItemId` + FIFO `purchasesLocationId`).
  final String? purchaseItemId;
  final String? purchasesLocationId;
  final String? purchaseItemDisplayName;

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
  final double lineCovered;
  final double lineEffectiveDue;

  /// Remaining due on this line for `allocate-item-payments` caps.
  final double lineAmountDue;

  final bool refundable;
  final bool refundPending;
  final String? refundBlockReason;
  final BillingInvoiceItemActiveRefundRequest? activeRefundRequest;

  /// Invoice line title for UI and payments (custom → purchase item → consumable → drug → service → id).
  String get displayLabel {
    final custom = customDescription?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    final purchase = purchaseItemDisplayName?.trim();
    if (purchase != null && purchase.isNotEmpty) return purchase;
    final cons = consumableDisplayName?.trim();
    if (cons != null && cons.isNotEmpty) return cons;
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

  bool get isConsumableLine {
    final c = consumableId?.trim() ?? '';
    if (c.isNotEmpty) return true;
    final n = consumableDisplayName?.trim() ?? '';
    return n.isNotEmpty;
  }

  bool get isPurchaseItemLine {
    final p = purchaseItemId?.trim() ?? '';
    if (p.isNotEmpty) return true;
    final n = purchaseItemDisplayName?.trim() ?? '';
    return n.isNotEmpty;
  }

  factory BillingInvoiceItem.fromJson(Map<String, dynamic> json) {
    final service = json['service'];
    final serviceMap = service is Map
        ? Map<String, dynamic>.from(service)
        : null;
    final drugRaw = json['drug'];
    final drugMap = drugRaw is Map ? Map<String, dynamic>.from(drugRaw) : null;
    final consumableRaw = json['consumable'];
    final consumableMap = consumableRaw is Map
        ? Map<String, dynamic>.from(consumableRaw)
        : null;
    final purchaseItemRaw = json['purchaseItem'];
    final purchaseItemMap = purchaseItemRaw is Map
        ? Map<String, dynamic>.from(purchaseItemRaw)
        : null;
    final category = serviceMap?['category'];
    final department = serviceMap?['department'];
    final drugDisplay = _billingDrugDisplayName(drugMap);
    final drugIdResolved = _nullableString(json['drugId'] ?? drugMap?['id']);
    final consumableIdResolved =
        _nullableString(json['consumableId'] ?? consumableMap?['id']);
    final storeLocationIdResolved = _nullableString(json['storeLocationId']);
    final consumableDisplay = consumableMap == null
        ? null
        : _nullableString(consumableMap['name'] ?? consumableMap['label']);
    final purchaseItemIdResolved =
        _nullableString(json['purchaseItemId'] ?? purchaseItemMap?['id']);
    final purchasesLocationIdResolved =
        _nullableString(json['purchasesLocationId']);
    final purchaseItemDisplay = purchaseItemMap == null
        ? null
        : _nullableString(
            purchaseItemMap['itemName'] ??
                purchaseItemMap['name'] ??
                purchaseItemMap['label'],
          );
    final segmentsRaw = json['usageSegments'];
    final quantity = _asInt(json['quantity'], fallback: 1);
    final unitPrice = _asDouble(json['unitPrice'] ?? json['priceAtTime']);
    final lineTotal = _asDouble(
      json['lineTotal'],
      fallback: unitPrice * quantity,
    );
    final lineItemAmountPaid = _asDouble(json['amountPaid']);
    final lineCovered = _asDouble(json['lineCovered']);
    final lineEffectiveDue = json.containsKey('lineEffectiveDue')
        ? _asDouble(json['lineEffectiveDue'])
        : (lineTotal - lineCovered);
    final computedDue = lineEffectiveDue - lineItemAmountPaid;
    final lineAmountDue = json.containsKey('lineAmountDue')
        ? _asDouble(json['lineAmountDue'])
        : (computedDue > 0 ? computedDue : 0.0);
    BillingInvoiceItemActiveRefundRequest? activeRefundRequest;
    final activeRaw = json['activeRefundRequest'];
    if (activeRaw is Map) {
      activeRefundRequest = BillingInvoiceItemActiveRefundRequest.fromJson(
        Map<String, dynamic>.from(activeRaw),
      );
    }
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
      consumableId: consumableIdResolved,
      storeLocationId: storeLocationIdResolved,
      consumableDisplayName: consumableDisplay,
      purchaseItemId: purchaseItemIdResolved,
      purchasesLocationId: purchasesLocationIdResolved,
      purchaseItemDisplayName: purchaseItemDisplay,
      customDescription: _nullableString(json['customDescription']),
      quantity: quantity,
      unitPrice: unitPrice,
      isRecurringDaily: _asBool(json['isRecurringDaily']),
      lineTotal: lineTotal,
      lineItemAmountPaid: lineItemAmountPaid,
      lineCovered: lineCovered,
      lineEffectiveDue: lineEffectiveDue < 0 ? 0.0 : lineEffectiveDue,
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
      refundable: _asBool(json['refundable']),
      refundPending: _asBool(json['refundPending']),
      refundBlockReason: _nullableString(json['refundBlockReason']),
      activeRefundRequest: activeRefundRequest,
    );
  }
}

bool invoiceLineEligibleForRefundRequest(BillingInvoiceItem item) =>
    item.refundable && !item.refundPending;

String? invoiceItemRefundTooltip(BillingInvoiceItem item) {
  if (item.refundPending) return 'Pending accountant approval';
  if (!item.refundable) return item.refundBlockReason;
  return null;
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
    this.method,
    this.reference,
    this.notes,
    this.receivedById,
    this.receivedByName,
    this.createdById,
    this.createdByName,
    this.paidAt,
    this.walletTransactionId,
    this.createdAt,
  });

  final String id;
  final double amount;
  final String source;
  final String? method;
  final String? reference;
  final String? notes;
  final String? receivedById;
  final String? receivedByName;
  final String? createdById;
  final String? createdByName;
  final DateTime? paidAt;
  final String? walletTransactionId;
  final DateTime? createdAt;

  factory BillingInvoicePayment.fromJson(Map<String, dynamic> json) {
    final receivedByRaw = json['receivedBy'];
    final createdByRaw = json['createdBy'];
    final receivedBy = receivedByRaw is Map
        ? Map<String, dynamic>.from(receivedByRaw)
        : null;
    final createdBy = createdByRaw is Map
        ? Map<String, dynamic>.from(createdByRaw)
        : null;
    final receivedByName = _staffNameFromMap(receivedBy);
    final createdByName = _staffNameFromMap(createdBy);
    return BillingInvoicePayment(
      id: _asString(json['id']),
      amount: _asDouble(json['amount']),
      source: _asString(json['source'], fallback: 'CASH'),
      method: _nullableString(json['method']),
      reference: _nullableString(json['reference']),
      notes: _nullableString(json['notes']),
      receivedById: _nullableString(json['receivedById']),
      receivedByName: receivedByName.isNotEmpty ? receivedByName : null,
      createdById: _nullableString(json['createdById']),
      createdByName: createdByName.isNotEmpty ? createdByName : null,
      paidAt: _asDate(json['paidAt']),
      walletTransactionId: _nullableString(json['walletTransactionId']),
      createdAt: _asDate(json['createdAt']),
    );
  }
}

String _staffNameFromMap(Map<String, dynamic>? m) {
  if (m == null) return '';
  final first = _nullableString(m['firstName']) ?? '';
  final last = _nullableString(m['lastName']) ?? '';
  final full = '$first $last'.trim();
  return full;
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
    this.consumableId,
    this.storeLocationId,
    this.purchaseItemId,
    this.purchasesLocationId,
    required this.unitPrice,
    this.quantity = 1,
    this.isRecurringDaily = false,
    this.startedAt,
  }) : assert(
          () {
            final hasSvc = serviceId?.trim().isNotEmpty ?? false;
            final hasDrug = drugId?.trim().isNotEmpty ?? false;
            final hasCons = (consumableId?.trim().isNotEmpty ?? false) &&
                (storeLocationId?.trim().isNotEmpty ?? false);
            final hasPurchase =
                (purchaseItemId?.trim().isNotEmpty ?? false) &&
                (purchasesLocationId?.trim().isNotEmpty ?? false);
            final n = (hasSvc ? 1 : 0) +
                (hasDrug ? 1 : 0) +
                (hasCons ? 1 : 0) +
                (hasPurchase ? 1 : 0);
            return n == 1;
          }(),
          'Provide exactly one of: serviceId, drugId, consumableId+storeLocationId, or purchaseItemId+purchasesLocationId',
        );

  /// Catalog service UUID (not human-readable service codes).
  final String? serviceId;
  final String? drugId;

  /// Billable consumable line (mutually exclusive with [drugId] on server).
  final String? consumableId;
  final String? storeLocationId;

  /// Purchases catalog line (mutually exclusive with other line types on server).
  final String? purchaseItemId;
  final String? purchasesLocationId;

  final double unitPrice;
  final int quantity;
  final bool isRecurringDaily;

  /// When [isRecurringDaily] is true, start of the daily usage window (no future dates).
  final DateTime? startedAt;

  Map<String, dynamic> toJson() => {
    if (serviceId?.trim().isNotEmpty ?? false) 'serviceId': serviceId,
    if (drugId?.trim().isNotEmpty ?? false) 'drugId': drugId,
    if (consumableId?.trim().isNotEmpty ?? false) 'consumableId': consumableId,
    if (storeLocationId?.trim().isNotEmpty ?? false)
      'storeLocationId': storeLocationId,
    if (purchaseItemId?.trim().isNotEmpty ?? false)
      'purchaseItemId': purchaseItemId,
    if (purchasesLocationId?.trim().isNotEmpty ?? false)
      'purchasesLocationId': purchasesLocationId,
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

/// Human-readable HMO name from nested patient payload (tolerant of API shapes).
String? _patientHmoDisplayName(Map<String, dynamic>? patient) {
  if (patient == null) return null;
  final hmo = patient['hmo'];
  if (hmo is Map<String, dynamic>) {
    final name = _nullableString(hmo['name'] ?? hmo['displayName']);
    if (name != null) return name;
  }
  final hmoProvider = patient['hmoProvider'];
  if (hmoProvider is Map<String, dynamic>) {
    final name = _nullableString(
      hmoProvider['name'] ?? hmoProvider['displayName'],
    );
    if (name != null) return name;
  }
  return _nullableString(
    patient['hmoName'] ??
        patient['hmo_name'] ??
        patient['insuranceName'] ??
        patient['insurance'],
  );
}

String? _patientHmoIdFromMap(
  Map<String, dynamic> payload,
  Map<String, dynamic>? patient,
) {
  final direct = _nullableString(payload['hmoId'] ?? patient?['hmoId']);
  if (direct != null) return direct;
  final hmo = patient?['hmo'];
  if (hmo is Map<String, dynamic>) {
    final id = _nullableString(hmo['id']);
    if (id != null) return id;
  }
  final hmoProvider = patient?['hmoProvider'];
  if (hmoProvider is Map<String, dynamic>) {
    return _nullableString(hmoProvider['id']);
  }
  return null;
}

double? _patientHmoDefaultCoveragePercent(
  Map<String, dynamic> payload,
  Map<String, dynamic>? patient,
) {
  double? read(dynamic raw) {
    if (raw == null) return null;
    final value = _asDouble(raw, fallback: -1);
    if (value < 0) return null;
    return value;
  }

  final direct = read(payload['defaultCoveragePercent']) ??
      read(payload['hmoDefaultCoveragePercent']) ??
      read(patient?['defaultCoveragePercent']) ??
      read(patient?['hmoDefaultCoveragePercent']);
  if (direct != null) return direct;

  final hmo = patient?['hmo'];
  if (hmo is Map<String, dynamic>) {
    final percent = read(hmo['defaultCoveragePercent']) ??
        read(hmo['coveragePercent']) ??
        read(hmo['percent']);
    if (percent != null) return percent;
  }

  final hmoProvider = patient?['hmoProvider'];
  if (hmoProvider is Map<String, dynamic>) {
    return read(hmoProvider['defaultCoveragePercent']) ??
        read(hmoProvider['coveragePercent']) ??
        read(hmoProvider['percent']);
  }

  return null;
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

double _asDouble(dynamic value, {double fallback = 0}) =>
    parseApiDecimal(value, fallback: fallback);

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
