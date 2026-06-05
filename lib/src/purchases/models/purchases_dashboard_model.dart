class PurchasesDashboardSummary {
  const PurchasesDashboardSummary({
    required this.pendingRequisitions,
    required this.approvedRequisitions,
    required this.openPurchaseOrders,
    required this.completedPurchaseOrders,
    required this.totalPurchaseValue,
    required this.inventoryValue,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.nearExpiryCount,
    required this.expiredCount,
  });

  final int pendingRequisitions;
  final int approvedRequisitions;
  final int openPurchaseOrders;
  final int completedPurchaseOrders;
  final double totalPurchaseValue;
  final double inventoryValue;
  final int lowStockCount;
  final int outOfStockCount;
  final int nearExpiryCount;
  final int expiredCount;

  factory PurchasesDashboardSummary.fromJson(Map<String, dynamic> json) {
    return PurchasesDashboardSummary(
      pendingRequisitions: _toInt(json['pendingRequisitions']),
      approvedRequisitions: _toInt(json['approvedRequisitions']),
      openPurchaseOrders: _toInt(json['openPurchaseOrders']),
      completedPurchaseOrders: _toInt(json['completedPurchaseOrders']),
      totalPurchaseValue: _toDouble(json['totalPurchaseValue']),
      inventoryValue: _toDouble(json['inventoryValue']),
      lowStockCount: _toInt(json['lowStockCount']),
      outOfStockCount: _toInt(json['outOfStockCount']),
      nearExpiryCount: _toInt(json['nearExpiryCount']),
      expiredCount: _toInt(json['expiredCount']),
    );
  }
}

class PurchasesOrderStatusItem {
  const PurchasesOrderStatusItem({
    required this.status,
    required this.count,
    this.percentage,
  });

  final String status;
  final int count;
  final double? percentage;

  factory PurchasesOrderStatusItem.fromJson(Map<String, dynamic> json) {
    return PurchasesOrderStatusItem(
      status: json['status']?.toString() ?? '',
      count: _toInt(json['count']),
      percentage: json['percentage'] == null
          ? null
          : _toDouble(json['percentage']),
    );
  }
}

class PurchasesTopItem {
  const PurchasesTopItem({
    required this.itemName,
    required this.quantityPurchased,
    required this.totalCost,
    required this.avgCostPrice,
    required this.stockRemaining,
  });

  final String itemName;
  final int quantityPurchased;
  final double totalCost;
  final double avgCostPrice;
  final int stockRemaining;

  factory PurchasesTopItem.fromJson(Map<String, dynamic> json) {
    return PurchasesTopItem(
      itemName: json['itemName']?.toString() ?? json['name']?.toString() ?? '',
      quantityPurchased: _toInt(
        json['quantityPurchased'] ?? json['qtyPurchased'],
      ),
      totalCost: _toDouble(json['totalCost'] ?? json['cost']),
      avgCostPrice: _toDouble(json['avgCostPrice'] ?? json['avgPrice']),
      stockRemaining: _toInt(json['stockRemaining']),
    );
  }
}

class PurchasesTrendPoint {
  const PurchasesTrendPoint({
    required this.label,
    required this.purchaseValue,
    required this.orderCount,
  });

  final String label;
  final double purchaseValue;
  final int orderCount;

  factory PurchasesTrendPoint.fromJson(Map<String, dynamic> json) {
    return PurchasesTrendPoint(
      label: json['label']?.toString() ?? json['date']?.toString() ?? '',
      purchaseValue: _toDouble(json['purchaseValue'] ?? json['value']),
      orderCount: _toInt(json['orderCount']),
    );
  }
}

class SupplierPerformanceItem {
  const SupplierPerformanceItem({
    required this.supplierName,
    required this.orderCount,
    required this.onTimeDeliveries,
    required this.avgLeadTimeDays,
  });

  final String supplierName;
  final int orderCount;
  final int onTimeDeliveries;
  final double avgLeadTimeDays;

  factory SupplierPerformanceItem.fromJson(Map<String, dynamic> json) {
    return SupplierPerformanceItem(
      supplierName: json['supplierName']?.toString() ?? '',
      orderCount: _toInt(json['orderCount']),
      onTimeDeliveries: _toInt(json['onTimeDeliveries']),
      avgLeadTimeDays: _toDouble(json['avgLeadTimeDays']),
    );
  }
}

class PurchasesDashboardData {
  const PurchasesDashboardData({
    required this.summary,
    required this.orderStatuses,
    required this.topItems,
    required this.purchaseTrend,
    required this.supplierPerformance,
  });

  final PurchasesDashboardSummary summary;
  final List<PurchasesOrderStatusItem> orderStatuses;
  final List<PurchasesTopItem> topItems;
  final List<PurchasesTrendPoint> purchaseTrend;
  final List<SupplierPerformanceItem> supplierPerformance;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
