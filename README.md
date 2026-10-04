# Helty

Helty is the staff client for a hospital information system. It is a Flutter application (version **2.0.20**, Dart SDK `^3.12.0`) that covers registration, clinical care, diagnostics, pharmacy, billing, accounting, and hospital operations. The client talks to a separate HTTP API. It does not contain the database.

The same source tree builds four products:

| Product | Entry point | What it includes |
|---|---|---|
| Helty (full hospital) | `lib/main.dart` | Every module |
| Helty Pharmacy | `lib/main_pharmacy.dart` | Registration, billing, pharmacy, accounting |
| Helty Diagnostics | `lib/main_diagnostics.dart` | Registration, billing, laboratory, radiology, accounting |
| Helty Lab & Pharmacy | `lib/main_lab_pharmacy.dart` | Registration, billing, pharmacy, laboratory, HMO, accounting |

## Documentation

Start here if you are new to the codebase:

**[docs/README.md](docs/README.md)** — reading order, then a chapter for every layer of the app.

| Chapter | What you will understand |
|---|---|
| [What Helty is](docs/01-what-helty-is.md) | Products, users, and the patient journey in one page |
| [Repository map](docs/02-repository-map.md) | Every top-level folder and every `lib/src` module |
| [Startup and configuration](docs/03-startup-and-configuration.md) | How the app boots, finds an API, and loads branding |
| [Architecture](docs/04-architecture.md) | Layers, state, navigation, and how a screen reaches the API |
| [Authentication and permissions](docs/05-authentication-and-permissions.md) | Login, tokens, account types, roles, and menu rules |
| [Routing](docs/06-routing.md) | AutoRoute, product route groups, and landing pages |
| [HTTP, state, and models](docs/07-http-state-and-models.md) | Dio, services, Riverpod, and shared models |
| [UI conventions](docs/08-ui-conventions.md) | Layout, theme, tables, and the clinical look |
| [Patient journey](docs/09-patient-journey.md) | Register → pay → check in → encounter → orders → discharge |
| [Clinical modules](docs/10-clinical-modules.md) | Doctors, nurses, ED, lab, radiology, obstetrics, dialysis, theatre |
| [Finance](docs/11-finance.md) | Invoices, payments, wallets, HMO, receivables, accounts |
| [Inventory and operations](docs/12-inventory-and-operations.md) | Pharmacy stock, purchases, store, wards, housekeeping, assets |
| [Leadership and platform](docs/13-leadership-and-platform.md) | CMD, CMAC, chat, help, printing, notifications, reports |
| [Build, test, and release](docs/14-build-test-and-release.md) | Run, analyze, generate routes, Windows MSIX, Docker web |

Two narrower notes already live beside those chapters:

- [Product-line extraction plan](docs/product-line-extraction-plan.md) — why products share one repo and separate API deployments
- [Displaying `createdBy`](docs/client-createdby-display-guide.md) — how GET responses identify the staff member who created a record

## Run the hospital app

```bash
flutter pub get
flutter run -d windows
```

Copy `.env.example` to `.env` and set `API_BASE_URL` to the API you want to reach. Details are in [Startup and configuration](docs/03-startup-and-configuration.md).
