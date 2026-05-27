# Helty vibrant dashboard design system

Reference implementation: **CMAC oversight** (`lib/src/cmac/`). This document describes the visual language—especially the **Domain dashboards** gradient hub cards—so new screens can match it and so you can prompt an AI to redesign legacy pages consistently.

For API contracts on CMAC analytics, see [cmac-analytics-frontend.md](./cmac-analytics-frontend.md).

---

## Design goals

1. **Domain-colored identity** — Each functional area (clinical, lab, pharmacy, etc.) has a fixed two-color gradient. Users recognize where they are at a glance.
2. **Soft atmosphere, sharp content** — Page backgrounds use subtle tinted gradients and decorative blobs; KPIs, charts, and tables sit on elevated `surface` cards so data stays readable.
3. **Executive density** — KPI grids, alert strips, and hub navigation on one overview; drill-down screens reuse the same scaffold and accent.
4. **Responsive without custom logic per screen** — Shared breakpoints (`CmdBreakpoints`) and `LayoutBuilder` grids adapt column counts.

---

## File map (reuse these widgets)

| Widget / constant | Path | Use for |
|-------------------|------|---------|
| `CmacPalette` | `lib/src/cmac/cmac_palette.dart` | Domain accent colors, chart palette, severity/trend colors |
| `CmacHubTile` | `lib/src/cmac/widgets/cmac_hub_tile.dart` | **Domain dashboard cards** (gradient navigation tiles) |
| `CmacVibrantBackdrop` | `lib/src/cmac/widgets/cmac_vibrant_backdrop.dart` | Full-page tinted gradient + blob accents |
| `CmacAnalyticsScaffold` | `lib/src/cmac/widgets/cmac_analytics_scaffold.dart` | Standard domain drill-down page shell |
| `CmacPeriodToolbar` | `lib/src/cmac/widgets/cmac_period_toolbar.dart` | Period chips + refresh + advanced query |
| `CmacKpiGrid` / `CmacKpiCard` | `lib/src/cmac/widgets/cmac_kpi_card.dart` | Metric cards with accent stripe + trend chip |
| `CmacSectionHeader` | `lib/src/cmac/widgets/cmac_charts.dart` | Section title with gradient icon badge |
| `CmacBarChartCard` / `CmacLineChartCard` | `lib/src/cmac/widgets/cmac_charts.dart` | Chart sections inside `Card` |
| `CmacAlertBanner` / `CmacInsightList` | `lib/src/cmac/widgets/cmac_alerts_insights.dart` | Alerts and narrative insights |
| `CmacEmptyHint` | `lib/src/cmac/widgets/cmac_kpi_card.dart` | Empty state placeholder |
| `CmdDataTableBox` | `lib/src/cmd/widgets/cmd_data_table_box.dart` | **Required** wrapper for `DataTable2` inside scroll views |
| `CmdBreakpoints` | `lib/src/cmd/cmd_breakpoints.dart` | Padding, max width, responsive column counts |

---

## Color system

### Domain gradients (`CmacPalette`)

Each domain is a **pair** of colors: `[primary, secondary]`. Use **`.first`** as the screen accent (titles, borders, KPI stripe). Use **both** for hub tiles and backdrop blobs.

| Token | Hex (primary → secondary) | Typical use |
|-------|---------------------------|-------------|
| `overview` | `#6366F1` → `#EC4899` (+ `#14B8A6` third blob on overview only) | CMAC home / executive summary |
| `patientActivity` | `#0D9488` → `#5EEAD4` | Visits, admissions |
| `clinical` | `#4F46E5` → `#C4B5FD` | Diagnoses, outcomes |
| `laboratory` | `#9333EA` → `#F472B6` | Lab TAT, critical results |
| `pharmacy` | `#16A34A` → `#A3E635` | Prescribing, stock |
| `operations` | `#D97706` → `#FB923C` | Appointments, workload |
| `quality` | `#E11D48` → `#FB7185` | Incidents, audit flags |
| `staff` | `#2563EB` → `#7DD3FC` | Efficiency, workload |
| `insights` | `#8B5CF6` → `#A78BFA` | System insights list |
| `qualitySafety` | `#64748B` → `#94A3B8` | Neutral capture / forms hub |

### Semantic colors

| Role | Color | Constant |
|------|-------|----------|
| Positive trend | `#16A34A` | `CmacPalette.trendColor(isPositive: true)` |
| Negative trend | `#DC2626` | `CmacPalette.trendColor(isPositive: false)` |
| Critical alert | `#DC2626` | `severityColor('critical')` |
| Warning | `#F59E0B` | `severityColor('warning')` |
| Info | `#3B82F6` | `severityColor('info')` |

### Multi-series charts

Use `CmacPalette.chartColors` (8 distinct hues) in order for bar/line series—do not invent new colors per chart unless adding a ninth+ series.

### Theme integration

- Always blend domain colors with `Theme.of(context).colorScheme.surface` for backgrounds (see `CmacVibrantBackdrop`), not raw full-strength fills behind long text.
- Text on gradient tiles: **white** at `FontWeight.w800` (title) and `w600`/`w700` (labels).
- Body text on cards: `colorScheme.onSurface` / `onSurfaceVariant`.

---

## Domain dashboard cards (`CmacHubTile`)

These are the **“Domain dashboards”** cards on the CMAC overview (`cmac_overview_screen.dart`). They are the primary navigation pattern for multi-area modules.

### Visual spec

| Property | Value |
|----------|--------|
| Corner radius | `18` |
| Padding | `18` all sides |
| Gradient | `LinearGradient` top-left → bottom-right, `colors[0]` → `colors[1]` |
| Shadow | `BoxShadow(color: colors[0] @ 35% alpha, blur 14, offset (0, 6))` |
| Icon | White, size `32`, top of column |
| Title | `titleMedium`, white, `FontWeight.w800` |
| Subtitle | `bodySmall`, white @ 90% alpha |
| CTA row | Label **“Open”** + `Icons.arrow_forward_rounded` (white) |
| Interaction | `InkWell` + `Material(color: transparent)` |

### Grid layout (overview reference)

```dart
LayoutBuilder(
  builder: (context, c) {
    final w = c.maxWidth;
    final cols = w >= 1000 ? 4 : w >= 700 ? 3 : w >= 450 ? 2 : 1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.15,
      ),
      // itemBuilder → CmacHubTile(...)
    );
  },
)
```

### Adding a hub tile (checklist)

1. Add or reuse a `CmacPalette.*` pair for the domain.
2. Define title, subtitle, `IconData`, and `PageRouteInfo`.
3. Render with `CmacHubTile` and `onTap: () => context.router.push(route)`.
4. Keep subtitles to one short line (what the user will see inside).

### Reusing hub tiles outside CMAC

`CmacHubTile` is not CMAC-specific—only the palette tokens are named `Cmac*`. For pharmacy CMD, nursing, etc.:

- Add new palette entries in `cmac_palette.dart` **or** create `HeltyDomainPalette` later if you outgrow CMAC naming.
- Pass `colors: [primary, secondary]` and your route/`onTap`.

Example for a hypothetical “Billing hub” section:

```dart
CmacHubTile(
  title: 'Pending bills',
  subtitle: 'Outstanding inpatient charges',
  icon: Icons.receipt_long_rounded,
  colors: const [Color(0xFF0E7490), Color(0xFF67E8F9)],
  onTap: () => context.router.push(const PendingBillsRoute()),
)
```

---

## Page shell patterns

### A. Hub / overview page (like `CmacOverviewScreen`)

```
Scaffold
  └─ CmacVibrantBackdrop(colors: domainPalette)
       └─ CustomScrollView
            ├─ SliverAppBar (pinned, title + subtitle)
            └─ SliverToBoxAdapter
                 └─ Padding (CmdBreakpoints padding)
                      ├─ CmacPeriodToolbar(accentColor: palette.first)
                      ├─ CmacKpiGrid(...)
                      ├─ Section headers (titleMedium, w800)
                      ├─ CmacAlertBanner / CmacInsightList
                      └─ Domain dashboards grid (CmacHubTile)
```

### B. Domain drill-down page (like `CmacClinicalScreen`)

Prefer **`CmacAnalyticsScaffold`**—it wires backdrop, app bar tint, period toolbar, loading/error, polling, and max content width:

```dart
CmacAnalyticsScaffold(
  title: 'Clinical performance',
  subtitle: 'Diagnoses, outcomes & readmissions',
  colors: CmacPalette.clinical,
  accent: CmacPalette.clinical.first,
  asyncValue: ref.watch(cmacClinicalProvider),
  onRefresh: () => ref.invalidate(cmacClinicalProvider),
  pollInterval: const Duration(seconds: 120), // optional
  builder: (context, data) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CmacKpiGrid(kpis: data.kpis, accent: CmacPalette.clinical.first),
      // charts, tables, sections...
    ],
  ),
)
```

---

## Background (`CmacVibrantBackdrop`)

- Three-stop diagonal gradient: `lerp(surface, c1, 12–14%)` → `lerp(surface, c2, 8–10%)` → `surface`.
- Two circular **blobs** (220×220): top-right and bottom-left, primary/secondary @ 16–22% alpha (lighter in dark mode).
- Child scroll content sits above blobs in a `Stack`.

**Rule:** Every analytics-style page should wrap body content in `CmacVibrantBackdrop` with that page’s domain `colors` list.

---

## KPI cards (`CmacKpiCard`)

| Element | Spec |
|---------|------|
| Container | Radius `16`, `surface` @ 95% alpha, border `accent` @ 25% alpha |
| Shadow | `accent` @ 12% alpha, blur 12, offset (0, 4) |
| Left stripe | 6px wide vertical gradient `accent` → `accent` @ 50% |
| Value | `headlineSmall`, `FontWeight.w800` |
| Trend chip | Background `trendColor` @ 12%; icon `north_east` / `south_east` / `remove` |

Grid breakpoints (`CmacKpiGrid`): 4 cols ≥1200px, 3 ≥800, 2 ≥500, else 1. Aspect ratio `1.55` (or `2.8` on single column).

---

## Section typography

Use consistently across all vibrant dashboards:

| Element | Style |
|---------|--------|
| Screen title (app bar) | `titleLarge`, `FontWeight.w800`, **accent color** on domain pages |
| Screen subtitle | `labelSmall`, `onSurfaceVariant` |
| Section title (“Alerts”, “Domain dashboards”) | `titleMedium`, `FontWeight.w800` |
| Section spacing | `8` below title, `12–24` before next section |
| Chart card title | `titleSmall`, `FontWeight.w700` inside `Card` |

Optional: `CmacSectionHeader` for icon + title + subtitle blocks with a small gradient icon badge (12px radius).

---

## Period toolbar

- `Card` elevation 0, radius `16`, border `accent` @ 35%, fill `surface` @ 92%.
- `FilterChip` per period; selected fill `accent` @ 25%.
- Refresh: `IconButton.filledTonal`; advanced: `TextButton.icon` → dialog.

Requires `cmacAnalyticsQueryProvider` (CMAC) or replicate the pattern with your module’s query notifier.

---

## Charts

- Wrap in `Card(elevation: 0, shape: RoundedRectangleBorder(radius: 16))`.
- Default chart height: `220`.
- Empty data → `CmacEmptyHint`, not an empty card.
- Bar colors: cycle `CmacPalette.chartColors` by index.

---

## Tables (`DataTable2`)

**Never** place `DataTable2` directly inside a `Column` under `SingleChildScrollView` / `CustomScrollView`—it throws unbounded height flex errors.

Always:

```dart
Card(
  clipBehavior: Clip.antiAlias,
  child: CmdDataTableBox(
    heightFactor: 0.34, // tune per page
    minHeight: 220,
    child: DataTable2(...),
  ),
)
```

---

## Layout & spacing

| Token | Value |
|-------|--------|
| Max content width | `CmdBreakpoints.maxContentWidth` (1280) |
| Horizontal padding | 16 mobile / 24 tablet+ |
| Vertical padding | 16 mobile / 24 tablet+ |
| Grid gap | 12 |
| Between major sections | 16–24 |

---

## Adopting on a non-CMAC page (step-by-step)

1. **Pick a domain color pair** (existing `CmacPalette` or new documented hex pair).
2. Replace plain `Scaffold` body with `CmacVibrantBackdrop` + `CustomScrollView` or use `CmacAnalyticsScaffold` if the page loads async analytics.
3. Replace stat rows / plain `Card` metrics with `CmacKpiGrid` where you have KPI-shaped data.
4. Replace list-of-links navigation with a **`CmacHubTile` grid** and section header **“Domain dashboards”** (or a context-specific title like “Quick links”).
5. Use `CmacPeriodToolbar` or match its chip styling for date filters.
6. Wrap tables with `CmdDataTableBox`.
7. Use `CmacPalette.severityColor` / `trendColor` for alerts and deltas—do not hardcode random reds/greens.

---

## Anti-patterns (do not)

- Flat grey `Scaffold` backgrounds on executive dashboards that should match CMAC.
- Random per-screen primary colors without adding them to the palette table.
- `Expanded` / flex children inside unbounded scroll columns (including raw `DataTable2`).
- Full-opacity domain gradients behind paragraphs of body text.
- More than three font weights on one card (stick to w600 / w700 / w800).

---

## AI prompt template (redesign other pages)

Copy, fill in the bracketed sections, and attach this file:

```text
Redesign [SCREEN / MODULE NAME] in the Helty Flutter app to match the
"Helty vibrant dashboard design system" documented in docs/helty-vibrant-dashboard-design.md.

Reference implementation: lib/src/cmac/ (especially cmac_overview_screen.dart for
Domain dashboards hub cards and cmac_* domain screens for drill-down layout).

Requirements:
1. Use CmacVibrantBackdrop with domain colors: [palette token or hex pair].
2. Use CustomScrollView + SliverAppBar OR CmacAnalyticsScaffold for data pages.
3. Navigation / area picker: CmacHubTile grid with section header (like "Domain dashboards").
4. Metrics: CmacKpiGrid + CmacKpiCard with accent = palette.first.
5. Filters: CmacPeriodToolbar styling OR equivalent chips with accent border.
6. Charts: CmacBarChartCard / CmacLineChartCard inside radius-16 Cards.
7. Tables: DataTable2 only inside CmdDataTableBox inside a Card.
8. Alerts: CmacAlertBanner; insights: CmacInsightList / CmacInsightCard.
9. Layout: CmdBreakpoints padding, max width 1280, responsive grids per doc.
10. Do not change API contracts or business logic—UI/layout only unless noted.

Screens to migrate in this pass:
- [list routes or file paths]

Domain color assignment:
- [Screen A] → CmacPalette.[token]
- [Screen B] → [new hex pair, add to palette doc]

Keep existing routes and providers; match imports from lib/src/cmac/widgets/.
```

### Example: redesign pharmacy supply history

```text
Redesign lib/src/pharmacy/ui/suppliy.history.screen.dart per
docs/helty-vibrant-dashboard-design.md. Use CmacPalette.pharmacy, hub tiles for
"Stock history", "Reorder alerts", "Suppliers" if those routes exist, KPI row for
summary stats, CmdDataTableBox for the main table. UI only.
```

---

## Quick reference: overview screen structure

The canonical “Domain dashboards” block lives in `lib/src/cmac/ui/cmac_overview_screen.dart`:

1. `CmacVibrantBackdrop(colors: CmacPalette.overview)`
2. `CmacPeriodToolbar(accentColor: CmacPalette.overview.first)`
3. `CmacKpiGrid` → Alerts → Insights → **“Domain dashboards”** → `GridView` of `CmacHubTile`

When in doubt, open that file and mirror its spacing and section order.

---

## Related docs

- [cmac-analytics-frontend.md](./cmac-analytics-frontend.md) — API endpoints, KPI JSON, periods
- CMD financial screens — also use `CmdBreakpoints` and `CmdDataTableBox`; visual style is more subdued than CMAC but layout rules align
