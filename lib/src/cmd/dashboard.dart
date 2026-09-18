import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/widgets/helty_surface.dart';

import 'cmd_command_metrics.dart';
import 'cmd_providers.dart';
import 'models/cmd_models.dart';
import 'widgets/cmd_command_header.dart';
import 'widgets/cmd_command_kpi_strip.dart';
import 'widgets/cmd_command_panels.dart';
import 'widgets/cmd_command_sidebar.dart';

@RoutePage()
class CMDDashboardScreen extends ConsumerWidget {
  const CMDDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final asyncDash = ref.watch(cmdExecutiveDashboardProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final compact = width < CmdCommandMetrics.cardBreakpoint;
          final showSideBySide = width >= CmdCommandMetrics.sidebarBreakpoint;
          final useSnapKpis = width < 520;

          return asyncDash.when(
            loading: () => _StatusScaffold(
              compact: compact,
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _StatusScaffold(
              compact: compact,
              child: _ErrorState(
                message: '$e',
                onRetry: () => ref.invalidate(cmdExecutiveDashboardProvider),
              ),
            ),
            data: (bundle) => _DashboardBody(
              bundle: bundle,
              compact: compact,
              showSideBySide: showSideBySide,
              useSnapKpis: useSnapKpis,
              onRefresh: () => ref.invalidate(cmdExecutiveDashboardProvider),
            ),
          );
        },
      ),
    );
  }
}

class _StatusScaffold extends StatelessWidget {
  const _StatusScaffold({required this.compact, required this.child});

  final bool compact;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CmdCommandHeader(compact: compact),
        const SizedBox(height: 10),
        Expanded(child: child),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: HeltySurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const HeltySolidIcon(
                icon: Icons.error_outline,
                color: CmdCommandMetrics.waitRed,
                size: 34,
                iconSize: 18,
                radius: 8,
              ),
              const SizedBox(height: 12),
              SelectableText(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({
    required this.bundle,
    required this.compact,
    required this.showSideBySide,
    required this.useSnapKpis,
    required this.onRefresh,
  });

  final CmdExecutiveDashboardBundle bundle;
  final bool compact;
  final bool showSideBySide;
  final bool useSnapKpis;
  final VoidCallback onRefresh;

  void _openOverview(BuildContext context) {
    context.router.push(const CMDHospitalOverviewRoute());
  }

  void _openFinancial(BuildContext context) {
    context.router.push(const CMDFinancialCommandRoute());
  }

  void _openAlerts(BuildContext context) {
    context.router.push(const CMDAlertsIncidentsRoute());
  }

  Widget _sidebar(BuildContext context, {required bool fillHeight}) {
    return CmdCommandSidebar(
      alerts: bundle.alerts,
      activity: bundle.activityFeed,
      onRefresh: onRefresh,
      onHospitalOverview: () => _openOverview(context),
      onFinancialCommand: () => _openFinancial(context),
      onAlerts: () => _openAlerts(context),
      onViewAllActivity: () =>
          showCmdActivityDialog(context, bundle.activityFeed),
      fillHeight: fillHeight,
    );
  }

  Widget _mainColumn() {
    final kpis = CmdCommandMetrics.kpiItemsFor(bundle);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CmdCommandHeader(compact: compact),
        const SizedBox(height: 10),
        CmdCommandKpiStrip(items: kpis, useSnapStrip: useSnapKpis),
        const SizedBox(height: 10),
        Expanded(
          child: SingleChildScrollView(
            child: CmdCommandOverviewGrid(bundle: bundle, compact: compact),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (showSideBySide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 9, child: _mainColumn()),
          const SizedBox(width: 12),
          Expanded(flex: 3, child: _sidebar(context, fillHeight: true)),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.maxHeight.isFinite;
        if (bounded) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _mainColumn()),
              const SizedBox(height: 10),
              SizedBox(
                height: 280,
                child: SingleChildScrollView(
                  child: _sidebar(context, fillHeight: false),
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CmdCommandHeader(compact: compact),
            const SizedBox(height: 10),
            CmdCommandKpiStrip(
              items: CmdCommandMetrics.kpiItemsFor(bundle),
              useSnapStrip: useSnapKpis,
            ),
            const SizedBox(height: 10),
            CmdCommandOverviewGrid(bundle: bundle, compact: compact),
            const SizedBox(height: 10),
            _sidebar(context, fillHeight: false),
          ],
        );
      },
    );
  }
}
