import 'package:helty/src/core/utils/api_decimal.dart';

import 'cmac_analytics_models.dart';
import 'cmac_quality_safety_models.dart';

double? _numOpt(dynamic v) => tryParseApiDecimal(v);

num _num(dynamic v) => tryParseApiDecimal(v) ?? 0;

String _str(dynamic v, [String fallback = '']) =>
    v?.toString() ?? fallback;

DateTime? _dtOpt(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) {
  if (v is! List) return [];
  return v
      .whereType<Map>()
      .map((e) => f(Map<String, dynamic>.from(e)))
      .toList();
}

Map<String, dynamic> _map(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : {};

CmacMetricComparison? _comparison(dynamic v) {
  if (v is! Map) return null;
  final m = Map<String, dynamic>.from(v);
  return CmacMetricComparison(
    current: _num(m['current']),
    previous: _num(m['previous']),
    percentChange: _numOpt(m['percentChange']),
    direction: _str(m['direction'], 'flat'),
    isPositive: m['isPositive'] == true,
  );
}

CmacKpiMetric _kpi(Map<String, dynamic> j) => CmacKpiMetric(
      key: _str(j['key']),
      label: _str(j['label']),
      value: _num(j['value']),
      unit: j['unit']?.toString(),
      comparison: _comparison(j['comparison']),
    );

CmacSeriesPoint _seriesPoint(Map<String, dynamic> j) => CmacSeriesPoint(
      label: _str(j['label']),
      value: _num(j['value']),
      start: _dtOpt(j['start']),
      end: _dtOpt(j['end']),
    );

CmacAlert _alert(Map<String, dynamic> j) => CmacAlert(
      severity: _str(j['severity'], 'info'),
      code: _str(j['code']),
      message: _str(j['message']),
      metric: j['metric']?.toString(),
    );

CmacInsight _insight(Map<String, dynamic> j) => CmacInsight(
      id: _str(j['id']),
      message: _str(j['message']),
      category: j['category']?.toString(),
      severity: _str(j['severity'], 'info'),
    );

CmacAuditFlag _auditFlag(Map<String, dynamic> j) => CmacAuditFlag(
      entityType: _str(j['entityType']),
      entityId: _str(j['entityId']),
      patientId: _str(j['patientId']),
      rule: _str(j['rule']),
      severity: _str(j['severity'], 'warning'),
    );

CmacNamedValue _namedValue(Map<String, dynamic> j) => CmacNamedValue(
      label: _str(j['label'] ?? j['name'] ?? j['diagnosis'] ?? j['test']),
      value: _num(j['value'] ?? j['count'] ?? 0),
      extra: j['patientName']?.toString(),
    );

CmacOverviewResponse parseCmacOverview(Map<String, dynamic> j) =>
    CmacOverviewResponse(
      period: _str(j['period'], 'month'),
      asOf: _dtOpt(j['asOf']),
      generatedAt: _dtOpt(j['generatedAt']),
      headlineKpis: _list(j['headlineKpis'], _kpi),
      alerts: _list(j['alerts'], _alert),
      insights: _list(j['insights'], _insight),
    );

CmacInsightsResponse parseCmacInsights(Map<String, dynamic> j) =>
    CmacInsightsResponse(
      period: _str(j['period'], 'month'),
      asOf: _dtOpt(j['asOf']),
      insights: _list(j['insights'], _insight),
    );

/// Insights endpoint may return a bare array or `{ period, insights: [...] }`.
CmacInsightsResponse parseCmacInsightsFromBody(dynamic data) {
  if (data is List) {
    return CmacInsightsResponse(
      period: 'month',
      insights: _list(data, _insight),
    );
  }
  if (data is Map) {
    return parseCmacInsights(Map<String, dynamic>.from(data));
  }
  return CmacInsightsResponse(period: 'month', insights: []);
}

CmacPatientActivityResponse parseCmacPatientActivity(Map<String, dynamic> j) {
  final series = _map(j['series']);
  return CmacPatientActivityResponse(
    period: _str(j['period'], 'month'),
    asOf: _dtOpt(j['asOf']),
    kpis: _list(j['kpis'], _kpi),
    newPatientsSeries: _list(series['newPatients'], _seriesPoint),
    referralsInSeries: _list(series['referralsIn'], _seriesPoint),
    referralsOutSeries: _list(series['referralsOut'], _seriesPoint),
  );
}

CmacClinicalResponse parseCmacClinical(Map<String, dynamic> j) {
  final outcomes = _map(j['treatmentOutcomes']);
  final readm = _map(j['readmissions']);
  return CmacClinicalResponse(
    period: _str(j['period'], 'month'),
    asOf: _dtOpt(j['asOf']),
    kpis: _list(j['kpis'], _kpi),
    topDiagnoses: _list(j['topDiagnoses'], _namedValue),
    treatmentOutcomes: _list(outcomes['current'] ?? outcomes, _namedValue),
    readmissionsCurrent: _numOpt(readm['current']),
    readmissionsPrevious: _numOpt(readm['previous']),
  );
}

CmacLaboratoryResponse parseCmacLaboratory(Map<String, dynamic> j) {
  final pvc = _map(j['pendingVsCompleted']);
  return CmacLaboratoryResponse(
    period: _str(j['period'], 'month'),
    asOf: _dtOpt(j['asOf']),
    kpis: _list(j['kpis'], _kpi),
    pendingCount: _numOpt(pvc['pending'] ?? j['pending']),
    completedCount: _numOpt(pvc['completed'] ?? j['completed']),
    statusBreakdown: _list(j['statusBreakdown'], _namedValue),
    topTests: _list(j['topTests'], _namedValue),
    criticalAlerts: j['criticalAlerts'] is List
        ? (j['criticalAlerts'] as List)
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : [],
  );
}

CmacPharmacyResponse parseCmacPharmacy(Map<String, dynamic> j) =>
    CmacPharmacyResponse(
      period: _str(j['period'], 'month'),
      asOf: _dtOpt(j['asOf']),
      kpis: _list(j['kpis'], _kpi),
      topPrescribed: _list(j['topPrescribed'], _namedValue),
      antibioticTrend: _list(j['antibioticTrend'], _seriesPoint),
    );

CmacOperationsResponse parseCmacOperations(Map<String, dynamic> j) =>
    CmacOperationsResponse(
      period: _str(j['period'], 'month'),
      asOf: _dtOpt(j['asOf']),
      kpis: _list(j['kpis'], _kpi),
      doctorWorkload: _list(j['doctorWorkload'], _namedValue),
      departmentUtilization:
          _list(j['departmentUtilization'], _namedValue),
      peakVisitingHours: _list(j['peakVisitingHours'], _seriesPoint),
    );

CmacQualityResponse parseCmacQuality(Map<String, dynamic> j) =>
    CmacQualityResponse(
      period: _str(j['period'], 'month'),
      asOf: _dtOpt(j['asOf']),
      kpis: _list(j['kpis'], _kpi),
      incidentsByType: _list(j['incidentsByType'], _namedValue),
      complaintsByCategory: _list(j['complaintsByCategory'], _namedValue),
      auditFlags: _list(j['auditFlags'], _auditFlag),
    );

CmacStaffResponse parseCmacStaff(Map<String, dynamic> j) =>
    CmacStaffResponse(
      period: _str(j['period'], 'month'),
      asOf: _dtOpt(j['asOf']),
      patientsPerDoctor: _list(j['patientsPerDoctor'], _namedValue),
      labWorkloadPerTechnician:
          _list(j['labWorkloadPerTechnician'], _namedValue),
      departmentEfficiency: _list(j['departmentEfficiency'], (m) {
        return CmacDepartmentEfficiency(
          department: _str(
            m['department'] ?? m['name'] ?? m['label'],
          ),
          score: _num(m['score']),
          volume: _numOpt(m['volume'] ?? m['count']),
          complaints: _numOpt(m['complaints']),
          waitMinutes: _numOpt(m['waitMinutes'] ?? m['wait']),
        );
      }),
    );

List<QualitySafetyRecord> parseQualitySafetyList(
  dynamic data,
  QualitySafetyEntity entity,
) {
  List<dynamic> items;
  if (data is List) {
    items = data;
  } else if (data is Map) {
    final m = Map<String, dynamic>.from(data);
    items = (m['items'] ?? m['data'] ?? m['results'] ?? []) as List<dynamic>? ??
        [];
  } else {
    return [];
  }
  return items
      .whereType<Map>()
      .map((e) {
        final raw = Map<String, dynamic>.from(e);
        return QualitySafetyRecord(
          id: _str(raw['id']),
          entity: entity,
          raw: raw,
        );
      })
      .toList();
}

QualitySafetyRecord parseQualitySafetyDetail(
  Map<String, dynamic> j,
  QualitySafetyEntity entity,
) =>
    QualitySafetyRecord(
      id: _str(j['id']),
      entity: entity,
      raw: j,
    );
