import 'cmd_models.dart';

double _num(dynamic v) {
  if (v is num) return v.toDouble();
  if (v is String) return double.parse(v);
  throw FormatException('Expected number, got $v');
}

int _int(dynamic v) {
  if (v is num) return v.toInt();
  if (v is String) return int.parse(v);
  throw FormatException('Expected int, got $v');
}

String _str(dynamic v) => v as String;

DateTime _dt(dynamic v) => DateTime.parse(v as String);

DateTime? _dtOpt(dynamic v) => v == null ? null : DateTime.parse(v as String);

List<T> _list<T>(dynamic v, T Function(Map<String, dynamic>) f) {
  final list = v as List<dynamic>;
  return list.map((e) => f(e as Map<String, dynamic>)).toList();
}

Map<String, dynamic> _map(dynamic v) => Map<String, dynamic>.from(v as Map);

CmdTrendDirection _trend(String s) {
  switch (s.toLowerCase()) {
    case 'up':
      return CmdTrendDirection.up;
    case 'down':
      return CmdTrendDirection.down;
    case 'flat':
      return CmdTrendDirection.flat;
    default:
      return CmdTrendDirection.flat;
  }
}

CmdIncidentSeverity _severity(String s) {
  switch (s.toLowerCase()) {
    case 'critical':
      return CmdIncidentSeverity.critical;
    case 'high':
      return CmdIncidentSeverity.high;
    case 'medium':
      return CmdIncidentSeverity.medium;
    case 'low':
      return CmdIncidentSeverity.low;
    default:
      return CmdIncidentSeverity.low;
  }
}

CmdKpiTile _kpi(Map<String, dynamic> j) => CmdKpiTile(
      id: _str(j['id']),
      label: _str(j['label']),
      value: _str(j['value']),
      trendLabel: _str(j['trendLabel']),
      direction: _trend(_str(j['direction'])),
      iconKey: _str(j['iconKey']),
      severity: j['severity'] as String?,
    );

CmdAlertChip _alert(Map<String, dynamic> j) => CmdAlertChip(
      id: _str(j['id']),
      message: _str(j['message']),
      level: _str(j['level']),
    );

CmdActivityFeedItem _activity(Map<String, dynamic> j) => CmdActivityFeedItem(
      id: _str(j['id']),
      at: _dt(j['at']),
      category: _str(j['category']),
      message: _str(j['message']),
      actorLabel: _str(j['actorLabel']),
    );

CmdRevenueSeriesPoint _revPoint(Map<String, dynamic> j) => CmdRevenueSeriesPoint(
      dayIndex: _int(j['dayIndex']),
      revenueInpatient: _num(j['revenueInpatient']),
      revenueOutpatient: _num(j['revenueOutpatient']),
    );

CmdCapacitySnapshot _capacity(Map<String, dynamic> j) => CmdCapacitySnapshot(
      totalBeds: _int(j['totalBeds']),
      occupiedBeds: _int(j['occupiedBeds']),
      occupancyPercent: _num(j['occupancyPercent']),
      icuPercent: _num(j['icuPercent']),
      generalWardPercent: _num(j['generalWardPercent']),
      maternityPercent: _num(j['maternityPercent']),
      erLoadLabel: _str(j['erLoadLabel']),
      icuLoadPercent: _num(j['icuLoadPercent']),
    );

CmdClinicalPerformance _clinical(Map<String, dynamic> j) => CmdClinicalPerformance(
      surgerySuccessRate: _num(j['surgerySuccessRate']),
      readmission30d: _num(j['readmission30d']),
      infectionRate: _num(j['infectionRate']),
      patientSatisfaction: _num(j['patientSatisfaction']),
    );

CmdStaffDutySnapshot _staffDuty(Map<String, dynamic> j) => CmdStaffDutySnapshot(
      doctorsOnDuty: _int(j['doctorsOnDuty']),
      nursesOnDuty: _int(j['nursesOnDuty']),
      absenteeismPercent: _num(j['absenteeismPercent']),
      overtimeHoursWeek: _int(j['overtimeHoursWeek']),
    );

CmdPharmacySnapshot _pharmacy(Map<String, dynamic> j) => CmdPharmacySnapshot(
      lowStockCount: _int(j['lowStockCount']),
      expiringBatches: _int(j['expiringBatches']),
      topDispensed: (j['topDispensed'] as List<dynamic>).map((e) => e as String).toList(),
    );

CmdLabSnapshot _labSnap(Map<String, dynamic> j) => CmdLabSnapshot(
      testsToday: _int(j['testsToday']),
      pendingCount: _int(j['pendingCount']),
      avgTurnaroundHours: _num(j['avgTurnaroundHours']),
      machineUptimePercent: _num(j['machineUptimePercent']),
      redoRatePercent: _num(j['redoRatePercent']),
    );

CmdExecutiveDashboardBundle parseCmdExecutiveDashboardBundle(Map<String, dynamic> j) {
  return CmdExecutiveDashboardBundle(
    kpis: _list(j['kpis'], _kpi),
    alerts: _list(j['alerts'], _alert),
    activityFeed: _list(j['activityFeed'], _activity),
    revenueWeek: _list(j['revenueWeek'], _revPoint),
    capacity: _capacity(_map(j['capacity'])),
    clinical: _clinical(_map(j['clinical'])),
    staff: _staffDuty(_map(j['staff'])),
    pharmacy: _pharmacy(_map(j['pharmacy'])),
    lab: _labSnap(_map(j['lab'])),
    revenueToday: _num(j['revenueToday']),
    revenueWeekTotal: _num(j['revenueWeekTotal']),
    revenueMonthTotal: _num(j['revenueMonthTotal']),
    patientsTodayOpd: _int(j['patientsTodayOpd']),
    patientsTodayAdmitted: _int(j['patientsTodayAdmitted']),
    pendingLabResults: _int(j['pendingLabResults']),
  );
}

CmdDepartmentScorecard _deptScore(Map<String, dynamic> j) => CmdDepartmentScorecard(
      departmentId: _str(j['departmentId']),
      name: _str(j['name']),
      patientsSeen: _int(j['patientsSeen']),
      revenue: _num(j['revenue'] ?? j['revenueDummy']),
      slaBreaches: _int(j['slaBreaches']),
      status: _str(j['status']),
    );

CmdFlowStageMetric _flow(Map<String, dynamic> j) => CmdFlowStageMetric(
      stage: _str(j['stage']),
      patientsInStage: _int(j['patientsInStage']),
      avgMinutes: _int(j['avgMinutes']),
    );

CmdWaitTimeRow _wait(Map<String, dynamic> j) => CmdWaitTimeRow(
      area: _str(j['area']),
      p50Minutes: _int(j['p50Minutes']),
      p90Minutes: _int(j['p90Minutes']),
      trendLabel: _str(j['trendLabel']),
    );

CmdHospitalOverview parseCmdHospitalOverview(Map<String, dynamic> j) => CmdHospitalOverview(
      departments: _list(j['departments'], _deptScore),
      flow: _list(j['flow'], _flow),
      waitTimes: _list(j['waitTimes'], _wait),
      dailySummary: _str(j['dailySummary']),
      weeklySummary: _str(j['weeklySummary']),
    );

CmdRevenueByDepartment _revDept(Map<String, dynamic> j) => CmdRevenueByDepartment(
      department: _str(j['department']),
      amount: _num(j['amount']),
      percentOfTotal: _num(j['percentOfTotal']),
    );

CmdPaymentMix _payMix(Map<String, dynamic> j) => CmdPaymentMix(
      insuranceAmount: _num(j['insuranceAmount']),
      cashAmount: _num(j['cashAmount']),
      corporateAmount: _num(j['corporateAmount']),
    );

CmdExpenseLine _expLine(Map<String, dynamic> j) => CmdExpenseLine(
      category: _str(j['category']),
      amount: _num(j['amount']),
      budget: _num(j['budget']),
      variancePercent: _num(j['variancePercent']),
    );

CmdLeakFlag _leak(Map<String, dynamic> j) => CmdLeakFlag(
      id: _str(j['id']),
      description: _str(j['description']),
      estimatedExposure: _num(j['estimatedExposure'] ?? j['estimatedExposureDummy']),
      status: _str(j['status']),
    );

CmdFinancialOverview parseCmdFinancialOverview(Map<String, dynamic> j) => CmdFinancialOverview(
      outstandingPayments: _num(j['outstandingPayments']),
      profitMarginPercent: _num(j['profitMarginPercent']),
      forecastNextMonth: _num(j['forecastNextMonth'] ?? j['forecastNextMonthDummy']),
      byDepartment: _list(j['byDepartment'], _revDept),
      paymentMix: _payMix(_map(j['paymentMix'])),
      expenses: _list(j['expenses'], _expLine),
      leaks: _list(j['leaks'], _leak),
    );

CmdStaffAttendanceSummary _attendance(Map<String, dynamic> j) => CmdStaffAttendanceSummary(
      onDuty: _int(j['onDuty']),
      scheduled: _int(j['scheduled']),
      late: _int(j['late']),
      absent: _int(j['absent']),
    );

CmdDepartmentStaffing _deptStaff(Map<String, dynamic> j) => CmdDepartmentStaffing(
      department: _str(j['department']),
      requiredHeadcount: _int(j['requiredHeadcount']),
      present: _int(j['present']),
      gap: _int(j['gap']),
    );

CmdStaffPerformanceRow _perfRow(Map<String, dynamic> j) => CmdStaffPerformanceRow(
      role: _str(j['role']),
      nameOrTeam: _str(j['nameOrTeam']),
      patientsHandled: _int(j['patientsHandled']),
      efficiencyScore: _num(j['efficiencyScore']),
    );

CmdStaffingAlert _staffAlert(Map<String, dynamic> j) => CmdStaffingAlert(
      id: _str(j['id']),
      message: _str(j['message']),
    );

CmdStaffOversight parseCmdStaffOversight(Map<String, dynamic> j) => CmdStaffOversight(
      attendance: _attendance(_map(j['attendance'])),
      byDepartment: _list(j['byDepartment'], _deptStaff),
      performance: _list(j['performance'], _perfRow),
      alerts: _list(j['alerts'], _staffAlert),
    );

CmdWardBedStats _ward(Map<String, dynamic> j) => CmdWardBedStats(
      wardName: _str(j['wardName']),
      totalBeds: _int(j['totalBeds']),
      occupied: _int(j['occupied']),
      acuityMix: _str(j['acuityMix']),
    );

CmdAdmissionDischargeEvent _admEvent(Map<String, dynamic> j) => CmdAdmissionDischargeEvent(
      at: _dt(j['at']),
      type: _str(j['type']),
      ward: _str(j['ward']),
      patientRef: _str(j['patientRef']),
    );

CmdBedsSnapshot parseCmdBedsSnapshot(Map<String, dynamic> j) => CmdBedsSnapshot(
      wards: _list(j['wards'], _ward),
      recentEvents: _list(j['recentEvents'], _admEvent),
      overcrowdingMessages: (j['overcrowdingMessages'] as List<dynamic>).map((e) => e as String).toList(),
    );

CmdLabPendingRow _labPending(Map<String, dynamic> j) => CmdLabPendingRow(
      testCode: _str(j['testCode']),
      count: _int(j['count']),
      oldestHours: _num(j['oldestHours']),
    );

CmdLabMachineStat _machine(Map<String, dynamic> j) => CmdLabMachineStat(
      name: _str(j['name']),
      uptimePercent: _num(j['uptimePercent']),
      backlog: _int(j['backlog']),
    );

CmdLabMonitoring parseCmdLabMonitoring(Map<String, dynamic> j) => CmdLabMonitoring(
      pendingRows: _list(j['pendingRows'], _labPending),
      delayedCount: _int(j['delayedCount']),
      avgTatHours: _num(j['avgTatHours']),
      redoPercent: _num(j['redoPercent']),
      machines: _list(j['machines'], _machine),
    );

CmdIncident _incident(Map<String, dynamic> j) => CmdIncident(
      id: _str(j['id']),
      severity: _severity(_str(j['severity'])),
      category: _str(j['category']),
      title: _str(j['title']),
      detail: _str(j['detail']),
      createdAt: _dt(j['createdAt']),
      owner: _str(j['owner']),
      status: _str(j['status']),
    );

List<CmdIncident> parseCmdIncidentList(List<dynamic> list) =>
    list.map((e) => _incident(e as Map<String, dynamic>)).toList();

CmdReportTemplate _reportTpl(Map<String, dynamic> j) => CmdReportTemplate(
      id: _str(j['id']),
      name: _str(j['name']),
      cadence: _str(j['cadence']),
      lastGeneratedAt: _dtOpt(j['lastGeneratedAt']),
      formatsSupported: (j['formatsSupported'] as List<dynamic>).map((e) => e as String).toList(),
    );

List<CmdReportTemplate> parseCmdReportTemplateList(List<dynamic> list) =>
    list.map((e) => _reportTpl(e as Map<String, dynamic>)).toList();

CmdAuditLogEntry _auditLog(Map<String, dynamic> j) => CmdAuditLogEntry(
      id: _str(j['id']),
      at: _dt(j['at']),
      user: _str(j['user']),
      action: _str(j['action']),
      entity: _str(j['entity']),
      metadata: _str(j['metadata']),
    );

CmdComplianceItem _compliance(Map<String, dynamic> j) => CmdComplianceItem(
      code: _str(j['code']),
      description: _str(j['description']),
      status: _str(j['status']),
      evidenceUrl: j['evidenceUrl'] as String?,
    );

CmdAuditComplianceBundle parseCmdAuditComplianceBundle(Map<String, dynamic> j) => CmdAuditComplianceBundle(
      logs: _list(j['logs'], _auditLog),
      compliance: _list(j['compliance'], _compliance),
    );

CmdApprovalRequest _approval(Map<String, dynamic> j) => CmdApprovalRequest(
      id: _str(j['id']),
      type: _str(j['type']),
      amount: _num(j['amount'] ?? j['amountDummy']),
      requester: _str(j['requester']),
      status: _str(j['status']),
      submittedAt: _dt(j['submittedAt']),
    );

List<CmdApprovalRequest> parseCmdApprovalRequestList(List<dynamic> list) =>
    list.map((e) => _approval(e as Map<String, dynamic>)).toList();

CmdIntegrationSetting _integration(Map<String, dynamic> j) => CmdIntegrationSetting(
      name: _str(j['name']),
      status: _str(j['status']),
      lastSyncAt: _dtOpt(j['lastSyncAt']),
    );

CmdSettingsOverview parseCmdSettingsOverview(Map<String, dynamic> j) => CmdSettingsOverview(
      integrations: _list(j['integrations'], _integration),
      rolesSummary: _str(j['rolesSummary']),
      bannerDraft: _str(j['bannerDraft']),
    );

CmdAnnouncement _announcement(Map<String, dynamic> j) => CmdAnnouncement(
      id: _str(j['id']),
      title: _str(j['title']),
      body: _str(j['body']),
      audience: _str(j['audience']),
      priority: _str(j['priority']),
      scheduledFor: _dtOpt(j['scheduledFor']),
      sentAt: _dtOpt(j['sentAt']),
    );

List<CmdAnnouncement> parseCmdAnnouncementList(List<dynamic> list) =>
    list.map((e) => _announcement(e as Map<String, dynamic>)).toList();

CmdSatisfactionMetric _sat(Map<String, dynamic> j) => CmdSatisfactionMetric(
      label: _str(j['label']),
      score: _num(j['score']),
      benchmark: _num(j['benchmark']),
      trendLabel: _str(j['trendLabel']),
    );

CmdComplaintRow _complaint(Map<String, dynamic> j) => CmdComplaintRow(
      id: _str(j['id']),
      department: _str(j['department']),
      summary: _str(j['summary']),
      status: _str(j['status']),
      openedAt: _dt(j['openedAt']),
    );

CmdDepartmentRating _deptRating(Map<String, dynamic> j) => CmdDepartmentRating(
      department: _str(j['department']),
      stars: _num(j['stars']),
      responseCount: _int(j['responseCount']),
    );

CmdPatientExperienceOverview parseCmdPatientExperienceOverview(Map<String, dynamic> j) =>
    CmdPatientExperienceOverview(
      metrics: _list(j['metrics'], _sat),
      complaints: _list(j['complaints'], _complaint),
      departmentRatings: _list(j['departmentRatings'], _deptRating),
      waitTimeInsight: _str(j['waitTimeInsight']),
    );
