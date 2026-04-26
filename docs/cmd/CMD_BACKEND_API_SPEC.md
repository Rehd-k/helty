# Command center (CMD) — backend API specification

This document describes REST endpoints and JSON shapes expected by the Helty Flutter client. Parsers live in [`lib/src/cmd/models/cmd_from_json.dart`](../../lib/src/cmd/models/cmd_from_json.dart); paths in [`lib/src/cmd/services/cmd_endpoints.dart`](../../lib/src/cmd/services/cmd_endpoints.dart).

## Conventions

- **Base URL**: whatever [`ApiService`](../../lib/src/services/api_service.dart) uses; paths below are relative (e.g. `/cmd/dashboard`).
- **Money**: JSON **numbers** are **major currency units in NGN** (naira), same as Dart `double` fields (not kobo), unless you later agree to switch to integer minor units (document that breaking change clearly).
- **Dates**: ISO-8601 strings (e.g. `2026-03-23T14:30:00.000Z`). The app formats them with `DateFormatter` for display.
- **Enums** (string values, case-insensitive where noted):
  - `CmdTrendDirection`: `up` | `down` | `flat`
  - `CmdIncidentSeverity`: `critical` | `high` | `medium` | `low`
- **Wrappers**: parsers assume the response body is either the object/array **directly**, or a single-key wrapper—if you use `{ "data": ... }`, add a unwrap step on the client or flatten at the gateway.

---

## `GET /cmd/dashboard`

**Response**: single JSON object → `CmdExecutiveDashboardBundle`.

| Field | Type | Notes |
|-------|------|--------|
| `kpis` | array of object | see `CmdKpiTile` |
| `alerts` | array of object | `CmdAlertChip` |
| `activityFeed` | array of object | `CmdActivityFeedItem` |
| `revenueWeek` | array of object | `CmdRevenueSeriesPoint` |
| `capacity` | object | `CmdCapacitySnapshot` |
| `clinical` | object | `CmdClinicalPerformance` |
| `staff` | object | `CmdStaffDutySnapshot` |
| `pharmacy` | object | `CmdPharmacySnapshot` |
| `lab` | object | `CmdLabSnapshot` |
| `revenueToday` | number | |
| `revenueWeekTotal` | number | |
| `revenueMonthTotal` | number | |
| `patientsTodayOpd` | number (int) | |
| `patientsTodayAdmitted` | number (int) | |
| `pendingLabResults` | number (int) | |

**`CmdKpiTile`**: `id`, `label`, `value`, `trendLabel`, `direction` (`up`/`down`/`flat`), `iconKey` (string), optional `severity` (string).

**`CmdAlertChip`**: `id`, `message`, `level`.

**`CmdActivityFeedItem`**: `id`, `at`, `category`, `message`, `actorLabel`.

**`CmdRevenueSeriesPoint`**: `dayIndex` (int), `revenueInpatient`, `revenueOutpatient` (numbers).

**`CmdCapacitySnapshot`**: `totalBeds`, `occupiedBeds`, `occupancyPercent`, `icuPercent`, `generalWardPercent`, `maternityPercent`, `erLoadLabel`, `icuLoadPercent`.

**`CmdClinicalPerformance`**: `surgerySuccessRate`, `readmission30d`, `infectionRate`, `patientSatisfaction` (0–1 style ratios).

**`CmdStaffDutySnapshot`**: `doctorsOnDuty`, `nursesOnDuty`, `absenteeismPercent`, `overtimeHoursWeek`.

**`CmdPharmacySnapshot`**: `lowStockCount`, `expiringBatches`, `topDispensed` (array of string).

**`CmdLabSnapshot`**: `testsToday`, `pendingCount`, `avgTurnaroundHours`, `machineUptimePercent`, `redoRatePercent`.

---

## `GET /cmd/hospital/overview`

**Response**: `CmdHospitalOverview` — `departments` (array of `CmdDepartmentScorecard`), `flow` (`CmdFlowStageMetric`), `waitTimes` (`CmdWaitTimeRow`), `dailySummary`, `weeklySummary` (strings).

**`CmdDepartmentScorecard`**: `departmentId`, `name`, `patientsSeen`, `revenueDummy`, `slaBreaches`, `status`.

**`CmdFlowStageMetric`**: `stage`, `patientsInStage`, `avgMinutes`.

**`CmdWaitTimeRow`**: `area`, `p50Minutes`, `p90Minutes`, `trendLabel`.

---

## `GET /cmd/financial/overview`

**Response**: `CmdFinancialOverview` — `outstandingPayments`, `profitMarginPercent`, `forecastNextMonthDummy`, `byDepartment` (array of `CmdRevenueByDepartment`), `paymentMix` (`CmdPaymentMix`), `expenses` (`CmdExpenseLine`), `leaks` (`CmdLeakFlag`).

**`CmdRevenueByDepartment`**: `department`, `amount`, `percentOfTotal`.

**`CmdPaymentMix`**: `insuranceAmount`, `cashAmount`, `corporateAmount`.

**`CmdExpenseLine`**: `category`, `amount`, `budget`, `variancePercent`.

**`CmdLeakFlag`**: `id`, `description`, `estimatedExposureDummy`, `status`.

---

## `GET /cmd/staff/oversight`

**Response**: `CmdStaffOversight` — `attendance` (`CmdStaffAttendanceSummary`: `onDuty`, `scheduled`, `late`, `absent`), `byDepartment` (`CmdDepartmentStaffing`), `performance` (`CmdStaffPerformanceRow`), `alerts` (`CmdStaffingAlert`).

**`CmdDepartmentStaffing`**: `department`, `requiredHeadcount`, `present`, `gap`.

**`CmdStaffPerformanceRow`**: `role`, `nameOrTeam`, `patientsHandled`, `efficiencyScore`.

**`CmdStaffingAlert`**: `id`, `message`.

---

## `GET /cmd/beds/snapshot`

**Response**: `CmdBedsSnapshot` — `wards` (`CmdWardBedStats`), `recentEvents` (`CmdAdmissionDischargeEvent`), `overcrowdingMessages` (array of string).

**`CmdWardBedStats`**: `wardName`, `totalBeds`, `occupied`, `acuityMix`.

**`CmdAdmissionDischargeEvent`**: `at`, `type`, `ward`, `patientRef`.

---

## `GET /cmd/lab/monitoring`

**Response**: `CmdLabMonitoring` — `pendingRows` (`CmdLabPendingRow`), `delayedCount`, `avgTatHours`, `redoPercent`, `machines` (`CmdLabMachineStat`).

**`CmdLabPendingRow`**: `testCode`, `count`, `oldestHours`.

**`CmdLabMachineStat`**: `name`, `uptimePercent`, `backlog`.

---

## `GET /cmd/alerts`

**Response**: JSON **array** of `CmdIncident`.

**`CmdIncident`**: `id`, `severity`, `category`, `title`, `detail`, `createdAt`, `owner`, `status`.

---

## `GET /cmd/reports/templates`

**Response**: JSON **array** of `CmdReportTemplate`.

**`CmdReportTemplate`**: `id`, `name`, `cadence`, `lastGeneratedAt` (nullable ISO string), `formatsSupported` (array of string).

---

## `GET /cmd/audit/logs`

**Response** (current client): single JSON object `CmdAuditComplianceBundle` — `logs` (`CmdAuditLogEntry`), `compliance` (`CmdComplianceItem`).

> If you split audit logs and compliance into two routes (`/cmd/audit/logs` and `/cmd/audit/compliance-checklist`), merge them in a BFF layer or extend [`CmdCommandService.fetchAuditCompliance`](../../lib/src/cmd/services/cmd_command_service.dart) to call both and assemble one bundle.

**`CmdAuditLogEntry`**: `id`, `at`, `user`, `action`, `entity`, `metadata`.

**`CmdComplianceItem`**: `code`, `description`, `status`, optional `evidenceUrl`.

---

## `GET /cmd/approvals/pending`

**Response**: JSON **array** of `CmdApprovalRequest`.

**`CmdApprovalRequest`**: `id`, `type`, `amountDummy`, `requester`, `status`, `submittedAt`.

---

## `GET /cmd/settings/overview`

**Response**: `CmdSettingsOverview` — `integrations` (`CmdIntegrationSetting`), `rolesSummary`, `bannerDraft`.

**`CmdIntegrationSetting`**: `name`, `status`, optional `lastSyncAt`.

---

## `GET /cmd/communications`

**Response**: JSON **array** of `CmdAnnouncement`.

**`CmdAnnouncement`**: `id`, `title`, `body`, `audience`, `priority`, optional `scheduledFor`, optional `sentAt`.

---

## `POST /cmd/communications/broadcast`

**Body** (JSON object):

```json
{
  "title": "string",
  "body": "string",
  "audience": "string",
  "priority": "string"
}
```

**Response**: `204` or small JSON `{ "ok": true }` (client ignores body today).

---

## `GET /cmd/patient-experience`

**Response**: `CmdPatientExperienceOverview` — `metrics` (`CmdSatisfactionMetric`), `complaints` (`CmdComplaintRow`), `departmentRatings` (`CmdDepartmentRating`), `waitTimeInsight`.

**`CmdSatisfactionMetric`**: `label`, `score`, `benchmark`, `trendLabel`.

**`CmdComplaintRow`**: `id`, `department`, `summary`, `status`, `openedAt`.

**`CmdDepartmentRating`**: `department`, `stars`, `responseCount`.

---

## Minimal example: `GET /cmd/dashboard` (truncated)

```json
{
  "revenueToday": 42850,
  "revenueWeekTotal": 284200,
  "revenueMonthTotal": 1124500,
  "patientsTodayOpd": 842,
  "patientsTodayAdmitted": 87,
  "pendingLabResults": 63,
  "kpis": [
    {
      "id": "k1",
      "label": "Patients Today (OPD)",
      "value": "842",
      "trendLabel": "+5.2%",
      "direction": "up",
      "iconKey": "people"
    }
  ],
  "alerts": [],
  "activityFeed": [],
  "revenueWeek": [],
  "capacity": {
    "totalBeds": 520,
    "occupiedBeds": 406,
    "occupancyPercent": 78,
    "icuPercent": 20,
    "generalWardPercent": 65,
    "maternityPercent": 15,
    "erLoadLabel": "High",
    "icuLoadPercent": 94
  },
  "clinical": {
    "surgerySuccessRate": 0.982,
    "readmission30d": 0.118,
    "infectionRate": 0.038,
    "patientSatisfaction": 0.886
  },
  "staff": {
    "doctorsOnDuty": 46,
    "nursesOnDuty": 132,
    "absenteeismPercent": 3.1,
    "overtimeHoursWeek": 442
  },
  "pharmacy": {
    "lowStockCount": 14,
    "expiringBatches": 5,
    "topDispensed": ["Amoxicillin"]
  },
  "lab": {
    "testsToday": 1418,
    "pendingCount": 63,
    "avgTurnaroundHours": 2.4,
    "machineUptimePercent": 99.1,
    "redoRatePercent": 1.7
  }
}
```

Fill `revenueWeek`, `activityFeed`, etc. with real arrays in production.
