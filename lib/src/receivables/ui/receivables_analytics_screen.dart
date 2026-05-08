import 'dart:math' as math;

import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/receivables_models.dart';
import 'package:helty/src/services/receivables_service.dart';

@RoutePage()
class ReceivablesAnalyticsScreen extends StatefulWidget {
  const ReceivablesAnalyticsScreen({super.key});

  @override
  State<ReceivablesAnalyticsScreen> createState() =>
      _ReceivablesAnalyticsScreenState();
}

class _ReceivablesAnalyticsScreenState extends State<ReceivablesAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  final ReceivablesService _service = ReceivablesService();

  late DateTimeRange _currentRange;

  bool _loadingHmo = false;
  bool _loadingDiscount = false;
  bool _loadingRemittance = false;

  String? _hmoError;
  String? _discountError;
  String? _remittanceError;

  HmoCoverageAnalytics? _hmoCurrent;
  HmoCoverageAnalytics? _hmoPrevious;

  DiscountCoverageAnalytics? _discountCurrent;
  DiscountCoverageAnalytics? _discountPrevious;

  RemittanceCollectionsAnalytics? _remittanceCurrent;
  RemittanceCollectionsAnalytics? _remittancePrevious;

  late final TabController _remittanceTabController;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _currentRange = DateTimeRange(
      start: DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(const Duration(days: 6)),
      end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
    );
    _remittanceTabController = TabController(length: 2, vsync: this);
    _loadAll();
  }

  @override
  void dispose() {
    _remittanceTabController.dispose();
    super.dispose();
  }

  DateTimeRange get _previousRange {
    final days = _currentRange.end.difference(_currentRange.start).inDays + 1;
    final previousEnd = _currentRange.start.subtract(
      const Duration(milliseconds: 1),
    );
    final previousStart = previousEnd.subtract(Duration(days: days - 1));
    return DateTimeRange(start: previousStart, end: previousEnd);
  }

  Future<void> _loadAll() async {
    await Future.wait<void>([
      _loadHmoCoverage(),
      _loadDiscountCoverage(),
      _loadRemittanceCollections(),
    ]);
  }

  Future<void> _loadHmoCoverage() async {
    setState(() {
      _loadingHmo = true;
      _hmoError = null;
    });
    final previous = _previousRange;
    try {
      final results = await Future.wait<HmoCoverageAnalytics>([
        _service.getHmoCoverageAnalytics(
          fromDate: _currentRange.start,
          toDate: _currentRange.end,
        ),
        _service.getHmoCoverageAnalytics(
          fromDate: previous.start,
          toDate: previous.end,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _hmoCurrent = results[0];
        _hmoPrevious = results[1];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _hmoError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingHmo = false);
      }
    }
  }

  Future<void> _loadDiscountCoverage() async {
    setState(() {
      _loadingDiscount = true;
      _discountError = null;
    });
    final previous = _previousRange;
    try {
      final results = await Future.wait<DiscountCoverageAnalytics>([
        _service.getDiscountCoverageAnalytics(
          fromDate: _currentRange.start,
          toDate: _currentRange.end,
        ),
        _service.getDiscountCoverageAnalytics(
          fromDate: previous.start,
          toDate: previous.end,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _discountCurrent = results[0];
        _discountPrevious = results[1];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _discountError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingDiscount = false);
      }
    }
  }

  Future<void> _loadRemittanceCollections() async {
    setState(() {
      _loadingRemittance = true;
      _remittanceError = null;
    });
    final previous = _previousRange;
    try {
      final results = await Future.wait<RemittanceCollectionsAnalytics>([
        _service.getRemittanceCollectionsAnalytics(
          fromDate: _currentRange.start,
          toDate: _currentRange.end,
        ),
        _service.getRemittanceCollectionsAnalytics(
          fromDate: previous.start,
          toDate: previous.end,
        ),
      ]);
      if (!mounted) return;
      setState(() {
        _remittanceCurrent = results[0];
        _remittancePrevious = results[1];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _remittanceError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loadingRemittance = false);
      }
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _currentRange,
    );
    if (picked == null) return;
    setState(() {
      _currentRange = DateTimeRange(
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
    });
    await _loadAll();
  }

  String _rangeLabel(DateTimeRange range) {
    return '${DateFormatter.shortDate(range.start)} - ${DateFormatter.shortDate(range.end)}';
  }

  Widget _kpiCard({
    required String label,
    required String currentDisplay,
    required PeriodComparisonMetric metric,
  }) {
    final color = switch (metric.trend) {
      'up' => Colors.green,
      'down' => Colors.red,
      _ => Colors.grey,
    };
    final icon = switch (metric.trend) {
      'up' => Icons.trending_up,
      'down' => Icons.trending_down,
      _ => Icons.trending_flat,
    };
    final percent = metric.percentageChange == null
        ? 'N/A'
        : '${metric.percentageChange!.toStringAsFixed(2)}%';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(
              currentDisplay,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${metric.absoluteChange.toFinancial(isMoney: true)} ($percent)',
                  style: TextStyle(color: color, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _amountBars({
    required List<(String label, double value, int count)> items,
    String emptyText = 'No data in period',
  }) {
    if (items.isEmpty) return Text(emptyText);
    final max = items.map((e) => e.$2).fold<double>(0, math.max);
    return Column(
      children: items.map((e) {
        final ratio = max <= 0 ? 0.0 : (e.$2 / max).clamp(0.0, 1.0).toDouble();
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  e.$1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              Expanded(
                flex: 4,
                child: LinearProgressIndicator(value: ratio, minHeight: 8),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 150,
                child: Text(
                  '${e.$2.toFinancial(isMoney: true)} • ${e.$3}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _errorState(String message, VoidCallback onRetry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, maxLines: 3, overflow: TextOverflow.ellipsis),
          ),
          const SizedBox(width: 10),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final previous = _previousRange;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Receivables Analytics'),
        actions: [
          IconButton(onPressed: _loadAll, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text('Current: ${_rangeLabel(_currentRange)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey.withValues(alpha: 0.35),
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Previous: ${_rangeLabel(previous)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildHmoSection(),
          const SizedBox(height: 16),
          _buildDiscountSection(),
          const SizedBox(height: 16),
          _buildRemittanceSection(),
        ],
      ),
    );
  }

  Widget _buildHmoSection() {
    if (_hmoError != null) return _errorState(_hmoError!, _loadHmoCoverage);
    if (_loadingHmo && _hmoCurrent == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final current = _hmoCurrent;
    final previous = _hmoPrevious;
    if (current == null || previous == null) return const SizedBox.shrink();
    final amountMetric = PeriodComparisonMetric(
      currentValue: current.totalAmount,
      previousValue: previous.totalAmount,
    );
    final countMetric = PeriodComparisonMetric(
      currentValue: current.totalCount.toDouble(),
      previousValue: previous.totalCount.toDouble(),
    );
    final bars = current.data
        .map((e) => (e.hmoName, e.totalAmount, e.count))
        .toList();
    return _sectionContainer(
      title: 'Invoice Coverage - HMO',
      child: Column(
        children: [
          Row(
            children: [
              _kpiCard(
                label: 'Total HMO Coverage Amount',
                currentDisplay: current.totalAmount.toFinancial(isMoney: true),
                metric: amountMetric,
              ),
              const SizedBox(width: 10),
              _kpiCard(
                label: 'Total HMO Coverage Count',
                currentDisplay: '${current.totalCount}',
                metric: countMetric,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _amountBars(items: bars, emptyText: 'No HMO coverage records'),
        ],
      ),
    );
  }

  Widget _buildDiscountSection() {
    if (_discountError != null) {
      return _errorState(_discountError!, _loadDiscountCoverage);
    }
    if (_loadingDiscount && _discountCurrent == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final current = _discountCurrent;
    final previous = _discountPrevious;
    if (current == null || previous == null) return const SizedBox.shrink();
    final amountMetric = PeriodComparisonMetric(
      currentValue: current.totalAmount,
      previousValue: previous.totalAmount,
    );
    return _sectionContainer(
      title: 'Discount Coverage',
      child: Column(
        children: [
          Row(
            children: [
              _kpiCard(
                label: 'Total Discount Coverage Amount',
                currentDisplay: current.totalAmount.toFinancial(isMoney: true),
                metric: amountMetric,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'By Reason',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _amountBars(
            items: current.byReason
                .map((e) => (e.reason, e.totalAmount, e.count))
                .toList(),
            emptyText: 'No discount reasons in period',
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'By Policy',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Policy')),
                DataColumn(label: Text('Reason')),
                DataColumn(label: Text('Amount')),
                DataColumn(label: Text('Count')),
              ],
              rows: current.byPolicy.isEmpty
                  ? const [
                      DataRow(
                        cells: [
                          DataCell(Text('No policy data')),
                          DataCell(Text('-')),
                          DataCell(Text('-')),
                          DataCell(Text('-')),
                        ],
                      ),
                    ]
                  : current.byPolicy
                        .map(
                          (e) => DataRow(
                            cells: [
                              DataCell(Text(e.policyName)),
                              DataCell(Text(e.reason)),
                              DataCell(
                                Text(e.totalAmount.toFinancial(isMoney: true)),
                              ),
                              DataCell(Text('${e.count}')),
                            ],
                          ),
                        )
                        .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemittanceSection() {
    if (_remittanceError != null) {
      return _errorState(_remittanceError!, _loadRemittanceCollections);
    }
    if (_loadingRemittance && _remittanceCurrent == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final current = _remittanceCurrent;
    final previous = _remittancePrevious;
    if (current == null || previous == null) return const SizedBox.shrink();
    final amountMetric = PeriodComparisonMetric(
      currentValue: current.totalAmount,
      previousValue: previous.totalAmount,
    );
    final countMetric = PeriodComparisonMetric(
      currentValue: current.totalCount.toDouble(),
      previousValue: previous.totalCount.toDouble(),
    );
    final combinedBars = <(String, double, int)>[
      ...current.byHmo.map(
        (e) => ('HMO: ${e.hmoName}', e.totalAmount, e.count),
      ),
      ...current.byStaff.map(
        (e) => ('STAFF: ${e.payerStaffName}', e.totalAmount, e.count),
      ),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    return _sectionContainer(
      title: 'Remittance Collections',
      child: Column(
        children: [
          Row(
            children: [
              _kpiCard(
                label: 'Total Remittance Collected',
                currentDisplay: current.totalAmount.toFinancial(isMoney: true),
                metric: amountMetric,
              ),
              const SizedBox(width: 10),
              _kpiCard(
                label: 'Number of Remittances',
                currentDisplay: '${current.totalCount}',
                metric: countMetric,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _amountBars(
            items: combinedBars,
            emptyText: 'No remittance data in period',
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _remittanceTabController,
            tabs: const [
              Tab(text: 'By HMO'),
              Tab(text: 'By Staff'),
            ],
          ),
          SizedBox(
            height: 260,
            child: TabBarView(
              controller: _remittanceTabController,
              children: [
                _breakdownTable(
                  columns: const ['Name', 'Amount', 'Count'],
                  rows: current.byHmo
                      .map(
                        (e) => [
                          e.hmoName,
                          e.totalAmount.toFinancial(isMoney: true),
                          '${e.count}',
                        ],
                      )
                      .toList(),
                ),
                _breakdownTable(
                  columns: const ['Staff', 'Code', 'Amount', 'Count'],
                  rows: current.byStaff
                      .map(
                        (e) => [
                          e.payerStaffName,
                          e.payerStaffCode ?? '-',
                          e.totalAmount.toFinancial(isMoney: true),
                          '${e.count}',
                        ],
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _breakdownTable({
    required List<String> columns,
    required List<List<String>> rows,
  }) {
    if (rows.isEmpty) return const Center(child: Text('No records'));
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: columns.map((e) => DataColumn(label: Text(e))).toList(),
        rows: rows
            .map(
              (row) => DataRow(
                cells: row.map((value) => DataCell(Text(value))).toList(),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _sectionContainer({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_loadingHmo || _loadingDiscount || _loadingRemittance)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
