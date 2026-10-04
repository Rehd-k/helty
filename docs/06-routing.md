# Routing

Navigation uses [auto_route](https://pub.dev/packages/auto_route). Route classes are generated into `lib/app_router.gr.dart`. The hand-written list is `lib/app_router.dart` plus `lib/src/routing/`.

A widget becomes a route when it is annotated `@RoutePage()`. `AppRouter` replaces the suffix `Screen` or `Page` with `Route`, so `LoginScreen` is `LoginRoute` and `HomeScreen` is `HomeRoute`.

The single router instance is `NavigationService.router` in `lib/src/services/navigation.service.dart`. `HeltyApp` passes `NavigationService.router.config()` to `MaterialApp.router`. The default transition is Material.

## Top of the tree

```dart
List<AutoRoute> get routes => [
  ...sharedAuthRoutes(),
  AutoRoute(
    page: HomeRoute.page,
    guards: [const AuthGuard()],
    children: ProductRoutes.homeChildren(),
  ),
];
```

Auth pages are siblings of the shell. Everything a signed-in person does is a child of `HomeRoute`, which is why the sidebar stays on screen.

## How children are chosen

`ProductRoutes.homeChildren` in `lib/src/routing/product_routes.dart` reads the active product and concatenates groups:

| Order | Group | Included when |
|---|---|---|
| 1 | `sharedHomeChildren()` | Always |
| 2 | `registrationRoutes` | `AppModule.registration` |
| 3 | `billingRoutes` | `AppModule.billing` |
| 4 | `pharmacyRoutes` | `AppModule.pharmacy` |
| 5 | `laboratoryRoutes` | `AppModule.laboratory` |
| 6 | `radiologyRoutes` | `AppModule.radiology` |
| 7 | `hmoRoutes` | `AppModule.hmo` |
| 8 | `accountingRoutes` | `AppModule.accounting` |
| 9 | `hospitalOnlyRoutes` | The product is hospital |

Exactly one child is marked `initial`.

- Hospital: `CMDDashboardRoute` is initial (`hospitalOnlyRoutes(initialCmd: true)`).
- Other products: the front desk dashboard is initial (`registrationRoutes(initial: true)`).

`registeredHomeRouteNames` walks the tree so tests can assert which names exist. `isRouteAllowed` consults `moduleForRouteName` and then checks that the name was actually registered.

## `ProductModuleGuard`

`lib/src/routing/product_module_guard.dart` is attached inside the route groups. If `moduleForRouteName` returns a module that this product does not enable, `resolver.next(false)`. Routes with no module mapping (help, chat, enlist patient, super-admin staff list) are treated as shared and stay available.

Leaving a group out of `homeChildren` is the primary filter. The guard covers a navigation that still names a route from another product.

## Module map

`lib/src/routing/route_module_map.dart` is a `Map<String, AppModule>` from generated route name to module. When you add a `@RoutePage`, add the generated name here or the guard will treat the page as shared.

A few mappings are easy to misread:

| Route | Module | Why |
|---|---|---|
| `AccountsRevenueByServiceRoute` and its detail | `billing` | Registered from `billingRoutes` so a diagnostics build can open revenue by service |
| `AccountsRefundRequestsRoute` | `billing` | Same reason. Refund history stays on `accounting` |
| `ConsultationPaymentReportRoute` | `accounting` | The screen file lives in `lib/src/medical_records/` |
| `AnnouncementManagementRoute` | `administration` | The route is declared inside `billingRoutes` |
| `HospitalReportsHubRoute` | `medicalRecords` | Declared inside hospital-only routes |
| `HubLabsRoute` | `laboratory` | A patient-hub tab, omitted when lab is off |
| `HubImagingRoute` | `radiology` | Same pattern |
| `HubMedsRoute` | `pharmacy` | Same pattern |
| `HubDialysisRoute` | `dialysis` | Same pattern |
| `HubTheatreRoute` | `theatre` | Same pattern |
| `DashboardRoute` | `ict` | The ICT card grid, not the CMD dashboard |

## Auth routes

`sharedAuthRoutes()`:

| Route | Screen |
|---|---|
| `LoginRoute` | `LoginScreen` (initial) |
| `RegisterRoute` | `RegisterScreen` |
| `ForgotPasswordRoute` | `ForgotPasswordScreen` |
| `ResetPasswordRoute` | `ResetPasswordScreen` |

`RegisterRoute` is also listed under the home children so an admin can open registration from inside the shell.

## Shared home children

`EnlistPaitientRoute`, `NotAvailableRoute`, `HelpCenterRoute`, `SupportTicketDetailRoute`, `StaffChatRoute`, `StaffChatThreadRoute`, `RegisterRoute`, `SuperAdminStaffListRoute`, `SuperAdminStaffDetailRoute`.

`EnlistPaitientRoute` takes `serviceName` (for example `OPD` or `Pharmacy`). It is the “choose a patient” step, not the service catalog.

## Registration

`registrationRoutes` in `route_groups/registration_routes.dart`:

Front desk dashboard, patient devices, patient list and form, chart select and chart, hub search and hub, appointments, appointment requests, today’s patients, new appointment, new patient.

Hospital-only extras in this group: pending device approvals, family links, link a one-time patient.

`PatientHubRoute` children always include overview, profile, encounters, vitals, documents, and notes. Labs, imaging, meds, dialysis, and theatre tabs are added only when that module is in `enabledModules`.

## Billing

`billingRoutes`: pending bills, billing dashboard, HMO receivables, discount receivables, discount policies, clinical packages, transactions, system setup, banks, consulting rooms, ward management, announcements, the older enlist/render/view/add service screens, inpatient bill list, patient billing account, patient billing (the charge sheet), wallet history, revenue by service, refund requests.

Hospital-only inside this group: billing ward inpatients, awaiting billing clearance.

`PendingBillsRoute` can be marked initial for a product that has billing and does not use the hospital CMD home. The current composer marks registration initial for non-hospital products instead.

## Pharmacy, laboratory, radiology, HMO

`pharmacyRoutes`: dashboards, reports, sales breakdown, inventory valuation, medicine inventory, add drug / supplier / batch, ward-pricing preview, stock transfer, requisition, supply history, dispense history, locations, the POS screen, dispense, medication requests, refill requests, waiting patients, and `PurchaseItemSalesRoute` (the screen class lives under `purchases/`).

`laboratoryRoutes`: dashboard, investigations report, lab config, create order, order detail, result entry.

`radiologyRoutes`: dashboard, investigations report, worklist, create request, request detail, patient history.

`hmoRoutes`: list, detail, form, service pricing.

## Accounting

`accountingRoutes`: accounts dashboard, consultation payment report, revenue summary, daily collections, aging, financial reports hub, profit and loss, cash flow, expense versus budget, collection efficiency, period comparison, payment mix, audit log, compliance, invoice changes, leak detection, staff activity, refund history, wallets overview, daily cash reconciliation, bank reconciliation, approvals, period close, journal entries, chart of accounts, banks, receivables analytics.

## Hospital-only routes

`hospitalOnlyRoutes` in `route_groups/hospital_routes.dart` is the rest of the full hospital:

- Super-admin hub and the CMD screens (overview, finance, staff, beds, lab monitoring, incidents, reports, audit, communications, custom push, patient experience, system control)
- CMAC overview, insights, patient activity, clinical, laboratory, pharmacy, operations, quality, staff, and the quality-safety hub (referrals, complaints, incidents, infections, detail)
- Nursing dashboard, roster, assignments, consumable usage, waiting patients, inpatient list, nurses clearance, and the inpatient chart with its tabs
- Doctor lists, walk-in queue, waiting patients, ongoing and completed encounters, both encounter viewers and their tabs, pending labs / imaging / prescriptions placeholders, templates, profile, edit history
- Emergency board, requests, registration, triage
- Ward rounds
- Hospital reports and health campaigns / news
- Full obstetrics tree (dashboard through gynaecology procedure edit)
- Purchases inventory and history
- Dialysis dashboard, patient select, encounters, create session, session detail
- Theatre dashboard, schedule form, case detail, rooms
- Store dashboard through consumable detail
- ICT dashboard, department-head staff and roster
- Hospital assets and housekeeping

Inpatient and encounter tabs are real child routes, not only `TabBar` indexes. Opening a tab changes the nested route, which is why each tab has its own `*Route` name in the module map.

## Navigating in code

Prefer generated route objects:

```dart
context.router.push(PatientBillingRoute(patientId: id));
context.router.replaceAll([
  const HomeRoute(children: [LabDashboardRoute()]),
]);
```

`NavigationService` is also used from interceptors, where there is no `BuildContext` (the refresh interceptor sends the user to login this way).

## Adding a screen

1. Create a widget annotated `@RoutePage()`.
2. Add an `AutoRoute` in the right file under `lib/src/routing/route_groups/`.
3. Map the generated name in `route_module_map.dart`.
4. If a person should see it in the sidebar, add a `MenuItem` in `account_types.dart` or the home screen menu for that role, behind the module check.
5. Run build_runner (see [Build, test, and release](14-build-test-and-release.md)).
6. If the landing page for a role should change, update `initial_route_for_role.dart` and `test/src/routing/initial_route_for_role_test.dart`.
7. If a product should gain or lose the page, that follows from `AppModule` on the product definition. Do not copy the route into a second group unless the screen must stay available when its “natural” module is off (revenue-by-service is the existing example).
