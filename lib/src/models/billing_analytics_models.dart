// Models for GET /billing/analytics/* (see docs/billing-dashboard-api.md).

class DateWindow {
  const DateWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  factory DateWindow.fromJson(Map<String, dynamic> json) {
    return DateWindow(
      start: DateTime.parse(json['start'] as String),
      end: DateTime.parse(json['end'] as String),
    );
  }
}

class TrendMetric {
  const TrendMetric({
    required this.current,
    required this.previous,
    required this.percentChange,
    required this.direction,
  });

  final double current;
  final double previous;
  final double percentChange;

  /// `up` | `down` | `flat`
  final String direction;

  factory TrendMetric.fromJson(Map<String, dynamic> json) {
    return TrendMetric(
      current: _toDouble(json['current']),
      previous: _toDouble(json['previous']),
      percentChange: _toDouble(json['percentChange']),
      direction: json['direction']?.toString() ?? 'flat',
    );
  }

  static TrendMetric? tryParse(Object? raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) {
      return TrendMetric.fromJson(raw);
    }
    if (raw is Map) {
      return TrendMetric.fromJson(Map<String, dynamic>.from(raw));
    }
    return null;
  }
}

class RevenueSummary {
  const RevenueSummary({
    required this.period,
    required this.window,
    required this.previousWindow,
    required this.current,
    required this.previous,
    required this.percentChange,
    required this.direction,
  });

  final String period;
  final DateWindow window;
  final DateWindow previousWindow;
  final double current;
  final double previous;
  final double percentChange;
  final String direction;

  factory RevenueSummary.fromJson(Map<String, dynamic> json) {
    return RevenueSummary(
      period: json['period']?.toString() ?? '',
      window: DateWindow.fromJson(
        Map<String, dynamic>.from(json['window'] as Map),
      ),
      previousWindow: DateWindow.fromJson(
        Map<String, dynamic>.from(json['previousWindow'] as Map),
      ),
      current: _toDouble(json['current']),
      previous: _toDouble(json['previous']),
      percentChange: _toDouble(json['percentChange']),
      direction: json['direction']?.toString() ?? 'flat',
    );
  }
}

class OpenStock {
  const OpenStock({
    required this.invoiceCount,
    required this.lineItemCount,
    required this.quantitySum,
    required this.outstandingTotal,
  });

  final int invoiceCount;
  final int lineItemCount;
  final int quantitySum;
  final double outstandingTotal;

  factory OpenStock.fromJson(Map<String, dynamic> json) {
    return OpenStock(
      invoiceCount: _toInt(json['invoiceCount']),
      lineItemCount: _toInt(json['lineItemCount']),
      quantitySum: _toInt(json['quantitySum']),
      outstandingTotal: _toDouble(json['outstandingTotal']),
    );
  }
}

class UnpaidWindows {
  const UnpaidWindows({required this.current, required this.previous});

  final DateWindow current;
  final DateWindow previous;

  factory UnpaidWindows.fromJson(Map<String, dynamic> json) {
    return UnpaidWindows(
      current: DateWindow.fromJson(
        Map<String, dynamic>.from(json['current'] as Map),
      ),
      previous: DateWindow.fromJson(
        Map<String, dynamic>.from(json['previous'] as Map),
      ),
    );
  }
}

class UnpaidSummary {
  const UnpaidSummary({
    required this.period,
    required this.windows,
    required this.openStock,
    required this.lineItems,
    required this.quantities,
    required this.outstandingAmount,
  });

  final String period;
  final UnpaidWindows windows;
  final OpenStock openStock;
  final TrendMetric lineItems;
  final TrendMetric quantities;
  final TrendMetric outstandingAmount;

  factory UnpaidSummary.fromJson(Map<String, dynamic> json) {
    final windowsRaw = json['windows'];
    if (windowsRaw is! Map<String, dynamic>) {
      throw FormatException('UnpaidSummary: missing windows');
    }
    return UnpaidSummary(
      period: json['period']?.toString() ?? '',
      windows: UnpaidWindows.fromJson(windowsRaw),
      openStock: OpenStock.fromJson(
        Map<String, dynamic>.from(json['openStock'] as Map? ?? {}),
      ),
      lineItems: TrendMetric.fromJson(
        Map<String, dynamic>.from(json['lineItems'] as Map? ?? {}),
      ),
      quantities: TrendMetric.fromJson(
        Map<String, dynamic>.from(json['quantities'] as Map? ?? {}),
      ),
      outstandingAmount: TrendMetric.fromJson(
        Map<String, dynamic>.from(json['outstandingAmount'] as Map? ?? {}),
      ),
    );
  }
}

class OverdueStock {
  const OverdueStock({
    required this.invoiceCount,
    required this.outstandingTotal,
  });

  final int invoiceCount;
  final double outstandingTotal;

  factory OverdueStock.fromJson(Map<String, dynamic> json) {
    return OverdueStock(
      invoiceCount: _toInt(json['invoiceCount']),
      outstandingTotal: _toDouble(json['outstandingTotal']),
    );
  }

  static OverdueStock empty() =>
      const OverdueStock(invoiceCount: 0, outstandingTotal: 0);
}

/// Defensive parsing: backend shape may vary; see docs (semantics only).
class OverdueSummary {
  const OverdueSummary({
    required this.period,
    required this.overdueStock,
    this.newOverdueInvoiceTrend,
    this.newOverdueAmountTrend,
  });

  final String period;
  final OverdueStock overdueStock;
  final TrendMetric? newOverdueInvoiceTrend;
  final TrendMetric? newOverdueAmountTrend;

  factory OverdueSummary.fromJson(Map<String, dynamic> json) {
    final stockRaw = json['overdueStock'];
    final overdueStock = stockRaw is Map<String, dynamic>
        ? OverdueStock.fromJson(stockRaw)
        : OverdueStock.empty();

    TrendMetric? invoiceTrend;
    TrendMetric? amountTrend;
    final rawNew = json['newOverdueInPeriod'];
    if (rawNew is Map<String, dynamic>) {
      invoiceTrend =
          TrendMetric.tryParse(rawNew['invoiceCount']) ??
          TrendMetric.tryParse(rawNew['invoices']);
      amountTrend =
          TrendMetric.tryParse(rawNew['outstandingTotal']) ??
          TrendMetric.tryParse(rawNew['amount']);
    }

    return OverdueSummary(
      period: json['period']?.toString() ?? '',
      overdueStock: overdueStock,
      newOverdueInvoiceTrend: invoiceTrend,
      newOverdueAmountTrend: amountTrend,
    );
  }
}

class RevenueSeriesPoint {
  const RevenueSeriesPoint({
    required this.label,
    required this.revenue,
    this.start,
    this.end,
  });

  final String label;
  final double revenue;
  final DateTime? start;
  final DateTime? end;

  factory RevenueSeriesPoint.fromJson(Map<String, dynamic> json) {
    DateTime? p(String? k) {
      final v = json[k];
      if (v is! String || v.isEmpty) return null;
      try {
        return DateTime.parse(v);
      } catch (_) {
        return null;
      }
    }

    return RevenueSeriesPoint(
      label: json['label']?.toString() ?? '',
      revenue: _toDouble(json['revenue']),
      start: p('start'),
      end: p('end'),
    );
  }
}

class RevenueSeries {
  const RevenueSeries({
    required this.period,
    required this.window,
    required this.points,
    required this.maxRevenue,
  });

  final String period;
  final DateWindow window;
  final List<RevenueSeriesPoint> points;
  final double maxRevenue;

  factory RevenueSeries.fromJson(Map<String, dynamic> json) {
    final rawPoints = json['points'];
    final list = rawPoints is List
        ? rawPoints
              .whereType<Map>()
              .map(
                (e) =>
                    RevenueSeriesPoint.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <RevenueSeriesPoint>[];

    final windowRaw = json['window'];
    final window = windowRaw is Map<String, dynamic>
        ? DateWindow.fromJson(windowRaw)
        : DateWindow(
            start: DateTime.fromMillisecondsSinceEpoch(0),
            end: DateTime.fromMillisecondsSinceEpoch(0),
          );

    return RevenueSeries(
      period: json['period']?.toString() ?? '',
      window: window,
      points: list,
      maxRevenue: _toDouble(json['maxRevenue']),
    );
  }
}

class DepartmentSlice {
  const DepartmentSlice({
    this.departmentId,
    required this.name,
    required this.amount,
    required this.percent,
  });

  final String? departmentId;
  final String name;
  final double amount;
  final double percent;

  factory DepartmentSlice.fromJson(Map<String, dynamic> json) {
    return DepartmentSlice(
      departmentId: json['departmentId']?.toString(),
      name: json['name']?.toString() ?? 'Unknown',
      amount: _toDouble(json['amount']),
      percent: _toDouble(json['percent']),
    );
  }
}

class RevenueByDepartment {
  const RevenueByDepartment({
    required this.period,
    required this.window,
    required this.total,
    required this.slices,
  });

  final String period;
  final DateWindow window;
  final double total;
  final List<DepartmentSlice> slices;

  factory RevenueByDepartment.fromJson(Map<String, dynamic> json) {
    final raw = json['slices'];
    final slices = raw is List
        ? raw
              .whereType<Map>()
              .map(
                (e) => DepartmentSlice.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <DepartmentSlice>[];

    final windowRaw = json['window'];
    final window = windowRaw is Map<String, dynamic>
        ? DateWindow.fromJson(windowRaw)
        : DateWindow(
            start: DateTime.fromMillisecondsSinceEpoch(0),
            end: DateTime.fromMillisecondsSinceEpoch(0),
          );

    return RevenueByDepartment(
      period: json['period']?.toString() ?? '',
      window: window,
      total: _toDouble(json['total']),
      slices: slices,
    );
  }
}

class RecentInvoiceRow {
  const RecentInvoiceRow({
    required this.invoiceId,
    required this.status,
    required this.patientName,
    required this.date,
    required this.amount,
  });

  final String invoiceId;
  final String status;
  final String patientName;
  final DateTime date;
  final double amount;

  factory RecentInvoiceRow.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date']?.toString();
    DateTime date;
    try {
      date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    return RecentInvoiceRow(
      invoiceId: json['invoiceId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? '',
      date: date,
      amount: _toDouble(json['amount']),
    );
  }
}

class RecentInvoicesResponse {
  const RecentInvoicesResponse({
    required this.period,
    this.asOf,
    required this.take,
    required this.items,
  });

  final String period;
  final DateTime? asOf;
  final int take;
  final List<RecentInvoiceRow> items;

  factory RecentInvoicesResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = raw is List
        ? raw
              .whereType<Map>()
              .map(
                (e) => RecentInvoiceRow.fromJson(Map<String, dynamic>.from(e)),
              )
              .toList()
        : <RecentInvoiceRow>[];

    DateTime? asOf;
    final asOfStr = json['asOf']?.toString();
    if (asOfStr != null && asOfStr.isNotEmpty) {
      try {
        asOf = DateTime.parse(asOfStr);
      } catch (_) {}
    }

    return RecentInvoicesResponse(
      period: json['period']?.toString() ?? '',
      asOf: asOf,
      take: _toInt(json['take']),
      items: items,
    );
  }
}

double _toDouble(Object? value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}

int _toInt(Object? value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}
