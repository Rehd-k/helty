# Frontend Implementation: Pharmacy Department Dashboard

This document defines the frontend requirements for a Pharmacy Dashboard that gives operational, financial, clinical safety, and compliance visibility in one page.

## 1) Dashboard Goals

- Track daily pharmacy operations (orders, dispensing, pending workload).
- Monitor financial performance (revenue, insurance claims, purchase costs).
- Prevent stockout and wastage (low stock, expiry trends, inventory value).
- Improve safety and compliance (interaction/allergy alerts, controlled substances).
- Measure team output (pharmacist productivity and turnaround times).

## 2) Recommended Page Structure

Use a responsive layout with these sections:

1. Global filters + date range + department/store selector.
2. KPI cards row (high-priority metrics).
3. Operations and fulfillment panels.
4. Inventory health and expiry panels.
5. Revenue and usage charts.
6. Supplier/purchase and insurance panels.
7. Safety/compliance panels.
8. Pharmacist productivity table and trend chart.

## 3) Global Filters (Top Bar)

- Date range presets: `Today`, `Last 7 Days`, `Last 30 Days`, `This Month`, `Custom`.
- Optional filters:
  - `storeId` (main pharmacy, branch pharmacy)
  - `drugCategoryId`
  - `payerType` (`Cash`, `Insurance`, `Corporate`, `HMO`)
  - `pharmacistId`
  - `supplierId`
- Auto-refresh toggle (`30s`, `60s`, `5m`) and manual refresh button.

## 4) KPI Cards (Minimum Set)

Show these cards with value, delta (% change), and small sparkline:

1. **Prescriptions Processed**  
   - Count of prescriptions received/processed within date filter.
2. **Pending Orders**  
   - Orders not yet dispensed or partially dispensed.
3. **Dispensed Orders**  
   - Completed orders fully dispensed.
4. **Pharmacy Revenue**  
   - Total net sales in period.
5. **Inventory Value**  
   - Current stock value (`qty_on_hand * unit_cost`).
6. **Low Stock Drugs**  
   - Number of SKUs below reorder level.
7. **Out-of-Stock Drugs**  
   - Number of SKUs with zero available quantity.
8. **Near-Expiry Drugs**  
   - SKUs expiring within configurable threshold (default: 90 days).
9. **Expired Drugs**  
   - SKUs already expired but still in inventory records.

## 5) Core Widgets and Tables

### A) Order Status Breakdown
- Visualization: donut or stacked bar.
- Segments: `Pending`, `Partially Dispensed`, `Dispensed`, `Cancelled`.
- Include absolute count + percentage.

### B) Top-Selling Medications
- Metric basis: quantity sold and revenue generated.
- Table columns:
  - Drug name
  - Quantity sold
  - Revenue
  - Avg selling price
  - Stock remaining
- Time filter follows global date range.

### C) Most-Prescribed Medications
- Metric basis: number of prescription lines containing the drug.
- Table columns:
  - Drug name
  - Times prescribed
  - Distinct prescribers
  - Dispense completion rate

### D) Stock Movement
- Show inflow/outflow for period:
  - Opening stock
  - Purchases/receipts
  - Adjustments (+/-)
  - Dispensed quantity
  - Returns
  - Closing stock
- Visualization: waterfall or grouped bar.

### E) Supplier and Purchase Order Status
- Cards or table for:
  - Open purchase orders
  - Partially received
  - Fully received
  - Delayed orders
  - Outstanding payable amount
- Table columns:
  - PO number, supplier, order date, expected date, status, amount

### F) Insurance Claims
- Cards:
  - Submitted claims
  - Approved claims
  - Rejected claims
  - Pending claims
  - Claims value
- Trend chart: submissions vs approvals over time.
- Rejection reasons table (top reasons, frequency, value impact).

### G) Pharmacist Productivity
- Table columns:
  - Pharmacist name
  - Prescriptions verified
  - Orders dispensed
  - Avg turnaround time
  - Interventions/clarifications raised
  - Shift hours
- Optional derived metric:
  - `orders_dispensed / shift_hour`

### H) Drug Interaction and Allergy Alerts
- Cards:
  - Total alerts triggered
  - High-severity alerts
  - Overridden alerts
  - Accepted alerts (dispense blocked/changed)
- Recent alerts feed columns:
  - Time, patient, drug pair/allergen, severity, action taken, pharmacist

### I) Controlled Substance Log
- Compliance metrics:
  - Controlled prescriptions dispensed
  - Balance discrepancies
  - Unreconciled transactions
  - Daily opening vs closing balance variance
- Ledger table columns:
  - Drug, batch, opening balance, dispensed, adjusted, closing balance, witness/user, timestamp

## 6) Required Charts

### 1) Revenue Trend
- Type: line/area chart.
- X-axis: date bucket (day/week/month based on selected range).
- Series:
  - Gross revenue
  - Net revenue
  - Insurance reimbursed
  - Cash collected

### 2) Drug Usage Trend
- Type: multi-series line chart (top 5 or top 10 drugs).
- Values: quantity dispensed over time.
- Feature: selectable drug list (searchable).

### 3) Inventory Trend
- Type: line or area chart.
- Values:
  - Inventory value over time
  - Total stock units
  - Low-stock SKU count trend
  - Expiry-at-risk value trend

## 7) Suggested Backend Contracts (Frontend Consumption)

If your backend has different paths, map these to equivalent endpoints and keep response payloads consistent.

### Dashboard Summary
- `GET /pharmacy/dashboard/summary`
- Query:
  - `fromDate`, `toDate` (ISO)
  - `storeId?`, `pharmacistId?`, `supplierId?`, `payerType?`
- Response:
```json
{
  "prescriptionsProcessed": 0,
  "pendingOrders": 0,
  "dispensedOrders": 0,
  "revenue": 0,
  "inventoryValue": 0,
  "lowStockCount": 0,
  "outOfStockCount": 0,
  "nearExpiryCount": 0,
  "expiredCount": 0
}
```

### Operational Breakdown
- `GET /pharmacy/dashboard/orders-status`
- `GET /pharmacy/dashboard/top-selling`
- `GET /pharmacy/dashboard/most-prescribed`
- `GET /pharmacy/dashboard/stock-movement`

### Supply Chain + Insurance
- `GET /pharmacy/dashboard/purchase-orders`
- `GET /pharmacy/dashboard/insurance-claims`

### Safety + Compliance
- `GET /pharmacy/dashboard/interaction-alerts`
- `GET /pharmacy/dashboard/controlled-substances`

### Chart Data
- `GET /pharmacy/dashboard/charts/revenue`
- `GET /pharmacy/dashboard/charts/drug-usage`
- `GET /pharmacy/dashboard/charts/inventory`

## 8) Frontend Data Model (TypeScript Suggestion)

```ts
export type PharmacyDashboardFilters = {
  fromDate: string;
  toDate: string;
  storeId?: string;
  pharmacistId?: string;
  supplierId?: string;
  payerType?: 'Cash' | 'Insurance' | 'Corporate' | 'HMO';
};
```

```ts
export type KpiCardData = {
  key: string;
  label: string;
  value: number;
  delta?: number;
  trend?: Array<{ x: string; y: number }>;
};
```

## 9) UX and Behavior Requirements

- Use loading skeletons for each widget (not full-page spinner only).
- Handle partial failures: one widget failing should not blank the full dashboard.
- Allow CSV export for:
  - Top-selling drugs
  - Most-prescribed drugs
  - Purchase order list
  - Insurance claims
  - Controlled substance ledger
- Use color semantics:
  - Green = healthy/positive
  - Amber = warning (near expiry/low stock)
  - Red = critical (out-of-stock/expired/high-risk alerts)
- Add quick links from critical cards:
  - Low stock -> inventory reorder view
  - Expired drugs -> quarantine/disposal view
  - Rejected claims -> claims resolution queue

## 10) Performance and Caching

- Load summary KPIs first (fast endpoint), then lazy-load heavier widgets.
- Cache chart queries by filter hash for short duration (30-120s).
- Debounce filter changes (200-400ms) before refetch.
- Use pagination on large tables (`take`, `skip` or `page`, `limit`).

## 11) Access Control and Audit

- Roles:
  - `Pharmacist`: operational and stock views.
  - `PharmacyManager`: full dashboard.
  - `Finance`: revenue and claims, no sensitive patient alert details.
  - `ComplianceOfficer`: controlled substance and safety alerts.
- Log export and sensitive panel access for compliance audits.

## 12) Acceptance Checklist

- [ ] All KPI cards render and update with filters.
- [ ] Order status, top-selling, and most-prescribed widgets show correct ranking.
- [ ] Low/out-of-stock and near-expiry/expired data match inventory source.
- [ ] Revenue, usage, and inventory trend charts render correctly for date presets.
- [ ] Supplier/purchase-order and insurance claims statuses are visible and filterable.
- [ ] Pharmacist productivity metrics calculate correctly.
- [ ] Interaction/allergy alerts and controlled substance logs are available and exportable.
- [ ] Empty states and error states are implemented for every widget.

