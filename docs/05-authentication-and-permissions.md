# Authentication and permissions

Access has three layers. A person must have a token, their department must exist in this product, and the individual screen may still check a finer role.

## Login

`LoginScreen` (`lib/src/ui/auth/login_screen.dart`) calls `authProvider.notifier.login`.

`AuthNotifier` (`lib/src/providers/auth_provider.dart`) delegates to `AuthRepository` (`lib/src/repositories/auth_repository.dart`), which calls `AuthService`:

| Action | HTTP |
|---|---|
| Login | `POST /auth/login` with `emailOrPhone` and `password` |
| Current user | `GET /auth/me` |
| Refresh | `POST /auth/refresh` with `refreshToken` |
| Logout | `POST /auth/logout`, then clear local tokens |
| Register | `POST` used by `RegisterScreen` |
| Forgot / reset password | `/auth/forgot-password`, `/auth/reset-password` |

A successful login returns `AuthResponse` (`lib/src/models/auth_response.dart`): access token, optional refresh token, and `Staff`. `_persist` writes the tokens through `TokenStorage`.

`SavedLoginStorage` keeps up to five login identifiers in SharedPreferences so the login form can offer them again. It does not store passwords.

Refresh is automatic. `RefreshTokenInterceptor` ignores 401s from login, forgot-password, and reset-password. For every other 401 it refreshes once and retries. If the body says the token is missing or invalid, it clears storage and `NavigationService.router.replaceAll` to `LoginRoute`.

## `AuthGuard`

`lib/src/core/guards/auth_guard.dart` runs on `HomeRoute`.

- Token present → `resolver.next(true)`.
- Token absent → replace the stack with login and `resolver.next(false)`.

The guard reads storage only. It does not decode the JWT and it does not call `/auth/me`.

## Staff identity

`Staff` in `lib/src/models/staff_model.dart` includes:

| Field | Use |
|---|---|
| `staffRole` | String, usually `SCREAMING_SNAKE_CASE`. Drives fine-grained menus |
| `accountType` | `AccountType?`. Drives the department home |
| `pharmacyRole` | Extra pharmacy distinction when the API sends it |
| `permissions` | Optional list from the API |
| `departmentId`, `departmentName` | Home department |
| `wardId`, `wardName` | Home ward for nurses |
| `isActive` | Whether the account can work |

`AccountType` values: `billing`, `accounting`, `hmo`, `pharmacy`, `nurse`, `physician`, `laboratory`, `radiology`, `dialysis`, `theatre`, `store`, `purchases`, `medical_records`, `front_desk`, `ict`, `janitor`, `cmd`, `cmac`, `super_admin`, and legacy `staff`.

`AccountType.fromString` accepts aliases the API has used over time: `bills` → billing, `accounts` → accounting, `lab` → laboratory, `frontdesk` → front desk, nurse and physician and pharmacy and housekeeping aliases. Unknown leftovers such as `other` become `staff`.

`departmentTypes` is the list used in dropdowns, without the legacy `staff` value.

## Role catalog

Roles are not a Dart enum. `kStaffRolesByCategory` in `staff_registration_options.dart` is the source of labels shown when an admin creates a staff member. The strings below are what the client sends and what menus compare against.

| Category | `staffRole` values |
|---|---|
| Billing | `BILLING_HEAD`, `BILLING_STAFF` |
| Accounting | `ACCOUNT_HEAD`, `ACCOUNTING_STAFF` |
| HMO | `HMO_HEAD`, `HMO_STAFF` |
| Pharmacy | `PHARMACY_STORE`, `PHARMACY_DISPENSARY`, `PHARMACY_HEAD` |
| Nursing | `MATRON`, `WARD_CHARGE_NURSE`, `ICU_CHARGE_NURSE`, `EMERGENCY_CHARGE_NURSE`, `OPD_CHARGE_NURSE`, `ONG_CHARGE_NURSE`, `INPATIENT_NURSE`, `EMERGENCY_NURSE`, `ICU_NURSE`, `ONG_NURSE`, `OUTPATIENT_NURSE` |
| Physician | `PHYSICIAN_HEAD`, `CONSULTANT`, `SPECIALIST`, `RESIDENT`, `INTERN`, `JUNIOR_RESIDENT`, `SENIOR_RESIDENT`, `HOUSE_OFFICER`, `MEDICAL_OFFICER`, `CHIEF_RESIDENT`, `MEDICAL_STUDENT` |
| Laboratory | `LAB_HEAD`, `LAB_SCIENTIST` |
| Radiology | `RADIOLOGY_HEAD`, `RADIOGRAPHER`, `RADIOLOGY_RECEPTIONIST` |
| Dialysis | `DIALYSIS_HEAD`, `DIALYSIS_NURSE`, `DIALYSIS_TECH`, `DIALYSIS_RECEPTIONIST` |
| Theatre | `THEATRE_HEAD`, `THEATRE`, `THEATRE_NURSE`, `THEATRE_SCRUB`, `THEATRE_ANAESTHETIST`, `THEATRE_RECEPTIONIST` |
| Store | `HEAD_OF_STORE`, `STOREKEEPER` |
| Purchases | `PURCHASES_STORE`, `PURCHASES_HEAD` |
| Medical records | `MEDICAL_RECORDS_HEAD`, `MEDICAL_RECORDS` |
| Front desk | `FRONT_DESK_HEAD`, `FRONT_DESK` |
| ICT | `ICT_HEAD`, `ICT_STAFF` |
| Housekeeping | `JANITOR_HEAD` |
| Leadership | `CMD`, `CMAC`, `SUPER_ADMIN` |

`home_screen.dart` also declares `enum UserRole { admin, staff, receptionist }`. The live menu does not use that enum. It uses the strings above.

## Where the user lands

`initialRouteForRole(role, accountType)` in `lib/src/routing/initial_route_for_role.dart` maps the department to a first child of `HomeRoute`. Login and the super-admin hub both call it.

| Account type (and common aliases) | First screen |
|---|---|
| `front_desk`, `medical_records` | Front desk dashboard |
| `billing` | Billing dashboard if the role may see privileged billing, otherwise the pending-bills worklist |
| `hmo` | Enlist patient, service name `OPD` |
| Nurse variants (`nurse`, `matron`, charge nurses, inpatient and outpatient nurses) | Nurses dashboard |
| `pharmacy_head` or role `PHARMACY_HEAD` | Pharmacy head dashboard |
| `pharmacy_dispensary` or role `PHARMACY_DISPENSARY` | Enlist patient, service name `Pharmacy` |
| Other pharmacy | Medicine inventory |
| Purchases | Purchases dashboard |
| Physician, consultant, inpatient doctor | Doctor outpatient list |
| Laboratory | Lab dashboard |
| Radiology | Radiology dashboard |
| Dialysis roles | Dialysis dashboard |
| Theatre roles | Theatre dashboard |
| Store | Store dashboard |
| Accounting | Accounts dashboard |
| Janitor / housekeeping | Housekeeping home |
| ICT | ICT card dashboard (`DashboardRoute`) |
| CMAC | CMAC overview |
| CMD, admin, super admin | CMD dashboard |
| Anything else | Front desk dashboard |

If that landing module is turned off for the product, the function returns `ProductModuleAccess.fallbackInitialRoute()`. A super admin on a product that has no administration module lands on `SuperAdminStaffListRoute`.

## The sidebar

`_menuForRole` in `home_screen.dart` builds the drawer. Static lists live in `lib/src/ui/home/account_types.dart` (`frontDesk`, `bills`, `nurseMenuFor`, `doctors`, `pharmacy`, `phamDispense`, `labMenu`, `dialysisMenu`, `theatreMenu`, `accountsHeadMenu`, and the rest). CMAC and CMD item lists are declared in the home screen file.

A block is added only when the staff identity matches and `ProductModuleAccess.isModuleEnabled` is true. Examples:

- Front desk items require `AppModule.registration`.
- Billing staff see the worklist. The billing dashboard requires `staffCanAccessPrivilegedBilling`. `BILLING_STAFF` does not get `SystemSetupRoute`.
- Pharmacy dispensary and pharmacy store get different menus. The head gets extra report items.
- Dialysis and theatre use `canAccessDialysisModule` and `canAccessTheatreModule`.
- CMAC and CMD return early with their own menus when `AppModule.administration` is on.
- Super admin always gets the hub, the staff directory, and Register. “Add Service” appears on slim products when billing is on and administration is off.
- The equipment register is added only when `ProductEnvironment.currentProduct` is hospital and the assets provider says this user has grants.

## Super-admin preview

`super_admin_preview_provider.dart` holds a client-only “view as”. `setPreview` does nothing unless `staffIsSuperAdmin` (`accountType == super_admin` or `staffRole` normalizes to `super_admin`). While the preview is active, `HomeScreen` substitutes the preview role and account type before `_menuForRole`. The real staff record on the server does not change. API calls still use the super admin’s token, so the API remains the authority on what data comes back.

## Permission helpers

These functions are the finer checks inside a department. Screens call them before showing a button or a route.

| File | What it decides |
|---|---|
| `lib/src/auth/billing_permissions.dart` | Privileged billing, who may view receivables, payment and refund actions |
| `lib/src/auth/nursing_permissions.dart` | Who counts as nursing staff, charge-nurse scope |
| `lib/src/auth/dialysis_permissions.dart` | Dialysis module access |
| `lib/src/auth/theatre_permissions.dart` | Theatre module access |
| `lib/src/auth/department_head_permissions.dart` | Department head staff and roster screens |
| `lib/src/auth/hospital_service_permissions.dart` | Who may edit departments, services, and wards |
| `lib/src/pharmacy/auth/pharmacy_permissions.dart` | Store vs dispensary vs head |
| `lib/src/accounts/` access helpers | `canAccessAccountsModule`. Accounting account types, account head, super admin, and CMD read-only. Bank and approval mutations stay with the head |
| `lib/src/patient_chart/patient_chart_permissions.dart` | Who may open the aggregated chart |
| `lib/src/notifications/custom_push/custom_push_permissions.dart` | Who may send a patient-app push |

`ProductModuleAccess.isAccountTypeAllowedForProduct` is the product-level check. An unknown account-type alias is allowed on the hospital product and rejected on the smaller products.

## Adding a permission

1. Decide whether the rule is “this product has the module” (`AppModule`) or “this person may press the button” (a helper next to the feature).
2. If it is a new page, register the route and add it to `_routeModules` in `route_module_map.dart`.
3. Add a `MenuItem` only in the role list that should see it, behind `moduleOn`.
4. Cover the helper with a test under `test/src/auth/` or the feature’s test folder. Existing tests already cover billing, dialysis, department head, patient access, and accounting permissions.
