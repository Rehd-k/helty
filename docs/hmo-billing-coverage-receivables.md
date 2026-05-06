# HMO Split, Discount, and Receivables Update Guide

This document covers all backend updates implemented for HMO bill split, discount charging, and receivables tracking, plus the exact UI behavior needed to handle them correctly.

## What Was Added

- **Invoice coverage engine** (`InvoiceCoverage`) to represent non-cash coverage.
- **Discount catalog** (`DiscountPolicy`) for CMD/CMAC/SUPER_ADMIN owned discount templates.
- **Receivables settlement ledger** (`CoverageRemittance`, `CoverageRemittanceLine`).
- **Coverage-aware invoice math** so patient due is based on:
  - `effectivePayable = totalAmount - coveredAmount`
  - invoice `PAID` when `amountPaid + coveredAmount >= totalAmount`
- **HMO defaults and per-service overrides**:
  - `Hmo.defaultCoveragePercent`
  - `HmoServicePrice.coveragePercent`

## Core Accounting Rule

Coverage and discounts are **not cash**.

- `InvoicePayment` = actual money received.
- `InvoiceCoverage` = value committed by HMO or discount owner.
- receivables are later settled with `CoverageRemittance`.

## New/Updated Data Models

- `Hmo.defaultCoveragePercent`
- `HmoServicePrice.coveragePercent`
- `DiscountPolicy`
- `InvoiceCoverage`
- `CoverageRemittance`
- `CoverageRemittanceLine`
- `InvoiceAuditAction` additions:
  - `COVERAGE_APPLIED`
  - `COVERAGE_REVERSED`
  - `COVERAGE_REMITTANCE_RECORDED`

Migration created and applied:

- `prisma/migrations/20260506060807_invoice_coverage_and_discounts/migration.sql`

Backfill included:

- `HmoServicePrice.coveragePercent = (hmoPays / fullCost) * 100` where `fullCost > 0`.

## Backend Endpoints

### Coverage (HMO split + discounts)

- `GET /invoices/:invoiceId/coverages`
- `POST /invoices/:invoiceId/coverages/hmo`
  - Roles: `HMO`, `SUPER_ADMIN`
  - Body:
    - `scope: INVOICE | ITEM`
    - `itemIds?: string[]` (required for `ITEM`)
    - `percentOverride?: number`
    - `notes?: string`
- `POST /invoices/:invoiceId/coverages/discount`
  - Roles: `BILLING/BILLS`, `CMD`, `CMAC`, `SUPER_ADMIN`
  - Body:
    - `policyId: string`
    - `scope: INVOICE | ITEM`
    - `itemIds?: string[]`
    - `valueOverride?: number`
    - `notes?: string`
- `DELETE /invoices/:invoiceId/coverages/:coverageId`
  - Roles: `HMO`, `BILLING/BILLS`, `CMD`, `CMAC`, `SUPER_ADMIN`
  - Body:
    - `reason?: string`

### Discount Policy Catalog

- `GET /discount-policies`
- `GET /discount-policies/:id`
- `POST /discount-policies` (CMD/CMAC/SUPER_ADMIN)
- `PATCH /discount-policies/:id` (CMD/CMAC/SUPER_ADMIN)
- `DELETE /discount-policies/:id` (CMD/CMAC/SUPER_ADMIN; blocked if used)

### Receivables

- `GET /receivables/hmo`
- `GET /receivables/hmo/:hmoId/statement`
- `GET /receivables/discount`
- `GET /receivables/discount/owner/:staffId/statement`
- `GET /receivables/remittances`
- `GET /receivables/remittances/:id`
- `POST /receivables/remittances`
  - Roles: `ACCOUNTING`, `SUPER_ADMIN`
  - Body:
    - `payerType: HMO | STAFF`
    - `hmoId?` or `payerStaffId?` (based on payerType)
    - `amount`
    - `reference?`
    - `notes?`
    - `paidAt?`
    - `lines: [{ coverageId, amount }]`

## Invoice Response Changes

`GET /invoices/:id` now includes:

- `coverages`
- `coveredAmount`
- `effectivePayable`
- for each invoice item:
  - `lineCovered`
  - `lineEffectiveDue`
  - `lineAmountDue` (based on `lineEffectiveDue - amountPaid`)

## Required UI Behavior

### 1) HMO Billing Split

- In patient billing and pending bills screens:
  - show **Split with HMO** if invoice is not `PAID` and patient has `hmoId`.
- On click:
  - call `POST /invoices/:id/coverages/hmo` with `scope: INVOICE` by default.
  - refetch invoice immediately.
- If `effectivePayable === 0`:
  - show invoice as settled/fully covered.
  - hide payment amount input.
- Else:
  - keep invoice pending/partially paid.
  - allow billing department to collect remainder.

### 2) Discount Apply Flow

- Add discount dropdown on billing and pending bills screens.
- Source options from `GET /discount-policies?active=true`.
- Group by reason (`CMD`, `CMAC`, `SUPER_ADMIN`) in UI.
- On apply:
  - call `POST /invoices/:id/coverages/discount`.
  - refetch invoice.

### 3) Coverage Visibility

- Render coverage chips/list on invoice detail:
  - type (`HMO` / `DISCOUNT`)
  - value/mode
  - computed covered amount
  - owner/payer info
  - status
- Provide reverse action where role allows.

### 4) Receivables Module

- Two tabs: **HMO Receivables** and **Discount Receivables**.
- Add filters:
  - date range
  - payer
  - status
  - search
- Add statement pages for print:
  - HMO statement endpoint
  - owner statement endpoint
- Add remittance modal:
  - select outstanding coverages
  - enforce exact sum
  - submit to `/receivables/remittances`

## Validation and Edge Cases

- Never allow pay amount greater than `effectivePayable - amountPaid`.
- Do not show HMO split button if patient has no registered HMO.
- Reversing a coverage may move invoice from `PAID` back to `PARTIALLY_PAID`; always refetch.
- Settled coverage cannot be reversed.
- Remittance lines must match exact coverage amounts.

## Files Added/Changed (backend)

- `prisma/schema.prisma`
- `prisma/migrations/20260506060807_invoice_coverage_and_discounts/migration.sql`
- `src/modules/invoice/invoice.service.ts`
- `src/modules/invoice/invoice.module.ts`
- `src/modules/invoice/coverage/coverage.controller.ts`
- `src/modules/invoice/coverage/coverage.service.ts`
- `src/modules/invoice/coverage/dto/apply-hmo-coverage.dto.ts`
- `src/modules/invoice/coverage/dto/apply-discount.dto.ts`
- `src/modules/invoice/coverage/dto/reverse-coverage.dto.ts`
- `src/modules/discount/discount.module.ts`
- `src/modules/discount/discount.controller.ts`
- `src/modules/discount/discount.service.ts`
- `src/modules/discount/dto/discount-policy.dto.ts`
- `src/modules/receivables/receivables.module.ts`
- `src/modules/receivables/receivables.controller.ts`
- `src/modules/receivables/receivables.service.ts`
- `src/modules/receivables/dto/receivables.dto.ts`
- `src/modules/hmo/dto/hmo.dto.ts`
- `src/modules/hmo/hmo.service.ts`
- `src/app.module.ts`
- tests:
  - `src/modules/invoice/coverage/coverage.service.spec.ts`
  - `src/modules/receivables/receivables.service.spec.ts`

## Frontend Note

No frontend source code exists in this backend workspace, so direct UI code changes were not possible here.  
Use this document with your frontend repository to implement the UI updates exactly against the new API contract.

