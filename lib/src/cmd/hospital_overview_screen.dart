import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/widgets/helty_surface.dart';

import 'cmd_overview_metrics.dart';
import 'cmd_providers.dart';
import 'models/cmd_models.dart';
import 'widgets/cmd_command_kpi_strip.dart';
import 'widgets/cmd_overview_filter_bar.dart';
import 'widgets/cmd_overview_header.dart';
import 'widgets/cmd_overview_sidebar.dart';
import 'widgets/cmd_overview_table.dart';

@RoutePage()
class CMDHospitalOverviewScreen extends ConsumerStatefulWidget {
  const CMDHospitalOverviewScreen({super.key});

  @override
  ConsumerState<CMDHospitalOverviewScreen> createState() =>
      _CMDHospitalOverviewScreenState();
}

class _CMDHospitalOverviewScreenState
    extends ConsumerState<CMDHospitalOverviewScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusValue = 'all';
  String _sortValue = 'name';
  int _skip = 0;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _searchQuery) {
        setState(() {
          _searchQuery = q;
          _skip = 0;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<CmdDepartmentScorecard> _filtered(CmdHospitalOverview data) {
    return CmdOverviewMetrics.applyClientFilters(
      rows: data.departments,
      query: _searchQuery,
      statusValue: _statusValue,
      sortValue: _sortValue,
    );
  }

  List<CmdDepartmentScorecard> _page(List<CmdDepartmentScorecard> filtered) {
    if (_skip >= filtered.length) return const [];
    final end = _skip + CmdOverviewMetrics.pageSize;
    return filtered.sublist(
      _skip,
      end > filtered.length ? filtered.length : end,
    );
  }

  String get _emptyMessage {
    if (_searchQuery.isNotEmpty || _statusValue != 'all') {
      return 'No departments match the current filters.';
    }
    return 'No department scorecards.';
  }

  void _goPrev() {
    if (_skip <= 0) return;
    setState(() {
      final next = _skip - CmdOverviewMetrics.pageSize;
      _skip = next < 0 ? 0 : next;
    });
  }

  void _goNext(int total) {
    if (_skip + CmdOverviewMetrics.pageSize >= total) return;
    setState(() => _skip += CmdOverviewMetrics.pageSize);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final async = ref.watch(cmdHospitalOverviewProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final compact = width < CmdOverviewMetrics.cardBreakpoint;
          final showSideBySide = width >= CmdOverviewMetrics.sidebarBreakpoint;
          final useSnapKpis = width < 520;

          return async.when(
            loading: () => _StatusScaffold(
              compact: compact,
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => _StatusScaffold(
              compact: compact,
              child: _ErrorState(
                message: '$e',
                onRetry: () => ref.invalidate(cmdHospitalOverviewProvider),
              ),
            ),
            data: (data) => _OverviewBody(
              data: data,
              compact: compact,
              showSideBySide: showSideBySide,
              useSnapKpis: useSnapKpis,
              searchController: _searchCtrl,
              statusValue: _statusValue,
              onStatusChanged: (value) {
                setState(() {
                  _statusValue = value;
                  _skip = 0;
                });
              },
              sortValue: _sortValue,
              onSortChanged: (value) {
                setState(() {
                  _sortValue = value;
                  _skip = 0;
                });
              },
              pageRows: _page(_filtered(data)),
              filteredTotal: _filtered(data).length,
              skip: _skip,
              emptyMessage: _emptyMessage,
              onPrev: _goPrev,
              onNext: () => _goNext(_filtered(data).length),
              onRefresh: () {
                setState(() => _skip = 0);
                ref.invalidate(cmdHospitalOverviewProvider);
              },
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
        CmdOverviewHeader(compact: compact),
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
                color: CmdOverviewMetrics.waitRed,
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

class _OverviewBody extends StatelessWidget {
  const _OverviewBody({
    required this.data,
    required this.compact,
    required this.showSideBySide,
    required this.useSnapKpis,
    required this.searchController,
    required this.statusValue,
    required this.onStatusChanged,
    required this.sortValue,
    required this.onSortChanged,
    required this.pageRows,
    required this.filteredTotal,
    required this.skip,
    required this.emptyMessage,
    required this.onPrev,
    required this.onNext,
    required this.onRefresh,
  });

  final CmdHospitalOverview data;
  final bool compact;
  final bool showSideBySide;
  final bool useSnapKpis;
  final TextEditingController searchController;
  final String statusValue;
  final ValueChanged<String> onStatusChanged;
  final String sortValue;
  final ValueChanged<String> onSortChanged;
  final List<CmdDepartmentScorecard> pageRows;
  final int filteredTotal;
  final int skip;
  final String emptyMessage;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onRefresh;

  Widget _sidebar(BuildContext context, {required bool fillHeight}) {
    return CmdOverviewSidebar(
      flow: data.flow,
      waitTimes: data.waitTimes,
      dailySummary: data.dailySummary,
      weeklySummary: data.weeklySummary,
      onRefresh: onRefresh,
      onCommandCenter: () => context.router.push(const CMDDashboardRoute()),
      onStaffOversight: () =>
          context.router.push(const CMDStaffOversightRoute()),
      onAlerts: () => context.router.push(const CMDAlertsIncidentsRoute()),
      onViewSummaries: () => showCmdOverviewSummariesDialog(
        context: context,
        dailySummary: data.dailySummary,
        weeklySummary: data.weeklySummary,
        waitTimes: data.waitTimes,
      ),
      fillHeight: fillHeight,
    );
  }

  Widget _queuePanel({required bool useCards}) {
    final hasMore = skip + pageRows.length < filteredTotal;
    if (useCards) {
      return CmdOverviewScorecardCardList(
        rows: pageRows,
        skip: skip,
        loading: false,
        emptyMessage: emptyMessage,
        total: filteredTotal,
        hasMore: hasMore,
        pageSize: CmdOverviewMetrics.pageSize,
        onPrev: onPrev,
        onNext: onNext,
      );
    }
    return CmdOverviewScorecardTable(
      rows: pageRows,
      skip: skip,
      loading: false,
      emptyMessage: emptyMessage,
      total: filteredTotal,
      hasMore: hasMore,
      pageSize: CmdOverviewMetrics.pageSize,
      onPrev: onPrev,
      onNext: onNext,
    );
  }

  Widget _mainColumn({required bool useCards}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CmdOverviewHeader(compact: compact),
        const SizedBox(height: 10),
        CmdCommandKpiStrip(
          items: CmdOverviewMetrics.kpiItemsFor(data),
          useSnapStrip: useSnapKpis,
        ),
        const SizedBox(height: 10),
        CmdOverviewFilterBar(
          searchController: searchController,
          statusValue: statusValue,
          onStatusChanged: onStatusChanged,
          sortValue: sortValue,
          onSortChanged: onSortChanged,
          compact: compact,
        ),
        const SizedBox(height: 10),
        Expanded(child: _queuePanel(useCards: useCards)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final useCards = compact;
    if (showSideBySide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 9, child: _mainColumn(useCards: useCards)),
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
              Expanded(child: _mainColumn(useCards: useCards)),
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
            CmdOverviewHeader(compact: compact),
            const SizedBox(height: 10),
            CmdCommandKpiStrip(
              items: CmdOverviewMetrics.kpiItemsFor(data),
              useSnapStrip: useSnapKpis,
            ),
            const SizedBox(height: 10),
            CmdOverviewFilterBar(
              searchController: searchController,
              statusValue: statusValue,
              onStatusChanged: onStatusChanged,
              sortValue: sortValue,
              onSortChanged: onSortChanged,
              compact: compact,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: compact ? 480 : 520,
              child: _queuePanel(useCards: useCards),
            ),
            const SizedBox(height: 10),
            _sidebar(context, fillHeight: false),
          ],
        );
      },
    );
  }
}
