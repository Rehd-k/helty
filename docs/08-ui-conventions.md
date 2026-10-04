# UI conventions

New and redesigned screens follow the walk-in queue (`lib/src/doctor/walk_in/`). That screen is the reference for density, cards, and tables. The rules below are what the code and `.cursor/rules/` already require.

## Theme

`AppTheme` in `lib/src/helper/theme.dart` builds `lightTheme` and `darkTheme`. Screens read color from `Theme.of(context).colorScheme` and spacing from `AppTheme.radiusSm`, `radiusMd`, `radiusLg`, `spaceSm`, and `spaceMd`.

`DepartmentColors` in `lib/src/shared/department_colors.dart` gives each department a stable color (billing orange, pharmacy green, and the rest). `finance_status_colors.dart` builds invoice and payment colors from those constants. `module_surface_styles.dart` is the shared card and filter decoration.

Accent tiles used on KPI rows: blue `#2563EB`, teal `#0D9488`, purple `#7C3AED`, pink `#DB2777`, indigo `#4F46E5`, green `#16A34A`, amber `#EA580C`.

Google Fonts are loaded through the `google_fonts` package. Icons in the clinical chrome are `HeltySolidIcon`: an opaque rounded square, a white glyph, and a distinct color per control. A pale tint of the primary color is not the icon treatment.

## Clinical chrome

`lib/src/widgets/helty_surface.dart` exports the pieces:

| Widget | Use |
|---|---|
| `HeltySurfaceCard` | The card behind a section, a KPI, or a table |
| `HeltyStatusChip` | A short status |
| `HeltySolidIcon` | The icon tile |
| `HeltyEllipsisText`, `HeltyEllipsisChip` | One line, ellipsis, tooltip on hover |
| `HeltyPagePadding` | Page inset |

Long names (patients, drugs, diagnoses) stay on one line. The row does not grow taller to wrap them.

## Page structure

A department page is:

1. A compact header: solid title icon, title, subtitle. The header is not a row of large buttons.
2. A KPI row of small `HeltySurfaceCard`s: icon tile, label, large value, caption. Padding stays around 8–10. If the API did not return a metric, the value is an em dash (`—`). Counts are never invented.
3. One filter row: search plus the primary dropdowns. Dates and extra filters sit behind a filter icon that opens a menu or dialog.
4. The main table or chart.
5. From width 1100 upward, an optional utility rail (quick actions, lists, notes) that fills the leftover height beside the content. Below that width the rail stacks or becomes a sheet.

Section gaps are about 10–12 pixels.

## Responsive layout

Import `package:helty/src/core/responsive.dart`.

`AppBreakpoints.fromWidth`:

| Name | Width |
|---|---|
| Mobile | under 600 |
| Tablet | 600–1099 |
| Desktop | 1100 and up |
| Max content | 1280 |

Page bodies use `ResponsiveBody`. Lists and split panels use the default `expand: true` so a `Column` with `Expanded` receives a bounded height. Forms use `ResponsiveBody(expand: false)` and a `SingleChildScrollView`.

| Need | Widget |
|---|---|
| Two panels that stack on a phone | `ResponsiveRowColumn` |
| KPI or form grid, 1 / 2 / 3 columns | `ResponsiveWrapGrid` |
| Toolbar actions | `ResponsiveToolbar` or `Wrap` |
| Wide table | `ResponsiveDataTable` |
| App shell with a sidebar | `ResponsiveScaffold` (sidebar from 1100). The live home shell is `HomeScreen`, which uses its own drawer under 720 px |

On mobile, search fields are `Expanded`, not a fixed `SizedBox` width. Tables scroll horizontally and keep a minimum width around 720. Dialogs use `min(560, screenWidth - 32)`.

`AccountsBreakpoints`, `CmdBreakpoints`, and `BillingBreakpoints` exist from earlier screens. New code uses `AppBreakpoints`.

A panel that contains its own `Expanded` (`SelectUser`, chat lists) must be placed in an `Expanded` or `FlexPanel`. Dropping it into a `Column` as an ordinary child causes a render overflow.

## Tables

`ResponsiveDataTable` and `ReusableAsyncTable` (`lib/src/widgets/table/reusable_async_table.dart`) are the table shells. `data_table_2` is the underlying package.

- Zebra rows use `onSurface` at about 0.035 alpha.
- Column gutters are about 20 px.
- The row count and the paginator stay pinned in the card footer. Horizontal scroll applies to the header and the rows, not the footer.
- Row actions are a compact primary button (`View`, `Start`) plus a kebab. A tight cluster uses `FittedBox`.

## Forms and editors

Text fields go through `lib/src/widgets/text_field.dart` where the screen already uses that wrapper. Rich notes use `flutter_quill`; `quill_content_helper.dart` converts that document for the API. Dates go through `lib/src/helper/date.formatter.dart` and the Lagos timezone.

Empty states use `empty.widget.dart`. A feature that is not on this product uses `not_avaliable.dart` (`NotAvailable` screen, route `NotAvailableRoute`).

## Feedback

Snackbars go through `lib/src/helper/snack.bar.dart`. Blocking errors use the message from `userFacingErrorMessage`. The app-wide toast host is `AppNotificationHost`.

## Watermark and announcements

`watermark_overlay.dart` can stamp the organization logo over content. `AnnouncementBannerHost` is mounted from `HomeScreen` and reads active announcements from `/system-announcements/active`. Dismissal is local (`AnnouncementDismissalStorage`).

## Keeping a redesign safe

A visual rebuild must keep the same query parameters and the same mutations. Changing a card layout is not a reason to rename an API field or drop a filter the department already relies on.
