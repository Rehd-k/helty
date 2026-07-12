import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

import '../../core/extensions/number.extention.dart';
import '../../helper/app_timezone.dart';
import '../../helper/date.formatter.dart';
import '../../investigations/models/investigation_models.dart';
import '../../investigations/models/investigation_query_params.dart';
import '../../investigations/providers/investigation_providers.dart';
import '../../investigations/widgets/investigations_report_widgets.dart';
import '../../lab/models/lab_models.dart';
import '../../lab/providers/lab_providers.dart';
import '../../models/super_admin_department_preview.dart';
import '../../printing/pdf/investigations_report_pdf.dart';
import '../../providers/auth_provider.dart';

@RoutePage()
class LabInvestigationsScreen extends ConsumerStatefulWidget {
  const LabInvestigationsScreen({super.key});

  @override
  ConsumerState<LabInvestigationsScreen> createState() =>
      _LabInvestigationsScreenState();
}

class _LabInvestigationsScreenState
    extends ConsumerState<LabInvestigationsScreen> {
  static const _take = 20;

  late DateTimeRange _dateRange;
  String? _testName;
  String? _categoryId;
  String? _status;
  bool? _sampleCollected;
  InvestigationSortBy _sortBy = InvestigationSortBy.createdAt;
  InvestigationSortOrder _sortOrder = InvestigationSortOrder.desc;
  int _skip = 0;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    final now = AppTimezone.now();
    _dateRange = DateTimeRange(
      start: DateTime(now.year, now.month, now.day),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );
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
      testName: _testName,
      status: _status,
      categoryId: _categoryId,
      sampleCollected: _sampleCollected,
      sortBy: _sortBy,
      sortOrder: _sortOrder,
      skip: forSummary ? 0 : _skip,
      take: _take,
    );
  }

  void _refresh() {
    invalidateInvestigationCaches(ref, labParams: _buildParams());
    invalidateInvestigationCaches(
      ref,
      labParams: _buildParams(forSummary: true),
    );
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
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
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
      _testName = null;
      _categoryId = null;
      _status = null;
      _sampleCollected = null;
      _skip = 0;
    });
    _refresh();
  }

  String _dateSlug() {
    final start = DateFormatter.shortDate(
      _dateRange.start,
    ).replaceAll('/', '-');
    final end = DateFormatter.shortDate(_dateRange.end).replaceAll('/', '-');
    return start == end ? start : '${start}_to_$end';
  }

  String _filenameSlug(String raw) {
    final slug = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return slug.replaceAll(RegExp(r'^_|_$'), '');
  }

  String _exportSubtitle({String? extra}) {
    final parts = <String>[
      '${DateFormatter.shortDate(_dateRange.start)} – ${DateFormatter.shortDate(_dateRange.end)}',
    ];
    if (_testName != null && _testName!.isNotEmpty) {
      parts.add('Test: $_testName');
    }
    if (_categoryId != null) parts.add('Category filter applied');
    if (_status != null) parts.add('Status: $_status');
    if (_sampleCollected == true) {
      parts.add('Sample: collected');
    } else if (_sampleCollected == false) {
      parts.add('Sample: pending');
    }
    if (extra != null && extra.isNotEmpty) parts.add(extra);
    return parts.join(' · ');
  }

  Future<List<InvestigationListRow>> _fetchRowsForExport({
    required int take,
    String? testName,
    String? departmentId,
  }) async {
    if (take <= 0) return const [];

    final base = _buildParams(forSummary: true);
    final params = InvestigationsQueryParams(
      fromDate: base.fromDate,
      toDate: base.toDate,
      testName: testName ?? base.testName,
      status: base.status,
      departmentId: departmentId ?? base.departmentId,
      categoryId: base.categoryId,
      sampleCollected: base.sampleCollected,
      sortBy: base.sortBy,
      sortOrder: base.sortOrder,
      skip: 0,
      take: take,
    );
    final response = await ref
        .read(labApiServiceProvider)
        .getInvestigations(params);
    return response.data;
  }

  Future<void> _runExport(Future<void> Function() action) async {
    if (_exporting) return;
    setState(() => _exporting = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        messenger?.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _printReport({
    required String title,
    required String? subtitle,
    required InvestigationsReportMode mode,
    List<InvestigationListRow> detailRows = const [],
    InvestigationSummary? summary,
    num? totalAmount,
    int? totalCount,
  }) async {
    await Printing.layoutPdf(
      onLayout: (format) async {
        final bytes = await buildInvestigationsReportPdf(
          format: format,
          title: title,
          subtitle: subtitle,
          mode: mode,
          detailRows: detailRows,
          summary: summary,
          totalAmount: totalAmount,
          totalCount: totalCount,
        );
        return Uint8List.fromList(bytes);
      },
    );
  }

  Future<void> _shareReport({
    required String filename,
    required String title,
    required String? subtitle,
    required InvestigationsReportMode mode,
    List<InvestigationListRow> detailRows = const [],
    InvestigationSummary? summary,
    num? totalAmount,
    int? totalCount,
  }) async {
    final bytes = await buildInvestigationsReportPdf(
      format: PdfPageFormat.a4,
      title: title,
      subtitle: subtitle,
      mode: mode,
      detailRows: detailRows,
      summary: summary,
      totalAmount: totalAmount,
      totalCount: totalCount,
    );
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: filename,
    );
  }

  Future<void> _exportFilteredList({required bool share}) async {
    final summary = ref
        .read(labInvestigationsSummaryProvider(_buildParams(forSummary: true)))
        .valueOrNull;
    final total = summary?.totalCount ?? 0;
    if (total <= 0) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('No investigations to export.')),
      );
      return;
    }

    await _runExport(() async {
      final rows = await _fetchRowsForExport(take: total);
      final title = 'Lab Investigations';
      final subtitle = _exportSubtitle();
      final amount =
          summary?.totalAmount ??
          rows.fold<num>(0, (sum, row) => sum + row.amount);

      if (share) {
        await _shareReport(
          filename: 'lab_investigations_${_dateSlug()}.pdf',
          title: title,
          subtitle: subtitle,
          mode: InvestigationsReportMode.detail,
          detailRows: rows,
          totalAmount: amount,
          totalCount: total,
        );
      } else {
        await _printReport(
          title: title,
          subtitle: subtitle,
          mode: InvestigationsReportMode.detail,
          detailRows: rows,
          totalAmount: amount,
          totalCount: total,
        );
      }
    });
  }

  Future<void> _exportSummaryByTest({required bool share}) async {
    final summary = ref
        .read(labInvestigationsSummaryProvider(_buildParams(forSummary: true)))
        .valueOrNull;
    if (summary == null || summary.byTestName.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('No summary data to export.')),
      );
      return;
    }

    await _runExport(() async {
      const title = 'Lab Investigations — By Test Name';
      final subtitle = _exportSubtitle();
      if (share) {
        await _shareReport(
          filename: 'lab_investigations_summary_by_test_${_dateSlug()}.pdf',
          title: title,
          subtitle: subtitle,
          mode: InvestigationsReportMode.summaryByTest,
          summary: summary,
        );
      } else {
        await _printReport(
          title: title,
          subtitle: subtitle,
          mode: InvestigationsReportMode.summaryByTest,
          summary: summary,
        );
      }
    });
  }

  Future<void> _exportSummaryByDepartment({required bool share}) async {
    final summary = ref
        .read(labInvestigationsSummaryProvider(_buildParams(forSummary: true)))
        .valueOrNull;
    if (summary == null || summary.byDepartment.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('No summary data to export.')),
      );
      return;
    }

    await _runExport(() async {
      const title = 'Lab Investigations — By Department';
      final subtitle = _exportSubtitle();
      if (share) {
        await _shareReport(
          filename:
              'lab_investigations_summary_by_department_${_dateSlug()}.pdf',
          title: title,
          subtitle: subtitle,
          mode: InvestigationsReportMode.summaryByDepartment,
          summary: summary,
        );
      } else {
        await _printReport(
          title: title,
          subtitle: subtitle,
          mode: InvestigationsReportMode.summaryByDepartment,
          summary: summary,
        );
      }
    });
  }

  Future<void> _exportTestDetails({
    required String testName,
    required int count,
    required bool share,
  }) async {
    if (count <= 0 || testName.trim().isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('No investigations to export.')),
      );
      return;
    }

    await _runExport(() async {
      final rows = await _fetchRowsForExport(take: count, testName: testName);
      final title = 'Lab Investigations — $testName';
      final subtitle = _exportSubtitle(extra: 'Test: $testName');
      final amount = rows.fold<num>(0, (sum, row) => sum + row.amount);

      if (share) {
        await _shareReport(
          filename:
              'lab_investigations_${_filenameSlug(testName)}_${_dateSlug()}.pdf',
          title: title,
          subtitle: subtitle,
          mode: InvestigationsReportMode.detail,
          detailRows: rows,
          totalAmount: amount,
          totalCount: rows.length,
        );
      } else {
        await _printReport(
          title: title,
          subtitle: subtitle,
          mode: InvestigationsReportMode.detail,
          detailRows: rows,
          totalAmount: amount,
          totalCount: rows.length,
        );
      }
    });
  }

  Future<void> _exportDepartmentDetails({
    required String departmentId,
    required String departmentName,
    required int count,
    required bool share,
  }) async {
    if (count <= 0 || departmentId.isEmpty) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(content: Text('No investigations to export.')),
      );
      return;
    }

    await _runExport(() async {
      final rows = await _fetchRowsForExport(
        take: count,
        departmentId: departmentId,
      );
      final title = 'Lab Investigations — $departmentName';
      final subtitle = _exportSubtitle(extra: 'Department: $departmentName');
      final amount = rows.fold<num>(0, (sum, row) => sum + row.amount);

      if (share) {
        await _shareReport(
          filename:
              'lab_investigations_${_filenameSlug(departmentName)}_${_dateSlug()}.pdf',
          title: title,
          subtitle: subtitle,
          mode: InvestigationsReportMode.detail,
          detailRows: rows,
          totalAmount: amount,
          totalCount: rows.length,
        );
      } else {
        await _printReport(
          title: title,
          subtitle: subtitle,
          mode: InvestigationsReportMode.detail,
          detailRows: rows,
          totalAmount: amount,
          totalCount: rows.length,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final staff = ref.watch(currentStaffProvider);
    final isLabUser =
        staffIsSuperAdmin(staff) ||
        staff?.staffRole.toLowerCase() == 'admin' ||
        staff?.accountType?.name.toLowerCase() == 'laboratory' ||
        staff?.accountType?.name.toLowerCase() == 'lab';

    if (!isLabUser) {
      return Scaffold(
        appBar: AppBar(title: const Text('Lab investigations')),
        body: const Center(child: Text('Access denied for this account.')),
      );
    }

    final summaryParams = _buildParams(forSummary: true);
    final listParams = _buildParams();
    final summaryAsync = ref.watch(
      labInvestigationsSummaryProvider(summaryParams),
    );
    final listAsync = ref.watch(labInvestigationsListProvider(listParams));
    final categoriesAsync = ref.watch(labCategoriesFutureProvider);
    final testsAsync = ref.watch(labTestsFutureProvider);
    final summaryData = summaryAsync.valueOrNull;
    final listExportEnabled = (summaryData?.totalCount ?? 0) > 0;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Lab Investigations'),
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
            _buildFilterSection(theme, categoriesAsync, testsAsync),
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Investigation list',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                InvestigationExportActions(
                  enabled: listExportEnabled,
                  exporting: _exporting,
                  onPrint: () => _exportFilteredList(share: false),
                  onShare: () => _exportFilteredList(share: true),
                ),
              ],
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
                    showSampleColumn: true,
                  ),
                  const SizedBox(height: 8),
                  InvestigationPaginationBar(
                    total: response.total,
                    skip: response.skip,
                    take: response.take,
                    onPrevious: response.skip > 0
                        ? () {
                            setState(() {
                              _skip = (response.skip - _take).clamp(
                                0,
                                response.total,
                              );
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
            if (summary.sampleCollectedCount != null)
              SizedBox(
                width: 220,
                child: InvestigationKpiCard(
                  label: 'Samples collected',
                  value: '${summary.sampleCollectedCount}',
                  icon: Icons.biotech_outlined,
                  accent: theme.colorScheme.tertiary,
                ),
              ),
            if (summary.samplePendingCount != null)
              SizedBox(
                width: 220,
                child: InvestigationKpiCard(
                  label: 'Samples pending',
                  value: '${summary.samplePendingCount}',
                  icon: Icons.hourglass_empty_outlined,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        InvestigationBreakdownTables(
          summary: summary,
          exporting: _exporting,
          onPrintSummaryByTest: () => _exportSummaryByTest(share: false),
          onShareSummaryByTest: () => _exportSummaryByTest(share: true),
          onPrintSummaryByDepartment: () =>
              _exportSummaryByDepartment(share: false),
          onShareSummaryByDepartment: () =>
              _exportSummaryByDepartment(share: true),
          onPrintTestDetails: (testName, count) => _exportTestDetails(
            testName: testName,
            count: count,
            share: false,
          ),
          onShareTestDetails: (testName, count) =>
              _exportTestDetails(testName: testName, count: count, share: true),
          onPrintDepartmentDetails: (departmentId, departmentName, count) =>
              _exportDepartmentDetails(
                departmentId: departmentId,
                departmentName: departmentName,
                count: count,
                share: false,
              ),
          onShareDepartmentDetails: (departmentId, departmentName, count) =>
              _exportDepartmentDetails(
                departmentId: departmentId,
                departmentName: departmentName,
                count: count,
                share: true,
              ),
        ),
      ],
    );
  }

  Widget _buildFilterSection(
    ThemeData theme,
    AsyncValue categoriesAsync,
    AsyncValue testsAsync,
  ) {
    final categories = categoriesAsync.maybeWhen(
      data: (response) => response.data,
      orElse: () => const <LabCategory>[],
    );
    final tests = testsAsync.maybeWhen(
      data: (response) => response.data,
      orElse: () => const <LabTest>[],
    );
    final visibleTests = _categoryId == null
        ? tests
        : tests.where((t) => t.category?.id == _categoryId).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
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
                DropdownButton<String?>(
                  value: _categoryId,
                  hint: const Text('Category'),
                  onChanged: (v) {
                    setState(() {
                      _categoryId = v;
                      _testName = null;
                    });
                  },
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All categories'),
                    ),
                    for (final c in categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                ),
                DropdownButton<String?>(
                  value: _testName,
                  hint: const Text('Test'),
                  onChanged: (v) => setState(() => _testName = v),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All tests'),
                    ),
                    for (final t in visibleTests)
                      DropdownMenuItem(value: t.name, child: Text(t.name)),
                  ],
                ),
                DropdownButton<String?>(
                  value: _status,
                  hint: const Text('Status'),
                  onChanged: (v) => setState(() => _status = v),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All statuses'),
                    ),
                    for (final s in LabOrderStatus.values)
                      DropdownMenuItem(
                        value: s.apiValue,
                        child: Text(s.apiValue),
                      ),
                  ],
                ),
                DropdownButton<bool?>(
                  value: _sampleCollected,
                  hint: const Text('Sample'),
                  onChanged: (v) => setState(() => _sampleCollected = v),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('All samples')),
                    DropdownMenuItem(value: true, child: Text('Collected')),
                    DropdownMenuItem(value: false, child: Text('Pending')),
                  ],
                ),
                FilledButton.tonal(
                  onPressed: _applyFilters,
                  child: const Text('Apply'),
                ),
                TextButton(
                  onPressed: _clearFilters,
                  child: const Text('Clear'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
