import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/widgets/helty_surface.dart';

import '../auth/nursing_permissions.dart';
import '../helper/date.formatter.dart';
import '../models/nurse_dashboard_models.dart';
import '../models/staff_model.dart';
import '../nursing/models/nursing_models.dart';
import '../nursing/providers/nursing_providers.dart';
import '../providers/auth_provider.dart';
import 'dashboard/nurse_dashboard_metrics.dart';
import 'dashboard/widgets/nurse_dashboard_charts.dart';
import 'dashboard/widgets/nurse_dashboard_filter_bar.dart';
import 'dashboard/widgets/nurse_dashboard_header.dart';
import 'dashboard/widgets/nurse_dashboard_kpi_strip.dart';
import 'dashboard/widgets/nurse_dashboard_role_strip.dart';
import 'dashboard/widgets/nurse_dashboard_sidebar.dart';
import 'dashboard/widgets/nurse_dashboard_worklist.dart';

@RoutePage()
class NursesDashboardScreen extends ConsumerStatefulWidget {
  const NursesDashboardScreen({super.key});

  @override
  ConsumerState<NursesDashboardScreen> createState() =>
      _NursesDashboardScreenState();
}

class _NursesDashboardScreenState extends ConsumerState<NursesDashboardScreen> {
  final _searchCtrl = TextEditingController();
  String _timeRange = 'Today';
  String _searchQuery = '';
  NursingDashboardOverview? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _searchQuery) setState(() => _searchQuery = q);
    });
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(nursingApiServiceProvider);
      final staff = ref.read(authProvider).staff;
      final bootstrap = ref.read(nursingBootstrapDataProvider);
      final role =
          bootstrap?.normalizedStaffRole ??
          normalizeNursingStaffRole(staff?.staffRole);
      final overview = await service.getOverviewForRole(
        staffRole: role.isNotEmpty ? role : 'INPATIENT_NURSE',
        timeRange: _timeRange,
      );
      if (!mounted) return;
      setState(() {
        _data = overview;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e is DioException && e.response?.statusCode == 403
          ? 'You do not have access to this nursing dashboard.'
          : e.toString();
      setState(() {
        _error = msg;
        _loading = false;
      });
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String? _unitLine(NursingDashboardOverview data) {
    final staff = ref.read(authProvider).staff;
    final bootstrap = ref.read(nursingBootstrapDataProvider);
    final unitDisplay = isChargeNurse(staff)
        ? (bootstrap?.ward?.name ?? bootstrap?.department?.name)
        : bootstrap?.department?.name;
    final parts = [
      if (unitDisplay != null && unitDisplay.trim().isNotEmpty) unitDisplay,
      if (data.nursingUnit != null && data.nursingUnit!.trim().isNotEmpty)
        NurseDashboardMetrics.unitLabel(data.nursingUnit),
    ];
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  String? _windowLabel(NursingDashboardOverview data) {
    final start = DateFormatter.shortDate(data.base.window.start);
    final end = DateFormatter.shortDate(data.base.window.end);
    if (start == end) return start;
    return '$start – $end';
  }

  List<NursingAssignedAdmission> _filteredAdmissions(
    NursingDashboardOverview data,
  ) {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return data.assignedAdmissions;
    return data.assignedAdmissions.where((a) {
      final hay = [
        a.patientName,
        a.patientNumber ?? '',
        a.wardName ?? '',
        a.bedLabel ?? '',
        a.admissionId,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  List<NursingOutpatientQueuePatient> _filteredOpd(
    NursingDashboardOverview data,
  ) {
    final q = _searchQuery.toLowerCase();
    if (q.isEmpty) return data.outpatientQueue;
    return data.outpatientQueue.where((p) {
      final hay = [
        p.patientName,
        p.serviceName ?? '',
        p.invoiceId,
      ].join(' ').toLowerCase();
      return hay.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final staff = ref.watch(authProvider).staff;
    final bootstrap = ref.watch(nursingBootstrapDataProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final compact = width < NurseDashboardMetrics.cardBreakpoint;
          final showSideBySide =
              width >= NurseDashboardMetrics.sidebarBreakpoint;
          final useSnapKpis = width < 520;

          if (_loading && _data == null) {
            return _StatusScaffold(
              compact: compact,
              child: const Center(child: CircularProgressIndicator()),
            );
          }

          final data = _data;
          if (data == null) {
            return _StatusScaffold(
              compact: compact,
              child: _ErrorState(
                message: _error ?? 'No dashboard data',
                onRetry: _load,
              ),
            );
          }

          return _DashboardBody(
            data: data,
            staff: staff,
            bootstrap: bootstrap,
            compact: compact,
            showSideBySide: showSideBySide,
            useSnapKpis: useSnapKpis,
            loading: _loading,
            timeRange: _timeRange,
            searchController: _searchCtrl,
            unitLine: _unitLine(data),
            windowLabel: _windowLabel(data),
            admissions: _filteredAdmissions(data),
            outpatientQueue: _filteredOpd(data),
            onTimeRangeChanged: (value) {
              setState(() => _timeRange = value);
              _load();
            },
            onRefresh: _load,
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
        NursesDashboardHeader(
          compact: compact,
          header: const NurseDashboardHeader(
            title: 'Nursing Dashboard',
            subtitle: 'Ward coverage, patient flow, and staffing.',
          ),
        ),
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
                color: NurseDashboardMetrics.waitRed,
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
    required this.data,
    required this.staff,
    required this.bootstrap,
    required this.compact,
    required this.showSideBySide,
    required this.useSnapKpis,
    required this.loading,
    required this.timeRange,
    required this.searchController,
    required this.unitLine,
    required this.windowLabel,
    required this.admissions,
    required this.outpatientQueue,
    required this.onTimeRangeChanged,
    required this.onRefresh,
  });

  final NursingDashboardOverview data;
  final Staff? staff;
  final NursingDashboardMe? bootstrap;
  final bool compact;
  final bool showSideBySide;
  final bool useSnapKpis;
  final bool loading;
  final String timeRange;
  final TextEditingController searchController;
  final String? unitLine;
  final String? windowLabel;
  final List<NursingAssignedAdmission> admissions;
  final List<NursingOutpatientQueuePatient> outpatientQueue;
  final ValueChanged<String> onTimeRangeChanged;
  final VoidCallback onRefresh;

  bool get _showWorklist =>
      data.isLineDashboard ||
      admissions.isNotEmpty ||
      outpatientQueue.isNotEmpty;

  bool get _showCharts => !data.isLineDashboard;

  bool get _showSearch => _showWorklist;

  bool get _showKpis {
    if (!data.isLineDashboard) return true;
    return NurseDashboardMetrics.kpiItemsFor(
      data,
    ).any((item) => item.value.trim().isNotEmpty && item.value.trim() != '—');
  }

  Widget _sidebar(BuildContext context, {required bool fillHeight}) {
    final canRoster = canManageShiftRoster(staff, bootstrap);
    final canAssign =
        canAssignInpatientPatients(staff, bootstrap) ||
        canAssignOutpatientPatients(staff, bootstrap);
    return NurseDashboardSidebar(
      staffOnDuty: data.base.staffOnDuty,
      alerts: data.base.criticalAlerts,
      myShifts: data.isLineDashboard ? data.myRosterShifts : const [],
      onRefresh: onRefresh,
      onWardCensus: () => context.router.push(const InpatientsListRoute()),
      onWaitingPatients: () =>
          context.router.push(const WaitingPatientsRoute()),
      onViewAlerts: () =>
          showNurseDashboardAlertsDialog(context, data.base.criticalAlerts),
      onManageRoster: canRoster
          ? () => context.router.push(const NursingRosterRoute())
          : null,
      onAssignments: canAssign
          ? () => context.router.push(const NursingAssignmentsRoute())
          : null,
      fillHeight: fillHeight,
    );
  }

  Widget _mainPanel(BuildContext context, {required bool useCards}) {
    void openAdmission(NursingAssignedAdmission a) {
      context.router.push(
        InpatientPatientViewRoute(admissionId: a.admissionId),
      );
    }

    if (_showCharts && _showWorklist) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: NurseDashboardCharts(
              overview: data.base,
              timeRange: timeRange,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            flex: 4,
            child: NurseDashboardWorklist(
              admissions: admissions,
              outpatientQueue: outpatientQueue,
              useCards: useCards,
              emptyMessage: _emptyMessage,
              onOpenAdmission: openAdmission,
            ),
          ),
        ],
      );
    }
    if (_showCharts) {
      return NurseDashboardCharts(overview: data.base, timeRange: timeRange);
    }
    return NurseDashboardWorklist(
      admissions: admissions,
      outpatientQueue: outpatientQueue,
      useCards: useCards,
      emptyMessage: _emptyMessage,
      onOpenAdmission: openAdmission,
    );
  }

  String get _emptyMessage {
    if (_searchQueryActive) {
      return 'No patients match the current search.';
    }
    if (data.isLineDashboard) {
      return 'No assigned patients for this shift.';
    }
    return 'No patients to display.';
  }

  bool get _searchQueryActive => searchController.text.trim().isNotEmpty;

  Widget _mainColumn(BuildContext context, {required bool useCards}) {
    final canRoster = canManageShiftRoster(staff, bootstrap);
    final canAssign =
        canAssignInpatientPatients(staff, bootstrap) ||
        canAssignOutpatientPatients(staff, bootstrap);
    final showHospitalUnits =
        canViewHospitalDashboard(staff, bootstrap) &&
        data.unitRosterCounts.isNotEmpty;
    final showShifts =
        canViewUnitDashboard(staff, bootstrap) &&
        data.shiftBreakdown.isNotEmpty;

    final roleStrip = NurseDashboardRoleStrip(
      unitRosterCounts: showHospitalUnits ? data.unitRosterCounts : const [],
      shiftBreakdown: showShifts ? data.shiftBreakdown : const [],
      onManageRoster: canRoster
          ? () => context.router.push(const NursingRosterRoute())
          : null,
      onAssignments: canAssign
          ? () => context.router.push(const NursingAssignmentsRoute())
          : null,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (loading) const LinearProgressIndicator(minHeight: 2),
        NursesDashboardHeader(
          compact: compact,
          header: data.base.header,
          unitLine: unitLine,
        ),
        const SizedBox(height: 10),
        if (_showKpis) ...[
          NurseDashboardKpiStrip(
            items: NurseDashboardMetrics.kpiItemsFor(data),
            useSnapStrip: useSnapKpis,
          ),
          const SizedBox(height: 10),
        ],
        NurseDashboardFilterBar(
          timeRange: timeRange,
          onTimeRangeChanged: onTimeRangeChanged,
          compact: compact,
          searchController: searchController,
          showSearch: _showSearch,
          windowLabel: windowLabel,
        ),
        if (!roleStrip.isEmpty) ...[const SizedBox(height: 10), roleStrip],
        const SizedBox(height: 10),
        Expanded(child: _mainPanel(context, useCards: useCards)),
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
          Expanded(flex: 9, child: _mainColumn(context, useCards: useCards)),
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
              Expanded(child: _mainColumn(context, useCards: useCards)),
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
            NursesDashboardHeader(
              compact: compact,
              header: data.base.header,
              unitLine: unitLine,
            ),
            const SizedBox(height: 10),
            if (_showKpis) ...[
              NurseDashboardKpiStrip(
                items: NurseDashboardMetrics.kpiItemsFor(data),
                useSnapStrip: useSnapKpis,
              ),
              const SizedBox(height: 10),
            ],
            NurseDashboardFilterBar(
              timeRange: timeRange,
              onTimeRangeChanged: onTimeRangeChanged,
              compact: compact,
              searchController: searchController,
              showSearch: _showSearch,
              windowLabel: windowLabel,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: compact ? 480 : 520,
              child: _mainPanel(context, useCards: useCards),
            ),
            const SizedBox(height: 10),
            _sidebar(context, fillHeight: false),
          ],
        );
      },
    );
  }
}
