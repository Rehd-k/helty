import '../cmd_money_format.dart';
import '../models/cmd_models.dart';

/// Rich dummy dataset for CMD screens. Financial amounts are **not** real.
abstract final class CmdMockData {
  static final DateTime _now = DateTime(2026, 3, 23, 14, 30);

  static CmdExecutiveDashboardBundle executiveDashboard() {
    const revenueToday = 42850.00;
    const outstandingArDummy = 118000.00;
    final compact = cmdNairaCompactFormat();
    return CmdExecutiveDashboardBundle(
      revenueToday: revenueToday,
      revenueWeekTotal: 284200.00,
      revenueMonthTotal: 1124500.00,
      patientsTodayOpd: 842,
      patientsTodayAdmitted: 87,
      pendingLabResults: 63,
      kpis: [
        const CmdKpiTile(
          id: 'k1',
          label: 'Patients Today (OPD)',
          value: '842',
          trendLabel: '+5.2%',
          direction: CmdTrendDirection.up,
          iconKey: 'people',
        ),
        const CmdKpiTile(
          id: 'k2',
          label: 'Admissions Today',
          value: '87',
          trendLabel: '+2.1%',
          direction: CmdTrendDirection.up,
          iconKey: 'login',
        ),
        const CmdKpiTile(
          id: 'k3',
          label: 'Bed occupancy',
          value: '78%',
          trendLabel: '-1.0%',
          direction: CmdTrendDirection.down,
          iconKey: 'bed',
        ),
        CmdKpiTile(
          id: 'k4',
          label: 'Revenue today (dummy)',
          value: compact.format(revenueToday),
          trendLabel: '+12%',
          direction: CmdTrendDirection.up,
          iconKey: 'money',
        ),
        const CmdKpiTile(
          id: 'k5',
          label: 'Staff on duty',
          value: '312',
          trendLabel: '+3%',
          direction: CmdTrendDirection.up,
          iconKey: 'badge',
        ),
        const CmdKpiTile(
          id: 'k6',
          label: 'Pending lab results',
          value: '63',
          trendLabel: '+4',
          direction: CmdTrendDirection.up,
          iconKey: 'science',
          severity: 'warn',
        ),
        CmdKpiTile(
          id: 'k7',
          label: 'Outstanding AR (dummy)',
          value: compact.format(outstandingArDummy),
          trendLabel: '-2%',
          direction: CmdTrendDirection.down,
          iconKey: 'receipt',
        ),
        const CmdKpiTile(
          id: 'k8',
          label: 'ER visits (24h)',
          value: '142',
          trendLabel: '+8%',
          direction: CmdTrendDirection.up,
          iconKey: 'emergency',
        ),
      ],
      alerts: [
        const CmdAlertChip(id: 'a1', message: 'ICU at 94% capacity — consider diversion', level: 'critical'),
        const CmdAlertChip(id: 'a2', message: 'MRI suite offline until 18:00 (planned maintenance)', level: 'high'),
        const CmdAlertChip(id: 'a3', message: 'Pharmacy: 14 items below par level', level: 'high'),
        const CmdAlertChip(id: 'a4', message: 'Ward B: surgical site infection cluster under review', level: 'medium'),
        const CmdAlertChip(id: 'a5', message: '12 unpaid inpatient accounts > 7 days', level: 'medium'),
        const CmdAlertChip(id: 'a6', message: 'Blood bank O- units below safety stock', level: 'high'),
      ],
      activityFeed: [
        CmdActivityFeedItem(
          id: 'f1',
          at: _now.subtract(const Duration(minutes: 4)),
          category: 'Admission',
          message: 'Patient admitted to ICU bay 3 — sepsis protocol',
          actorLabel: 'ER Charge Nurse',
        ),
        CmdActivityFeedItem(
          id: 'f2',
          at: _now.subtract(const Duration(minutes: 12)),
          category: 'Lab',
          message: 'CBC batch #4482 — TAT exceeded 120m (flagged)',
          actorLabel: 'Lab Supervisor',
        ),
        CmdActivityFeedItem(
          id: 'f3',
          at: _now.subtract(const Duration(minutes: 25)),
          category: 'Billing',
          message:
              'Large invoice ${cmdNairaFormat().format(18400)} pending CMD approval',
          actorLabel: 'Billing Lead',
        ),
        CmdActivityFeedItem(
          id: 'f4',
          at: _now.subtract(const Duration(minutes: 40)),
          category: 'Radiology',
          message: 'CT backlog cleared for priority list',
          actorLabel: 'Radiology Manager',
        ),
        CmdActivityFeedItem(
          id: 'f5',
          at: _now.subtract(const Duration(hours: 1, minutes: 5)),
          category: 'System',
          message: 'HL7 feed to insurer restored — 22m downtime',
          actorLabel: 'IT Operations',
        ),
        CmdActivityFeedItem(
          id: 'f6',
          at: _now.subtract(const Duration(hours: 2)),
          category: 'Discharge',
          message: 'Med-surg 4W: 6 discharges before noon',
          actorLabel: 'Ward Clerk',
        ),
      ],
      revenueWeek: List.generate(
        7,
        (i) => CmdRevenueSeriesPoint(
          dayIndex: i,
          revenueInpatient: [30, 42, 38, 45, 41, 48, 44][i] * 1000.0,
          revenueOutpatient: [22, 28, 25, 30, 27, 32, 29][i] * 1000.0,
        ),
      ),
      capacity: const CmdCapacitySnapshot(
        totalBeds: 520,
        occupiedBeds: 406,
        occupancyPercent: 78,
        icuPercent: 20,
        generalWardPercent: 65,
        maternityPercent: 15,
        erLoadLabel: 'High',
        icuLoadPercent: 94,
      ),
      clinical: const CmdClinicalPerformance(
        surgerySuccessRate: 0.982,
        readmission30d: 0.118,
        infectionRate: 0.038,
        patientSatisfaction: 0.886,
      ),
      staff: const CmdStaffDutySnapshot(
        doctorsOnDuty: 46,
        nursesOnDuty: 132,
        absenteeismPercent: 3.1,
        overtimeHoursWeek: 442,
      ),
      pharmacy: const CmdPharmacySnapshot(
        lowStockCount: 14,
        expiringBatches: 5,
        topDispensed: [
          'Amoxicillin',
          'Paracetamol',
          'Metformin',
          'Atorvastatin',
          'Salbutamol inhaler',
        ],
      ),
      lab: const CmdLabSnapshot(
        testsToday: 1418,
        pendingCount: 63,
        avgTurnaroundHours: 2.4,
        machineUptimePercent: 99.1,
        redoRatePercent: 1.7,
      ),
    );
  }

  static CmdHospitalOverview hospitalOverview() {
    return CmdHospitalOverview(
      dailySummary:
          'As of 14:30 — ER flow steady; lab TAT elevated on chemistry; radiology backlog normalized.',
      weeklySummary:
          'Week-to-date: +6% outpatient visits vs prior week; inpatient admissions flat; pharmacy walk-ins +11%.',
      departments: const [
        CmdDepartmentScorecard(
          departmentId: 'er',
          name: 'Emergency',
          patientsSeen: 428,
          revenueDummy: 98500,
          slaBreaches: 12,
          status: 'Pressure',
        ),
        CmdDepartmentScorecard(
          departmentId: 'lab',
          name: 'Laboratory',
          patientsSeen: 0,
          revenueDummy: 62400,
          slaBreaches: 8,
          status: 'Watch',
        ),
        CmdDepartmentScorecard(
          departmentId: 'pharm',
          name: 'Pharmacy',
          patientsSeen: 0,
          revenueDummy: 41200,
          slaBreaches: 2,
          status: 'OK',
        ),
        CmdDepartmentScorecard(
          departmentId: 'rad',
          name: 'Radiology',
          patientsSeen: 0,
          revenueDummy: 77800,
          slaBreaches: 3,
          status: 'OK',
        ),
        CmdDepartmentScorecard(
          departmentId: 'surg',
          name: 'Surgery',
          patientsSeen: 36,
          revenueDummy: 201500,
          slaBreaches: 1,
          status: 'OK',
        ),
        CmdDepartmentScorecard(
          departmentId: 'med',
          name: 'Internal Medicine',
          patientsSeen: 198,
          revenueDummy: 134200,
          slaBreaches: 5,
          status: 'OK',
        ),
      ],
      flow: const [
        CmdFlowStageMetric(stage: 'Check-in / triage', patientsInStage: 54, avgMinutes: 14),
        CmdFlowStageMetric(stage: 'Consultation', patientsInStage: 112, avgMinutes: 28),
        CmdFlowStageMetric(stage: 'Diagnostics ordered', patientsInStage: 86, avgMinutes: 19),
        CmdFlowStageMetric(stage: 'Lab / imaging in progress', patientsInStage: 63, avgMinutes: 62),
        CmdFlowStageMetric(stage: 'Treatment / observation', patientsInStage: 204, avgMinutes: 95),
        CmdFlowStageMetric(stage: 'Discharge planning', patientsInStage: 31, avgMinutes: 41),
      ],
      waitTimes: const [
        CmdWaitTimeRow(area: 'ER triage', p50Minutes: 12, p90Minutes: 38, trendLabel: '+4m'),
        CmdWaitTimeRow(area: 'OPD consult', p50Minutes: 22, p90Minutes: 55, trendLabel: '-3m'),
        CmdWaitTimeRow(area: 'Lab routine', p50Minutes: 45, p90Minutes: 120, trendLabel: '+18m'),
        CmdWaitTimeRow(area: 'CT scan', p50Minutes: 35, p90Minutes: 90, trendLabel: '-10m'),
        CmdWaitTimeRow(area: 'Pharmacy dispense', p50Minutes: 18, p90Minutes: 42, trendLabel: 'flat'),
      ],
    );
  }

  static CmdFinancialOverview financialOverview() {
    return CmdFinancialOverview(
      outstandingPayments: 118400.00,
      profitMarginPercent: 18.6,
      forecastNextMonthDummy: 1240000.00,
      byDepartment: const [
        CmdRevenueByDepartment(department: 'Surgery', amount: 201500, percentOfTotal: 22.4),
        CmdRevenueByDepartment(department: 'Internal Medicine', amount: 134200, percentOfTotal: 14.9),
        CmdRevenueByDepartment(department: 'Emergency', amount: 98500, percentOfTotal: 10.9),
        CmdRevenueByDepartment(department: 'Radiology', amount: 77800, percentOfTotal: 8.6),
        CmdRevenueByDepartment(department: 'Laboratory', amount: 62400, percentOfTotal: 6.9),
        CmdRevenueByDepartment(department: 'Obstetrics', amount: 91200, percentOfTotal: 10.1),
        CmdRevenueByDepartment(department: 'Pharmacy (disp.)', amount: 41200, percentOfTotal: 4.6),
        CmdRevenueByDepartment(department: 'Other / ancillary', amount: 192700, percentOfTotal: 21.6),
      ],
      paymentMix: const CmdPaymentMix(
        insuranceAmount: 582000.00,
        cashAmount: 241500.00,
        corporateAmount: 198400.00,
      ),
      expenses: const [
        CmdExpenseLine(category: 'Payroll & locums', amount: 412000, budget: 400000, variancePercent: 3.0),
        CmdExpenseLine(category: 'Supplies & pharmacy COGS', amount: 198000, budget: 205000, variancePercent: -3.4),
        CmdExpenseLine(category: 'Utilities & facilities', amount: 62000, budget: 60000, variancePercent: 3.3),
        CmdExpenseLine(category: 'Equipment maintenance', amount: 48000, budget: 52000, variancePercent: -7.7),
        CmdExpenseLine(category: 'IT & software', amount: 31000, budget: 30000, variancePercent: 3.3),
      ],
      leaks: [
        const CmdLeakFlag(
          id: 'L1',
          description: 'Duplicate billing on 6 inpatient stays (coding review)',
          estimatedExposureDummy: 22400,
          status: 'Open',
        ),
        const CmdLeakFlag(
          id: 'L2',
          description: 'Theatre time blocks released late — 11 lost cases (opportunity)',
          estimatedExposureDummy: 48000,
          status: 'Investigating',
        ),
        const CmdLeakFlag(
          id: 'L3',
          description: 'Unmatched insurer remittances — 23 claims',
          estimatedExposureDummy: 13200,
          status: 'Open',
        ),
      ],
    );
  }

  static CmdStaffOversight staffOversight() {
    return CmdStaffOversight(
      attendance: const CmdStaffAttendanceSummary(
        onDuty: 312,
        scheduled: 318,
        late: 9,
        absent: 6,
      ),
      byDepartment: const [
        CmdDepartmentStaffing(department: 'ER', requiredHeadcount: 28, present: 26, gap: 2),
        CmdDepartmentStaffing(department: 'ICU', requiredHeadcount: 42, present: 42, gap: 0),
        CmdDepartmentStaffing(department: 'Med-Surg', requiredHeadcount: 55, present: 52, gap: 3),
        CmdDepartmentStaffing(department: 'Theatre', requiredHeadcount: 24, present: 24, gap: 0),
        CmdDepartmentStaffing(department: 'Lab', requiredHeadcount: 18, present: 17, gap: 1),
        CmdDepartmentStaffing(department: 'Radiology', requiredHeadcount: 14, present: 14, gap: 0),
      ],
      performance: const [
        CmdStaffPerformanceRow(role: 'Consultant', nameOrTeam: 'Team A — Gen Med', patientsHandled: 86, efficiencyScore: 0.91),
        CmdStaffPerformanceRow(role: 'Consultant', nameOrTeam: 'Team B — Gen Med', patientsHandled: 79, efficiencyScore: 0.88),
        CmdStaffPerformanceRow(role: 'Registrar', nameOrTeam: 'ER pool', patientsHandled: 124, efficiencyScore: 0.84),
        CmdStaffPerformanceRow(role: 'Nursing', nameOrTeam: 'ICU shift lead', patientsHandled: 0, efficiencyScore: 0.93),
      ],
      alerts: [
        const CmdStaffingAlert(id: 's1', message: 'ER: 2 RN short vs roster — locum requested'),
        const CmdStaffingAlert(id: 's2', message: 'Med-Surg 3E: 3 unplanned absences this morning'),
      ],
    );
  }

  static CmdBedsSnapshot bedsSnapshot() {
    return CmdBedsSnapshot(
      wards: const [
        CmdWardBedStats(wardName: 'ICU', totalBeds: 28, occupied: 26, acuityMix: 'High acuity 82%'),
        CmdWardBedStats(wardName: 'HDU', totalBeds: 12, occupied: 9, acuityMix: 'Step-down'),
        CmdWardBedStats(wardName: 'Med-Surg 3E', totalBeds: 36, occupied: 31, acuityMix: 'Mixed'),
        CmdWardBedStats(wardName: 'Med-Surg 4W', totalBeds: 40, occupied: 28, acuityMix: 'Mixed'),
        CmdWardBedStats(wardName: 'Maternity', totalBeds: 24, occupied: 19, acuityMix: 'Post-op + L&D'),
        CmdWardBedStats(wardName: 'Paediatrics', totalBeds: 20, occupied: 14, acuityMix: 'Mixed'),
      ],
      recentEvents: [
        CmdAdmissionDischargeEvent(
          at: _now.subtract(const Duration(minutes: 8)),
          type: 'Admission',
          ward: 'ICU',
          patientRef: 'IN-P-****821',
        ),
        CmdAdmissionDischargeEvent(
          at: _now.subtract(const Duration(minutes: 22)),
          type: 'Discharge',
          ward: 'Med-Surg 4W',
          patientRef: 'IN-P-****774',
        ),
        CmdAdmissionDischargeEvent(
          at: _now.subtract(const Duration(minutes: 35)),
          type: 'Transfer',
          ward: 'ER → HDU',
          patientRef: 'IN-P-****902',
        ),
        CmdAdmissionDischargeEvent(
          at: _now.subtract(const Duration(hours: 1, minutes: 10)),
          type: 'Admission',
          ward: 'Maternity',
          patientRef: 'IN-P-****301',
        ),
      ],
      overcrowdingMessages: const [
        'ICU: 2 beds remain — escalation protocol active',
        'ER: boarding time > 6h on 4 patients — consider ward expansion',
      ],
    );
  }

  static CmdLabMonitoring labMonitoring() {
    return CmdLabMonitoring(
      pendingRows: const [
        CmdLabPendingRow(testCode: 'CBC / FBC', count: 18, oldestHours: 3.2),
        CmdLabPendingRow(testCode: 'LFT', count: 12, oldestHours: 2.8),
        CmdLabPendingRow(testCode: 'Troponin', count: 9, oldestHours: 1.1),
        CmdLabPendingRow(testCode: 'HbA1c', count: 7, oldestHours: 6.0),
        CmdLabPendingRow(testCode: 'Culture', count: 14, oldestHours: 22.0),
      ],
      delayedCount: 27,
      avgTatHours: 2.4,
      redoPercent: 1.7,
      machines: const [
        CmdLabMachineStat(name: 'Chemistry analyser A', uptimePercent: 99.4, backlog: 42),
        CmdLabMachineStat(name: 'Chemistry analyser B', uptimePercent: 98.1, backlog: 58),
        CmdLabMachineStat(name: 'Haematology', uptimePercent: 99.8, backlog: 21),
        CmdLabMachineStat(name: 'Coagulation', uptimePercent: 97.2, backlog: 15),
      ],
    );
  }

  static List<CmdIncident> incidents() {
    return [
      CmdIncident(
        id: 'i1',
        severity: CmdIncidentSeverity.critical,
        category: 'Clinical',
        title: 'Code blue — Cath lab',
        detail: 'Adult male — ROSC achieved; moved to ICU.',
        createdAt: _now.subtract(const Duration(minutes: 6)),
        owner: 'Hospital coordinator',
        status: 'Active',
      ),
      CmdIncident(
        id: 'i2',
        severity: CmdIncidentSeverity.high,
        category: 'Safety',
        title: 'Blood fridge temperature excursion',
        detail: 'Unit B2 — 2°C above limit for 14 minutes; quarantine initiated.',
        createdAt: _now.subtract(const Duration(minutes: 18)),
        owner: 'Blood bank lead',
        status: 'Contained',
      ),
      CmdIncident(
        id: 'i3',
        severity: CmdIncidentSeverity.high,
        category: 'Operations',
        title: 'MRI downtime extended',
        detail: 'Vendor ETA 18:00 — elective list rescheduled (11 patients).',
        createdAt: _now.subtract(const Duration(minutes: 45)),
        owner: 'Radiology manager',
        status: 'Monitoring',
      ),
      CmdIncident(
        id: 'i4',
        severity: CmdIncidentSeverity.medium,
        category: 'Patient experience',
        title: 'Formal complaint — Ward 4W',
        detail: 'Delay in pain management — family escalated to on-call.',
        createdAt: _now.subtract(const Duration(hours: 2)),
        owner: 'Patient relations',
        status: 'Open',
      ),
      CmdIncident(
        id: 'i5',
        severity: CmdIncidentSeverity.medium,
        category: 'Billing',
        title: 'Insurance pre-auth failures spike',
        detail: '32 elective cases flagged — payer API errors 09:00–11:00.',
        createdAt: _now.subtract(const Duration(hours: 3)),
        owner: 'Billing manager',
        status: 'Mitigated',
      ),
    ];
  }

  static List<CmdReportTemplate> reportTemplates() {
    return [
      CmdReportTemplate(
        id: 'r1',
        name: 'Daily executive flash',
        cadence: 'Daily',
        lastGeneratedAt: _now.subtract(const Duration(hours: 5)),
        formatsSupported: const ['PDF', 'Excel'],
      ),
      CmdReportTemplate(
        id: 'r2',
        name: 'Weekly revenue & volume',
        cadence: 'Weekly',
        lastGeneratedAt: _now.subtract(const Duration(days: 2)),
        formatsSupported: const ['PDF', 'Excel', 'CSV'],
      ),
      CmdReportTemplate(
        id: 'r3',
        name: 'Monthly clinical quality pack',
        cadence: 'Monthly',
        lastGeneratedAt: _now.subtract(const Duration(days: 9)),
        formatsSupported: const ['PDF'],
      ),
      CmdReportTemplate(
        id: 'r4',
        name: 'Department scorecards',
        cadence: 'Monthly',
        lastGeneratedAt: _now.subtract(const Duration(days: 14)),
        formatsSupported: const ['Excel', 'PDF'],
      ),
    ];
  }

  static CmdAuditComplianceBundle auditCompliance() {
    return CmdAuditComplianceBundle(
      logs: [
        CmdAuditLogEntry(
          id: 'al1',
          at: _now.subtract(const Duration(minutes: 9)),
          user: 'jdoe@hospital',
          action: 'Override discount',
          entity: 'Invoice #INV-99281',
          metadata: 'Amount ${cmdNairaFormat().format(2400)} — reason: goodwill',
        ),
        CmdAuditLogEntry(
          id: 'al2',
          at: _now.subtract(const Duration(minutes: 44)),
          user: 'billing_mgr',
          action: 'Refund approved',
          entity: 'Payment #PAY-44102',
          metadata: '${cmdNairaFormat().format(640)} — duplicate charge',
        ),
        CmdAuditLogEntry(
          id: 'al3',
          at: _now.subtract(const Duration(hours: 2)),
          user: 'pharm_lead',
          action: 'Batch adjustment',
          entity: 'Inventory batch B-8831',
          metadata: 'Quarantine 120 units',
        ),
        CmdAuditLogEntry(
          id: 'al4',
          at: _now.subtract(const Duration(hours: 5)),
          user: 'admin',
          action: 'Role changed',
          entity: 'Staff #ST-221',
          metadata: 'Granted lab.result.finalize',
        ),
      ],
      compliance: const [
        CmdComplianceItem(code: 'MOH-01', description: 'Incident reporting within 24h', status: 'Compliant'),
        CmdComplianceItem(code: 'MOH-07', description: 'Controlled drug register reconciliation', status: 'Compliant'),
        CmdComplianceItem(code: 'DATA-03', description: 'PHI access review (quarterly)', status: 'Due in 12d'),
        CmdComplianceItem(code: 'RAD-02', description: 'Radiation safety badge audit', status: 'Action required'),
      ],
    );
  }

  static List<CmdApprovalRequest> approvals() {
    return [
      CmdApprovalRequest(
        id: 'ap1',
        type: 'Large adjustment',
        amountDummy: 18400,
        requester: 'Billing — M. Okon',
        status: 'Pending CMD',
        submittedAt: _now.subtract(const Duration(hours: 1)),
      ),
      CmdApprovalRequest(
        id: 'ap2',
        type: 'Refund',
        amountDummy: 2200,
        requester: 'Front desk — A. Mensah',
        status: 'Pending CMD',
        submittedAt: _now.subtract(const Duration(hours: 3)),
      ),
      CmdApprovalRequest(
        id: 'ap3',
        type: 'Theatre overtime block',
        amountDummy: 9600,
        requester: 'Theatre manager',
        status: 'Pending CMD',
        submittedAt: _now.subtract(const Duration(hours: 6)),
      ),
    ];
  }

  static CmdSettingsOverview settingsOverview() {
    return CmdSettingsOverview(
      integrations: [
        CmdIntegrationSetting(name: 'HL7 ADT — insurer', status: 'Connected', lastSyncAt: _now.subtract(const Duration(minutes: 2))),
        CmdIntegrationSetting(name: 'PACS / DICOM router', status: 'Connected', lastSyncAt: _now.subtract(const Duration(minutes: 5))),
        CmdIntegrationSetting(name: 'National ID verification', status: 'Degraded', lastSyncAt: _now.subtract(const Duration(hours: 2))),
        CmdIntegrationSetting(name: 'SMS gateway', status: 'Connected', lastSyncAt: _now.subtract(const Duration(minutes: 1))),
      ],
      rolesSummary: '42 roles defined · 18 permission bundles · last RBAC export 02 Mar 2026',
      bannerDraft: 'Board visit Thu 09:00 — ensure lobby signage and visitor badges.',
    );
  }

  static List<CmdAnnouncement> announcements() {
    return [
      CmdAnnouncement(
        id: 'an1',
        title: 'MRI downtime — elective rescheduling',
        body: 'Please communicate delays to patients on today\'s elective MRI list.',
        audience: 'All clinical + front desk',
        priority: 'High',
        sentAt: _now.subtract(const Duration(hours: 1)),
      ),
      CmdAnnouncement(
        id: 'an2',
        title: 'Sepsis pathway refresh',
        body: 'Training slides uploaded to intranet — completion by month end.',
        audience: 'ER + wards',
        priority: 'Normal',
        scheduledFor: _now.add(const Duration(days: 1)),
      ),
      CmdAnnouncement(
        id: 'an3',
        title: 'Visitor policy — flu season',
        body: 'Masks required in paediatrics and maternity until further notice.',
        audience: 'All staff',
        priority: 'Normal',
        sentAt: _now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  static CmdPatientExperienceOverview patientExperience() {
    return CmdPatientExperienceOverview(
      waitTimeInsight:
          'OPD wait P90 improved 8% vs last month; lab wait P90 worsened — align phlebotomy staffing on Mon/Wed peaks.',
      metrics: const [
        CmdSatisfactionMetric(label: 'Overall NPS (rolling 30d)', score: 42, benchmark: 35, trendLabel: '+6'),
        CmdSatisfactionMetric(label: 'Likelihood to recommend', score: 4.2, benchmark: 4.0, trendLabel: '+0.1'),
        CmdSatisfactionMetric(label: 'Communication clarity', score: 4.4, benchmark: 4.1, trendLabel: '+0.2'),
      ],
      complaints: [
        CmdComplaintRow(
          id: 'c1',
          department: 'ER',
          summary: 'Long wait with insufficient updates',
          status: 'In review',
          openedAt: _now.subtract(const Duration(days: 1)),
        ),
        CmdComplaintRow(
          id: 'c2',
          department: 'Billing',
          summary: 'Unexpected co-pay — explanation unclear',
          status: 'Resolved',
          openedAt: _now.subtract(const Duration(days: 4)),
        ),
        CmdComplaintRow(
          id: 'c3',
          department: 'Radiology',
          summary: 'Appointment rescheduled twice',
          status: 'Open',
          openedAt: _now.subtract(const Duration(hours: 20)),
        ),
      ],
      departmentRatings: const [
        CmdDepartmentRating(department: 'OPD', stars: 4.3, responseCount: 186),
        CmdDepartmentRating(department: 'ER', stars: 3.9, responseCount: 92),
        CmdDepartmentRating(department: 'Lab', stars: 4.1, responseCount: 64),
        CmdDepartmentRating(department: 'Pharmacy', stars: 4.5, responseCount: 141),
        CmdDepartmentRating(department: 'Maternity', stars: 4.7, responseCount: 58),
      ],
    );
  }
}
