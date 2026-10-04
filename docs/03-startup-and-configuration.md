# Startup and configuration

This chapter follows one launch from `main()` until a logged-in shell can call the API.

## Entry points

Every entry point calls `bootstrapHeltyApp` in `lib/src/app/bootstrap.dart`.

```dart
Future<void> main() => bootstrapHeltyApp();
```

The pharmacy, diagnostics, and lab-pharmacy mains pass a product:

```dart
Future<void> main() => bootstrapHeltyApp(product: AppProduct.pharmacy);
```

Passing `product` calls `ProductEnvironment.bind`, which overrides the compile-time `APP_PRODUCT` define for that process.

## What `bootstrapHeltyApp` does

1. `WidgetsFlutterBinding.ensureInitialized()`.
2. `OrgConfig.load()` reads branding and the API URL from dotenv.
3. If a product was passed, `ProductEnvironment.bind(product)`.
4. `ProductEnvironment.validateReleaseConfig()`. In release mode, pharmacy, diagnostics, and lab-pharmacy builds throw if `API_BASE_URL` is empty. The hospital product is allowed to fall through to the built-in candidate list.
5. `AppTimezone.initialize()` in `lib/src/helper/app_timezone.dart`. The wall clock used by the app is `Africa/Lagos`.
6. `SharedPreferences` supplies the saved theme and the saved PDF report template. If preferences cannot be read (this happens on multi-user Windows when a previous elevated launch locked the file), startup continues with the system theme and the classic navy report template.
7. `runApp` with a Riverpod `ProviderScope`. The scope overrides `themeModeProvider` and `reportTemplateProvider` with those initial values.
8. The widget tree starts at `ClockSyncGate`, which then builds `HeltyApp`.
9. `revealHeltyDesktopWindow()` shows the desktop window after the binding is up (`bitsdojo_window` on desktop).

## `HeltyApp`

`HeltyApp` is a `ConsumerStatefulWidget`. On the first frame it:

- calls `authProvider.notifier.restoreSession()`
- calls `chatNotificationCoordinatorProvider.initialize()`

Its `build` method watches theme mode and app lifecycle, then returns `MaterialApp.router`:

- title is `ProductEnvironment.displayName`
- light and dark themes come from `AppTheme` in `lib/src/helper/theme.dart`
- `routerConfig` is `NavigationService.router.config()`
- Flutter Quill localizations are registered because notes use the Quill editor
- the builder wraps every page in `HeltyDesktopUpdateLayer`, then `AppNotificationHost`, then `SafeArea`

`HeltyDesktopUpdateLayer` checks the Windows App Installer feed. Update checks must not block launch: `msix_config` sets `update_blocks_activation: false` because a shared hospital PC often cannot apply an MSIX update while another Windows user still has the package open.

## Finding an API

`ClockSyncGate` (`lib/src/widgets/clock_sync_gate.dart`) runs before the rest of the app is useful.

1. It asks `ProductEnvironment.apiCandidateBaseUrls()` for origins.
2. `ApiEndpointSelector.selectFastest` probes each origin with `GET /server-time`.
3. The fastest successful origin is stored with `ApiService().setBaseUrl`.
4. The payload is a `ServerTimePayload` (`lib/src/models/server_time_model.dart`).
5. If the device clock and the server clock differ by more than `ServerTimeService.maxAllowedSkewMs` (120000 ms, two minutes), the gate stays on a mismatch screen and does not build `HeltyApp`.
6. If every probe fails, the gate shows a retryable error.

### Precedence for the base URL

1. An explicit override passed into `apiCandidateBaseUrls` (used by tests and by the gate).
2. `--dart-define=API_BASE_URL=...`
3. `API_BASE_URL` from `.env` via `OrgConfig`
4. `kApiCandidateBaseUrls` in `lib/src/app/api_candidates.dart`

A value may be one URL or several URLs separated by `;`. Each entry is probed. Trailing slashes are stripped.

The built-in candidate list, used when no URL is configured, is:

- `http://localhost:3000`
- `http://192.168.2.121:3000`
- `http://192.168.2.120:3000`
- `http://api.imsh.ng`

## `OrgConfig`

`lib/src/app/org_config.dart` is a singleton. `load()` tries `.env`, then `.env.example`, then `defaults()` (Ibom Multispecialty Hospital).

| Key | Field | Meaning |
|---|---|---|
| `ORG_NAME` | `name` | Printed and on-screen organization name |
| `ORG_ADDRESSES` | `addresses` | `;`-separated lines |
| `ORG_PHONES` | `phones` | `;`-separated |
| `ORG_EMAILS` | `emails` | `;`-separated |
| `ORG_WEBSITE` | `website` | Public site |
| `ORG_LOGO` | `logoAsset` | Flutter asset used on PDFs, receipts, and the watermark |
| `API_BASE_URL` | `apiBaseUrl` | One origin or a `;`-separated race list |
| `ORG_TAGLINES` | `taglines` | Lines used on formal letterhead |

The login screen and sidebar keep `assets/logo.png` (the Helty mark). `ORG_LOGO` is for documents, not for app chrome.

## `ProductEnvironment`

`lib/src/app/product_environment.dart` is the read API for “which product is this process?”

| Member | Meaning |
|---|---|
| `currentProduct` | Bound product, otherwise `APP_PRODUCT` (default `hospital`) |
| `definition` | The `ProductDefinition` for that product |
| `displayName` | Window title |
| `enabledModules` | The `Set<AppModule>` |
| `isModuleEnabled` | One module check |
| `resolvedApiBaseUrl` | dart-define, then dotenv |
| `validateReleaseConfig` | Release guard for non-hospital products |
| `debugResetBind` | Test-only |

`parseAppProduct` accepts `pharmacy`, `diagnostics` or `diagnostic`, `lab_pharmacy` / `lab-pharmacy` / `labpharmacy`. Any other string, including empty, is hospital.

Compile-time defines:

```bash
flutter run -d windows -t lib/main_pharmacy.dart ^
  --dart-define=API_BASE_URL=https://api.example
```

You can also set `APP_PRODUCT` the same way. Dedicated `main_*.dart` files are the preferred way to pick a product, because the bind happens in Dart and does not depend on a forgotten define.

## Session restore, still during startup

`restoreSession` runs in a microtask, in parallel with the first route decision:

1. `TokenStorage.hasToken()` looks for `access_token` in `flutter_secure_storage`.
2. If a token exists, `GET /auth/me` loads `Staff` into `AuthState`.
3. On failure (expired token, unreadable Windows credential store), the notifier logs out: best-effort `POST /auth/logout`, then `TokenStorage.clearAll()`.

`AuthGuard` on `HomeRoute` only checks that a token exists in storage. It does not wait for `restoreSession` to finish. A stored token lets the shell open; a failed `/auth/me` then clears it and returns the user to login. Details are in [Authentication and permissions](05-authentication-and-permissions.md).

## Desktop window chrome

`lib/src/services/window_chrome.dart` (with `_io` and `_stub` variants) hides the window until Flutter is ready and applies the custom title bar used on Windows. Web and mobile use the stub.

## What you configure per deployment

| Concern | Where |
|---|---|
| Which modules exist | Entry point or `APP_PRODUCT` |
| Which API to call | `API_BASE_URL` dart-define or `.env` |
| Letterhead and watermark | `ORG_*` keys |
| Theme and PDF template | User’s SharedPreferences, seeded at startup |
| Installer update feed | `appinstaller_url` inside `msix_config` in `pubspec.yaml` |
