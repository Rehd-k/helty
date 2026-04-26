# CMD module — switch from mocks to live API

Use this checklist when the backend matches [`CMD_BACKEND_API_SPEC.md`](./CMD_BACKEND_API_SPEC.md) (or paste your OpenAPI / sample JSON **in the section below** so a future agent or developer can align types without guessing).

---

## Contract drop zone

**Paste backend contract here** (OpenAPI YAML link, Postman export, or a real JSON sample per endpoint):

```
<!-- Example:
GET /cmd/dashboard → { ... sample ... }
-->
```

---

## Checklist

1. **Verify URLs**  
   Confirm deployed paths match [`lib/src/cmd/services/cmd_endpoints.dart`](../../lib/src/cmd/services/cmd_endpoints.dart). Adjust constants if your API uses a prefix (e.g. `/api/v1/cmd/...`).

2. **Response shape**  
   If the server wraps payloads (`{ "data": { ... } }` or `{ "items": [ ... ] }`), either:
   - normalize at the API gateway, or  
   - update [`CmdCommandService`](../../lib/src/cmd/services/cmd_command_service.dart) `_asMap` / `_asList` (or add an unwrap helper) before calling `parseCmd*`.

3. **Parsing**  
   All `parseCmd*` functions live in [`lib/src/cmd/models/cmd_from_json.dart`](../../lib/src/cmd/models/cmd_from_json.dart). Extend them for renamed fields, optional blocks, or enum string changes.

4. **Flip off mocks**  
   - Option A: change [`cmdCommandServiceProvider`](../../lib/src/cmd/cmd_providers.dart) to `CmdCommandService(useMockData: false)`.  
   - Option B: inject via `ProviderScope` overrides in tests / flavor-specific bootstrap.

5. **Auth & errors**  
   Ensure [`ApiService`](../../lib/src/services/api_service.dart) (or Dio interceptors) attach auth headers. Map `401`/`403` to sign-out or CMD-specific error UI; Riverpod `AsyncValue` will surface `DioException` in existing `CmdAsyncScaffold` / dashboard error states.

6. **Remove mock-only copy**  
   Search for “dummy”, “stub”, “mock” in [`lib/src/cmd/`](../../lib/src/cmd/) UI strings and subtitles; tighten subtitles once data is real.

7. **Dates as strings from API**  
   If any field is a date string in a nested object you add later, prefer `DateTime.parse` inside `cmd_from_json.dart` and keep UI on [`DateFormatter`](../../lib/src/helper/date.formatter.dart) (`formatFromBackend` if you store raw strings in models).

8. **Money**  
   Keep amounts as NGN major units in JSON to match [`cmd_money_format.dart`](../../lib/src/cmd/cmd_money_format.dart) / UI. If backend sends kobo integers, convert once in parsers (`value / 100.0`).

9. **QA**  
   Run through CMD routes on **mobile &lt;600px**, **tablet**, and **desktop**; confirm tables still scroll inside [`CmdDataTableBox`](../../lib/src/cmd/widgets/cmd_data_table_box.dart).

---

## Files that typically change when going live

| File | Why |
|------|-----|
| [`lib/src/cmd/cmd_providers.dart`](../../lib/src/cmd/cmd_providers.dart) | `CmdCommandService(useMockData: false)` |
| [`lib/src/cmd/services/cmd_command_service.dart`](../../lib/src/cmd/services/cmd_command_service.dart) | Unwrap responses, extra endpoints, error handling |
| [`lib/src/cmd/services/cmd_endpoints.dart`](../../lib/src/cmd/services/cmd_endpoints.dart) | Path changes |
| [`lib/src/cmd/models/cmd_from_json.dart`](../../lib/src/cmd/models/cmd_from_json.dart) | Field renames, new enums, optional fields |
| [`lib/src/services/api_service.dart`](../../lib/src/services/api_service.dart) | Base URL, interceptors |

---

## After integration

- Delete or trim [`lib/src/cmd/data/cmd_mock_data.dart`](../../lib/src/cmd/data/cmd_mock_data.dart) only if nothing else imports it (keep for demos/tests if useful).  
- Consider golden/widget tests for one CMD screen parsing sample JSON fixtures.
