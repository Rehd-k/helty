import 'package:flutter/foundation.dart';

// ── Dashboard bundle ───────────────────────────────────────────────────────

enum CmdTrendDirection { up, down, flat }

@immutable
class CmdKpiTile {
  const CmdKpiTile({
    required this.id,
    required this.label,
    required this.value,
    required this.trendLabel,
    required this.direction,
    required this.iconKey,
    this.severity,
  });

  final String id;
  final String label;
  final String value;
  final String trendLabel;
  final CmdTrendDirection direction;
  final String iconKey;
  final String? severity;
}

@immutable
class CmdActivityFeedItem {
  const CmdActivityFeedItem({
    required this.id,
    required this.at,
    required this.category,
    required this.message,
    required this.actorLabel,
  });

  final String id;
  final DateTime at;
  final String category;
  final String message;
  final String actorLabel;
}

@immutable
class CmdRevenueSeriesPoint {
  const CmdRevenueSeriesPoint({
    required this.dayIndex,
    required this.revenueInpatient,
    required this.revenueOutpatient,
  });

  final int dayIndex;
  final double revenueInpatient;
  final double revenueOutpatient;
}

@immutable
class CmdCapacitySnapshot {
  const CmdCapacitySnapshot({
    required this.totalBeds,
    required this.occupiedBeds,
    required this.occupancyPercent,
    required this.icuPercent,
    required this.generalWardPercent,
    required this.maternityPercent,
    required this.erLoadLabel,
    required this.icuLoadPercent,
  });

  final int totalBeds;
  final int occupiedBeds;
  final double occupancyPercent;
  final double icuPercent;
  final double generalWardPercent;
  final double maternityPercent;
  final String erLoadLabel;
  final double icuLoadPercent;
}

@immutable
class CmdClinicalPerformance {
  const CmdClinicalPerformance({
    required this.surgerySuccessRate,
    required this.readmission30d,
    required this.infectionRate,
    required this.patientSatisfaction,
  });

  final double surgerySuccessRate;
  final double readmission30d;
  final double infectionRate;
  final double patientSatisfaction;
}

@immutable
class CmdStaffDutySnapshot {
  const CmdStaffDutySnapshot({
    required this.doctorsOnDuty,
    required this.nursesOnDuty,
    required this.absenteeismPercent,
    required this.overtimeHoursWeek,
  });

  final int doctorsOnDuty;
  final int nursesOnDuty;
  final double absenteeismPercent;
  final int overtimeHoursWeek;
}

@immutable
class CmdPharmacySnapshot {
  const CmdPharmacySnapshot({
    required this.lowStockCount,
    required this.expiringBatches,
    required this.topDispensed,
  });

  final int lowStockCount;
  final int expiringBatches;
  final List<String> topDispensed;
}

@immutable
class CmdLabSnapshot {
  const CmdLabSnapshot({
    required this.testsToday,
    required this.pendingCount,
    required this.avgTurnaroundHours,
    required this.machineUptimePercent,
    required this.redoRatePercent,
  });

  final int testsToday;
  final int pendingCount;
  final double avgTurnaroundHours;
  final double machineUptimePercent;
  final double redoRatePercent;
}

@immutable
class CmdAlertChip {
  const CmdAlertChip({required this.id, required this.message, required this.level});

  final String id;
  final String message;
  final String level;
}

@immutable
class CmdExecutiveDashboardBundle {
  const CmdExecutiveDashboardBundle({
    required this.kpis,
    required this.alerts,
    required this.activityFeed,
    required this.revenueWeek,
    required this.capacity,
    required this.clinical,
    required this.staff,
    required this.pharmacy,
    required this.lab,
    required this.revenueToday,
    required this.revenueWeekTotal,
    required this.revenueMonthTotal,
    required this.patientsTodayOpd,
    required this.patientsTodayAdmitted,
    required this.pendingLabResults,
  });

  final List<CmdKpiTile> kpis;
  final List<CmdAlertChip> alerts;
  final List<CmdActivityFeedItem> activityFeed;
  final List<CmdRevenueSeriesPoint> revenueWeek;
  final CmdCapacitySnapshot capacity;
  final CmdClinicalPerformance clinical;
  final CmdStaffDutySnapshot staff;
  final CmdPharmacySnapshot pharmacy;
  final CmdLabSnapshot lab;
  final double revenueToday;
  final double revenueWeekTotal;
  final double revenueMonthTotal;
  final int patientsTodayOpd;
  final int patientsTodayAdmitted;
  final int pendingLabResults;
}

// ── Hospital overview ───────────────────────────────────────────────────────

@immutable
class CmdDepartmentScorecard {
  const CmdDepartmentScorecard({
    required this.departmentId,
    required this.name,
    required this.patientsSeen,
    required this.revenueDummy,
    required this.slaBreaches,
    required this.status,
  });

  final String departmentId;
  final String name;
  final int patientsSeen;
  final double revenueDummy;
  final int slaBreaches;
  final String status;
}

@immutable
class CmdFlowStageMetric {
  const CmdFlowStageMetric({
    required this.stage,
    required this.patientsInStage,
    required this.avgMinutes,
  });

  final String stage;
  final int patientsInStage;
  final int avgMinutes;
}

@immutable
class CmdWaitTimeRow {
  const CmdWaitTimeRow({
    required this.area,
    required this.p50Minutes,
    required this.p90Minutes,
    required this.trendLabel,
  });

  final String area;
  final int p50Minutes;
  final int p90Minutes;
  final String trendLabel;
}

@immutable
class CmdHospitalOverview {
  const CmdHospitalOverview({
    required this.departments,
    required this.flow,
    required this.waitTimes,
    required this.dailySummary,
    required this.weeklySummary,
  });

  final List<CmdDepartmentScorecard> departments;
  final List<CmdFlowStageMetric> flow;
  final List<CmdWaitTimeRow> waitTimes;
  final String dailySummary;
  final String weeklySummary;
}

// ── Financial (dummy figures) ─────────────────────────────────────────────

@immutable
class CmdRevenueByDepartment {
  const CmdRevenueByDepartment({
    required this.department,
    required this.amount,
    required this.percentOfTotal,
  });

  final String department;
  final double amount;
  final double percentOfTotal;
}

@immutable
class CmdPaymentMix {
  const CmdPaymentMix({
    required this.insuranceAmount,
    required this.cashAmount,
    required this.corporateAmount,
  });

  final double insuranceAmount;
  final double cashAmount;
  final double corporateAmount;
}

@immutable
class CmdExpenseLine {
  const CmdExpenseLine({
    required this.category,
    required this.amount,
    required this.budget,
    required this.variancePercent,
  });

  final String category;
  final double amount;
  final double budget;
  final double variancePercent;
}

@immutable
class CmdLeakFlag {
  const CmdLeakFlag({
    required this.id,
    required this.description,
    required this.estimatedExposureDummy,
    required this.status,
  });

  final String id;
  final String description;
  final double estimatedExposureDummy;
  final String status;
}

@immutable
class CmdFinancialOverview {
  const CmdFinancialOverview({
    required this.outstandingPayments,
    required this.profitMarginPercent,
    required this.forecastNextMonthDummy,
    required this.byDepartment,
    required this.paymentMix,
    required this.expenses,
    required this.leaks,
  });

  final double outstandingPayments;
  final double profitMarginPercent;
  final double forecastNextMonthDummy;
  final List<CmdRevenueByDepartment> byDepartment;
  final CmdPaymentMix paymentMix;
  final List<CmdExpenseLine> expenses;
  final List<CmdLeakFlag> leaks;
}

// ── Staff ─────────────────────────────────────────────────────────────────

@immutable
class CmdStaffAttendanceSummary {
  const CmdStaffAttendanceSummary({
    required this.onDuty,
    required this.scheduled,
    required this.late,
    required this.absent,
  });

  final int onDuty;
  final int scheduled;
  final int late;
  final int absent;
}

@immutable
class CmdDepartmentStaffing {
  const CmdDepartmentStaffing({
    required this.department,
    required this.requiredHeadcount,
    required this.present,
    required this.gap,
  });

  final String department;
  final int requiredHeadcount;
  final int present;
  final int gap;
}

@immutable
class CmdStaffPerformanceRow {
  const CmdStaffPerformanceRow({
    required this.role,
    required this.nameOrTeam,
    required this.patientsHandled,
    required this.efficiencyScore,
  });

  final String role;
  final String nameOrTeam;
  final int patientsHandled;
  final double efficiencyScore;
}

@immutable
class CmdStaffingAlert {
  const CmdStaffingAlert({required this.id, required this.message});

  final String id;
  final String message;
}

@immutable
class CmdStaffOversight {
  const CmdStaffOversight({
    required this.attendance,
    required this.byDepartment,
    required this.performance,
    required this.alerts,
  });

  final CmdStaffAttendanceSummary attendance;
  final List<CmdDepartmentStaffing> byDepartment;
  final List<CmdStaffPerformanceRow> performance;
  final List<CmdStaffingAlert> alerts;
}

// ── Beds ──────────────────────────────────────────────────────────────────

@immutable
class CmdWardBedStats {
  const CmdWardBedStats({
    required this.wardName,
    required this.totalBeds,
    required this.occupied,
    required this.acuityMix,
  });

  final String wardName;
  final int totalBeds;
  final int occupied;
  final String acuityMix;
}

@immutable
class CmdAdmissionDischargeEvent {
  const CmdAdmissionDischargeEvent({
    required this.at,
    required this.type,
    required this.ward,
    required this.patientRef,
  });

  final DateTime at;
  final String type;
  final String ward;
  final String patientRef;
}

@immutable
class CmdBedsSnapshot {
  const CmdBedsSnapshot({
    required this.wards,
    required this.recentEvents,
    required this.overcrowdingMessages,
  });

  final List<CmdWardBedStats> wards;
  final List<CmdAdmissionDischargeEvent> recentEvents;
  final List<String> overcrowdingMessages;
}

// ── Lab monitoring ────────────────────────────────────────────────────────

@immutable
class CmdLabPendingRow {
  const CmdLabPendingRow({
    required this.testCode,
    required this.count,
    required this.oldestHours,
  });

  final String testCode;
  final int count;
  final double oldestHours;
}

@immutable
class CmdLabMachineStat {
  const CmdLabMachineStat({
    required this.name,
    required this.uptimePercent,
    required this.backlog,
  });

  final String name;
  final double uptimePercent;
  final int backlog;
}

@immutable
class CmdLabMonitoring {
  const CmdLabMonitoring({
    required this.pendingRows,
    required this.delayedCount,
    required this.avgTatHours,
    required this.redoPercent,
    required this.machines,
  });

  final List<CmdLabPendingRow> pendingRows;
  final int delayedCount;
  final double avgTatHours;
  final double redoPercent;
  final List<CmdLabMachineStat> machines;
}

// ── Alerts / incidents ─────────────────────────────────────────────────────

enum CmdIncidentSeverity { critical, high, medium, low }

@immutable
class CmdIncident {
  const CmdIncident({
    required this.id,
    required this.severity,
    required this.category,
    required this.title,
    required this.detail,
    required this.createdAt,
    required this.owner,
    required this.status,
  });

  final String id;
  final CmdIncidentSeverity severity;
  final String category;
  final String title;
  final String detail;
  final DateTime createdAt;
  final String owner;
  final String status;
}

// ── Reports ────────────────────────────────────────────────────────────────

@immutable
class CmdReportTemplate {
  const CmdReportTemplate({
    required this.id,
    required this.name,
    required this.cadence,
    required this.lastGeneratedAt,
    required this.formatsSupported,
  });

  final String id;
  final String name;
  final String cadence;
  final DateTime? lastGeneratedAt;
  final List<String> formatsSupported;
}

// ── Audit ─────────────────────────────────────────────────────────────────

@immutable
class CmdAuditLogEntry {
  const CmdAuditLogEntry({
    required this.id,
    required this.at,
    required this.user,
    required this.action,
    required this.entity,
    required this.metadata,
  });

  final String id;
  final DateTime at;
  final String user;
  final String action;
  final String entity;
  final String metadata;
}

@immutable
class CmdComplianceItem {
  const CmdComplianceItem({
    required this.code,
    required this.description,
    required this.status,
    this.evidenceUrl,
  });

  final String code;
  final String description;
  final String status;
  final String? evidenceUrl;
}

@immutable
class CmdAuditComplianceBundle {
  const CmdAuditComplianceBundle({
    required this.logs,
    required this.compliance,
  });

  final List<CmdAuditLogEntry> logs;
  final List<CmdComplianceItem> compliance;
}

// ── Approvals / settings ─────────────────────────────────────────────────

@immutable
class CmdApprovalRequest {
  const CmdApprovalRequest({
    required this.id,
    required this.type,
    required this.amountDummy,
    required this.requester,
    required this.status,
    required this.submittedAt,
  });

  final String id;
  final String type;
  final double amountDummy;
  final String requester;
  final String status;
  final DateTime submittedAt;
}

@immutable
class CmdIntegrationSetting {
  const CmdIntegrationSetting({
    required this.name,
    required this.status,
    this.lastSyncAt,
  });

  final String name;
  final String status;
  final DateTime? lastSyncAt;
}

@immutable
class CmdSettingsOverview {
  const CmdSettingsOverview({
    required this.integrations,
    required this.rolesSummary,
    required this.bannerDraft,
  });

  final List<CmdIntegrationSetting> integrations;
  final String rolesSummary;
  final String bannerDraft;
}

// ── Communication ────────────────────────────────────────────────────────

@immutable
class CmdAnnouncement {
  const CmdAnnouncement({
    required this.id,
    required this.title,
    required this.body,
    required this.audience,
    required this.priority,
    this.scheduledFor,
    this.sentAt,
  });

  final String id;
  final String title;
  final String body;
  final String audience;
  final String priority;
  final DateTime? scheduledFor;
  final DateTime? sentAt;
}

// ── Patient experience ─────────────────────────────────────────────────────

@immutable
class CmdSatisfactionMetric {
  const CmdSatisfactionMetric({
    required this.label,
    required this.score,
    required this.benchmark,
    required this.trendLabel,
  });

  final String label;
  final double score;
  final double benchmark;
  final String trendLabel;
}

@immutable
class CmdComplaintRow {
  const CmdComplaintRow({
    required this.id,
    required this.department,
    required this.summary,
    required this.status,
    required this.openedAt,
  });

  final String id;
  final String department;
  final String summary;
  final String status;
  final DateTime openedAt;
}

@immutable
class CmdDepartmentRating {
  const CmdDepartmentRating({
    required this.department,
    required this.stars,
    required this.responseCount,
  });

  final String department;
  final double stars;
  final int responseCount;
}

@immutable
class CmdPatientExperienceOverview {
  const CmdPatientExperienceOverview({
    required this.metrics,
    required this.complaints,
    required this.departmentRatings,
    required this.waitTimeInsight,
  });

  final List<CmdSatisfactionMetric> metrics;
  final List<CmdComplaintRow> complaints;
  final List<CmdDepartmentRating> departmentRatings;
  final String waitTimeInsight;
}
