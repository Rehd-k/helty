# Build, test, and release

## Requirements

- Flutter SDK that satisfies Dart `^3.12.0` (see `pubspec.yaml`)
- A running Helty API. This repository does not contain the server
- For Windows desktop, a Windows toolchain (`flutter doctor` should list it)
- For the installer, the MSIX tooling pulled in by the `msix` dev dependency

## First run

```bash
flutter pub get
```

Copy `.env.example` to `.env`. Set `API_BASE_URL` to the origin you want, or to a `;`-separated list. Set `ORG_*` to the hospital’s letterhead. Details are in [Startup and configuration](03-startup-and-configuration.md).

Hospital app on Windows:

```bash
flutter run -d windows
```

Other products:

```bash
flutter run -d windows -t lib/main_pharmacy.dart --dart-define=API_BASE_URL=https://api.example
flutter run -d windows -t lib/main_diagnostics.dart --dart-define=API_BASE_URL=https://api.example
flutter run -d windows -t lib/main_lab_pharmacy.dart --dart-define=API_BASE_URL=https://api.example
```

Release builds of the three smaller products throw at startup if `API_BASE_URL` is empty. The hospital product falls through to `kApiCandidateBaseUrls`.

Web:

```bash
flutter run -d chrome
```

The Docker image is the production-shaped web build. It uses `lib/main.dart` (hospital) and serves `build/web` from nginx on port 80, with `try_files` falling back to `index.html` so client routes work.

```bash
docker build -t helty .
```

## Static analysis

```bash
flutter analyze
```

`analysis_options.yaml` includes `package:flutter_lints/flutter.yaml` and excludes `build/` plus the platform folders. Fix analyzer issues in `lib/` and `test/` before handing a change on.

## Code generation

AutoRoute, Freezed, and `json_serializable` write generated files. After you add a `@RoutePage`, change `app_router.dart` or a route group, or edit a Freezed model:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Commit the generated `lib/app_router.gr.dart` and any `*.freezed.dart` / `*.g.dart` that the change produced. Do not hand-edit them.

The router annotation is `@AutoRouterConfig(replaceInRouteName: 'Screen|Page,Route')` on `AppRouter`.

## Tests

```bash
flutter test
```

The suite is unit and widget tests, not a full device walkthrough. Areas already covered:

| Area | Examples |
|---|---|
| Product and routes | `test/src/app/product_environment_test.dart`, `test/src/routing/product_routes_test.dart`, `test/src/routing/initial_route_for_role_test.dart` |
| Permissions | `test/src/auth/` (billing, dialysis, department head), accounting, patient access, custom push, medication requests |
| Clinical models | lab orders, lab AST, theatre models, operative note compiler, dialysis models, radiology report preview |
| Money | invoice billing detail, receivables, HMO tariff parser, consultation credit utils |
| Platform | auth response, saved login storage, notification navigation, patient display name and initials, API decimals |

When you change `initialRouteForRole`, `ProductRoutes`, or a permission helper, extend the matching test. Those tests are how a product build is kept from leaking a hospital-only route.

## Windows installer

`flutter_launcher_icons` reads `assets/logo.png` for Android, iOS, and Windows.

The `msix_config` block in `pubspec.yaml` sets:

| Setting | Value in tree |
|---|---|
| Display name | Helty |
| Publisher | VesselLabs |
| Identity | `VesselLabs.Helty` |
| Output | `helty` |
| Capabilities | internet, private network, documents, pictures, removable storage |
| Update check | Every 8 hours, background task on, activation not blocked, no startup prompt |
| App Installer | `make_appinstaller: true` and `appinstaller_url` pointing at the desktop update feed |

Build the package with the `msix` tool after a Windows release build (see the `msix` package docs for the current command). The in-app layer is `HeltyDesktopUpdateLayer`. It must keep letting the app open when an update cannot be applied.

Changing `appinstaller_url` changes where every installed client looks for updates. Treat that URL as environment configuration.

## Dependencies worth knowing

| Package | Why it is here |
|---|---|
| `flutter_riverpod` | App state |
| `dio` | HTTP |
| `auto_route` | Navigation |
| `flutter_secure_storage` | Tokens |
| `shared_preferences` | Theme, report template, saved logins |
| `flutter_dotenv` | `.env` |
| `freezed` / `json_serializable` | A few generated models |
| `pdf`, `printing` | Documents |
| `esc_pos_utils_plus`, `esc_pos_printer_plus` | Receipt printers |
| `socket_io_client` | Staff chat |
| `flutter_local_notifications` | Queue and chat alerts |
| `flutter_quill` | Clinical notes |
| `data_table_2`, `infinite_scroll_pagination` | Tables |
| `fl_chart` | Dashboards |
| `bitsdojo_window`, `win32` | Windows chrome and raw printing |
| `file_picker`, `image` | Uploads, including radiology images |
| `intl`, `timezone` | Dates in `Africa/Lagos` |
| `updat`, `package_info_plus` | Desktop update checks |
| `google_fonts` | Typography |

`provider` is in `pubspec.yaml` and is unused. New code uses Riverpod.

## Platforms

| Folder | Status in this repo |
|---|---|
| `windows/` | Primary hospital desktop |
| `web/` | Used by the Dockerfile |
| `android/`, `ios/` | Flutter shells and launcher icons |
| `linux/`, `macos/` | Flutter shells |

A layout change should be checked at 360 px, 768 px, and 1280 px wide so `ResponsiveBody` does not overflow. See [UI conventions](08-ui-conventions.md).

## Habits that keep the tree coherent

- Add a screen by following [Routing](06-routing.md): annotation, route group, module map, menu, build_runner.
- Call `ApiService().dio` (or inject `Dio`) from a service. Do not construct a second Dio with its own base URL.
- Gate a department with `AppModule` and `ProductModuleAccess`, and gate a button with a permission helper that has a test.
- Match the walk-in queue look for new clinical pages.
- Leave metrics blank (`—`) when the API omits them.
- Keep `.env` out of commits when it contains a deployment-specific URL or anything private. `.env.example` is the template.

## Where to look when something breaks

| Symptom | Look at |
|---|---|
| App stuck before login on a clock or connection message | `ClockSyncGate`, `API_BASE_URL`, device clock versus `/server-time` |
| Bounce back to login immediately | `TokenStorage`, `RefreshTokenInterceptor`, `GET /auth/me` |
| Menu item missing | `_menuForRole`, `ProductModuleAccess`, the product entry point |
| Route not found after a pull | Run build_runner. Confirm the route group is included for this product |
| Numbers look like `{s, e, d}` | `DecimalNormalizeInterceptor` and `api_decimal.dart` |
| PDF has the wrong hospital name | `ORG_*` in `.env` and `OrgConfig.load` |
| Dispense screen does nothing on pay | You are on `PharmacyPOSScreen`. The live screen is `DispenseScreen` |
