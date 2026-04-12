// Models for GET /nurses/dashboard/overview (see docs/nestjs-nurse-dashboard-api-prompt.md).

class NurseDashboardOverview {
  const NurseDashboardOverview({
    required this.asOf,
    required this.timeRange,
    required this.window,
    required this.header,
    required this.kpis,
    required this.admissionsDischargesSeries,
    required this.departmentLoad,
    required this.staffOnDuty,
    required this.criticalAlerts,
  });

  final DateTime asOf;
  final String timeRange;
  final NurseDashboardWindow window;
  final NurseDashboardHeader header;
  final NurseDashboardKpis kpis;
  final NurseAdmissionsDischargesSeries admissionsDischargesSeries;
  final NurseDepartmentLoadBundle departmentLoad;
  final List<NurseStaffOnDuty> staffOnDuty;
  final List<NurseCriticalAlert> criticalAlerts;

  factory NurseDashboardOverview.fromJson(Map<String, dynamic> json) {
    return NurseDashboardOverview(
      asOf: DateTime.parse(json['asOf'] as String),
      timeRange: json['timeRange'] as String? ?? 'Today',
      window: NurseDashboardWindow.fromJson(
        _asMap(json['window'], const {}),
      ),
      header: NurseDashboardHeader.fromJson(
        _asMap(json['header'], const {}),
      ),
      kpis: NurseDashboardKpis.fromJson(_asMap(json['kpis'], const {})),
      admissionsDischargesSeries: NurseAdmissionsDischargesSeries.fromJson(
        _asMap(json['admissionsDischargesSeries'], const {}),
      ),
      departmentLoad: NurseDepartmentLoadBundle.fromJson(json['departmentLoad']),
      staffOnDuty: _list(json['staffOnDuty'], NurseStaffOnDuty.fromJson),
      criticalAlerts: _list(json['criticalAlerts'], NurseCriticalAlert.fromJson),
    );
  }
}

Map<String, dynamic> _asMap(dynamic value, Map<String, dynamic> fallback) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return fallback;
}

List<T> _list<T>(dynamic value, T Function(Map<String, dynamic>) parse) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((e) => parse(Map<String, dynamic>.from(e)))
      .toList();
}

class NurseDashboardWindow {
  const NurseDashboardWindow({required this.start, required this.end});

  final DateTime start;
  final DateTime end;

  factory NurseDashboardWindow.fromJson(Map<String, dynamic> json) =>
      NurseDashboardWindow(
        start: DateTime.parse(json['start'] as String),
        end: DateTime.parse(json['end'] as String),
      );
}

class NurseDashboardHeader {
  const NurseDashboardHeader({
    this.title,
    this.subtitle,
    this.subtitleTemplate,
    this.userDisplayName = '',
  });

  final String? title;
  final String? subtitle;
  final String? subtitleTemplate;
  final String userDisplayName;

  factory NurseDashboardHeader.fromJson(Map<String, dynamic> json) =>
      NurseDashboardHeader(
        title: json['title'] as String?,
        subtitle: json['subtitle'] as String?,
        subtitleTemplate: json['subtitleTemplate'] as String?,
        userDisplayName: json['userDisplayName'] as String? ?? '',
      );
}

class NurseKpiDelta {
  const NurseKpiDelta({
    required this.kind,
    required this.label,
    this.direction,
    this.isPositive = true,
    this.value,
  });

  final String kind;
  final String label;
  final String? direction;
  final bool isPositive;
  final double? value;

  factory NurseKpiDelta.fromJson(Map<String, dynamic> json) => NurseKpiDelta(
        kind: json['kind'] as String? ?? 'text',
        label: json['label'] as String? ?? '—',
        direction: json['direction'] as String?,
        isPositive: json['isPositive'] as bool? ?? true,
        value: json['value'] == null ? null : (json['value'] as num).toDouble(),
      );
}

class NurseKpiCount {
  const NurseKpiCount({
    this.value,
    this.valueFormatted = '—',
    required this.delta,
  });

  final int? value;
  final String valueFormatted;
  final NurseKpiDelta delta;

  factory NurseKpiCount.fromJson(Map<String, dynamic> json) => NurseKpiCount(
        value: (json['value'] as num?)?.toInt(),
        valueFormatted: json['valueFormatted'] as String? ?? '—',
        delta: NurseKpiDelta.fromJson(
          _asMap(json['delta'], const {'kind': 'text', 'label': '—'}),
        ),
      );
}

class NurseKpiBedOccupancy {
  const NurseKpiBedOccupancy({
    required this.ratio,
    this.valueFormatted = '—',
    required this.delta,
  });

  final double ratio;
  final String valueFormatted;
  final NurseKpiDelta delta;

  factory NurseKpiBedOccupancy.fromJson(Map<String, dynamic> json) =>
      NurseKpiBedOccupancy(
        ratio: (json['ratio'] as num?)?.toDouble() ?? 0,
        valueFormatted: json['valueFormatted'] as String? ?? '—',
        delta: NurseKpiDelta.fromJson(
          _asMap(json['delta'], const {'kind': 'text', 'label': '—'}),
        ),
      );
}

class NurseKpiActiveStaff {
  const NurseKpiActiveStaff({
    this.count,
    this.valueFormatted = '—',
    required this.delta,
  });

  final int? count;
  final String valueFormatted;
  final NurseKpiDelta delta;

  factory NurseKpiActiveStaff.fromJson(Map<String, dynamic> json) =>
      NurseKpiActiveStaff(
        count: (json['count'] as num?)?.toInt(),
        valueFormatted: json['valueFormatted'] as String? ?? '—',
        delta: NurseKpiDelta.fromJson(
          _asMap(json['delta'], const {'kind': 'text', 'label': '—'}),
        ),
      );
}

class NurseKpiAverageWait {
  const NurseKpiAverageWait({
    this.minutes,
    this.valueFormatted = '—',
    required this.delta,
  });

  final int? minutes;
  final String valueFormatted;
  final NurseKpiDelta delta;

  factory NurseKpiAverageWait.fromJson(Map<String, dynamic> json) =>
      NurseKpiAverageWait(
        minutes: (json['minutes'] as num?)?.toInt(),
        valueFormatted: json['valueFormatted'] as String? ?? '—',
        delta: NurseKpiDelta.fromJson(
          _asMap(json['delta'], const {'kind': 'text', 'label': '—'}),
        ),
      );
}

class NurseDashboardKpis {
  const NurseDashboardKpis({
    required this.totalPatients,
    required this.bedOccupancy,
    required this.activeStaff,
    required this.averageWaitTime,
  });

  final NurseKpiCount totalPatients;
  final NurseKpiBedOccupancy bedOccupancy;
  final NurseKpiActiveStaff activeStaff;
  final NurseKpiAverageWait averageWaitTime;

  factory NurseDashboardKpis.fromJson(Map<String, dynamic> json) =>
      NurseDashboardKpis(
        totalPatients: NurseKpiCount.fromJson(
          _asMap(json['totalPatients'], const {}),
        ),
        bedOccupancy: NurseKpiBedOccupancy.fromJson(
          _asMap(json['bedOccupancy'], const {}),
        ),
        activeStaff: NurseKpiActiveStaff.fromJson(
          _asMap(json['activeStaff'], const {}),
        ),
        averageWaitTime: NurseKpiAverageWait.fromJson(
          _asMap(json['averageWaitTime'], const {}),
        ),
      );
}

class NurseAdmissionDischargePoint {
  const NurseAdmissionDischargePoint({
    required this.label,
    required this.admissions,
    required this.discharges,
  });

  final String label;
  final double admissions;
  final double discharges;

  factory NurseAdmissionDischargePoint.fromJson(Map<String, dynamic> json) =>
      NurseAdmissionDischargePoint(
        label: json['label'] as String? ?? '',
        admissions: (json['admissions'] as num?)?.toDouble() ?? 0,
        discharges: (json['discharges'] as num?)?.toDouble() ?? 0,
      );
}

class NurseSeriesMeta {
  const NurseSeriesMeta({this.yAxisMax, this.yAxisSuggested});

  final double? yAxisMax;
  final bool? yAxisSuggested;

  factory NurseSeriesMeta.fromJson(Map<String, dynamic> json) => NurseSeriesMeta(
        yAxisMax: (json['yAxisMax'] as num?)?.toDouble(),
        yAxisSuggested: json['yAxisSuggested'] as bool?,
      );
}

class NurseAdmissionsDischargesSeries {
  const NurseAdmissionsDischargesSeries({
    required this.points,
    this.meta,
  });

  final List<NurseAdmissionDischargePoint> points;
  final NurseSeriesMeta? meta;

  factory NurseAdmissionsDischargesSeries.fromJson(
    Map<String, dynamic> json,
  ) {
    final raw = json['points'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => NurseAdmissionDischargePoint.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <NurseAdmissionDischargePoint>[];
    final metaJson = json['meta'];
    return NurseAdmissionsDischargesSeries(
      points: list,
      meta: metaJson is Map
          ? NurseSeriesMeta.fromJson(Map<String, dynamic>.from(metaJson))
          : null,
    );
  }
}

class NurseDepartmentBar {
  const NurseDepartmentBar({
    required this.departmentId,
    required this.shortLabel,
    required this.load,
  });

  final String departmentId;
  final String shortLabel;
  final double load;

  factory NurseDepartmentBar.fromJson(Map<String, dynamic> json) =>
      NurseDepartmentBar(
        departmentId: json['departmentId']?.toString() ?? '',
        shortLabel: json['shortLabel'] as String? ?? '',
        load: (json['load'] as num?)?.toDouble() ?? 0,
      );
}

class NurseDepartmentLoadBundle {
  const NurseDepartmentLoadBundle({
    required this.chartMax,
    required this.bars,
  });

  final double chartMax;
  final List<NurseDepartmentBar> bars;

  factory NurseDepartmentLoadBundle.fromJson(dynamic json) {
    if (json is List) {
      final bars = json
          .whereType<Map>()
          .map((e) => NurseDepartmentBar.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      return NurseDepartmentLoadBundle(chartMax: 100, bars: bars);
    }
    if (json is Map) {
      final m = Map<String, dynamic>.from(json);
      final raw = m['bars'];
      final bars = raw is List
          ? raw
              .whereType<Map>()
              .map((e) =>
                  NurseDepartmentBar.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : <NurseDepartmentBar>[];
      final max = (m['chartMax'] as num?)?.toDouble() ?? 100;
      return NurseDepartmentLoadBundle(chartMax: max > 0 ? max : 100, bars: bars);
    }
    return const NurseDepartmentLoadBundle(chartMax: 100, bars: []);
  }
}

class NurseStaffOnDuty {
  const NurseStaffOnDuty({
    required this.id,
    required this.name,
    required this.role,
    required this.status,
    this.statusTone,
    this.photoUrl,
  });

  final String id;
  final String name;
  final String role;
  final String status;
  final String? statusTone;
  final String? photoUrl;

  factory NurseStaffOnDuty.fromJson(Map<String, dynamic> json) =>
      NurseStaffOnDuty(
        id: json['id']?.toString() ?? '',
        name: json['name'] as String? ?? '',
        role: json['role'] as String? ?? '',
        status: json['status'] as String? ?? '',
        statusTone: json['statusTone'] as String?,
        photoUrl: json['photoUrl'] as String?,
      );
}

class NurseCriticalAlert {
  const NurseCriticalAlert({
    required this.id,
    required this.location,
    required this.message,
    required this.severity,
    required this.occurredAt,
    this.relativeLabel,
  });

  final String id;
  final String location;
  final String message;
  final String severity;
  final DateTime occurredAt;
  final String? relativeLabel;

  factory NurseCriticalAlert.fromJson(Map<String, dynamic> json) =>
      NurseCriticalAlert(
        id: json['id']?.toString() ?? '',
        location: json['location'] as String? ?? '',
        message: json['message'] as String? ?? '',
        severity: json['severity'] as String? ?? 'warning',
        occurredAt: json['occurredAt'] != null
            ? DateTime.parse(json['occurredAt'] as String)
            : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
        relativeLabel: json['relativeLabel'] as String?,
      );
}
