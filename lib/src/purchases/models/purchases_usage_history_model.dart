import 'package:helty/src/core/utils/api_decimal.dart';

import '../../pharmacy/models/pharmacy_model.dart';

class PurchaseUsageHistoryQuery {
  const PurchaseUsageHistoryQuery({
    required this.fromDate,
    required this.toDate,
    this.purchaseItemId,
    this.purchasesLocationId,
    this.patientQuery,
    this.skip = 0,
    this.take = 20,
  });

  final DateTime fromDate;
  final DateTime toDate;
  final String? purchaseItemId;
  final String? purchasesLocationId;
  final String? patientQuery;
  final int skip;
  final int take;

  Map<String, dynamic> toQuery() => {
    'fromDate': fromDate.toUtc().toIso8601String(),
    'toDate': toDate.toUtc().toIso8601String(),
    if (purchaseItemId != null && purchaseItemId!.trim().isNotEmpty)
      'purchaseItemId': purchaseItemId!.trim(),
    if (purchasesLocationId != null && purchasesLocationId!.trim().isNotEmpty)
      'purchasesLocationId': purchasesLocationId!.trim(),
    if (patientQuery != null && patientQuery!.trim().isNotEmpty)
      'patientQuery': patientQuery!.trim(),
    'skip': skip,
    'take': take,
  };
}

class PurchaseUsageHistoryCatalogItem {
  const PurchaseUsageHistoryCatalogItem({
    required this.id,
    required this.name,
    this.sku,
  });

  final String id;
  final String name;
  final String? sku;

  factory PurchaseUsageHistoryCatalogItem.fromJson(Map<String, dynamic> json) {
    final name =
        json['name']?.toString().trim() ??
        json['itemName']?.toString().trim() ??
        '';
    return PurchaseUsageHistoryCatalogItem(
      id: json['id']?.toString() ?? '',
      name: name.isNotEmpty ? name : 'Unknown item',
      sku: json['sku']?.toString(),
    );
  }
}

class PurchaseUsageHistoryItem {
  const PurchaseUsageHistoryItem({
    required this.invoiceItemId,
    required this.invoiceUUID,
    required this.invoiceId,
    required this.issuedAt,
    required this.encounterId,
    required this.quantity,
    required this.unitPrice,
    required this.amountPaid,
    required this.purchaseItem,
    required this.patient,
    this.issuedBy,
    this.purchasesLocation,
  });

  final String invoiceItemId;
  final String invoiceUUID;
  final String invoiceId;
  final DateTime? issuedAt;
  final String encounterId;
  final int quantity;
  final double unitPrice;
  final double amountPaid;
  final PurchaseUsageHistoryCatalogItem purchaseItem;
  final DispenseHistoryPatient patient;
  final DispenseAuditStaff? issuedBy;
  final DispenseAuditLocation? purchasesLocation;

  factory PurchaseUsageHistoryItem.fromJson(Map<String, dynamic> json) =>
      PurchaseUsageHistoryItem(
        invoiceItemId: json['invoiceItemId']?.toString() ?? '',
        invoiceId: json['invoiceId']?.toString() ?? '',
        invoiceUUID: json['invoiceUUID']?.toString() ?? '',
        issuedAt: json['issuedAt'] == null
            ? null
            : DateTime.tryParse(json['issuedAt'].toString()),
        encounterId: json['encounterId']?.toString() ?? '',
        quantity: () {
          final v = json['quantity'];
          if (v is int) return v;
          if (v is num) return v.toInt();
          return int.tryParse(v?.toString() ?? '') ?? 0;
        }(),
        unitPrice: parseApiDecimal(json['unitPrice']),
        amountPaid: parseApiDecimal(json['amountPaid']),
        purchaseItem: PurchaseUsageHistoryCatalogItem.fromJson(
          Map<String, dynamic>.from(
            (json['purchaseItem'] as Map?) ?? const {},
          ),
        ),
        patient: DispenseHistoryPatient.fromJson(
          Map<String, dynamic>.from((json['patient'] as Map?) ?? const {}),
        ),
        issuedBy: json['issuedBy'] is Map
            ? DispenseAuditStaff.fromJson(
                Map<String, dynamic>.from(json['issuedBy'] as Map),
              )
            : null,
        purchasesLocation: json['purchasesLocation'] is Map
            ? DispenseAuditLocation.fromJson(
                Map<String, dynamic>.from(json['purchasesLocation'] as Map),
              )
            : null,
      );
}

/// Body for `POST /invoice-purchases/:invoiceId/items/:itemId/return`.
class ReturnPurchaseInvoiceItemDto {
  const ReturnPurchaseInvoiceItemDto({required this.quantity, this.reason});

  final int quantity;
  final String? reason;

  Map<String, dynamic> toJson() => {
    'quantity': quantity,
    if (reason != null && reason!.trim().isNotEmpty) 'reason': reason!.trim(),
  };
}

class ReturnPurchaseInvoiceItemResult {
  const ReturnPurchaseInvoiceItemResult({
    required this.returnId,
    required this.fullLineRemoved,
    this.invoice,
  });

  final String returnId;
  final bool fullLineRemoved;
  final Map<String, dynamic>? invoice;

  factory ReturnPurchaseInvoiceItemResult.fromJson(Map<String, dynamic> json) =>
      ReturnPurchaseInvoiceItemResult(
        returnId: json['returnId']?.toString() ?? '',
        fullLineRemoved: json['fullLineRemoved'] == true,
        invoice: json['invoice'] is Map
            ? Map<String, dynamic>.from(json['invoice'] as Map)
            : null,
      );
}
