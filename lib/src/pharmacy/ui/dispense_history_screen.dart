import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/pharmacy/widgets/pharmacy_page_chrome.dart';
import 'package:helty/src/shared/department_colors.dart';
import 'package:helty/src/widgets/helty_surface.dart';

import '../models/pharmacy_model.dart';
import '../models/pharmacy_queue_models.dart';
import '../services/pharmacy_queue_service.dart';
import '../services/pharmacy_service.dart';

enum _QuickRange { today, last7, thisMonth }

const double _kUnpaidEpsilon = 1e-6;
const int _kAggregateMaxRecords = 5000;
const int _kAggregateMaxPages = 200;

bool _isUnpaidDispenseLine(DispenseHistoryItem row) =>
    row.amountPaid.abs() < _kUnpaidEpsilon;

@RoutePage()
class DispenseHistoryScreen extends StatefulWidget {
  const DispenseHistoryScreen({
    super.key,
    @QueryParam('fromDate') this.fromDate,
    @QueryParam('toDate') this.toDate,
    @QueryParam('drugId') this.drugId,
    @QueryParam('patientQuery') this.patientQuery,
    @QueryParam('page') this.page,
  });

  final String? fromDate;
  final String? toDate;
  final String? drugId;
  final String? patientQuery;
  final int? page;

  @override
  State<DispenseHistoryScreen> createState() => _DispenseHistoryScreenState();
}

class _DispenseHistoryScreenState extends State<DispenseHistoryScreen> {
  final PharmacyApiService _api = PharmacyApiService();
  final PharmacyQueueApiService _queueApi = PharmacyQueueApiService();
  final TextEditingController _patientCtrl = TextEditingController();
  final int _take = 25;

  DateTime _from = _startOfDay(DateTime.now());
  DateTime _to = _endOfDay(DateTime.now());
  String? _selectedDrugId;
  String? _selectedDrugName;
  int _page = 1;

  List<DispenseHistoryItem> _rows = [];
  int _total = 0;
  bool _loading = true;
  String _error = '';
  Timer? _debounce;
  int _requestId = 0;

  int _summaryGeneration = 0;
  String? _cachedSummaryFilterKey;
  bool _summaryLoading = false;
  String? _summaryCapMessage;
  int _aggRowCount = 0;
  int _aggTotalQty = 0;
  double _aggAmountPaid = 0;
  double _aggGrossValue = 0;
  int _aggUnpaidCount = 0;
  int _aggDistinctPatients = 0;

  @override
  void initState() {
    super.initState();
    _restoreQueryState();
    _patientCtrl.addListener(_onPatientFilterChanged);
    _fetchHistory();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _patientCtrl.dispose();
    super.dispose();
  }

  void _restoreQueryState() {
    final from = DateTime.tryParse(widget.fromDate ?? '');
    final to = DateTime.tryParse(widget.toDate ?? '');
    _from = from == null ? _from : _startOfDay(from.toLocal());
    _to = to == null ? _to : _endOfDay(to.toLocal());
    _selectedDrugId = widget.drugId?.trim().isEmpty == true
        ? null
        : widget.drugId;
    _patientCtrl.text = (widget.patientQuery ?? '').trim();
    _page = (widget.page == null || widget.page! < 1) ? 1 : widget.page!;
  }

  void _onPatientFilterChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      _page = 1;
      _syncQueryState();
      _fetchHistory();
    });
  }

  Future<void> _fetchHistory() async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await _api.getDispenseHistory(
        DispenseHistoryQuery(
          fromDate: _from,
          toDate: _to,
          drugId: _selectedDrugId,
          patientQuery: _patientCtrl.text.trim().isEmpty
              ? null
              : _patientCtrl.text.trim(),
          skip: (_page - 1) * _take,
          take: _take,
        ),
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _rows = data.items;
        _total = data.total;
        _loading = false;
      });
      final filterKey = _dispenseFilterKey();
      if (filterKey != _cachedSummaryFilterKey) {
        _cachedSummaryFilterKey = filterKey;
        final gen = ++_summaryGeneration;
        unawaited(_loadAggregates(gen));
      }
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      _summaryGeneration++;
      _cachedSummaryFilterKey = null;
      setState(() {
        _error = e.toString();
        _loading = false;
        _resetSummaryAggregates();
      });
    }
  }

  String _dispenseFilterKey() =>
      '${_from.toUtc().toIso8601String()}|${_to.toUtc().toIso8601String()}|'
      '${_selectedDrugId ?? ''}|${_patientCtrl.text.trim()}';

  void _resetSummaryAggregates() {
    _summaryLoading = false;
    _summaryCapMessage = null;
    _aggRowCount = 0;
    _aggTotalQty = 0;
    _aggAmountPaid = 0;
    _aggGrossValue = 0;
    _aggUnpaidCount = 0;
    _aggDistinctPatients = 0;
  }

  Future<void> _loadAggregates(int gen) async {
    if (!mounted || gen != _summaryGeneration) return;

    if (_total == 0) {
      if (!mounted || gen != _summaryGeneration) return;
      setState(() {
        _resetSummaryAggregates();
      });
      return;
    }

    setState(() {
      _summaryLoading = true;
      _summaryCapMessage = null;
    });

    final cap = _total > _kAggregateMaxRecords ? _kAggregateMaxRecords : _total;
    final all = <DispenseHistoryItem>[];
    var pages = 0;

    try {
      while (all.length < cap && pages < _kAggregateMaxPages) {
        if (!mounted || gen != _summaryGeneration) return;
        final skip = all.length;
        final data = await _api.getDispenseHistory(
          DispenseHistoryQuery(
            fromDate: _from,
            toDate: _to,
            drugId: _selectedDrugId,
            patientQuery: _patientCtrl.text.trim().isEmpty
                ? null
                : _patientCtrl.text.trim(),
            skip: skip,
            take: _take,
          ),
        );
        if (!mounted || gen != _summaryGeneration) return;
        if (data.items.isEmpty) break;
        all.addAll(data.items);
        if (data.items.length < _take) break;
        pages++;
      }

      var totalQty = 0;
      var totalPaid = 0.0;
      var gross = 0.0;
      var unpaid = 0;
      final patientIds = <String>{};
      for (final r in all) {
        totalQty += r.quantity;
        totalPaid += r.amountPaid;
        gross += r.quantity * r.unitPrice;
        if (_isUnpaidDispenseLine(r)) unpaid++;
        if (r.patient.id.isNotEmpty) patientIds.add(r.patient.id);
      }

      String? capMsg;
      if (all.length < _total) {
        capMsg =
            'Totals include first ${all.length} of $_total records. Narrow filters for full accuracy.';
      }

      if (!mounted || gen != _summaryGeneration) return;
      setState(() {
        _summaryLoading = false;
        _aggRowCount = all.length;
        _aggTotalQty = totalQty;
        _aggAmountPaid = totalPaid;
        _aggGrossValue = gross;
        _aggUnpaidCount = unpaid;
        _aggDistinctPatients = patientIds.length;
        _summaryCapMessage = capMsg;
      });
    } catch (_) {
      if (!mounted || gen != _summaryGeneration) return;
      setState(() {
        _summaryLoading = false;
        _resetSummaryAggregates();
        _summaryCapMessage = 'Could not load summary totals.';
      });
    }
  }

  void _syncQueryState() {
    context.router.replace(
      DispenseHistoryRoute(
        fromDate: _from.toUtc().toIso8601String(),
        toDate: _to.toUtc().toIso8601String(),
        drugId: _selectedDrugId,
        patientQuery: _patientCtrl.text.trim().isEmpty
            ? null
            : _patientCtrl.text.trim(),
        page: _page,
      ),
    );
  }

  Future<void> _pickDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (range == null) return;
    setState(() {
      _from = _startOfDay(range.start);
      _to = _endOfDay(range.end);
      _page = 1;
    });
    _syncQueryState();
    _fetchHistory();
  }

  Future<void> _pickDrug() async {
    final selected = await showModalBottomSheet<Drug>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _DrugPickerSheet(api: _api),
    );
    if (selected == null) return;
    setState(() {
      _selectedDrugId = selected.id;
      _selectedDrugName = '${selected.genericName} (${selected.brandName})';
      _page = 1;
    });
    _syncQueryState();
    _fetchHistory();
  }

  void _applyQuickRange(_QuickRange quickRange) {
    final now = DateTime.now();
    switch (quickRange) {
      case _QuickRange.today:
        _from = _startOfDay(now);
        _to = _endOfDay(now);
        break;
      case _QuickRange.last7:
        _from = _startOfDay(now.subtract(const Duration(days: 6)));
        _to = _endOfDay(now);
        break;
      case _QuickRange.thisMonth:
        _from = DateTime(now.year, now.month, 1);
        _to = _endOfDay(now);
        break;
    }
    _page = 1;
    _syncQueryState();
    _fetchHistory();
  }

  Future<void> _onDoReturn(DispenseHistoryItem row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ReturnDrugLineDialog(row: row, queueApi: _queueApi),
    );
    if (ok == true && mounted) {
      _cachedSummaryFilterKey = null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Return recorded.')));
      await _fetchHistory();
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_total / _take).ceil().clamp(1, 1000000);
    final cs = Theme.of(context).colorScheme;
    final metricsReady = !_loading && _error.isEmpty && !_summaryLoading;
    final qtyValue = metricsReady
        ? _aggTotalQty.toFinancial(isMoney: false)
        : '—';
    final paidValue = metricsReady
        ? _aggAmountPaid.toFinancial(isMoney: true)
        : '—';
    final linesValue = _loading || _error.isNotEmpty ? '—' : '$_total';
    final unpaidValue = metricsReady ? '$_aggUnpaidCount' : '—';

    return Scaffold(
      backgroundColor: cs.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final compact = width < PharmacyAccent.cardBreakpoint;
          final showRail = width >= PharmacyAccent.railBreakpoint;

          final header = PharmacyPageHeader(
            title: 'Dispense History',
            subtitle: 'Review dispensed lines and return unpaid stock.',
            icon: Icons.receipt_long_outlined,
            iconColor: DepartmentColors.pharmacy,
            onRefresh: _loading ? null : _fetchHistory,
          );
          final kpis = PharmacyKpiStrip(
            items: [
              PharmacyKpiItem(
                label: 'Lines',
                value: linesValue,
                caption: 'Matching records',
                icon: Icons.list_alt,
                accent: PharmacyAccent.blue,
              ),
              PharmacyKpiItem(
                label: 'Quantity',
                value: qtyValue,
                caption: 'Units dispensed',
                icon: Icons.numbers,
                accent: PharmacyAccent.teal,
              ),
              PharmacyKpiItem(
                label: 'Collected',
                value: paidValue,
                caption: 'Amount paid',
                icon: Icons.payments_outlined,
                accent: PharmacyAccent.green,
              ),
              PharmacyKpiItem(
                label: 'Unpaid',
                value: unpaidValue,
                caption: 'Lines still open',
                icon: Icons.money_off_csred_outlined,
                accent: PharmacyAccent.amber,
              ),
            ],
          );
          final filters = _DispenseFilterBar(
            controller: _patientCtrl,
            compact: compact,
            drugLabel: _selectedDrugName,
            onPickDrug: _pickDrug,
            onOpenFilters: _openFilters,
          );

          final table = _DispenseTable(
            rows: _rows,
            loading: _loading,
            error: _error,
            useCards: compact,
            page: _page,
            total: _total,
            take: _take,
            totalPages: totalPages,
            onPrev: _page > 1
                ? () {
                    setState(() => _page -= 1);
                    _syncQueryState();
                    _fetchHistory();
                  }
                : null,
            onNext: _page < totalPages
                ? () {
                    setState(() => _page += 1);
                    _syncQueryState();
                    _fetchHistory();
                  }
                : null,
            onReturn: _onDoReturn,
            onRetry: _fetchHistory,
          );

          final rail = _DispenseRail(
            gross: metricsReady
                ? _aggGrossValue.toFinancial(isMoney: true)
                : '—',
            patients: metricsReady ? '$_aggDistinctPatients' : '—',
            included: metricsReady ? '$_aggRowCount' : '—',
            capMessage: _summaryCapMessage,
            canClearDrug: _selectedDrugId != null,
            onClearDrug: () {
              setState(() {
                _selectedDrugId = null;
                _selectedDrugName = null;
                _page = 1;
              });
              _syncQueryState();
              _fetchHistory();
            },
            onRefresh: _loading ? null : _fetchHistory,
          );

          final main = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 10),
              kpis,
              const SizedBox(height: 10),
              filters,
              const SizedBox(height: 10),
              Expanded(child: table),
            ],
          );

          if (showRail) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 9, child: main),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: rail),
              ],
            );
          }

          return Column(
            children: [
              Expanded(child: main),
              const SizedBox(height: 10),
              rail,
            ],
          );
        },
      ),
    );
  }

  Future<void> _openFilters() async {
    await showPharmacyFilterDialog(
      context: context,
      body: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Date range',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    await _pickDateRange();
                    setDialogState(() {});
                  },
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text(
                    '${DateFormatter.shortDate(_from)} – ${DateFormatter.shortDate(_to)}',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      label: const Text('Today'),
                      onPressed: () {
                        _applyQuickRange(_QuickRange.today);
                        setDialogState(() {});
                      },
                    ),
                    ActionChip(
                      label: const Text('Last 7 days'),
                      onPressed: () {
                        _applyQuickRange(_QuickRange.last7);
                        setDialogState(() {});
                      },
                    ),
                    ActionChip(
                      label: const Text('This month'),
                      onPressed: () {
                        _applyQuickRange(_QuickRange.thisMonth);
                        setDialogState(() {});
                      },
                    ),
                  ],
                ),
                if (_selectedDrugId != null) ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedDrugId = null;
                          _selectedDrugName = null;
                          _page = 1;
                        });
                        _syncQueryState();
                        _fetchHistory();
                        Navigator.of(ctx).maybePop();
                      },
                      child: const Text('Clear drug'),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

class _DispenseFilterBar extends StatelessWidget {
  const _DispenseFilterBar({
    required this.controller,
    required this.compact,
    required this.drugLabel,
    required this.onPickDrug,
    required this.onOpenFilters,
  });

  final TextEditingController controller;
  final bool compact;
  final String? drugLabel;
  final VoidCallback onPickDrug;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final search = TextField(
      controller: controller,
      style: const TextStyle(fontSize: 12),
      decoration: pharmacyFieldDecoration(
        context,
        label: 'Search',
        hint: 'Patient name or hospital number…',
        icon: Icons.search,
        iconColor: PharmacyAccent.indigo,
      ),
    );
    final drug = OutlinedButton.icon(
      onPressed: onPickDrug,
      icon: const Icon(Icons.medication_outlined, size: 18),
      label: HeltyEllipsisText(text: drugLabel ?? 'All drugs'),
    );
    return Row(
      children: [
        Expanded(flex: 3, child: search),
        if (!compact) ...[
          const SizedBox(width: 8),
          Expanded(flex: 2, child: drug),
        ],
        const SizedBox(width: 8),
        PharmacyFilterButton(onPressed: onOpenFilters),
      ],
    );
  }
}

class _DispenseTable extends StatelessWidget {
  const _DispenseTable({
    required this.rows,
    required this.loading,
    required this.error,
    required this.useCards,
    required this.page,
    required this.total,
    required this.take,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
    required this.onReturn,
    required this.onRetry,
  });

  final List<DispenseHistoryItem> rows;
  final bool loading;
  final String error;
  final bool useCards;
  final int page;
  final int total;
  final int take;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;
  final ValueChanged<DispenseHistoryItem> onReturn;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final start = rows.isEmpty ? 0 : ((page - 1) * take) + 1;
    final end = rows.isEmpty ? 0 : start + rows.length - 1;
    final footer = PharmacyPaginationFooter(
      label: rows.isEmpty
          ? 'No dispense records to display'
          : 'Showing $start–$end of $total',
      page: page,
      canPrev: onPrev != null,
      canNext: onNext != null && page < totalPages,
      onPrev: onPrev,
      onNext: onNext,
    );

    if (loading && rows.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final body = error.isNotEmpty && rows.isEmpty
        ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                FilledButton(onPressed: onRetry, child: const Text('Retry')),
              ],
            ),
          )
        : rows.isEmpty
        ? const Center(child: Text('No dispense records found.'))
        : useCards
        ? ListView.builder(
            itemCount: rows.length,
            itemBuilder: (context, index) => _DispenseCard(
              row: rows[index],
              onReturn: () => onReturn(rows[index]),
            ),
          )
        : _DispenseRows(rows: rows, onReturn: onReturn);

    return HeltySurfaceCard(
      child: Column(
        children: [
          Expanded(child: body),
          footer,
        ],
      ),
    );
  }
}

class _DispenseRows extends StatelessWidget {
  const _DispenseRows({required this.rows, required this.onReturn});

  final List<DispenseHistoryItem> rows;
  final ValueChanged<DispenseHistoryItem> onReturn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, inner) {
        const minWidth = 980.0;
        final width = inner.maxWidth < minWidth ? minWidth : inner.maxWidth;
        final sheet = SizedBox(
          width: width,
          height: inner.maxHeight,
          child: Column(
            children: [
              Container(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Row(
                  children: [
                    _head(context, 'PATIENT', flex: 3),
                    const SizedBox(width: 20),
                    _head(context, 'DRUG', flex: 3),
                    const SizedBox(width: 20),
                    _head(context, 'QTY', flex: 1),
                    const SizedBox(width: 20),
                    _head(context, 'PAID', flex: 2),
                    const SizedBox(width: 20),
                    _head(context, 'STATUS', flex: 2),
                    const SizedBox(width: 20),
                    _head(context, 'ACTIONS', flex: 2, alignEnd: true),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  primary: false,
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    color: cs.outline.withValues(alpha: 0.08),
                  ),
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final unpaid = _isUnpaidDispenseLine(row);
                    final when = row.dispensedAt == null
                        ? '—'
                        : DateFormatter.dateTime(row.dispensedAt!);
                    return Material(
                      color: pharmacyZebra(cs, index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  HeltyEllipsisText(
                                    text: row.patient.name,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  HeltyEllipsisText(
                                    text: row.patient.patientId,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 3,
                              child: Tooltip(
                                message:
                                    '$when · ${row.dispensedBy?.name ?? '—'} · ${row.dispensary?.name ?? '—'} · ${row.invoiceId}',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    HeltyEllipsisText(
                                      text: row.drug.name,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    HeltyEllipsisText(
                                      text: when,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: cs.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 1,
                              child: HeltyEllipsisText(text: '${row.quantity}'),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: HeltyEllipsisText(
                                text: row.amountPaid.toFinancial(isMoney: true),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: HeltyEllipsisChip(
                                label: unpaid ? 'Unpaid' : 'Paid',
                                color: unpaid
                                    ? PharmacyAccent.amber
                                    : PharmacyAccent.green,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              flex: 2,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: SizedBox(
                                  height: 40,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Tooltip(
                                      message: unpaid
                                          ? 'Return units to stock'
                                          : 'Paid lines cannot be returned',
                                      child: OutlinedButton(
                                        onPressed: unpaid
                                            ? () => onReturn(row)
                                            : null,
                                        style: OutlinedButton.styleFrom(
                                          visualDensity: VisualDensity.compact,
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                          ),
                                          shape: const StadiumBorder(),
                                        ),
                                        child: const Text('Return'),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
        if (inner.maxWidth >= minWidth) return sheet;
        return _DispenseHScroll(child: sheet);
      },
    );
  }

  Widget _head(
    BuildContext context,
    String label, {
    required int flex,
    bool alignEnd = false,
  }) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: alignEnd ? TextAlign.end : TextAlign.start,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }
}

class _DispenseHScroll extends StatefulWidget {
  const _DispenseHScroll({required this.child});

  final Widget child;

  @override
  State<_DispenseHScroll> createState() => _DispenseHScrollState();
}

class _DispenseHScrollState extends State<_DispenseHScroll> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      notificationPredicate: (notification) => notification.depth == 0,
      child: SingleChildScrollView(
        controller: _controller,
        primary: false,
        scrollDirection: Axis.horizontal,
        child: widget.child,
      ),
    );
  }
}

class _DispenseCard extends StatelessWidget {
  const _DispenseCard({required this.row, required this.onReturn});

  final DispenseHistoryItem row;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final unpaid = _isUnpaidDispenseLine(row);
    final when = row.dispensedAt == null
        ? '—'
        : DateFormatter.dateTime(row.dispensedAt!);
    return HeltySurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: HeltyEllipsisText(
                    text: row.patient.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                HeltyStatusChip(
                  label: unpaid ? 'Unpaid' : 'Paid',
                  color: unpaid ? PharmacyAccent.amber : PharmacyAccent.green,
                ),
              ],
            ),
            HeltyEllipsisText(
              text: row.drug.name,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            HeltyEllipsisText(
              text:
                  '$when · Qty ${row.quantity} · ${row.amountPaid.toFinancial(isMoney: true)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton(
                onPressed: unpaid ? onReturn : null,
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  shape: const StadiumBorder(),
                ),
                child: const Text('Return'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DispenseRail extends StatelessWidget {
  const _DispenseRail({
    required this.gross,
    required this.patients,
    required this.included,
    required this.capMessage,
    required this.canClearDrug,
    required this.onClearDrug,
    required this.onRefresh,
  });

  final String gross;
  final String patients;
  final String included;
  final String? capMessage;
  final bool canClearDrug;
  final VoidCallback onClearDrug;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HeltySurfaceCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const HeltySolidIcon(
                    icon: Icons.flash_on,
                    color: PharmacyAccent.amber,
                    size: 26,
                    iconSize: 14,
                    radius: 7,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Quick Actions',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              PharmacyRailButton(
                label: 'Refresh',
                icon: Icons.refresh,
                colors: [
                  PharmacyAccent.green,
                  Color.lerp(PharmacyAccent.green, cs.primary, 0.25)!,
                ],
                onPressed: onRefresh,
              ),
              const SizedBox(height: 8),
              PharmacyRailButton(
                label: 'Clear drug',
                icon: Icons.medication_outlined,
                colors: [
                  PharmacyAccent.teal,
                  Color.lerp(PharmacyAccent.teal, cs.primary, 0.25)!,
                ],
                onPressed: canClearDrug ? onClearDrug : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        HeltySurfaceCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Gross line value',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                gross,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Distinct patients',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                patients,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Rows in totals',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                included,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (capMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  capMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.tertiary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ReturnDrugLineDialog extends StatefulWidget {
  const _ReturnDrugLineDialog({required this.row, required this.queueApi});

  final DispenseHistoryItem row;
  final PharmacyQueueApiService queueApi;

  @override
  State<_ReturnDrugLineDialog> createState() => _ReturnDrugLineDialogState();
}

class _ReturnDrugLineDialogState extends State<_ReturnDrugLineDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _reasonCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: '${widget.row.quantity}');
    _reasonCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState?.validate() != true) return;
    setState(() => _submitting = true);
    try {
      final q = int.parse(_qtyCtrl.text.trim());
      await widget.queueApi.returnInvoiceDrugItem(
        widget.row.invoiceUUID,
        widget.row.invoiceItemId,
        ReturnDrugInvoiceItemDto(
          quantity: q,
          reason: _reasonCtrl.text.trim().isEmpty
              ? null
              : _reasonCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.row;
    return AlertDialog(
      title: const Text('Return drug line'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${r.drug.name} · up to ${r.quantity} units',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _qtyCtrl,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Quantity to return',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 1) {
                    return 'Enter a positive whole number';
                  }
                  if (n > r.quantity) {
                    return 'Cannot exceed ${r.quantity}';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reasonCtrl,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting
              ? null
              : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit return'),
        ),
      ],
    );
  }
}

class _DrugPickerSheet extends StatefulWidget {
  const _DrugPickerSheet({required this.api});

  final PharmacyApiService api;

  @override
  State<_DrugPickerSheet> createState() => _DrugPickerSheetState();
}

class _DrugPickerSheetState extends State<_DrugPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final List<Drug> _drugs = [];
  Timer? _debounce;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), _load);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await widget.api.getDrugs(
        PharmacyQueryParams(
          page: 1,
          pageSize: 50,
          search: _searchCtrl.text.trim().isEmpty
              ? null
              : _searchCtrl.text.trim(),
          sortBy: 'genericName',
          sortOrder: SortOrder.asc,
        ),
      );
      if (!mounted) return;
      setState(() {
        _drugs
          ..clear()
          ..addAll(resp.items.where((d) => d.id != null && d.id!.isNotEmpty));
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _drugs.clear();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Search drug',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: controller,
                      itemCount: _drugs.length,
                      itemBuilder: (_, i) {
                        final d = _drugs[i];
                        return ListTile(
                          title: Text('${d.genericName} (${d.brandName})'),
                          onTap: () => Navigator.of(context).pop(d),
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

DateTime _startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _endOfDay(DateTime d) =>
    DateTime(d.year, d.month, d.day, 23, 59, 59, 999);
