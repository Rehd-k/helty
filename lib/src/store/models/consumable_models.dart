// Consumables under /store/consumables — DTOs and list params (decoupled from pharmacy).

import 'package:helty/src/store/models/store_models.dart';

/// Query for `GET /store/consumables` (aligned with common Helty list params).
class StoreConsumableListParams {
  const StoreConsumableListParams({
    this.page = 1,
    this.pageSize = 20,
    this.sortBy,
    this.sortOrder = 'desc',
    this.search,
    this.filters = const {},
  });

  final int page;
  final int pageSize;
  final String? sortBy;

  /// `asc` | `desc`
  final String sortOrder;
  final String? search;
  final Map<String, dynamic> filters;

  Map<String, dynamic> toQuery() => {
        'page': page,
        'pageSize': pageSize,
        if (sortBy != null && sortBy!.trim().isNotEmpty) 'sortBy': sortBy,
        'sortOrder': sortOrder,
        if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
        if (search != null && search!.trim().isNotEmpty) 'q': search!.trim(),
        ...filters,
      };
}

enum ConsumableUsageSource {
  nursing('NURSING'),
  encounterProcedure('ENCOUNTER_PROCEDURE');

  const ConsumableUsageSource(this.json);
  final String json;
}

enum ConsumableUsageDirection {
  use('USE'),
  return_('RETURN');

  const ConsumableUsageDirection(this.json);
  final String json;
}

/// Batch row for a consumable at a store location (`ConsumableBatch` API).
class ConsumableBatch {
  const ConsumableBatch({
    this.id,
    required this.consumableId,
    this.storeLocationId,
    this.storeLocation,
    this.batchNumber,
    this.expiryDate,
    this.quantityReceived = 0,
    this.quantityRemaining,
    this.costPrice,
    this.sellingPrice,
    this.createdAt,
  });

  final String? id;
  final String consumableId;
  final String? storeLocationId;
  final StoreLocation? storeLocation;
  final String? batchNumber;
  final DateTime? expiryDate;
  final int quantityReceived;
  final int? quantityRemaining;
  final double? costPrice;
  final double? sellingPrice;
  final DateTime? createdAt;

  factory ConsumableBatch.fromJson(Map<String, dynamic> json) {
    StoreLocation? loc;
    final locRaw = json['storeLocation'];
    if (locRaw is Map) {
      loc = StoreLocation.fromJson(Map<String, dynamic>.from(locRaw));
    }
    return ConsumableBatch(
      id: json['id']?.toString(),
      consumableId:
          json['consumableId']?.toString() ?? json['drugId']?.toString() ?? '',
      storeLocationId: json['storeLocationId']?.toString() ??
          json['toLocationId']?.toString() ??
          json['fromLocationId']?.toString(),
      storeLocation: loc,
      batchNumber: json['batchNumber']?.toString(),
      expiryDate: json['expiryDate'] != null
          ? DateTime.tryParse(json['expiryDate'].toString())
          : null,
      quantityReceived: _asInt(json['quantityReceived'], 0),
      quantityRemaining: json['quantityRemaining'] != null
          ? _asInt(json['quantityRemaining'], 0)
          : null,
      costPrice: _asDoubleOrNull(json['costPrice']),
      sellingPrice: _asDoubleOrNull(json['sellingPrice']),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toCreateBody() => {
        if (storeLocationId != null && storeLocationId!.trim().isNotEmpty)
          'storeLocationId': storeLocationId,
        'quantityReceived': quantityReceived,
        if (quantityRemaining != null) 'quantityRemaining': quantityRemaining,
        if (costPrice != null) 'costPrice': costPrice,
        if (sellingPrice != null) 'sellingPrice': sellingPrice,
        if (batchNumber != null && batchNumber!.trim().isNotEmpty)
          'batchNumber': batchNumber,
        if (expiryDate != null) 'expiryDate': expiryDate!.toIso8601String(),
      };
}

int _asInt(dynamic v, int d) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v?.toString() ?? '') ?? d;
}

double? _asDoubleOrNull(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toDouble();
  return double.tryParse(v.toString());
}

class RecordConsumableUsageDto {
  const RecordConsumableUsageDto({
    required this.consumableId,
    required this.storeLocationId,
    required this.patientId,
    this.encounterId,
    this.admissionId,
    required this.source,
    required this.quantity,
  });

  final String consumableId;
  final String storeLocationId;
  final String patientId;
  final String? encounterId;
  final String? admissionId;
  final ConsumableUsageSource source;
  final int quantity;

  Map<String, dynamic> toJson() => {
        'consumableId': consumableId,
        'storeLocationId': storeLocationId,
        'patientId': patientId,
        if (encounterId != null && encounterId!.trim().isNotEmpty)
          'encounterId': encounterId,
        if (admissionId != null && admissionId!.trim().isNotEmpty)
          'admissionId': admissionId,
        'source': source.json,
        'quantity': quantity,
      };
}

class ConsumableUsageEvent {
  const ConsumableUsageEvent({
    required this.id,
    required this.direction,
    required this.source,
    required this.quantity,
    this.consumableId,
    this.patientId,
    this.encounterId,
    this.admissionId,
    this.reversalOfId,
    this.createdAt,
  });

  final String id;
  final ConsumableUsageDirection direction;
  final ConsumableUsageSource source;
  final int quantity;
  final String? consumableId;
  final String? patientId;
  final String? encounterId;
  final String? admissionId;
  final String? reversalOfId;
  final DateTime? createdAt;

  factory ConsumableUsageEvent.fromJson(Map<String, dynamic> json) {
    return ConsumableUsageEvent(
      id: json['id']?.toString() ?? '',
      direction: _parseDirection(json['direction']),
      source: _parseSource(json['source']),
      quantity: _asInt(json['quantity'], 0),
      consumableId: json['consumableId']?.toString(),
      patientId: json['patientId']?.toString(),
      encounterId: json['encounterId']?.toString(),
      admissionId: json['admissionId']?.toString(),
      reversalOfId: json['reversalOfId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }
}

ConsumableUsageDirection _parseDirection(dynamic v) {
  final s = v?.toString().toUpperCase() ?? 'USE';
  return ConsumableUsageDirection.values.firstWhere(
    (e) => e.json == s,
    orElse: () => ConsumableUsageDirection.use,
  );
}

ConsumableUsageSource _parseSource(dynamic v) {
  final s = v?.toString().toUpperCase() ?? '';
  return ConsumableUsageSource.values.firstWhere(
    (e) => e.json == s,
    orElse: () => ConsumableUsageSource.nursing,
  );
}

/// Single movement row in usage history (shape may vary by backend).
class ConsumableStockMovementRow {
  const ConsumableStockMovementRow({
    required this.raw,
  });

  final Map<String, dynamic> raw;

  factory ConsumableStockMovementRow.fromJson(Map<String, dynamic> json) =>
      ConsumableStockMovementRow(raw: Map<String, dynamic>.from(json));
}

class ConsumableUsageHistoryResponse {
  const ConsumableUsageHistoryResponse({
    required this.usageEvents,
    required this.stockMovements,
    required this.total,
    required this.skip,
    required this.take,
  });

  final List<ConsumableUsageEvent> usageEvents;
  final List<ConsumableStockMovementRow> stockMovements;
  final int total;
  final int skip;
  final int take;

  factory ConsumableUsageHistoryResponse.fromJson(Map<String, dynamic> json) {
    final ue = json['usageEvents'] ?? json['usage_events'];
    final sm = json['stockMovements'] ?? json['stock_movements'];
    return ConsumableUsageHistoryResponse(
      usageEvents: ue is List
          ? ue
              .whereType<Map>()
              .map((e) => ConsumableUsageEvent.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
      stockMovements: sm is List
          ? sm
              .whereType<Map>()
              .map((e) => ConsumableStockMovementRow.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList()
          : const [],
      total: _asInt(json['total'], 0),
      skip: _asInt(json['skip'], 0),
      take: _asInt(json['take'] ?? json['limit'], 20),
    );
  }
}

/// Paginated list row for `GET /invoice-consumables` (invoice summary).
class InvoiceWithConsumableLines {
  const InvoiceWithConsumableLines({
    required this.id,
    this.patientId,
    this.status,
    this.createdAt,
    this.raw,
  });

  final String id;
  final String? patientId;
  final String? status;
  final DateTime? createdAt;
  final Map<String, dynamic>? raw;

  factory InvoiceWithConsumableLines.fromJson(Map<String, dynamic> json) {
    return InvoiceWithConsumableLines(
      id: json['id']?.toString() ?? '',
      patientId: json['patientId']?.toString(),
      status: json['status']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      raw: Map<String, dynamic>.from(json),
    );
  }
}
