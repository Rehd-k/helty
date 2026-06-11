import 'package:helty/src/core/utils/api_decimal.dart';

class PharmacyDashboardSummary {
  const PharmacyDashboardSummary({
    required this.prescriptionsProcessed,
    required this.pendingOrders,
    required this.dispensedOrders,
    required this.revenue,
    required this.inventoryValue,
    required this.lowStockCount,
    required this.outOfStockCount,
    required this.nearExpiryCount,
    required this.expiredCount,
  });

  final int prescriptionsProcessed;
  final int pendingOrders;
  final int dispensedOrders;
  final double revenue;
  final double inventoryValue;
  final int lowStockCount;
  final int outOfStockCount;
  final int nearExpiryCount;
  final int expiredCount;

  factory PharmacyDashboardSummary.fromJson(Map<String, dynamic> json) {
    return PharmacyDashboardSummary(
      prescriptionsProcessed: _toInt(json['prescriptionsProcessed']),
      pendingOrders: _toInt(json['pendingOrders']),
      dispensedOrders: _toInt(json['dispensedOrders']),
      revenue: _toDouble(json['revenue']),
      inventoryValue: _toDouble(json['inventoryValue']),
      lowStockCount: _toInt(json['lowStockCount']),
      outOfStockCount: _toInt(json['outOfStockCount']),
      nearExpiryCount: _toInt(json['nearExpiryCount']),
      expiredCount: _toInt(json['expiredCount']),
    );
  }
}

class PharmacyOrderStatusItem {
  const PharmacyOrderStatusItem({
    required this.status,
    required this.count,
    this.percentage,
  });

  final String status;
  final int count;
  final double? percentage;

  factory PharmacyOrderStatusItem.fromJson(Map<String, dynamic> json) {
    return PharmacyOrderStatusItem(
      status: json['status']?.toString() ?? '',
      count: _toInt(json['count']),
      percentage: json['percentage'] == null
          ? null
          : _toDouble(json['percentage']),
    );
  }
}

class PharmacyTopSellingItem {
  const PharmacyTopSellingItem({
    required this.drugName,
    required this.quantitySold,
    required this.revenue,
    required this.avgSellingPrice,
    required this.stockRemaining,
  });

  final String drugName;
  final int quantitySold;
  final double revenue;
  final double avgSellingPrice;
  final int stockRemaining;

  factory PharmacyTopSellingItem.fromJson(Map<String, dynamic> json) {
    return PharmacyTopSellingItem(
      drugName: json['drugName']?.toString() ?? json['name']?.toString() ?? '',
      quantitySold: _toInt(json['quantitySold'] ?? json['qtySold']),
      revenue: _toDouble(json['revenue']),
      avgSellingPrice: _toDouble(json['avgSellingPrice'] ?? json['avgPrice']),
      stockRemaining: _toInt(json['stockRemaining']),
    );
  }
}

class PharmacyRevenuePoint {
  const PharmacyRevenuePoint({
    required this.label,
    required this.grossRevenue,
    required this.netRevenue,
    required this.insuranceReimbursed,
    required this.cashCollected,
  });

  final String label;
  final double grossRevenue;
  final double netRevenue;
  final double insuranceReimbursed;
  final double cashCollected;

  factory PharmacyRevenuePoint.fromJson(Map<String, dynamic> json) {
    return PharmacyRevenuePoint(
      label: json['label']?.toString() ?? json['date']?.toString() ?? '',
      grossRevenue: _toDouble(json['grossRevenue']),
      netRevenue: _toDouble(json['netRevenue']),
      insuranceReimbursed: _toDouble(json['insuranceReimbursed']),
      cashCollected: _toDouble(json['cashCollected']),
    );
  }
}

class PharmacySafetySummary {
  const PharmacySafetySummary({
    required this.totalAlerts,
    required this.highSeverityAlerts,
    required this.overriddenAlerts,
    required this.acceptedAlerts,
    required this.controlledDiscrepancies,
  });

  final int totalAlerts;
  final int highSeverityAlerts;
  final int overriddenAlerts;
  final int acceptedAlerts;
  final int controlledDiscrepancies;

  factory PharmacySafetySummary.fromJson(Map<String, dynamic> json) {
    return PharmacySafetySummary(
      totalAlerts: _toInt(json['totalAlerts']),
      highSeverityAlerts: _toInt(json['highSeverityAlerts']),
      overriddenAlerts: _toInt(json['overriddenAlerts']),
      acceptedAlerts: _toInt(json['acceptedAlerts']),
      controlledDiscrepancies: _toInt(
        json['controlledDiscrepancies'] ?? json['balanceDiscrepancies'],
      ),
    );
  }
}

class PharmacyDashboardData {
  const PharmacyDashboardData({
    required this.summary,
    required this.orderStatuses,
    required this.topSelling,
    required this.revenueTrend,
    required this.safety,
  });

  final PharmacyDashboardSummary summary;
  final List<PharmacyOrderStatusItem> orderStatuses;
  final List<PharmacyTopSellingItem> topSelling;
  final List<PharmacyRevenuePoint> revenueTrend;
  final PharmacySafetySummary safety;
}

int _toInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

double _toDouble(dynamic value) => parseApiDecimal(value);
