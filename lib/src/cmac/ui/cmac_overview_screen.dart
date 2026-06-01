import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';

import '../../cmd/cmd_breakpoints.dart';
import '../cmac_palette.dart';
import '../models/cmac_analytics_models.dart';
import '../providers/cmac_providers.dart';
import '../widgets/cmac_alerts_insights.dart';
import '../widgets/cmac_hub_tile.dart';
import '../widgets/cmac_kpi_card.dart';
import '../widgets/cmac_period_toolbar.dart';
import '../widgets/cmac_vibrant_backdrop.dart';

@RoutePage()
class CmacOverviewScreen extends ConsumerWidget {
  const CmacOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void refresh() => ref.invalidate(cmacOverviewProvider);

    final async = ref.watch(cmacOverviewProvider);
    final theme = Theme.of(context);

    return Scaffold(
      body: CmacVibrantBackdrop(
        colors: CmacPalette.overview,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CMAC Oversight',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Executive hospital analytics',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: LayoutBuilder(
                builder: (context, c) {
                  final bp = CmdBreakpoints.fromWidth(c.maxWidth);
                  return Padding(
                    padding: EdgeInsets.fromLTRB(
                      bp.paddingH,
                      8,
                      bp.paddingH,
                      bp.paddingV,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CmacPeriodToolbar(
                          accentColor: CmacPalette.overview.first,
                          onRefresh: refresh,
                        ),
                        const SizedBox(height: 16),
                        async.when(
                          data: (data) => _OverviewBody(data: data),
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(48),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (e, _) => SelectableText('Error: $e'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewBody extends StatelessWidget {
  const _OverviewBody({required this.data});

  final CmacOverviewResponse data;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CmacKpiGrid(kpis: data.headlineKpis, accent: CmacPalette.overview.first),
        const SizedBox(height: 20),
        Text(
          'Alerts',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        CmacAlertBanner(alerts: data.alerts),
        const SizedBox(height: 20),
        Text(
          'Insights',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        CmacInsightList(insights: data.insights.take(5).toList()),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => context.router.push(const CmacInsightsRoute()),
            child: const Text('View all insights'),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Domain dashboards',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final cols = w >= 1000 ? 4 : w >= 700 ? 3 : w >= 450 ? 2 : 1;
            const tiles = _hubTiles;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: tiles.length,
              itemBuilder: (_, i) {
                final t = tiles[i];
                return CmacHubTile(
                  title: t.title,
                  subtitle: t.subtitle,
                  icon: t.icon,
                  colors: t.colors,
                  onTap: () => context.router.push(t.route),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _HubDef {
  const _HubDef({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final PageRouteInfo route;
}

const _hubTiles = <_HubDef>[
  _HubDef(
    title: 'Patient activity',
    subtitle: 'Visits, admissions, referrals',
    icon: Icons.people_alt_rounded,
    colors: CmacPalette.patientActivity,
    route: CmacPatientActivityRoute(),
  ),
  _HubDef(
    title: 'Clinical',
    subtitle: 'Diagnoses & outcomes',
    icon: Icons.medical_information_outlined,
    colors: CmacPalette.clinical,
    route: CmacClinicalRoute(),
  ),
  _HubDef(
    title: 'Laboratory',
    subtitle: 'TAT, critical results',
    icon: Icons.biotech_rounded,
    colors: CmacPalette.laboratory,
    route: CmacLaboratoryRoute(),
  ),
  _HubDef(
    title: 'Pharmacy',
    subtitle: 'Prescribing & stock',
    icon: Icons.medication_rounded,
    colors: CmacPalette.pharmacy,
    route: CmacPharmacyRoute(),
  ),
  _HubDef(
    title: 'Operations',
    subtitle: 'Appointments & workload',
    icon: Icons.schedule_rounded,
    colors: CmacPalette.operations,
    route: CmacOperationsRoute(),
  ),
  _HubDef(
    title: 'Quality',
    subtitle: 'Incidents & audit flags',
    icon: Icons.verified_user_rounded,
    colors: CmacPalette.quality,
    route: CmacQualityRoute(),
  ),
  _HubDef(
    title: 'Staff',
    subtitle: 'Efficiency & workload',
    icon: Icons.groups_rounded,
    colors: CmacPalette.staff,
    route: CmacStaffRoute(),
  ),
  _HubDef(
    title: 'Quality capture',
    subtitle: 'Log referrals & incidents',
    icon: Icons.edit_note_rounded,
    colors: CmacPalette.qualitySafety,
    route: CmacQualitySafetyHubRoute(),
  ),
];
