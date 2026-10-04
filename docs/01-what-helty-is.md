# What Helty is

Helty is the desktop-first staff application for a hospital. Reception, nurses, doctors, laboratory, radiology, pharmacy, billing, accounts, and hospital leadership each get a menu matched to their job. The app records patients, visits, orders, stock, and money, and it reads those records back from the API.

Patients do not use this app as their chart portal. A separate patient application receives some of the content this client publishes (health campaigns, news, and custom push notifications).

## Four products, one codebase

`lib/src/app/product_definition.dart` defines `AppProduct` and `AppModule`.

| Product | Constant | Display name | Enabled modules |
|---|---|---|---|
| Hospital | `kHospitalProduct` | Helty | Every `AppModule` |
| Pharmacy | `kPharmacyProduct` | Helty Pharmacy | registration, billing, pharmacy, accounting |
| Diagnostics | `kDiagnosticsProduct` | Helty Diagnostics | registration, billing, laboratory, radiology, accounting |
| Lab & pharmacy | `kLabPharmacyProduct` | Helty Lab & Pharmacy | registration, billing, pharmacy, laboratory, hmo, accounting |

`AppModule` values are: `registration`, `billing`, `pharmacy`, `laboratory`, `radiology`, `nursing`, `physician`, `purchases`, `dialysis`, `theatre`, `store`, `accounting`, `hmo`, `medicalRecords`, `ict`, `housekeeping`, `administration`.

A product build hides modules by leaving their routes out of the router and by filtering the sidebar. The hospital build is the default when nothing else is selected. Each organization is expected to point its build at its own API and database. See [product-line-extraction-plan.md](product-line-extraction-plan.md).

## Who signs in

A staff record has two identity fields that the UI cares about:

- `accountType` — the department bucket (`physician`, `nurse`, `billing`, `pharmacy`, and so on). Defined as `AccountType` in `lib/src/models/staff_model.dart`.
- `staffRole` — a finer job title string such as `WARD_CHARGE_NURSE` or `PHARMACY_DISPENSARY`. The allowed values are listed in `lib/src/models/staff_registration_options.dart`.

After login, `initialRouteForRole` sends the person to their department home. The sidebar in `HomeScreen` shows only the items that match both the person and the product. Super admins can preview another department’s menu without changing the real staff record.

## The work the app covers

**Identity and access.** Login, password reset, staff registration, device approvals, and family links for the patient app.

**Front door.** Register a patient, book an appointment, take payment for a consultation, and check the patient into a doctor’s queue.

**The visit.** A doctor opens an encounter and writes history, examination, diagnosis, notes, prescriptions, lab and imaging orders, procedures, admission, and follow-up. Emergency has its own board, triage, and disposition.

**The ward.** Nurses keep the inpatient chart: vitals, medications, IV fluids, intake and output, wounds, care plans, monitoring, handover, and discharge clearance.

**Diagnostics and treatment departments.** Laboratory, radiology, pharmacy dispensing, dialysis sessions, theatre cases, and obstetrics (antenatal through postnatal, plus gynaecology procedures).

**Money.** Invoices are the bill of record. Payments, wallets, HMO and discount coverage, receivables, refunds, and the accounts reports all hang off that invoice.

**Stock and facilities.** Drug inventory, non-drug purchases, the general store and consumables, wards and beds, housekeeping, and the equipment register.

**Oversight.** The CMD command center and CMAC analytics read hospital activity. They do not replace the departmental screens that write the chart.

## One sentence per layer

| Layer | Where | Responsibility |
|---|---|---|
| Entry | `lib/main*.dart` | Choose the product and start the app |
| Bootstrap | `lib/src/app/` | Branding, API candidates, timezone, theme |
| Shell | `lib/src/ui/home/` | Sidebar and nested page |
| Routes | `lib/src/routing/` + `lib/app_router.dart` | Which pages exist for this product |
| Features | `lib/src/<module>/` | Screens for one department |
| HTTP | `lib/src/services/api_service.dart` | One Dio client for the whole app |
| State | Riverpod providers next to features and in `lib/src/providers/` | Session, lists, and filters |

The next chapter is a folder-by-folder map. The patient path that connects these modules is written out in [Patient journey](09-patient-journey.md).
