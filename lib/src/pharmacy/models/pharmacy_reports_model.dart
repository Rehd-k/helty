import 'package:helty/src/core/utils/api_decimal.dart';

/// Executive KPI summary for the head of pharmacy.
/// Backed by `GET /pharmacy/dashboard/head-summary`.
class PharmacyHeadSummary {
  const PharmacyHeadSummary({
    required this.totalSales,
    required this.totalQuantitySold,
    required this.totalCogs,
    required this.grossProfit,
    required this.grossMarginPercent,
    required this.netCollections,
    required this.transactionCount,
    required this.avgSellingPrice,
    required this.avgProfitPerTransaction,
    required this.inventoryValueAtCost,
    required this.inventoryValueAtSellingPrice,
    required this.nearExpiryValueAtCost,
    required this.expiredValueAtCost,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.profitUnknownCount,
  });

  final double totalSales;
  final int totalQuantitySold;
  final double totalCogs;
  final double grossProfit;
  final double grossMarginPercent;
  final double netCollections;
  final int transactionCount;
  final double avgSellingPrice;
  final double avgProfitPerTransaction;
  final double inventoryValueAtCost;
  final double inventoryValueAtSellingPrice;
  final double nearExpiryValueAtCost;
  final double expiredValueAtCost;
  final int lowStockCount;
  final int outOfStockCount;
  final int profitUnknownCount;

  static const empty = PharmacyHeadSummary(
    totalSales: 0,
    totalQuantitySold: 0,
    totalCogs: 0,
    grossProfit: 0,
    grossMarginPercent: 0,
    netCollections: 0,
    transactionCount: 0,
    avgSellingPrice: 0,
    avgProfitPerTransaction: 0,
    inventoryValueAtCost: 0,
    inventoryValueAtSellingPrice: 0,
    nearExpiryValueAtCost: 0,
    expiredValueAtCost: 0,
    lowStockCount: 0,
    outOfStockCount: 0,
    profitUnknownCount: 0,
  );

  factory PharmacyHeadSummary.fromJson(Map<String, dynamic> json) {
    return PharmacyHeadSummary(
      totalSales: _toDouble(json['totalSales']),
      totalQuantitySold: _toInt(json['totalQuantitySold']),
      totalCogs: _toDouble(json['totalCogs']),
      grossProfit: _toDouble(json['grossProfit']),
      grossMarginPercent: _toDouble(json['grossMarginPercent']),
      netCollections: _toDouble(json['netCollections']),
      transactionCount: _toInt(json['transactionCount']),
      avgSellingPrice: _toDouble(json['avgSellingPrice']),
      avgProfitPerTransaction: _toDouble(json['avgProfitPerTransaction']),
      inventoryValueAtCost: _toDouble(json['inventoryValueAtCost']),
      inventoryValueAtSellingPrice: _toDouble(
        json['inventoryValueAtSellingPrice'],
      ),
      nearExpiryValueAtCost: _toDouble(json['nearExpiryValueAtCost']),
      expiredValueAtCost: _toDouble(json['expiredValueAtCost']),
      lowStockCount: _toInt(json['lowStockCount']),
      outOfStockCount: _toInt(json['outOfStockCount']),
      profitUnknownCount: _toInt(json['profitUnknownCount']),
    );
  }
}

/// A single bucket in the sales/profit time series.
/// Backed by `GET /pharmacy/dashboard/charts/sales-profit`.
class PharmacySalesProfitPoint {
  const PharmacySalesProfitPoint({
    required this.label,
    required this.grossSales,
    required this.cogs,
    required this.grossProfit,
    required this.quantitySold,
  });

  final String label;
  final double grossSales;
  final double cogs;
  final double grossProfit;
  final int quantitySold;

  factory PharmacySalesProfitPoint.fromJson(Map<String, dynamic> json) {
    return PharmacySalesProfitPoint(
      label: json['label']?.toString() ?? json['date']?.toString() ?? '',
      grossSales: _toDouble(json['grossSales']),
      cogs: _toDouble(json['cogs']),
      grossProfit: _toDouble(json['grossProfit']),
      quantitySold: _toInt(json['quantitySold']),
    );
  }
}

/// Bundle returned by the head dashboard service (summary + trend).
class PharmacyHeadDashboardData {
  const PharmacyHeadDashboardData({
    required this.summary,
    required this.salesProfitTrend,
    required this.storeValuations,
  });

  final PharmacyHeadSummary summary;
  final List<PharmacySalesProfitPoint> salesProfitTrend;
  final List<PharmacyInventoryStoreValuation> storeValuations;
}

/// Totals row for a grouped sales breakdown.
class PharmacySalesBreakdownTotals {
  const PharmacySalesBreakdownTotals({
    required this.quantitySold,
    required this.grossSales,
    required this.cogs,
    required this.grossProfit,
    required this.marginPercent,
    required this.transactionCount,
  });

  final int quantitySold;
  final double grossSales;
  final double cogs;
  final double grossProfit;
  final double marginPercent;
  final int transactionCount;

  static const empty = PharmacySalesBreakdownTotals(
    quantitySold: 0,
    grossSales: 0,
    cogs: 0,
    grossProfit: 0,
    marginPercent: 0,
    transactionCount: 0,
  );

  factory PharmacySalesBreakdownTotals.fromJson(Map<String, dynamic> json) {
    return PharmacySalesBreakdownTotals(
      quantitySold: _toInt(json['quantitySold']),
      grossSales: _toDouble(json['grossSales']),
      cogs: _toDouble(json['cogs']),
      grossProfit: _toDouble(json['grossProfit']),
      marginPercent: _toDouble(json['marginPercent']),
      transactionCount: _toInt(json['transactionCount']),
    );
  }
}

/// A grouped sales breakdown row (by drug, class, payer, or dispensary).
class PharmacySalesBreakdownRow {
  const PharmacySalesBreakdownRow({
    required this.groupKey,
    required this.groupLabel,
    required this.quantitySold,
    required this.grossSales,
    required this.cogs,
    required this.grossProfit,
    required this.marginPercent,
    required this.transactionCount,
    required this.percentOfTotalSales,
  });

  final String groupKey;
  final String groupLabel;
  final int quantitySold;
  final double grossSales;
  final double cogs;
  final double grossProfit;
  final double marginPercent;
  final int transactionCount;
  final double percentOfTotalSales;

  factory PharmacySalesBreakdownRow.fromJson(Map<String, dynamic> json) {
    return PharmacySalesBreakdownRow(
      groupKey: json['groupKey']?.toString() ?? '',
      groupLabel:
          json['groupLabel']?.toString() ?? json['name']?.toString() ?? '',
      quantitySold: _toInt(json['quantitySold']),
      grossSales: _toDouble(json['grossSales']),
      cogs: _toDouble(json['cogs']),
      grossProfit: _toDouble(json['grossProfit']),
      marginPercent: _toDouble(json['marginPercent']),
      transactionCount: _toInt(json['transactionCount']),
      percentOfTotalSales: _toDouble(json['percentOfTotalSales']),
    );
  }
}

/// Full grouped breakdown response (totals + rows).
class PharmacySalesBreakdown {
  const PharmacySalesBreakdown({required this.totals, required this.rows});

  final PharmacySalesBreakdownTotals totals;
  final List<PharmacySalesBreakdownRow> rows;

  static const empty = PharmacySalesBreakdown(
    totals: PharmacySalesBreakdownTotals.empty,
    rows: <PharmacySalesBreakdownRow>[],
  );
}

/// A line-level sale detail row (one FIFO batch allocation).
class PharmacySalesDetailRow {
  const PharmacySalesDetailRow({
    required this.dispensedAt,
    required this.drugName,
    required this.batchNumber,
    required this.quantity,
    required this.unitSellingPrice,
    required this.unitCost,
    required this.lineSales,
    required this.lineCogs,
    required this.lineProfit,
    required this.profitUnknown,
    required this.patientName,
    required this.payerType,
    required this.dispensaryName,
    required this.dispensedByName,
    required this.invoiceId,
  });

  final DateTime? dispensedAt;
  final String drugName;
  final String batchNumber;
  final int quantity;
  final double unitSellingPrice;

  /// Null for historical lines that predate batch-cost tracking.
  final double? unitCost;
  final double lineSales;
  final double? lineCogs;
  final double? lineProfit;
  final bool profitUnknown;
  final String patientName;
  final String payerType;
  final String dispensaryName;
  final String dispensedByName;
  final String invoiceId;

  factory PharmacySalesDetailRow.fromJson(Map<String, dynamic> json) {
    final unitCost = tryParseApiDecimal(json['unitCost']);
    final profitUnknown =
        json['profitUnknown'] == true || unitCost == null;
    return PharmacySalesDetailRow(
      dispensedAt: json['dispensedAt'] == null
          ? null
          : DateTime.tryParse(json['dispensedAt'].toString()),
      drugName: json['drugName']?.toString() ?? '',
      batchNumber: json['batchNumber']?.toString() ?? '',
      quantity: _toInt(json['quantity']),
      unitSellingPrice: _toDouble(json['unitSellingPrice']),
      unitCost: unitCost,
      lineSales: _toDouble(json['lineSales']),
      lineCogs: tryParseApiDecimal(json['lineCogs']),
      lineProfit: tryParseApiDecimal(json['lineProfit']),
      profitUnknown: profitUnknown,
      patientName: json['patientName']?.toString() ?? '',
      payerType: json['payerType']?.toString() ?? '',
      dispensaryName: json['dispensaryName']?.toString() ?? '',
      dispensedByName: json['dispensedByName']?.toString() ?? '',
      invoiceId: json['invoiceId']?.toString() ?? '',
    );
  }
}

/// Paginated sales detail response.
class PharmacySalesDetailPage {
  const PharmacySalesDetailPage({required this.total, required this.rows});

  final int total;
  final List<PharmacySalesDetailRow> rows;

  static const empty = PharmacySalesDetailPage(
    total: 0,
    rows: <PharmacySalesDetailRow>[],
  );
}

/// Inventory worth for one store/holding location.
class PharmacyInventoryStoreValuation {
  const PharmacyInventoryStoreValuation({
    required this.locationId,
    required this.locationName,
    required this.locationType,
    required this.batchCount,
    required this.totalQuantity,
    required this.valueAtCost,
    required this.valueAtSellingPrice,
    required this.nearExpiryValueAtCost,
  });

  final String locationId;
  final String locationName;
  final String locationType;
  final int batchCount;
  final int totalQuantity;
  final double valueAtCost;
  final double valueAtSellingPrice;
  final double nearExpiryValueAtCost;

  factory PharmacyInventoryStoreValuation.fromJson(Map<String, dynamic> json) {
    return PharmacyInventoryStoreValuation(
      locationId: json['locationId']?.toString() ?? '',
      locationName: json['locationName']?.toString() ?? '',
      locationType: json['locationType']?.toString() ?? '',
      batchCount: _toInt(json['batchCount']),
      totalQuantity: _toInt(json['totalQuantity']),
      valueAtCost: _toDouble(json['valueAtCost']),
      valueAtSellingPrice: _toDouble(json['valueAtSellingPrice']),
      nearExpiryValueAtCost: _toDouble(json['nearExpiryValueAtCost']),
    );
  }
}

/// Totals across all locations for the valuation report.
class PharmacyInventoryValuationTotals {
  const PharmacyInventoryValuationTotals({
    required this.batchCount,
    required this.totalQuantity,
    required this.valueAtCost,
    required this.valueAtSellingPrice,
    required this.nearExpiryValueAtCost,
  });

  final int batchCount;
  final int totalQuantity;
  final double valueAtCost;
  final double valueAtSellingPrice;
  final double nearExpiryValueAtCost;

  static const empty = PharmacyInventoryValuationTotals(
    batchCount: 0,
    totalQuantity: 0,
    valueAtCost: 0,
    valueAtSellingPrice: 0,
    nearExpiryValueAtCost: 0,
  );

  factory PharmacyInventoryValuationTotals.fromJson(Map<String, dynamic> json) {
    return PharmacyInventoryValuationTotals(
      batchCount: _toInt(json['batchCount']),
      totalQuantity: _toInt(json['totalQuantity']),
      valueAtCost: _toDouble(json['valueAtCost']),
      valueAtSellingPrice: _toDouble(json['valueAtSellingPrice']),
      nearExpiryValueAtCost: _toDouble(json['nearExpiryValueAtCost']),
    );
  }
}

/// Per-store valuation summary response.
class PharmacyInventoryValuation {
  const PharmacyInventoryValuation({
    required this.totals,
    required this.stores,
  });

  final PharmacyInventoryValuationTotals totals;
  final List<PharmacyInventoryStoreValuation> stores;

  static const empty = PharmacyInventoryValuation(
    totals: PharmacyInventoryValuationTotals.empty,
    stores: <PharmacyInventoryStoreValuation>[],
  );
}

/// A single batch line in the valuation drill-down.
class PharmacyInventoryBatchRow {
  const PharmacyInventoryBatchRow({
    required this.batchId,
    required this.drugId,
    required this.drugName,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantityRemaining,
    required this.unitCost,
    required this.unitSellingPrice,
    required this.lineValueAtCost,
    required this.lineValueAtSelling,
    required this.locationName,
    required this.supplierName,
  });

  final String batchId;
  final String drugId;
  final String drugName;
  final String batchNumber;
  final DateTime? expiryDate;
  final int quantityRemaining;
  final double unitCost;
  final double unitSellingPrice;
  final double lineValueAtCost;
  final double lineValueAtSelling;
  final String locationName;
  final String supplierName;

  factory PharmacyInventoryBatchRow.fromJson(Map<String, dynamic> json) {
    return PharmacyInventoryBatchRow(
      batchId: json['batchId']?.toString() ?? '',
      drugId: json['drugId']?.toString() ?? '',
      drugName: json['drugName']?.toString() ?? '',
      batchNumber: json['batchNumber']?.toString() ?? '',
      expiryDate: json['expiryDate'] == null
          ? null
          : DateTime.tryParse(json['expiryDate'].toString()),
      quantityRemaining: _toInt(json['quantityRemaining']),
      unitCost: _toDouble(json['unitCost']),
      unitSellingPrice: _toDouble(json['unitSellingPrice']),
      lineValueAtCost: _toDouble(json['lineValueAtCost']),
      lineValueAtSelling: _toDouble(json['lineValueAtSelling']),
      locationName: json['locationName']?.toString() ?? '',
      supplierName: json['supplierName']?.toString() ?? '',
    );
  }
}

/// Paginated valuation batch detail response.
class PharmacyInventoryBatchPage {
  const PharmacyInventoryBatchPage({required this.total, required this.rows});

  final int total;
  final List<PharmacyInventoryBatchRow> rows;

  static const empty = PharmacyInventoryBatchPage(
    total: 0,
    rows: <PharmacyInventoryBatchRow>[],
  );
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _toDouble(dynamic value) => parseApiDecimal(value);
