# Frontend Implementation Prompt: HMO Split + Discount + Receivables

You are a senior frontend engineer. Implement all UI and client integration updates for the backend coverage/discount/receivables release.

## Goal

Support the full billing flow where:

1. HMO staff can split invoices using the patient's registered HMO coverage.
2. CMD/CMAC/SUPER_ADMIN discount policies can be applied by billing.
3. Covered/discounted amounts are tracked as receivables and later remitted.
4. Cash collection remains accurate and never treats coverage as cash.

## Backend Contract

### Coverage endpoints

- `GET /invoices/:invoiceId/coverages`
- `POST /invoices/:invoiceId/coverages/hmo`
  - body: `{ scope: 'INVOICE' | 'ITEM', itemIds?: string[], percentOverride?: number, notes?: string }`
- `POST /invoices/:invoiceId/coverages/discount`
  - body: `{ policyId: string, scope: 'INVOICE' | 'ITEM', itemIds?: string[], valueOverride?: number, notes?: string }`
- `DELETE /invoices/:invoiceId/coverages/:coverageId`
  - body: `{ reason?: string }`

### Discount policy endpoints

- `GET /discount-policies?active=true`
- `GET /discount-policies/:id`
- `POST /discount-policies`
- `PATCH /discount-policies/:id`
- `DELETE /discount-policies/:id`

### Receivables endpoints

- `GET /receivables/hmo`
- `GET /receivables/hmo/:hmoId/statement`
- `GET /receivables/discount`
- `GET /receivables/discount/owner/:staffId/statement`
- `GET /receivables/remittances`
- `GET /receivables/remittances/:id`
- `POST /receivables/remittances`
  - body: `{ payerType: 'HMO'|'STAFF', hmoId?, payerStaffId?, amount, reference?, notes?, paidAt?, lines: [{ coverageId, amount }] }`

### Invoice detail response additions

`GET /invoices/:id` now includes:

- `coverages`
- `coveredAmount`
- `effectivePayable`
- per line:
  - `lineCovered`
  - `lineEffectiveDue`
  - `lineAmountDue`

## Required UI Changes

### 1. Billing screen and pending bills

- Add **Split with HMO** action.
- Show only when:
  - invoice status is not `PAID`
  - patient has `hmoId`
- On click:
  - `POST /invoices/:id/coverages/hmo` with `scope: 'INVOICE'`
  - immediately refetch invoice
- If `effectivePayable === 0`:
  - mark as fully covered
  - hide cash payment form
- Else:
  - show remaining payable and allow normal payment flow

### 2. Discount apply in billing

- Add discount dropdown sourced from `GET /discount-policies?active=true`.
- Group by reason (`CMD`, `CMAC`, `SUPER_ADMIN`).
- On selection:
  - call `POST /invoices/:id/coverages/discount`
  - refetch invoice

### 3. Invoice detail coverage UI

- Render all coverage rows (chips or table) showing:
  - kind (`HMO` / `DISCOUNT`)
  - scope (`INVOICE` / `ITEM`)
  - mode/value
  - computed amount
  - status
  - applied by, payer/owner details
- Add reverse action with reason modal.

### 4. New Receivables section

- Create top-level module/page with two tabs:
  - HMO receivables
  - Discount receivables
- Add filters:
  - date range
  - status
  - payer
  - search
- Add printable statement pages using statement endpoints.
- Add **Record Remittance** modal:
  - select outstanding coverages
  - enforce total equals sum(lines)
  - submit to `POST /receivables/remittances`

### 5. Discount policy management page

- Add admin page for CMD/CMAC/SUPER_ADMIN:
  - list/create/update/delete policies
  - fields: name, reason, mode, value, active, optional owner

## Permissions (hide/disable UI)

- HMO split: `HMO`, `SUPER_ADMIN`
- Apply discount: `BILLING/BILLS`, `CMD`, `CMAC`, `SUPER_ADMIN`
- Reverse coverage: `HMO`, `BILLING/BILLS`, `CMD`, `CMAC`, `SUPER_ADMIN`
- Discount catalog CRUD: `CMD`, `CMAC`, `SUPER_ADMIN`
- Receivables read: `ACCOUNTING`, `BILLING/BILLS`, `CMD`, `CMAC`, `SUPER_ADMIN`, `HMO`
- Remittance write: `ACCOUNTING`, `SUPER_ADMIN`

## Non-negotiable validation rules

- Never let user pay more than `effectivePayable - amountPaid`.
- Do not compute settlement client-side; always trust refreshed server state.
- Disable split button when patient has no HMO.
- Coverage reversal can move invoice out of `PAID`; always re-fetch invoice after mutation.

## UX Requirements

- Provide loading/empty/error/retry states on all new screens.
- Keep filter state in URL query params.
- Use server pagination (`skip`/`take`) for tables.
- Keep tables export-friendly (plain, normalized data structures).

## Acceptance Criteria

1. Split with HMO works for 100% and partial coverage.
2. Pending bills reflect remaining patient balance correctly.
3. Discounts apply from policy list and affect invoice due immediately.
4. Invoice detail displays coverage/discount entries correctly.
5. Receivables lists, statements, and remittance posting work.
6. No regression in existing payment/invoice flows.

