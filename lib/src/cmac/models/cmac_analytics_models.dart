class CmacMetricComparison {
  CmacMetricComparison({
    required this.current,
    required this.previous,
    this.percentChange,
    required this.direction,
    required this.isPositive,
  });

  final num current;
  final num previous;
  final double? percentChange;
  final String direction;
  final bool isPositive;
}

class CmacKpiMetric {
  CmacKpiMetric({
    required this.key,
    required this.label,
    required this.value,
    this.unit,
    this.comparison,
  });

  final String key;
  final String label;
  final num value;
  final String? unit;
  final CmacMetricComparison? comparison;
}

class CmacSeriesPoint {
  CmacSeriesPoint({
    required this.label,
    required this.value,
    this.start,
    this.end,
  });

  final String label;
  final num value;
  final DateTime? start;
  final DateTime? end;
}

class CmacAlert {
  CmacAlert({
    required this.severity,
    required this.code,
    required this.message,
    this.metric,
  });

  final String severity;
  final String code;
  final String message;
  final String? metric;
}

class CmacInsight {
  CmacInsight({
    required this.id,
    required this.message,
    this.category,
    required this.severity,
  });

  final String id;
  final String message;
  final String? category;
  final String severity;
}

class CmacAuditFlag {
  CmacAuditFlag({
    required this.entityType,
    required this.entityId,
    required this.patientId,
    required this.rule,
    required this.severity,
  });

  final String entityType;
  final String entityId;
  final String patientId;
  final String rule;
  final String severity;
}

class CmacNamedValue {
  CmacNamedValue({required this.label, required this.value, this.extra});

  final String label;
  final num value;
  final String? extra;
}

class CmacOverviewResponse {
  CmacOverviewResponse({
    required this.period,
    this.asOf,
    this.generatedAt,
    required this.headlineKpis,
    required this.alerts,
    required this.insights,
  });

  final String period;
  final DateTime? asOf;
  final DateTime? generatedAt;
  final List<CmacKpiMetric> headlineKpis;
  final List<CmacAlert> alerts;
  final List<CmacInsight> insights;
}

class CmacInsightsResponse {
  CmacInsightsResponse({
    required this.period,
    this.asOf,
    required this.insights,
  });

  final String period;
  final DateTime? asOf;
  final List<CmacInsight> insights;
}

class CmacPatientActivityResponse {
  CmacPatientActivityResponse({
    required this.period,
    this.asOf,
    required this.kpis,
    required this.newPatientsSeries,
    required this.referralsInSeries,
    required this.referralsOutSeries,
  });

  final String period;
  final DateTime? asOf;
  final List<CmacKpiMetric> kpis;
  final List<CmacSeriesPoint> newPatientsSeries;
  final List<CmacSeriesPoint> referralsInSeries;
  final List<CmacSeriesPoint> referralsOutSeries;
}

class CmacClinicalResponse {
  CmacClinicalResponse({
    required this.period,
    this.asOf,
    required this.kpis,
    required this.topDiagnoses,
    required this.treatmentOutcomes,
    this.readmissionsCurrent,
    this.readmissionsPrevious,
  });

  final String period;
  final DateTime? asOf;
  final List<CmacKpiMetric> kpis;
  final List<CmacNamedValue> topDiagnoses;
  final List<CmacNamedValue> treatmentOutcomes;
  final num? readmissionsCurrent;
  final num? readmissionsPrevious;
}

class CmacLaboratoryResponse {
  CmacLaboratoryResponse({
    required this.period,
    this.asOf,
    required this.kpis,
    this.pendingCount,
    this.completedCount,
    required this.statusBreakdown,
    required this.topTests,
    required this.criticalAlerts,
  });

  final String period;
  final DateTime? asOf;
  final List<CmacKpiMetric> kpis;
  final num? pendingCount;
  final num? completedCount;
  final List<CmacNamedValue> statusBreakdown;
  final List<CmacNamedValue> topTests;
  final List<Map<String, dynamic>> criticalAlerts;
}

class CmacPharmacyResponse {
  CmacPharmacyResponse({
    required this.period,
    this.asOf,
    required this.kpis,
    required this.topPrescribed,
    required this.antibioticTrend,
  });

  final String period;
  final DateTime? asOf;
  final List<CmacKpiMetric> kpis;
  final List<CmacNamedValue> topPrescribed;
  final List<CmacSeriesPoint> antibioticTrend;
}

class CmacOperationsResponse {
  CmacOperationsResponse({
    required this.period,
    this.asOf,
    required this.kpis,
    required this.doctorWorkload,
    required this.departmentUtilization,
    required this.peakVisitingHours,
  });

  final String period;
  final DateTime? asOf;
  final List<CmacKpiMetric> kpis;
  final List<CmacNamedValue> doctorWorkload;
  final List<CmacNamedValue> departmentUtilization;
  final List<CmacSeriesPoint> peakVisitingHours;
}

class CmacQualityResponse {
  CmacQualityResponse({
    required this.period,
    this.asOf,
    required this.kpis,
    required this.incidentsByType,
    required this.complaintsByCategory,
    required this.auditFlags,
  });

  final String period;
  final DateTime? asOf;
  final List<CmacKpiMetric> kpis;
  final List<CmacNamedValue> incidentsByType;
  final List<CmacNamedValue> complaintsByCategory;
  final List<CmacAuditFlag> auditFlags;
}

class CmacStaffResponse {
  CmacStaffResponse({
    required this.period,
    this.asOf,
    required this.patientsPerDoctor,
    required this.labWorkloadPerTechnician,
    required this.departmentEfficiency,
  });

  final String period;
  final DateTime? asOf;
  final List<CmacNamedValue> patientsPerDoctor;
  final List<CmacNamedValue> labWorkloadPerTechnician;
  final List<CmacDepartmentEfficiency> departmentEfficiency;
}

class CmacDepartmentEfficiency {
  CmacDepartmentEfficiency({
    required this.department,
    required this.score,
    this.volume,
    this.complaints,
    this.waitMinutes,
  });

  final String department;
  final num score;
  final num? volume;
  final num? complaints;
  final num? waitMinutes;
}
