import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/obstetrics/ui/obstetrics_patient_select_screen.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_cards.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_theme.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:helty/src/providers/service_providers.dart';

@RoutePage()
class ObstetricsDashboardScreen extends ConsumerStatefulWidget {
  const ObstetricsDashboardScreen({super.key});

  @override
  ConsumerState<ObstetricsDashboardScreen> createState() =>
      _ObstetricsDashboardScreenState();
}

class _ObstetricsDashboardScreenState
    extends ConsumerState<ObstetricsDashboardScreen> {
  int? _gynaeTotal;
  int? _pregnancyTotal;
  bool _loadingStats = true;
  String? _statsError;

  ObstetricsService get _service => ref.read(obstetricsServiceProvider);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _loadingStats = true;
      _statsError = null;
    });
    try {
      final gynaeRes = await _service.listGynaeProcedures(take: 1);
      int? pregTotal;
      final patient = ref.read(patientProvider).selectedPatient;
      final patientId = patient?.id;
      if (patientId != null && patientId.isNotEmpty) {
        final pregRes = await _service.listPregnancies(
          patientId: patientId,
          take: 1,
        );
        pregTotal = pregRes.total;
      }
      if (!mounted) return;
      setState(() {
        _gynaeTotal = gynaeRes.total;
        _pregnancyTotal = pregTotal;
        _loadingStats = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _statsError = e.message;
        _loadingStats = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingStats = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selectedPatient = ref.watch(patientProvider).selectedPatient;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              floating: true,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  'O&G',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                background: Container(
                  decoration: ObstetricsTheme.gradientHeader(colorScheme),
                  child: SafeArea(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 24, bottom: 16),
                        child: Icon(
                          Icons.pregnant_woman_rounded,
                          size: 64,
                          color: colorScheme.primary.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                child: Text(
                  'Obstetrics & Gynaecology',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: ObstetricsTheme.contentMaxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _buildStatsRow(theme, colorScheme, selectedPatient),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: ObstetricsTheme.contentMaxWidth,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                    child: ResponsiveWrapGrid(
                      mobileColumns: 1,
                      tabletColumns: 2,
                      desktopColumns: 2,
                      children: [
                        _DashboardCard(
                          title: 'Pregnancies',
                          bullets: const [
                            'Antenatal visits & vitals',
                            'Labour, delivery & babies',
                            'Postnatal follow-up',
                          ],
                          icon: Icons.pregnant_woman_rounded,
                          accent: colorScheme.primary,
                          onTap: () => context.router.push(
                            ObstetricsPatientSelectRoute(
                              target: ObstetricsSelectTarget.pregnancies,
                            ),
                          ),
                        ),
                        _DashboardCard(
                          title: 'Gynaecology',
                          bullets: const [
                            'Procedures & findings',
                            'Complications tracking',
                            'Patient-scoped records',
                          ],
                          icon: Icons.medical_services_rounded,
                          accent: colorScheme.tertiary,
                          onTap: () => context.router.push(
                            ObstetricsPatientSelectRoute(
                              target: ObstetricsSelectTarget.gynae,
                            ),
                          ),
                        ),
                        _DashboardCard(
                          title: 'ANC package',
                          bullets: const [
                            'Default antenatal services & drugs',
                            'Zero-bill covered items',
                            'Admin configuration',
                          ],
                          icon: Icons.inventory_2_outlined,
                          accent: colorScheme.secondary,
                          onTap: () => context.router.push(
                            const ClinicalPackageManagementRoute(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    ThemeData theme,
    ColorScheme colorScheme,
    dynamic selectedPatient,
  ) {
    if (_loadingStats) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final pregValue = _pregnancyTotal != null
        ? '$_pregnancyTotal'
        : (selectedPatient != null ? '0' : '—');
    final pregLabel = _pregnancyTotal != null
        ? 'Pregnancies (patient)'
        : 'Pregnancies (select patient)';

    return ResponsiveWrapGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 2,
      children: [
        ObKpiStatCard(
          icon: Icons.pregnant_woman_rounded,
          value: pregValue,
          label: pregLabel,
          color: colorScheme.primary,
        ),
        ObKpiStatCard(
          icon: Icons.medical_services_rounded,
          value: '${_gynaeTotal ?? '—'}',
          label: 'Gynae procedures (all)',
          color: colorScheme.tertiary,
        ),
      ],
    );
  }
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.bullets,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final List<String> bullets;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: ObstetricsTheme.borderRadius,
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: ObstetricsTheme.borderRadius,
        child: Ink(
          decoration: ObstetricsTheme.cardGradientAccent(accent, colorScheme),
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 32, color: accent),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                ...bullets.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: accent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            b,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Open',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Icon(Icons.arrow_forward_rounded, size: 18, color: accent),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
