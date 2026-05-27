enum CmacPeriod {
  today,
  week,
  month,
  quarter,
  year;

  String get apiValue => name;

  String get label {
    switch (this) {
      case CmacPeriod.today:
        return 'Today';
      case CmacPeriod.week:
        return 'Week';
      case CmacPeriod.month:
        return 'Month';
      case CmacPeriod.quarter:
        return 'Quarter';
      case CmacPeriod.year:
        return 'Year';
    }
  }
}

class CmacAnalyticsQuery {
  const CmacAnalyticsQuery({
    this.period = CmacPeriod.month,
    this.asOf,
    this.limit = 10,
    this.departmentId,
  });

  final CmacPeriod period;
  final DateTime? asOf;
  final int limit;
  final String? departmentId;

  CmacAnalyticsQuery copyWith({
    CmacPeriod? period,
    DateTime? asOf,
    bool clearAsOf = false,
    int? limit,
    String? departmentId,
    bool clearDepartmentId = false,
  }) {
    return CmacAnalyticsQuery(
      period: period ?? this.period,
      asOf: clearAsOf ? null : (asOf ?? this.asOf),
      limit: limit ?? this.limit,
      departmentId:
          clearDepartmentId ? null : (departmentId ?? this.departmentId),
    );
  }

  Map<String, dynamic> toQueryParams() {
    final m = <String, dynamic>{
      'period': period.apiValue,
      'limit': limit.clamp(1, 50),
    };
    if (asOf != null) m['asOf'] = asOf!.toUtc().toIso8601String();
    if (departmentId != null && departmentId!.isNotEmpty) {
      m['departmentId'] = departmentId;
    }
    return m;
  }
}
