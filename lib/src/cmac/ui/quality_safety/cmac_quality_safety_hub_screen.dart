import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';

import '../../cmac_palette.dart';
import '../../widgets/cmac_hub_tile.dart';
import '../../widgets/cmac_vibrant_backdrop.dart';

@RoutePage()
class CmacQualitySafetyHubScreen extends StatelessWidget {
  const CmacQualitySafetyHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: CmacVibrantBackdrop(
        colors: CmacPalette.qualitySafety,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              automaticallyImplyLeading: false,
              title: Text(
                'Quality & safety capture',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(24),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 320,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                delegate: SliverChildListDelegate([
                  CmacHubTile(
                    title: 'Referrals',
                    subtitle: 'In / out transfers',
                    icon: Icons.swap_horiz_rounded,
                    colors: const [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                    onTap: () => context.router.push(
                      const CmacQualityReferralsRoute(),
                    ),
                  ),
                  CmacHubTile(
                    title: 'Complaints',
                    subtitle: 'Patient feedback',
                    icon: Icons.record_voice_over_rounded,
                    colors: const [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                    onTap: () => context.router.push(
                      const CmacQualityComplaintsRoute(),
                    ),
                  ),
                  CmacHubTile(
                    title: 'Incidents',
                    subtitle: 'Safety reports',
                    icon: Icons.report_problem_rounded,
                    colors: const [Color(0xFFEF4444), Color(0xFFF87171)],
                    onTap: () => context.router.push(
                      const CmacQualityIncidentsRoute(),
                    ),
                  ),
                  CmacHubTile(
                    title: 'Infections',
                    subtitle: 'HAI registration',
                    icon: Icons.coronavirus_rounded,
                    colors: const [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    onTap: () => context.router.push(
                      const CmacQualityInfectionsRoute(),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
