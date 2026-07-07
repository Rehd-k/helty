# Lab Invoice Queue — Frontend Integration Guide

## Summary

`GET /invoices/by-service-categories?category=Laboratory` is the lab billing/work queue. It now returns **only Laboratory invoice lines that do not yet have a lab order**.

Previously, every Laboratory line on a patient's open invoice was returned, including lines that had already been turned into lab orders and completed. That caused duplicate entries for inpatients when doctors submitted additional lab requests.

**You no longer need client-side deduplication** for this endpoint. The backend excludes consumed lines.

---

## Helty app — where this lives

The lab invoice queue is implemented in the Helty Flutter app via the shared **Waiting Patients** screen, not a dedicated lab module. The same screen is reused for Radiology and Dialysis with different `use` / `categoryQueries` values.

### Entry point and routing

| Item | Value |
|------|-------|
| Menu | Lab → **Waiting Patients** in [`lib/src/ui/home/account_types.dart`](../lib/src/ui/home/account_types.dart) |
| Route | `NewPatientRoute(use: 'Laboratory', categoryQueries: ['Laboratory', 'Laboratory Tests'])` |
| Queue screen | `NewPatientScreen` in [`lib/src/paitients/view_waiting_patient.dart`](../lib/src/paitients/view_waiting_patient.dart) |
| Order screen | `LabCreateOrderRoute` → [`lib/src/lab/ui/lab_create_order_screen.dart`](../lib/src/lab/ui/lab_create_order_screen.dart) |
| Shared state | `paidModuleRequestContextProvider` + `PaidModuleRequestContext` in [`lib/src/providers/module_request_flow_provider.dart`](../lib/src/providers/module_request_flow_provider.dart) |

### Client flow

```mermaid
sequenceDiagram
    participant Menu as LabMenu
    participant Queue as NewPatientScreen
    participant API as GET_by_service_categories
    participant Ctx as paidModuleRequestContextProvider
    participant Order as LabCreateOrderScreen
    participant LabAPI as POST_lab_orders

    Menu->>Queue: NewPatientRoute use=Laboratory
    Queue->>API: category, fromDate, toDate, search fields
    API-->>Queue: rows with invoiceItems
    Queue->>Ctx: PaidModuleRequestContext + serviceLines
    Queue->>Order: LabCreateOrderRoute
    Order->>LabAPI: per invoiceItemId
    LabAPI-->>Order: LabOrder
    Order->>Order: LabOrderDetailRoute
```

1. Lab staff opens **Waiting Patients** from the lab menu.
2. `NewPatientScreen` fetches `GET /invoices/by-service-categories` and renders a patient/invoice table with a detail panel.
3. Staff selects a row and taps **Open Patient** (when payment rules allow).
4. The screen sets `paidModuleRequestContextProvider` with `PaidModuleRequestContext` (patient, invoice, and `PaidInvoiceServiceLine[]`) and navigates to `LabCreateOrderRoute`.
5. `LabCreateOrderScreen` maps tests per invoice line and calls `POST /lab/orders` once per line.
6. On success, the app navigates to `LabOrderDetailRoute`; the queue is not auto-refreshed.

### Query params the Helty app sends

The queue fetch is in `_fetchPatients()` in [`view_waiting_patient.dart`](../lib/src/paitients/view_waiting_patient.dart). Compared to the API parameter table below:

| Parameter | Sent by Helty? | Notes |
|-----------|----------------|-------|
| `category` | Yes | `['Laboratory', 'Laboratory Tests']` via Dio repeated params |
| `fromDate` / `toDate` | Yes | Defaults to **today**; user can widen via date-range picker |
| `transactionId`, `patientName`, `invoiceId`, `invoiceID` | Yes (search) | Same search string sent to all four — **not** the unified `search` param |
| `status` | No | Intentionally omitted so unpaid inpatient lines appear |
| `skip` / `take` | No | Full result set returned in one request |
| `search` | No | Not used |

### Row parsing and UI model

- API `rows[]` is parsed by `_UnregisteredPatientTxn.fromJson()` (private class in `view_waiting_patient.dart`).
- `invoice.invoiceItems[]` maps to `List<PaidInvoiceServiceLine>` (`invoiceItemId`, `serviceId`, `serviceName`, `categoryName`).
- The queue UI is **invoice/patient-centric** (table + detail panel showing service count/names), not one table row per `invoiceItem`.
- Line-level work happens on `LabCreateOrderScreen` via invoice-line chips and per-line test mapping.

### Payment / open rules

`canOpenModulePatient` in `_UnregisteredPatientTxn`:

- **OPD** (`ward` empty or `"OPD"`): **Open Patient** is disabled until the invoice appears paid (`rowAppearsPaid`).
- **Inpatient / other wards**: may open unpaid (credit billing).
- The button label shows **"Bill Not Paid"** for unpaid OPD rows.

### Order creation

From the paid-lab path in `LabCreateOrderScreen`:

- One `POST /lab/orders` per selected invoice line with `invoiceId`, `invoiceItemId`, `serviceId`, `patientId`, `doctorId`.
- `_orderIdByInvoiceItemId` prevents double-submit **within the same screen session** only — not a substitute for backend queue filtering.
- After success, navigates to `LabOrderDetailRoute`; does **not** auto-return or refresh the queue.

### Pharmacy parallel

| | Pharmacy | Lab |
|---|----------|-----|
| Screen | [`waiting.patient.dart`](../lib/src/pharmacy/ui/waiting.patient.dart) | [`view_waiting_patient.dart`](../lib/src/paitients/view_waiting_patient.dart) (shared) |
| API | `GET /invoice-drugs` | `GET /invoices/by-service-categories` |
| Service layer | `PharmacyQueueApiService` | Inline `Dio` in screen |
| Pagination | `skip=0`, `take=20` with load-more | Not implemented |
| Work screen | Same screen (dispense) | Separate `LabCreateOrderScreen` |

---

## Endpoint

```
GET /invoices/by-service-categories?category=Laboratory
```

### Query parameters

| Parameter | Required | Description |
|-----------|----------|-------------|
| `category` | Yes | Repeat or comma-separate. Use `Laboratory` or `Laboratory Tests` (case-insensitive). |
| `status` | No | Filter by invoice status: `PENDING`, `PARTIALLY_PAID`, `PAID`. |
| `fromDate` / `toDate` | No | Filter by invoice `updatedAt` range. |
| `search` | No | Broad search (invoice ID, patient name, payment reference). |
| `patientName` | No | Patient first/last name substring. |
| `invoiceId` / `invoiceID` | No | Human invoice number or UUID. |
| `skip` / `take` | No | Pagination (default `skip=0`, `take=20`). |

### Laboratory filtering rule

When the requested category is **Laboratory** or **Laboratory Tests**:

- An invoice line is included only if `InvoiceItem.labOrder` is **null** (no lab order linked yet).
- Lines that already have a `LabOrder` (pending, in progress, or completed) are **excluded**.
- If every Laboratory line on an invoice has been ordered, that invoice **does not appear** in the results.

Other categories (e.g. Pharmacy) are unaffected.

Mixed-category queries (e.g. `category=Laboratory&category=Pharmacy`) apply the lab-order exclusion **only** to Laboratory lines.

---

## Workflow

```mermaid
sequenceDiagram
    participant Doctor
    participant Queue as Lab queue API
    participant Lab

    Doctor->>Queue: Lab request created (adds invoice line)
    Queue-->>Lab: Line appears in GET by-service-categories

    Lab->>Lab: POST /lab/orders with invoiceId + invoiceItemId + serviceId
    Note over Queue: Line now has LabOrder linked

    Queue-->>Lab: Line no longer returned

    Doctor->>Queue: Another lab request on same inpatient invoice
    Queue-->>Lab: Only the new un-ordered line is returned
```

1. Doctor creates a lab request (`POST /lab-requests`) with a `serviceId` → a Laboratory invoice line is added.
2. Lab staff sees the patient/line in the queue via `GET /invoices/by-service-categories?category=Laboratory`.
3. Lab creates an order (`POST /lab/orders`) using the invoice line IDs from the response.
4. That line disappears from the queue on the next fetch.
5. If the doctor requests more labs later, only the **new** un-ordered line(s) appear — not historical ones.

---

## Inpatients

For actively admitted inpatients:

- Multiple lab requests on the same open invoice are normal (each request adds a separate line).
- Unpaid/pending invoice lines are valid for lab order creation (credit billing).
- After this change, the queue shows **only lines still awaiting a lab order**, not the full invoice history.

---

## Response shape

The response structure is **unchanged**. Only which rows are returned differs.

```json
{
  "total": 1,
  "skip": 0,
  "take": 20,
  "categories": ["Laboratory"],
  "rows": [
    {
      "patientName": "Jane Doe",
      "firstName": "Jane",
      "surname": "Doe",
      "phone": "+234...",
      "age": 42,
      "ward": "Medical Ward",
      "gender": "FEMALE",
      "date": "2026-07-07T12:00:00.000Z",
      "invoice": {
        "id": "uuid-invoice",
        "invoiceID": "INV0000123",
        "invoiceId": "INV0000123",
        "status": "PENDING",
        "patientId": "uuid-patient",
        "patient": {
          "id": "uuid-patient",
          "patientId": "HOS-001",
          "title": "Mrs",
          "firstName": "Jane",
          "otherName": null,
          "surname": "Doe"
        },
        "invoiceItems": [
          {
            "id": "uuid-invoice-item",
            "serviceId": "uuid-service",
            "service": {
              "id": "uuid-service",
              "name": "Full Blood Count",
              "category": {
                "id": "uuid-category",
                "name": "Laboratory"
              }
            },
            "quantity": 1,
            "unitPrice": "2500.00",
            "amountPaid": "0.00",
            "customDescription": null,
            "requestingDoctor": "Dr. Smith",
            "createdBy": {
              "id": "uuid-staff",
              "firstName": "John",
              "lastName": "Smith"
            }
          }
        ]
      }
    }
  ]
}
```

### IDs needed to create a lab order

From each `invoiceItems[]` entry, pass to `POST /lab/orders`:

| Field | Source |
|-------|--------|
| `invoiceId` | `row.invoice.id` |
| `invoiceItemId` | `row.invoice.invoiceItems[].id` |
| `serviceId` | `row.invoice.invoiceItems[].serviceId` |
| `patientId` | `row.invoice.patientId` |
| `doctorId` | Ordering doctor staff ID (from your session/context) |

---

## Migration notes — backend

General guidance for any frontend consuming this endpoint:

1. **Remove duplicate filtering** — If the lab queue UI was hiding lines that already had orders (e.g. by tracking local state or cross-referencing `/lab/orders`), that logic is no longer required for this endpoint.
2. **Empty state** — An invoice vanishing from the list means all its Laboratory lines have been ordered; this is expected.
3. **Re-fetch after order creation** — After a successful `POST /lab/orders`, refresh the queue; the consumed line should be gone.
4. **Multiple lines per invoice** — A single `rows[]` entry may still contain multiple `invoiceItems` when several un-ordered lab requests exist on the same invoice. Each item is a separate actionable row in the UI.
5. **Category aliases** — Both `Laboratory` and `Laboratory Tests` are valid category names and receive the same pending-only filter.

### Helty app status

| Migration note | Helty status |
|----------------|--------------|
| Remove duplicate filtering against `/lab/orders` | **Done** — queue fetch does not cross-reference orders |
| Re-fetch after order creation | **Gap** — user must navigate back and pull-to-refresh (or re-enter screen) |
| Each `invoiceItem` = separate actionable queue row | **Partial** — lines shown in detail panel; actionable on `LabCreateOrderScreen`, not as separate queue rows |
| Empty state when all lines ordered | **Works** — relies on backend exclusion; no client dedup |
| Category aliases | **Done** — both categories sent |
| Pagination (`skip`/`take`) | **Gap** — not implemented |
| Unified `search` param | **Gap** — uses four separate params |
| `GET /lab/investigations` as work queue | **N/A in UI** — used only for investigations **report** (`LabInvestigationsRoute`) |

---

## Related endpoints

| Endpoint | Purpose |
|----------|---------|
| `POST /lab-requests` | Doctor creates a lab request (optionally bills via `serviceId`). |
| `POST /lab/orders` | Lab creates an order from a queued invoice line. |
| `GET /lab/investigations` | Alternative lab work queue (filters `labRequest` where `invoiceItem.labOrder` is null). |

The invoice queue and lab investigations queue now follow the same rule: **do not show work that already has a lab order**.

---

## File reference

Key Helty source files for the lab invoice queue flow:

- [`lib/src/paitients/view_waiting_patient.dart`](../lib/src/paitients/view_waiting_patient.dart) — queue list, fetch, row parsing
- [`lib/src/providers/module_request_flow_provider.dart`](../lib/src/providers/module_request_flow_provider.dart) — `PaidModuleRequestContext`, `PaidInvoiceServiceLine`
- [`lib/src/lab/ui/lab_create_order_screen.dart`](../lib/src/lab/ui/lab_create_order_screen.dart) — order creation from queued invoice lines
- [`lib/src/lab/services/lab_api_service.dart`](../lib/src/lab/services/lab_api_service.dart) — `POST /lab/orders` client
- [`lib/src/ui/home/account_types.dart`](../lib/src/ui/home/account_types.dart) — lab menu wiring
- [`lib/app_router.dart`](../lib/app_router.dart) — route registration
