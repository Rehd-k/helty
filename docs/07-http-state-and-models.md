# HTTP, state, and models

## The client

`ApiService` (`lib/src/services/api_service.dart`) is the only Dio instance the app should use.

```dart
class ExampleService {
  ExampleService({Dio? dio}) : _dio = dio ?? ApiService().dio;
  final Dio _dio;

  Future<List<Thing>> list() async {
    final resp = await _dio.get('/things');
    final raw = resp.data;
    final list = raw is Map && raw['data'] is List ? raw['data'] : raw;
    return (list as List).map((e) => Thing.fromJson(e)).toList();
  }
}
```

Responses are not one shape. Services unwrap `data`, `items`, or a bare list, depending on the endpoint. When you add a client, match the unwrap style of the neighboring service for that API area.

Writes use `post`, `patch`, `put`, or `delete` with a `data:` map. Failures often rethrow `Exception(response.data['message'])` after Dio has already passed through `ErrorInterceptor`. Screens should still pass errors through `userFacingErrorMessage`.

### Variants

| Pattern | Who uses it |
|---|---|
| `ApiService().dio` inside the constructor | Most of `lib/src/services/` and module services |
| Optional `Dio? dio` argument | Accounts base service, several module services, tests |
| Required `Dio` in the constructor | `ChatApiService`, `TicketsApiService` |

`AccountsBaseService` also unwraps a `{ data }` envelope for the accounts pack.

### Endpoint families

Paths below are the prefixes the client calls. The API owns the exact resource names.

**Auth and platform.** `/auth`, `/server-time`, `/admin/db-backups`, `/tickets`, `/chat`, `/system-announcements`, `/notifications/custom`, health campaign and news routes, `/cmd/...`, `/cmac/analytics`, `/quality-safety/...`.

**People and places.** `/patients`, `/staff`, `/departments`, `/wards`, `/beds`, `/consulting-rooms`, `/waiting-patients`, `/appointments`, `/department-head/staff`.

**Clinical chart.** `/encounters`, `/admissions`, `/emergency/visits`, `/obstetrics`, `/nurses/dashboard`, nursing notes, vitals, intake-output, IV fluids, wound assessments, care plans, monitoring charts, ward-round notes, handover, medication orders, medication requests, medication administrations, dose schedules.

**Diagnostics.** `/lab` style routes on `LabApiService` and `LabOrderService`, `/radiology` on `RadiologyService`.

**Stock.** `/pharmacy`, `/purchases`, `/store`, `/store/consumables`, `/invoice-purchases`, `/invoice-consumables`, `/dialysis`, `/surgery-requests`, `/theatre`, `/hospital-assets`, `/housekeeping`.

**Money.** `/invoices` (including payments, wallets, coverages, soft-delete), `/billing`, `/billing/analytics`, `/receivables`, `/hmos`, `/discount-policies`, `/clinical-packages`, `/banks`, `/accounts/...`, `/services`, `/service-categories`.

**Reports.** `/reports/...` for operational extracts.

`CmdEndpoints` in `lib/src/cmd/services/cmd_endpoints.dart` lists the command-center paths (`/cmd/dashboard`, `/cmd/financial/overview`, `/cmd/beds/snapshot`, `/cmd/lab/monitoring`, and the rest). `CmdCommandService` issues those GETs.

## Services that are not HTTP

These files live in `lib/src/services/` but draw UI or talk to the operating system:

| File | Role |
|---|---|
| `navigation.service.dart` | Holds `AppRouter` |
| `window_chrome.dart` and the io/stub pair | Desktop window show and frame |
| `title_bar.dart` | Custom desktop title bar |
| `theme_switch_button.dart` | Theme toggle widget |
| `notificationbar.dart` | Sliding notification dropdown |
| `helty_desktop_update_service.dart` | Reads the desktop update feed |
| `api_endpoint_selector.dart` | Races `/server-time` across candidate origins |
| `widgets/searchable_service_selector.dart` | Catalog picker widget |

Module services that follow the same Dio pattern but live beside their screens include `PharmacyApiService`, `PurchasesApiService`, `StoreApiService`, `StoreConsumableApiService`, `LabApiService`, `RadiologyService`, `DialysisApiService`, `TheatreApiService`, `ObstetricsService`, `EmergencyService`, `NursingApiService`, `HousekeepingApiService`, `HospitalAssetsApiService`, `HospitalReportsService`, `CmacAnalyticsService`, `CmacQualitySafetyService`, `CmdCommandService`, the accounts services, `PatientAccessService`, `PatientChartService`, `PatientHubService`, `HealthContentService`, `SystemAnnouncementService`, `ClinicalPackageService`, `CustomPushService`, `DepartmentHeadApiService`.

`PatientService` lives with the patient registry under `lib/src/paitients/`.

## Riverpod

App-wide providers in `lib/src/providers/`:

| Provider file | Holds |
|---|---|
| `auth_provider.dart` | `authRepositoryProvider`, `authProvider` (`AuthNotifier`), `currentStaffProvider` |
| `theme_mode_provider.dart` | `ThemeMode`, persisted under the key `app_theme_mode` |
| `super_admin_preview_provider.dart` | View-as department |
| `module_request_flow_provider.dart` | Whether the current enlist flow is billing, radiology, laboratory, dialysis, or HMO, plus the paid invoice line context |
| `staff_providers.dart` | Department, ward, and staff lists |
| `appointment_providers.dart` | Appointment list and portal requests waiting on records or front desk |
| `billing_providers.dart` | Bill lists and bill detail |
| `invoices_providers.dart` | Invoice, patient invoices, wallet, wallet transactions |
| `parked_billing_provider.dart` | In-memory parked cashier sessions and a one-shot restore |
| `service_providers.dart` | Hospital services, obstetrics services, clinical packages, radiology services |
| `service_category_providers.dart` | Categories |
| `clinical_specialty_providers.dart` | Specialty catalog and encounter sections |
| `admission_clearance_providers.dart` | Pending billing clearance and pending nurses clearance |

Feature providers follow the same style: `accounts_providers.dart`, `cmac_providers.dart`, `cmd_providers.dart`, `store_providers.dart`, `nursing_providers.dart`, `patient_hub_providers.dart`, `investigation_providers.dart`, `theatre_providers.dart`, `patient_access_providers.dart`, chat shell and pending-order providers.

`reportTemplateProvider` lives with the printing theme code and is overridden at startup the same way theme mode is.

### How screens should use providers

- Watch a `FutureProvider` for a list that should refetch when its arguments change.
- Call `ref.invalidate` after a successful mutation.
- Keep parked bills and other purely local drafts in a `Notifier` so a navigation away from the cashier does not drop the cart. That is what `parked_billing_provider.dart` is for.
- Do not put tokens in a provider. `TokenStorage` is the source, and the interceptor reads it per request.

## Models and JSON

Most models are immutable classes with a `fromJson` factory and a `toJson` where the client writes the record back. Decimal fields must go through `lib/src/core/utils/api_decimal.dart` because the API sometimes sends a decimal.js object instead of a number. The interceptor normalizes response bodies; the helper is still used when a model parses a nested value itself.

`invoice.dart` uses Freezed (`invoice.freezed.dart`). Change the Freezed class, then run build_runner.

Staff who created a row often arrive as `createdBy: { id, firstName, lastName }` and may be null. The display rule is in [client-createdby-display-guide.md](client-createdby-display-guide.md): when `createdBy` is null, hide the creator. `staff_attribution.dart` is the shared formatter.

## Repositories

Only authentication has a repository. The file comment says providers should call `AuthRepository`, not `AuthService`, so token persistence stays in one place. Other features call their service from the widget or from a provider. That is the established pattern; a new feature does not need a repository class unless it also owns secure storage or another side effect the service should not know about.

## Printing is local

`lib/src/printing/` does not call the API to render PDFs. It builds documents with the `pdf` package and prints them with the `printing` package. Receipts use ESC/POS (`esc_pos_utils_plus`, `esc_pos_printer_plus`) over the network or the Windows raw printer. Organization lines on those documents come from `OrgConfig`.

## Sockets

Staff chat uses `socket_io_client` through `InternalChatSocket`. The home shell starts it. Pending-order ticks use the same notification path so pharmacy, lab, and similar queues can raise a local notification while the user is elsewhere in the app. Push to the patient application is a plain `POST /notifications/custom`, not a socket from this client.
