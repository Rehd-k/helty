# CMD Analytics Live API Contract

This document is the frontend-facing contract for CMD analytics using **live backend data only**.
All endpoints are available under the API base URL with bearer authentication.

- Base auth: `Authorization: Bearer <token>`
- Roles: `CMD`, `CMAC`, `SUPER_ADMIN`
- Common optional query params: `period`, `asOf`, `departmentId`, `limit`
- Date format: ISO-8601 UTC string
- Empty states: `[]` and numeric `0` (never `null` for list/numeric metrics)

## Endpoints

### `GET /cmd/dashboard`
Executive aggregate payload for cards, alerts, revenue trend, capacity, staff, pharmacy, and lab summary.

### `GET /cmd/hospital/overview`
Department throughput, flow/wait-time blocks, and narrative summaries.

### `GET /cmd/financial/overview`
Outstanding payments, department contribution breakdown, payment mix, and finance watch blocks.

### `GET /cmd/staff/oversight`
Attendance, departmental staffing gaps, and workload/performance list.

### `GET /cmd/beds/snapshot`
Ward occupancy table and overcrowding messages.

### `GET /cmd/lab/monitoring`
Pending test rows, delay count, TAT, and machine status list.

### `GET /cmd/alerts`
Incident/alert list with severities: `critical | high | medium | low`.

### `GET /cmd/reports/templates`
Saved report templates:
- `id`
- `name`
- `cadence`
- `lastGeneratedAt`
- `formatsSupported`

### `GET /cmd/audit/logs`
Returns:
- `logs`: normalized audit events
- `compliance`: compliance checklist entries

### `GET /cmd/approvals/pending`
Pending approval queue for CMD control workflows.

### `GET /cmd/communications`
Scheduled/sent CMD communications.

### `POST /cmd/communications/broadcast`
Create and dispatch CMD broadcast.

Request body:
```json
{
  "title": "Message title",
  "body": "Message body",
  "audience": "all_staff",
  "priority": "high"
}
```

Priority values: `critical | high | medium | low`

### `GET /cmd/patient-experience`
Patient-experience metrics, complaint stream, and department ratings.

### `GET /cmd/settings/overview`
Integration health summary, role summary, and system banner draft.

## Notes For Frontend

- Remove local CMD mock payloads and switch all providers/screens to these endpoints.
- Use polling only where needed:
  - `/cmd/dashboard`: 60-120s
  - `/cmd/alerts`: 30-60s
  - `/cmd/beds/snapshot`, `/cmd/lab/monitoring`: 60-120s
  - Other pages: manual refresh or 2-5 minutes
