import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/extensions/number.extention.dart';
import '../../helper/app_timezone.dart';
import '../../helper/date.formatter.dart';
import '../../investigations/models/investigation_models.dart';
import '../../investigations/models/investigation_query_params.dart';
import '../../investigations/providers/investigation_providers.dart';
import '../../investigations/widgets/investigations_report_widgets.dart';
import '../../models/staff_model.dart';
import '../../models/super_admin_department_preview.dart';
import '../../providers/auth_provider.dart';
import '../../radiology/models/radiology_models.dart';

const _radiologyInvestigationStatuses = [
  'PENDING',
  'SCHEDULED',
  'IN_PROGRESS',
  'COMPLETED',
  'REPORTED',
  'CANCELLED',
];

@RoutePage()
class RadiologyInvestigationsScreen extends ConsumerStatefulWidget {
  const RadiologyInvestigationsScreen({super.key});

  @override
  ConsumerState<RadiologyInvestigationsScreen> createState() =>
      _RadiologyInvestigationsScreenState();
}

class _RadiologyInvestigationsScreenState
    extends ConsumerState<RadiologyInvestigationsScreen> {
  static const _take = 20;

  late DateTimeRange _dateRange;
  final _testNameCtrl = TextEditingController();
  String? _status;
  RadiologyPriority? _priority;
  InvestigationSortBy _sortBy = InvestigationSortBy.createdAt;
  InvestigationSortOrder _sortOrder = InvestigationSortOrder.desc;
  int _skip = 0;

  @override
  void initState() {
    super.initState();
    final now = AppTimezone.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );
  }

  @override
  void dispose() {
    _testNameCtrl.dispose();
    super.dispose();
  }

  bool _canAccess(Staff? staff) {
    if (staff == null) return false;
    if (staffIsSuperAdmin(staff)) return true;
    final at = staff.accountType?.name.toLowerCase() ?? '';
    return at == 'radiology';
  }

  InvestigationsQueryParams _buildParams({bool forSummary = false}) {
    return InvestigationsQueryParams(
      fromDate: AppTimezone.dateTime(
        _dateRange.start.year,
        _dateRange.start.month,
        _dateRange.start.day,
      ),
      toDate: AppTimezone.dateTime(
        _dateRange.end.year,
        _dateRange.end.month,
        _dateRange.end.day,
        23,
        59,
        59,
        999,
      ),
      testName: _testNameCtrl.text.trim().isEmpty ? null : _testNameCtrl.text,
      status: _status,
      priority: _priority,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
      skip: forSummary ? 0 : _skip,
      take: _take,
    );
  }

  void _refresh() {
    invalidateInvestigationCaches(ref, radParams: _buildParams(forSummary: true));
    invalidateInvestigationCaches(ref, radParams: _buildParams());
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _dateRange,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateRange = DateTimeRange(
        start: DateTime(picked.start.year, picked.start.month, picked.start.day),
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
          999,
        ),
      );
      _skip = 0;
    });
    _refresh();
  }

  void _applyFilters() {
    setState(() => _skip = 0);
    _refresh();
  }

  void _clearFilters() {
    setState(() {
      _testNameCtrl.clear();
      _status = null;
      _priority = null;
      _skip = 0;
    });
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final staff = ref.watch(currentStaffProvider);

    if (!_canAccess(staff)) {
      return Scaffold(
        appBar: AppBar(title: const Text('Radiology investigations')),
        body: const Center(child: Text('Access denied for this account.')),
      );
    }

    final summaryParams = _buildParams(forSummary: true);
    final listParams = _buildParams();
    final summaryAsync =
        ref.watch(radiologyInvestigationsSummaryProvider(summaryParams));
    final listAsync = ref.watch(radiologyInvestigationsListProvider(listParams));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radiology investigations'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ResponsiveBody(
        expand: false,
        builder: (context, bp) => RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildFilterSection(theme),
            const SizedBox(height: 16),
            summaryAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => InvestigationErrorBanner(
                message: e.toString(),
                onRetry: _refresh,
              ),
              data: (summary) => _buildSummarySection(theme, summary),
            ),
            const SizedBox(height: 24),
            Text(
              'Investigation list',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            InvestigationSortControls(
              sortBy: _sortBy,
              sortOrder: _sortOrder,
              onSortByChanged: (v) {
                setState(() {
                  _sortBy = v;
                  _skip = 0;
                });
                _refresh();
              },
              onSortOrderChanged: (v) {
                setState(() {
                  _sortOrder = v;
                  _skip = 0;
                });
                _refresh();
              },
            ),
            const SizedBox(height: 8),
            listAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => InvestigationErrorBanner(
                message: e.toString(),
                onRetry: _refresh,
              ),
              data: (response) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InvestigationListTable(
                    rows: response.data,
                    showPriorityColumn: true,
                  ),
                  const SizedBox(height: 8),
                  InvestigationPaginationBar(
                    total: response.total,
                    skip: response.skip,
                    take: response.take,
                    onPrevious: response.skip > 0
                        ? () {
                            setState(() {
                              _skip = (response.skip - _take).clamp(0, response.total);
                            });
                            _refresh();
                          }
                        : null,
                    onNext: response.skip + response.take < response.total
                        ? () {
                            setState(() {
                              _skip = response.skip + _take;
                            });
                            _refresh();
                          }
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSummarySection(ThemeData theme, InvestigationSummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 220,
              child: InvestigationKpiCard(
                label: 'Total count',
                value: '${summary.totalCount}',
                icon: Icons.receipt_long_outlined,
              ),
            ),
            SizedBox(
              width: 220,
              child: InvestigationKpiCard(
                label: 'Total amount',
                value: summary.totalAmount.toFinancial(isMoney: true),
                icon: Icons.payments_outlined,
                accent: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        InvestigationBreakdownTables(summary: summary),
      ],
    );
  }

  Widget _buildFilterSection(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: _pickDateRange,
              icon: const Icon(Icons.date_range_outlined),
              label: Text(
                '${DateFormatter.shortDate(_dateRange.start)} – ${DateFormatter.shortDate(_dateRange.end)}',
              ),
            ),
            SizedBox(
              width: 180,
              child: TextField(
                controller: _testNameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Test name',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _applyFilters(),
              ),
            ),
            DropdownButton<String?>(
              value: _status,
              hint: const Text('Status'),
              onChanged: (v) => setState(() => _status = v),
              items: [
                const DropdownMenuItem(value: null, child: Text('All statuses')),
                for (final s in _radiologyInvestigationStatuses)
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
            ),
            DropdownButton<RadiologyPriority?>(
              value: _priority,
              hint: const Text('Priority'),
              onChanged: (v) => setState(() => _priority = v),
              items: [
                const DropdownMenuItem(value: null, child: Text('All priorities')),
                for (final p in RadiologyPriority.values)
                  DropdownMenuItem(value: p, child: Text(p.name)),
              ],
            ),
            FilledButton.tonal(
              onPressed: _applyFilters,
              child: const Text('Apply'),
            ),
            TextButton(onPressed: _clearFilters, child: const Text('Clear')),
          ],
        ),
      ),
    );
  }
}
