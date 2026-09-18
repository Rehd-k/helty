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
import '../../helper/theme.dart';
import '../../investigations/models/investigation_models.dart';
import '../../investigations/models/investigation_query_params.dart';
import '../../investigations/providers/investigation_providers.dart';
import '../../investigations/widgets/investigations_report_widgets.dart';
import '../../lab/models/lab_models.dart';
import '../../lab/providers/lab_providers.dart';
import '../../lab/ui/widgets/lab_clinical_ui.dart';
import '../../models/super_admin_department_preview.dart';
import '../../printing/pdf/investigations_report_pdf.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/helty_surface.dart';

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
  final _searchCtrl = TextEditingController();
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
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

  void _applyFilters() {
    setState(() {
      _skip = 0;
      final q = _searchCtrl.text.trim();
      _testName = q.isEmpty ? null : q;
    });
    _refresh();
  }

  void _clearFilters() {
    setState(() {
      _searchCtrl.clear();
      _testName = null;
      _categoryId = null;
      _status = null;
      _sampleCollected = null;
      _skip = 0;
    });
    _refresh();
  }

  void _applyDateRange(DateTime from, DateTime to) {
    setState(() {
      _dateRange = DateTimeRange(
        start: DateTime(from.year, from.month, from.day),
        end: DateTime(to.year, to.month, to.day, 23, 59, 59, 999),
      );
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

  String _filenameSlug(String raw) {
    final slug = raw
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return slug.replaceAll(RegExp(r'^_|_$'), '');
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
    final colorScheme = Theme.of(context).colorScheme;
    final staff = ref.watch(currentStaffProvider);
    final isLabUser =
        staffIsSuperAdmin(staff) ||
        staff?.staffRole.toLowerCase() == 'admin' ||
        staff?.accountType?.name.toLowerCase() == 'laboratory' ||
        staff?.accountType?.name.toLowerCase() == 'lab';

    if (!isLabUser) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: ResponsiveBody(
          builder: (context, bp) => Center(
            child: HeltySurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HeltySolidIcon(
                    icon: Icons.lock_outline,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Access denied for this account.',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final summaryParams = _buildParams(forSummary: true);
    final listParams = _buildParams();
    final summaryAsync = ref.watch(
      labInvestigationsSummaryProvider(summaryParams),
    );
    final listAsync = ref.watch(labInvestigationsListProvider(listParams));
    final categoriesAsync = ref.watch(labCategoriesFutureProvider);
    final summary = summaryAsync.valueOrNull;
    final list = listAsync.valueOrNull;
    final loadingList = listAsync.isLoading && list == null;
    final listError = listAsync.asError?.error;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final compact = width < LabClinicalUi.cardBreakpoint;
          final showSideBySide = width >= LabClinicalUi.sidebarBreakpoint;
          final useSnapKpis = width < 520;
          final useCards = compact;

          final header = LabPageHeader(
            title: 'Investigation reports',
            subtitle:
                'Summaries and line items for lab tests in the selected range.',
            icon: Icons.assessment_outlined,
            iconColor: LabClinicalUi.iconIndigo,
            compact: compact,
          );
          final kpis = LabKpiStrip(
            useSnapStrip: useSnapKpis,
            items: [
              LabKpiItem(
                label: 'Investigations',
                value: summary == null ? '—' : '${summary.totalCount}',
                caption: 'Test lines in range',
                icon: Icons.receipt_long_outlined,
                accent: LabClinicalUi.iconBlue,
              ),
              LabKpiItem(
                label: 'Amount',
                value: summary == null
                    ? '—'
                    : summary.totalAmount.toFinancial(isMoney: true),
                caption: 'Billed for these tests',
                icon: Icons.payments_outlined,
                accent: LabClinicalUi.iconTeal,
              ),
              LabKpiItem(
                label: 'Samples collected',
                value: summary?.sampleCollectedCount == null
                    ? '—'
                    : '${summary!.sampleCollectedCount}',
                caption: 'Drawn in this range',
                icon: Icons.biotech_outlined,
                accent: LabClinicalUi.iconPurple,
              ),
              LabKpiItem(
                label: 'Samples pending',
                value: summary?.samplePendingCount == null
                    ? '—'
                    : '${summary!.samplePendingCount}',
                caption: 'Awaiting collection',
                icon: Icons.hourglass_empty_outlined,
                accent: LabClinicalUi.iconAmber,
              ),
            ],
          );
          final filters = LabFilterBar(
            searchController: _searchCtrl,
            searchHint: 'Search by test name…',
            compact: compact,
            onSearchSubmitted: (_) => _applyFilters(),
            primaryFilter: _statusDropdown(context),
            filterMenuBody: _filterMenuBody(
              context,
              compact: compact,
              categoriesAsync: categoriesAsync,
            ),
          );

          final mainColumn = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 10),
              kpis,
              if (summaryAsync.hasError) ...[
                const SizedBox(height: 10),
                InvestigationErrorBanner(
                  message: '${summaryAsync.error}',
                  onRetry: _refresh,
                ),
              ],
              const SizedBox(height: 10),
              filters,
              const SizedBox(height: 10),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, tableConstraints) {
                    final listHeight = (tableConstraints.maxHeight * 0.72)
                        .clamp(420.0, 720.0)
                        .toDouble();
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _breakdownPanel(
                            summary: summary,
                            loading: summaryAsync.isLoading && summary == null,
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: listHeight,
                            child: _listPanel(
                              list: list,
                              loading: loadingList,
                              error: listError,
                              useCards: useCards,
                              exportEnabled: (summary?.totalCount ?? 0) > 0,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );

          if (showSideBySide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 9, child: mainColumn),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: _sidebar(summary: summary, fillHeight: true),
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: mainColumn),
              const SizedBox(height: 10),
              SizedBox(
                height: 280,
                child: SingleChildScrollView(
                  child: _sidebar(summary: summary, fillHeight: false),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  InputDecoration _filterDecoration(
    BuildContext context, {
    required String label,
    required Color iconColor,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      isDense: true,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(6),
        child: HeltySolidIcon(
          icon: icon,
          color: iconColor,
          size: 22,
          iconSize: 13,
          radius: 6,
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      labelStyle: const TextStyle(fontSize: 11),
    );
  }

  Widget _statusDropdown(BuildContext context) {
    return DropdownButtonFormField<String?>(
      key: ValueKey(_status ?? 'all'),
      initialValue: _status,
      isExpanded: true,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _filterDecoration(
        context,
        label: 'Status',
        iconColor: LabClinicalUi.iconAmber,
        icon: Icons.flag_outlined,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All statuses', overflow: TextOverflow.ellipsis),
        ),
        ...LabOrderStatus.values.map(
          (s) => DropdownMenuItem<String?>(
            value: s.apiValue,
            child: Text(
              LabClinicalUi.statusLabel(s),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
      onChanged: (v) {
        setState(() {
          _status = v;
          _skip = 0;
        });
        _refresh();
      },
    );
  }

  Widget _categoryDropdown(BuildContext context, List<LabCategory> categories) {
    return DropdownButtonFormField<String?>(
      key: ValueKey(_categoryId ?? 'all-cat'),
      initialValue: _categoryId,
      isExpanded: true,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _filterDecoration(
        context,
        label: 'Category',
        iconColor: LabClinicalUi.iconPink,
        icon: Icons.category_outlined,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All categories', overflow: TextOverflow.ellipsis),
        ),
        for (final c in categories)
          DropdownMenuItem<String?>(
            value: c.id,
            child: Text(c.name, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (v) {
        setState(() {
          _categoryId = v;
          _skip = 0;
        });
        _refresh();
      },
    );
  }

  Widget _sampleDropdown(BuildContext context) {
    return DropdownButtonFormField<bool?>(
      key: ValueKey('sample-$_sampleCollected'),
      initialValue: _sampleCollected,
      isExpanded: true,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _filterDecoration(
        context,
        label: 'Sample',
        iconColor: LabClinicalUi.iconTeal,
        icon: Icons.biotech_outlined,
      ),
      items: const [
        DropdownMenuItem<bool?>(
          value: null,
          child: Text('All samples', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem<bool?>(value: true, child: Text('Collected')),
        DropdownMenuItem<bool?>(value: false, child: Text('Pending')),
      ],
      onChanged: (v) {
        setState(() {
          _sampleCollected = v;
          _skip = 0;
        });
        _refresh();
      },
    );
  }

  Widget _sortDropdowns(BuildContext context) {
    return Column(
      children: [
        DropdownButtonFormField<InvestigationSortBy>(
          key: ValueKey('sort-$_sortBy'),
          initialValue: _sortBy,
          isExpanded: true,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: _filterDecoration(
            context,
            label: 'Sort by',
            iconColor: LabClinicalUi.iconIndigo,
            icon: Icons.sort,
          ),
          items: InvestigationSortBy.values
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(_sortLabel(e), overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _sortBy = v;
              _skip = 0;
            });
            _refresh();
          },
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<InvestigationSortOrder>(
          key: ValueKey('order-$_sortOrder'),
          initialValue: _sortOrder,
          isExpanded: true,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          decoration: _filterDecoration(
            context,
            label: 'Order',
            iconColor: LabClinicalUi.iconPurple,
            icon: Icons.swap_vert,
          ),
          items: const [
            DropdownMenuItem(
              value: InvestigationSortOrder.desc,
              child: Text('Newest first'),
            ),
            DropdownMenuItem(
              value: InvestigationSortOrder.asc,
              child: Text('Oldest first'),
            ),
          ],
          onChanged: (v) {
            if (v == null) return;
            setState(() {
              _sortOrder = v;
              _skip = 0;
            });
            _refresh();
          },
        ),
      ],
    );
  }

  String _sortLabel(InvestigationSortBy value) => switch (value) {
    InvestigationSortBy.createdAt => 'Created',
    InvestigationSortBy.testName => 'Test name',
    InvestigationSortBy.amount => 'Amount',
    InvestigationSortBy.patientName => 'Patient name',
    InvestigationSortBy.status => 'Status',
  };

  Widget _filterMenuBody(
    BuildContext context, {
    required bool compact,
    required AsyncValue categoriesAsync,
  }) {
    final categories = categoriesAsync.maybeWhen(
      data: (response) => response.data,
      orElse: () => const <LabCategory>[],
    );
    return LabDateFilterBody(
      from: _dateRange.start,
      to: _dateRange.end,
      onChanged: _applyDateRange,
      onRefresh: _refresh,
      leading: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (compact) ...[
            _statusDropdown(context),
            const SizedBox(height: 10),
          ],
          _categoryDropdown(context, categories),
          const SizedBox(height: 10),
          _sampleDropdown(context),
          const SizedBox(height: 10),
          _sortDropdowns(context),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: _clearFilters,
              child: const Text('Clear filters'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownPanel({
    required InvestigationSummary? summary,
    required bool loading,
  }) {
    if (loading) {
      return const HeltySurfaceCard(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (summary == null) {
      return HeltySurfaceCard(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Text(
            'No summary for this range.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return InvestigationBreakdownTables(
      summary: summary,
      fillHeight: false,
      shrinkWrap: true,
      exporting: _exporting,
      onPrintSummaryByTest: () => _exportSummaryByTest(share: false),
      onShareSummaryByTest: () => _exportSummaryByTest(share: true),
      onPrintSummaryByDepartment: () =>
          _exportSummaryByDepartment(share: false),
      onShareSummaryByDepartment: () => _exportSummaryByDepartment(share: true),
      onPrintTestDetails: (testName, count) =>
          _exportTestDetails(testName: testName, count: count, share: false),
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
    );
  }

  Widget _sidebar({
    required InvestigationSummary? summary,
    required bool fillHeight,
  }) {
    final cs = Theme.of(context).colorScheme;
    final actions = [
      LabQuickAction(
        label: 'Print list',
        icon: Icons.print_outlined,
        colors: [LabClinicalUi.iconBlue, LabClinicalUi.iconIndigo],
        onPressed: () => _exportFilteredList(share: false),
      ),
      LabQuickAction(
        label: 'Save PDF',
        icon: Icons.ios_share_outlined,
        colors: [LabClinicalUi.iconTeal, LabClinicalUi.iconGreen],
        onPressed: () => _exportFilteredList(share: true),
      ),
      LabQuickAction(
        label: 'Print by test',
        icon: Icons.science_outlined,
        colors: [LabClinicalUi.iconPurple, LabClinicalUi.iconPink],
        onPressed: () => _exportSummaryByTest(share: false),
      ),
      LabQuickAction(
        label: 'Print by department',
        icon: Icons.apartment_outlined,
        colors: [LabClinicalUi.iconAmber, LabClinicalUi.iconIndigo],
        onPressed: () => _exportSummaryByDepartment(share: false),
      ),
      LabQuickAction(
        label: 'Refresh',
        icon: Icons.refresh,
        colors: [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.45)!],
        onPressed: _refresh,
      ),
    ];
    final mix = <LabStatusCount>[
      if (summary != null)
        for (final row in summary.byTestName.take(12))
          LabStatusCount(
            label: row.testName,
            count: row.count,
            color: LabClinicalUi.avatarColor(row.testName),
          ),
    ];

    return LabSidebar(
      actions: actions,
      statusCounts: mix,
      fillHeight: fillHeight,
      mixTitle: 'By test',
      mixEmptyLabel: 'No tests in this range',
    );
  }

  Widget _listPanel({
    required InvestigationListResponse? list,
    required bool loading,
    required Object? error,
    required bool useCards,
    required bool exportEnabled,
  }) {
    if (error != null && list == null) {
      return InvestigationErrorBanner(message: '$error', onRetry: _refresh);
    }
    final rows = list?.data ?? const <InvestigationListRow>[];
    return InvestigationListTable(
      rows: rows,
      showSampleColumn: true,
      fillHeight: true,
      useCards: useCards,
      loading: loading,
      skip: list?.skip ?? _skip,
      pageSize: list?.take ?? _take,
      total: list?.total ?? 0,
      hasMore: list != null && list.skip + list.take < list.total,
      onPrev: list != null && list.skip > 0
          ? () {
              setState(() {
                _skip = (list.skip - _take).clamp(0, list.total);
              });
              _refresh();
            }
          : () {},
      onNext: list != null && list.skip + list.take < list.total
          ? () {
              setState(() => _skip = list.skip + _take);
              _refresh();
            }
          : () {},
      trailing: InvestigationExportActions(
        enabled: exportEnabled,
        exporting: _exporting,
        onPrint: () => _exportFilteredList(share: false),
        onShare: () => _exportFilteredList(share: true),
      ),
    );
  }
}
