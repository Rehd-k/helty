# Repository map

The repository root is a standard Flutter project plus hospital-specific source under `lib/src/`.

## Root

| Path | What it is |
|---|---|
| `lib/` | All Dart application code |
| `test/` | Widget and unit tests (about 40 files) |
| `assets/` | Logos and other bundled files |
| `docs/` | This documentation |
| `.env` / `.env.example` | Organization name, contacts, logo path, and API origins. `.env` is local and should stay out of commits that share secrets |
| `pubspec.yaml` | Package name `helty`, version `2.0.20`, dependencies |
| `analysis_options.yaml` | `flutter_lints`, with platform and `build/` folders excluded from the analyzer |
| `Dockerfile` | Builds the hospital web app and serves it with nginx |
| `android/`, `ios/`, `web/`, `windows/`, `linux/`, `macos/` | Flutter platform shells |
| `.cursor/rules/` | Editor rules for responsive layout and the clinical UI look |

`pubspec.yaml` bundles `assets/` and both env files as Flutter assets so `OrgConfig` can read them at runtime.

## `lib/` entry files

| File | Role |
|---|---|
| `main.dart` | Hospital product. Calls `bootstrapHeltyApp()` |
| `main_pharmacy.dart` | Binds `AppProduct.pharmacy` |
| `main_diagnostics.dart` | Binds `AppProduct.diagnostics` |
| `main_lab_pharmacy.dart` | Binds `AppProduct.labPharmacy` |
| `app_router.dart` | Hand-written AutoRoute config |
| `app_router.gr.dart` | Generated route classes. Do not edit by hand |

## `lib/src/` modules

Each row is a directory directly under `lib/src/`.

### Application skeleton

| Folder | Owns |
|---|---|
| `app/` | Bootstrap, product definitions, org branding, API candidate list, which account types a product may use |
| `routing/` | Route groups, the module map, the post-login landing page, the product guard |
| `core/` | HTTP interceptors, auth guard, token storage, breakpoints, responsive widgets, error types, platform file-save |
| `providers/` | App-wide Riverpod: auth, theme, billing lists, appointments, staff, specialties, parked bills |
| `services/` | Shared HTTP clients (auth, invoices, encounters, admissions, wards, labs, drugs, and the Dio singleton) |
| `models/` | Shared DTOs used by more than one feature |
| `repositories/` | `AuthRepository` only. It wraps `AuthService` and `TokenStorage` |
| `auth/` | Permission helpers for billing, nursing, dialysis, theatre, department heads, and hospital setup |
| `helper/` | Theme, Lagos timezone, dates, snackbars, Quill HTML, clinical image picking |
| `widgets/` | Cross-feature widgets: clinical chrome, tables, patient chips, clock gate, notifications, desktop updates |
| `ui/` | Login, the home shell, ICT dashboard, older service-catalog screens, banks, super-admin hub |
| `shared/` | Department colors, finance status colors, module card styles, goods-receipt unit conversion |

### Clinical care

| Folder | Owns |
|---|---|
| `paitients/` | Patient registry. The folder name is spelled that way in the tree; class names use `Patient` |
| `frontdesk/` | Reception dashboard, check-in, patient-app devices and family links |
| `doctor/` | Walk-in queue, waiting list, ongoing and completed encounters, the encounter chart, ward rounds, templates, specialty forms |
| `nurses/` | Nurse dashboard, waiting patients, inpatient chart and its tabs |
| `nursing/` | Roster and assignment API used by the nurse dashboard |
| `emergency/` | ED board, registration, triage, disposition, inbound emergency requests |
| `admissions/` | Discharge dialogs and ward-location widgets. The admission list itself lives on nursing, ward rounds, and billing |
| `obstetrics/` | Pregnancy, antenatal, labour, postnatal, gynaecology |
| `lab/` | Lab worklist, result entry, catalog configuration |
| `radiology/` | Imaging worklist, scheduling, images, reports |
| `investigations/` | Shared volume-and-revenue report widgets for lab and radiology |
| `medications/` | Dose and schedule math shared by prescribing and the medication administration record |
| `pharmacy/` | Drug inventory, purchasing, locations, dispense, medication-request queue, refills, pharmacy reports |
| `dialysis/` | Dialysis sessions and session consumables |
| `theatre/` | Surgery requests, rooms, schedules, cases, operative notes |
| `patient_chart/` | `GET /patients/:id/chart` and the chart screen |
| `patient_hub/` | Longitudinal view composed from the chart plus dialysis and theatre |
| `medical_records/` | Paid-consultation report and diagnosis formatting |
| `department_head/` | A head’s staff list and shift roster |

### Money

| Folder | Owns |
|---|---|
| `billings/` | Cashier worklist, inpatient charge sheet, billing dashboard, clearance |
| `transaction/` | Payment ledger, refunds, receipt reprint |
| `wallet/` | One patient’s prepaid balance |
| `accounts/` | Accounts and audit pack under `/accounts` |
| `receivables/` | What HMOs and discount sponsors still owe |
| `hmo/` | Insurer master data and tariff CSV import |
| `discount_policies/` | Named discount rules |
| `clinical_packages/` | Bundles of services and drugs that billing can apply together |

### Stock, facilities, catalog

| Folder | Owns |
|---|---|
| `purchases/` | Non-drug item inventory and counter sales |
| `store/` | General store, stock movements, consumable catalog |
| `hospital_service/` | Departments, service categories, billable services, wards and beds |
| `enlist_services/` | “Pick a patient, then continue” step used before a bill or a module request |
| `hospital_assets/` | Equipment register and access grants |
| `housekeeping/` | Workers, areas, shifts, supply logs |

### Leadership and cross-cutting product features

| Folder | Owns |
|---|---|
| `cmd/` | Chief medical director command center |
| `cmac/` | Clinical analytics and quality-safety records (referrals, complaints, incidents, infections) |
| `reports/` | Operational extracts (admissions, attendance, requests by ward) |
| `printing/` | PDF reports and ESC/POS receipts |
| `chat/` | Staff direct messages and the pending-orders ticker |
| `notifications/` | Local notifications and CMD custom push to the patient app |
| `help/` | In-app support tickets |
| `health_content/` | Campaigns and news for the patient app |
| `system_announcements/` | Staff-wide banners |

## `lib/src/models/`

These files are the shared language between screens. Feature folders sometimes keep their own models when only that feature uses them (pharmacy, accounts, theatre, dialysis, cmd, cmac).

Important shared models:

| File | Represents |
|---|---|
| `staff_model.dart` | Signed-in staff and `AccountType` |
| `staff_registration_options.dart` | Categories and `staffRole` strings offered when creating staff |
| `auth_response.dart` | Login payload (tokens and staff) |
| `encounter_model.dart` | A clinical encounter |
| `encounter_template_model.dart` | Reusable encounter content |
| `admission_model.dart` | An inpatient stay |
| `admission_billing_clearance_models.dart` | Discharge stuck on billing or nursing clearance |
| `appointment_model.dart` | A scheduled visit |
| `waiting_patient_model.dart` | Someone checked in for a doctor |
| `invoice.dart`, `invoice_billing_models.dart` | Invoices, wallets, coverages |
| `transaction.dart` | A payment |
| `receivables_models.dart` | HMO and discount balances |
| `hmo_models.dart`, `discount_policy_models.dart` | Payers and discount rules |
| `service_model.dart`, `service_category_model.dart` | The billable catalog |
| `ward_models.dart`, `consulting_room_model.dart` | Places care happens |
| `lab_order_model.dart`, `lab_catalog_model.dart` | Orders a doctor places, and the catalog behind them |
| `medication_order_model.dart`, `medication_request_model.dart`, `medication_administration_model.dart`, `medication_dose_schedule_model.dart` | Prescribe, request, give, schedule |
| `drug_catalog_model.dart` | Drugs the encounter picker uses |
| `patient_vitals_model.dart`, `intake_output_record_model.dart`, `iv_fluid_order_model.dart`, `iv_monitoring_model.dart` | Bedside measurements and infusions |
| `nursing_note_model.dart`, `ward_round_note_model.dart`, `handover_report_model.dart`, `care_plan_model.dart`, `wound_assessment_model.dart`, `monitoring_chart_model.dart`, `procedure_record_model.dart` | Nursing and ward documentation |
| `clinical_specialty_models.dart`, `icd10_model.dart` | Specialty sections and diagnosis codes |
| `consultation_credit_model.dart`, `paid_without_encounter_invoice.dart` | A paid consultation that has not been opened as an encounter yet |
| `server_time_model.dart` | Clock-sync payload |
| `bank_model.dart` | Banks used on payments |
| `staff_attribution.dart` | Display helpers for “who did this” |

`invoice.freezed.dart` is generated from the invoice model. Edit the source file and regenerate.

## `lib/src/services/`

The Dio singleton is `api_service.dart`. Everything else in this folder is a client for one API area, except a few UI helpers that were placed here historically (`theme_switch_button.dart`, `title_bar.dart`, `notificationbar.dart`, `window_chrome*.dart`).

Domain grouping and the request pattern are in [HTTP, state, and models](07-http-state-and-models.md).

## `lib/src/core/`

| Area | Files | Role |
|---|---|---|
| `interceptors/` | auth, refresh, error, decimal normalize | Every request passes through these |
| `guards/` | `auth_guard.dart` | Blocks `HomeRoute` when no access token is stored |
| `storage/` | `token_storage.dart`, `saved_login_storage.dart` | Secure tokens; recent login identifiers in SharedPreferences |
| `layout/` | `app_breakpoints.dart` | mobile &lt; 600, tablet 600–1099, desktop ≥ 1100 |
| `widgets/` | responsive body, row/column, grid, toolbar, data table, flex panel, patient avatar | The layout widgets screens are expected to use |
| `errors/` | `app_exception.dart`, `user_facing_error.dart` | Typed failures and the string shown to a user |
| `platform/` | `helty_platform`, `save_bytes` | Conditional imports so web and desktop can save files |
| `utils/` | decimals, patient display name, initials, ward ref | Small pure helpers |
| `providers/` | `app_lifecycle_provider.dart` | Observes `WidgetsBinding` |
| `responsive.dart` | barrel | `import 'package:helty/src/core/responsive.dart';` |

## `test/`

Tests sit beside the ideas they protect: routing and product environment, permissions, invoice and lab models, theatre operative-note compilation, notifications, and patient display helpers. The list of commands is in [Build, test, and release](14-build-test-and-release.md).

## Platforms and installer

Windows is the primary hospital desktop target. `pubspec.yaml` includes an `msix_config` block (display name Helty, publisher VesselLabs) and launcher icons from `assets/logo.png`. Android, iOS, macOS, Linux, and web shells are present because Flutter generates them. The Docker image builds web from the default `lib/main.dart`, which is the hospital product.
