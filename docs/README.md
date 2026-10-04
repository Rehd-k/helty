# Helty codebase documentation

This set explains the Flutter client in `lib/` so a new reader can find any screen, service, or rule without already knowing the project.

The backend (the HTTP API and its database) is a separate system. This repository is the staff application that calls that API.

## Read in this order

1. [What Helty is](01-what-helty-is.md) — products, departments, and the one-page picture.
2. [Repository map](02-repository-map.md) — where every folder lives and what it owns.
3. [Startup and configuration](03-startup-and-configuration.md) — from `main()` to the first screen.
4. [Architecture](04-architecture.md) — the layers and the path of one user action.
5. [Authentication and permissions](05-authentication-and-permissions.md) — who can see what.
6. [Routing](06-routing.md) — how URLs and named routes are assembled per product.
7. [HTTP, state, and models](07-http-state-and-models.md) — Dio, services, Riverpod, shared models.
8. [UI conventions](08-ui-conventions.md) — how screens are supposed to look and lay out.
9. [Patient journey](09-patient-journey.md) — the clinical and billing path that ties modules together.
10. [Clinical modules](10-clinical-modules.md) — physician, nursing, emergency, diagnostics, specialty care.
11. [Finance](11-finance.md) — invoices, cash, coverage, and the accounts pack.
12. [Inventory and operations](12-inventory-and-operations.md) — stock, catalog, wards, facilities.
13. [Leadership and platform](13-leadership-and-platform.md) — command center, analytics, chat, print, help.
14. [Build, test, and release](14-build-test-and-release.md) — commands, tests, Windows installer, web image.

## Other documents

| Document | Audience |
|---|---|
| [product-line-extraction-plan.md](product-line-extraction-plan.md) | Anyone deciding how pharmacy and diagnostics builds stay in this repo |
| [client-createdby-display-guide.md](client-createdby-display-guide.md) | Anyone rendering “created by” on a record |

## How the code is organized

Almost all application code is under `lib/src/`. A feature folder usually contains `ui/` or screen files, `services/` or a call into `lib/src/services/`, `models/`, and sometimes `providers/`. Shared HTTP clients that many features use live in `lib/src/services/`. Shared DTOs live in `lib/src/models/`.

Generated files you should treat as output, not as hand-written source:

- `lib/app_router.gr.dart` — AutoRoute output
- `*.freezed.dart` and `*.g.dart` — Freezed and `json_serializable` output

Regenerate them with the command in [Build, test, and release](14-build-test-and-release.md).
