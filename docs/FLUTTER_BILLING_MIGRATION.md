# Flutter client: billing and payments migration

This document describes the **invoice-led** billing API. Copy this file into your Flutter repo (e.g. `docs/BACKEND_BILLING.md`) and update your HTTP clients, models, and UI to match.

## Source of truth

| Concept | Authoritative API / model |
|--------|---------------------------|
| Bill total, amount paid, status | **`Invoice`** (`GET /invoices/:id`) |
| Money collected on a bill | **`InvoicePayment`** (`GET /invoices/:id/payments`) |
| Refunds on a bill | **`InvoiceRefund`** (on invoice detail) |
| Patient prepayment (not yet applied to a bill) | **`PatientWallet`** + **`WalletTransaction`** (CREDIT) |
| Operational / encounter bill wrapper | **`Transaction`** (billing module) — **`amountPaid` / status** are **kept in sync** with the invoice by the server |

Do **not** treat legacy **`Payment`** (`/payments`) as the ledger for new work. Mutating calls return **410 Gone**.

## Amount due on screen

When you **`GET /invoices/:id`**, the response includes:

- **`amountDue`**: `totalAmount - amountPaid` on the invoice (line-based total).
- **`netAmountDue`**: If the invoice is linked to **exactly one** active billing transaction, this is  
  `transaction.totalAmount - discount - insurance - invoice.amountPaid`.  
  Use **`netAmountDue`** for “what the patient still owes” when discounts or insurance apply.
- **`billingLink`** (optional): Present when there is a single linked billing transaction — includes `linkedTransactionId`, `discountAmount`, `insuranceCovered`.

If there is **no** linked billing transaction, **`netAmountDue`** equals **`amountDue`**.

## Endpoints: before → after

| Old / wrong usage | Use instead |
|-------------------|-------------|
| `POST /payments` | **`POST /invoices/:invoiceId/payments`** (see body below) |
| `PATCH /payments/:id` / `DELETE /payments/:id` | **410 Gone** — adjust via **`InvoiceRefund`** on the billing/invoice flow (backend transaction refund API) |
| Recording payment only on “transaction” without invoice | Prefer **`POST /invoices/:id/payments`**; **`POST /transaction/:id/...`** payment (if your backend exposes it) still posts to the **same invoice ledger** |
| Treating wallet deposit as paying a bill | **Deposit** = wallet only; **settlement** = invoice payment (possibly `source: WALLET`) |

### Collect payment (header-level)

`POST /invoices/:id/payments`

```json
{
  "amount": 5000,
  "source": "CASH",
  "method": "CASH",
  "reference": "POS-12345",
  "notes": null,
  "bankAccountNumber": null
}
```

- **`source`**: `WALLET` | `CASH` | `TRANSFER` | `CARD` | `INSURANCE` | `WAIVER` (see your OpenAPI enum).
- **`method`**: optional; derived from `source` when omitted (except wallet).
- Requires authenticated staff on routes that use JWT — `createdBy` / `receivedBy` are set from the token when available.

### Collect payment with per-line allocation

`POST /invoices/:id/allocate-item-payments`

```json
{
  "staffId": "<staff-uuid>",
  "amount": 3000,
  "method": "CASH",
  "reference": null,
  "notes": null,
  "bankAccountNumber": null,
  "billingTransactionId": null,
  "allocations": [
    { "invoiceItemId": "<line-uuid>", "amount": 2000 },
    { "invoiceItemId": "<line-uuid>", "amount": 1000 }
  ]
}
```

- Sum of **`allocations[].amount`** must equal **`amount`**.
- Pass **`billingTransactionId`** if the patient has more than one active billing transaction on the same invoice (rare); otherwise the server picks the latest non-cancelled link.

### Patient deposit (not a bill payment)

`POST /invoices/wallets/:patientId/deposits`

```json
{
  "amount": 10000,
  "reference": "bank-transfer-ref",
  "staffId": "<optional; else use auth sub>"
}
```

- Creates a wallet **CREDIT** only.
- Does **not** change any invoice.

### Pay invoice from wallet

Use **`POST /invoices/:id/payments`** with `"source": "WALLET"` (and sufficient balance).

### Wallet balance and history

- `GET /invoices/wallets/:patientId`
- `GET /invoices/wallets/:patientId/transactions`

## Legacy `GET /payments` (read-only)

Listing old **`Payment`** rows may still work for **historical** data. It is marked **deprecated** in OpenAPI. New reporting should use **invoice** and **InvoicePayment**.

## Error cases to handle in UI

- **410 Gone** on `POST|PATCH|DELETE /payments` — show a message and call invoice/wallet APIs instead.
- **400** when an invoice is linked to **multiple** active billing transactions — user must pick **`billingTransactionId`** on allocate-payment or data must be fixed in the back office.
- **400** when payment exceeds **net** outstanding (discount/insurance) — use **`netAmountDue`** from **`GET /invoices/:id`**.

## Idempotency (recommended)

For transfers and card callbacks, send a stable **`reference`** (and optionally store client-generated idempotency keys) so retries do not double-charge; server-side idempotency keys can be added later.

## Files to change in Flutter (checklist)

- [ ] Replace all **`/payments`** POST/PATCH/DELETE with **`/invoices/.../payments`** or wallet deposit.
- [ ] Bill / checkout screens: load **`GET /invoices/:id`** and display **`netAmountDue`** when present.
- [ ] Separate **“Deposit to wallet”** from **“Pay invoice”** flows and copy.
- [ ] Payment history per bill: **`GET /invoices/:id/payments`** instead of legacy payment list.
- [ ] Regenerate OpenAPI / Dart models from the current backend spec.
