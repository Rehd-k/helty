import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/services/invoice_purchases_service.dart';
import 'package:intl/intl.dart';

import '../models/purchases_model.dart';
import '../models/purchases_usage_history_model.dart';
import '../services/purchases_dashboard_service.dart';
import '../services/purchases_service.dart';

enum _QuickRange { today, last7, thisMonth }

const double _kUnpaidEpsilon = 1e-6;
const int _kAggregateMaxRecords = 5000;
const int _kAggregateMaxPages = 200;

bool _isUnpaidUsageLine(PurchaseUsageHistoryItem row) =>
    row.amountPaid.abs() < _kUnpaidEpsilon;

@RoutePage()
class PurchasesUsageHistoryScreen extends StatefulWidget {
  const PurchasesUsageHistoryScreen({
    super.key,
    @QueryParam('fromDate') this.fromDate,
    @QueryParam('toDate') this.toDate,
    @QueryParam('purchaseItemId') this.purchaseItemId,
    @QueryParam('purchasesLocationId') this.purchasesLocationId,
    @QueryParam('patientQuery') this.patientQuery,
    @QueryParam('page') this.page,
  });

  final String? fromDate;
  final String? toDate;
  final String? purchaseItemId;
  final String? purchasesLocationId;
  final String? patientQuery;
  final int? page;

  @override
  State<PurchasesUsageHistoryScreen> createState() =>
      _PurchasesUsageHistoryScreenState();
}

class _PurchasesUsageHistoryScreenState
    extends State<PurchasesUsageHistoryScreen> {
  final PurchasesDashboardService _dashboardService = PurchasesDashboardService();
  final PurchasesApiService _purchasesApi = PurchasesApiService();
  final InvoicePurchasesApiService _invoicePurchasesApi =
      InvoicePurchasesApiService();
  final TextEditingController _patientCtrl = TextEditingController();
  final ScrollController _tableVerticalScrollController = ScrollController();
  final int _take = 25;

  DateTime _from = _startOfDay(DateTime.now());
  DateTime _to = _endOfDay(DateTime.now());
  String? _selectedItemId;
  String? _selectedItemName;
  String? _selectedLocationId;
  String? _selectedLocationName;
  int _page = 1;

  List<PurchaseUsageHistoryItem> _rows = [];
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
    _tableVerticalScrollController.dispose();
    super.dispose();
  }

  void _restoreQueryState() {
    final from = DateTime.tryParse(widget.fromDate ?? '');
    final to = DateTime.tryParse(widget.toDate ?? '');
    _from = from == null ? _from : _startOfDay(from.toLocal());
    _to = to == null ? _to : _endOfDay(to.toLocal());
    _selectedItemId = widget.purchaseItemId?.trim().isEmpty == true
        ? null
        : widget.purchaseItemId;
    _selectedLocationId = widget.purchasesLocationId?.trim().isEmpty == true
        ? null
        : widget.purchasesLocationId;
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

  PurchaseUsageHistoryQuery _buildQuery({required int skip}) =>
      PurchaseUsageHistoryQuery(
        fromDate: _from,
        toDate: _to,
        purchaseItemId: _selectedItemId,
        purchasesLocationId: _selectedLocationId,
        patientQuery: _patientCtrl.text.trim().isEmpty
            ? null
            : _patientCtrl.text.trim(),
        skip: skip,
        take: _take,
      );

  Future<void> _fetchHistory() async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await _dashboardService.getUsageHistory(
        _buildQuery(skip: (_page - 1) * _take),
      );
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _rows = data.items;
        _total = data.total;
        _loading = false;
      });
      final filterKey = _usageFilterKey();
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

  String _usageFilterKey() =>
      '${_from.toUtc().toIso8601String()}|${_to.toUtc().toIso8601String()}|'
      '${_selectedItemId ?? ''}|${_selectedLocationId ?? ''}|'
      '${_patientCtrl.text.trim()}';

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
    final all = <PurchaseUsageHistoryItem>[];
    var pages = 0;

    try {
      while (all.length < cap && pages < _kAggregateMaxPages) {
        if (!mounted || gen != _summaryGeneration) return;
        final skip = all.length;
        final data = await _dashboardService.getUsageHistory(
          _buildQuery(skip: skip),
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
        if (_isUnpaidUsageLine(r)) unpaid++;
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
      PurchasesUsageHistoryRoute(
        fromDate: _from.toUtc().toIso8601String(),
        toDate: _to.toUtc().toIso8601String(),
        purchaseItemId: _selectedItemId,
        purchasesLocationId: _selectedLocationId,
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

  Future<void> _pickPurchaseItem() async {
    final selected = await showModalBottomSheet<PurchaseItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _PurchaseItemPickerSheet(api: _purchasesApi),
    );
    if (selected == null) return;
    setState(() {
      _selectedItemId = selected.id;
      _selectedItemName = selected.itemName;
      _page = 1;
    });
    _syncQueryState();
    _fetchHistory();
  }

  Future<void> _pickLocation() async {
    final selected = await showModalBottomSheet<PurchasesLocation>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _LocationPickerSheet(api: _purchasesApi),
    );
    if (selected == null) return;
    setState(() {
      _selectedLocationId = selected.id;
      _selectedLocationName = selected.name;
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

  Future<void> _onDoReturn(PurchaseUsageHistoryItem row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => _ReturnPurchaseLineDialog(
        row: row,
        invoicePurchasesApi: _invoicePurchasesApi,
      ),
    );
    if (ok == true && mounted) {
      _cachedSummaryFilterKey = null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Return recorded.')));
      await _fetchHistory();
    }
  }

  Widget _summaryCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: scheme.primary),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = (_total / _take).ceil().clamp(1, 1000000);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Usage History'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickDateRange,
                  icon: const Icon(Icons.date_range),
                  label: Text(
                    '${DateFormat('dd MMM yyyy').format(_from)} - ${DateFormat('dd MMM yyyy').format(_to)}',
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => _applyQuickRange(_QuickRange.today),
                  child: const Text('Today'),
                ),
                FilledButton.tonal(
                  onPressed: () => _applyQuickRange(_QuickRange.last7),
                  child: const Text('Last 7 days'),
                ),
                FilledButton.tonal(
                  onPressed: () => _applyQuickRange(_QuickRange.thisMonth),
                  child: const Text('This month'),
                ),
                OutlinedButton.icon(
                  onPressed: _pickPurchaseItem,
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: Text(_selectedItemName ?? 'Purchase item'),
                ),
                OutlinedButton.icon(
                  onPressed: _pickLocation,
                  icon: const Icon(Icons.location_on_outlined),
                  label: Text(_selectedLocationName ?? 'Location'),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _patientCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Patient search',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                if (_selectedItemId != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedItemId = null;
                        _selectedItemName = null;
                        _page = 1;
                      });
                      _syncQueryState();
                      _fetchHistory();
                    },
                    child: const Text('Clear item'),
                  ),
                if (_selectedLocationId != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedLocationId = null;
                        _selectedLocationName = null;
                        _page = 1;
                      });
                      _syncQueryState();
                      _fetchHistory();
                    },
                    child: const Text('Clear location'),
                  ),
              ],
            ),
            if (!_loading && _error.isEmpty) ...[
              if (_summaryLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 8),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              if (_summaryCapMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _summaryCapMessage!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.tertiary,
                    ),
                  ),
                ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Wrap(
                    spacing: 0,
                    runSpacing: 0,
                    children: [
                      SizedBox(
                        width: constraints.maxWidth >= 1200
                            ? (constraints.maxWidth - 32) / 6
                            : constraints.maxWidth >= 800
                            ? (constraints.maxWidth - 24) / 3
                            : constraints.maxWidth,
                        child: _summaryCard(
                          context,
                          title: 'Total quantity',
                          value: _aggTotalQty.toFinancial(isMoney: false),
                          icon: Icons.numbers,
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth >= 1200
                            ? (constraints.maxWidth - 32) / 6
                            : constraints.maxWidth >= 800
                            ? (constraints.maxWidth - 24) / 3
                            : constraints.maxWidth,
                        child: _summaryCard(
                          context,
                          title: 'Money collected',
                          value: _aggAmountPaid.toFinancial(isMoney: true),
                          icon: Icons.payments_outlined,
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth >= 1200
                            ? (constraints.maxWidth - 32) / 6
                            : constraints.maxWidth >= 800
                            ? (constraints.maxWidth - 24) / 3
                            : constraints.maxWidth,
                        child: _summaryCard(
                          context,
                          title: 'Gross line value',
                          value: _aggGrossValue.toFinancial(isMoney: true),
                          icon: Icons.receipt_long_outlined,
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth >= 1200
                            ? (constraints.maxWidth - 32) / 6
                            : constraints.maxWidth >= 800
                            ? (constraints.maxWidth - 24) / 3
                            : constraints.maxWidth,
                        child: _summaryCard(
                          context,
                          title: 'Issue lines',
                          value: '$_aggRowCount',
                          icon: Icons.list_alt,
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth >= 1200
                            ? (constraints.maxWidth - 32) / 6
                            : constraints.maxWidth >= 800
                            ? (constraints.maxWidth - 24) / 3
                            : constraints.maxWidth,
                        child: _summaryCard(
                          context,
                          title: 'Unpaid lines',
                          value: '$_aggUnpaidCount',
                          icon: Icons.money_off_csred_outlined,
                        ),
                      ),
                      SizedBox(
                        width: constraints.maxWidth >= 1200
                            ? (constraints.maxWidth - 32) / 6
                            : constraints.maxWidth >= 800
                            ? (constraints.maxWidth - 24) / 3
                            : constraints.maxWidth,
                        child: _summaryCard(
                          context,
                          title: 'Distinct patients',
                          value: '$_aggDistinctPatients',
                          icon: Icons.people_outline,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
            const SizedBox(height: 12),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error, textAlign: TextAlign.center),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: _fetchHistory,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _rows.isEmpty
                  ? const Center(child: Text('No usage records found.'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Scrollbar(
                        controller: _tableVerticalScrollController,
                        child: SingleChildScrollView(
                          controller: _tableVerticalScrollController,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('Issued At')),
                              DataColumn(label: Text('Issued By')),
                              DataColumn(label: Text('Location')),
                              DataColumn(label: Text('Item')),
                              DataColumn(label: Text('Patient')),
                              DataColumn(label: Text('Invoice')),
                              DataColumn(label: Text('Qty')),
                              DataColumn(label: Text('Unit Price')),
                              DataColumn(label: Text('Amount Paid')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: _rows.map((row) {
                              final canReturn = _isUnpaidUsageLine(row);
                              final itemLabel = row.purchaseItem.sku != null &&
                                      row.purchaseItem.sku!.isNotEmpty
                                  ? '${row.purchaseItem.name} (${row.purchaseItem.sku})'
                                  : row.purchaseItem.name;
                              return DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      row.issuedAt == null
                                          ? '—'
                                          : DateFormat(
                                              'dd MMM yyyy HH:mm',
                                            ).format(
                                              row.issuedAt!.toLocal(),
                                            ),
                                    ),
                                  ),
                                  DataCell(Text(row.issuedBy?.name ?? '—')),
                                  DataCell(
                                    Text(row.purchasesLocation?.name ?? '—'),
                                  ),
                                  DataCell(Text(itemLabel)),
                                  DataCell(
                                    Text(
                                      '${row.patient.name} (${row.patient.patientId})',
                                    ),
                                  ),
                                  DataCell(Text(row.invoiceId)),
                                  DataCell(Text('${row.quantity}')),
                                  DataCell(
                                    Text(
                                      row.unitPrice.toFinancial(isMoney: true),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      row.amountPaid.toFinancial(isMoney: true),
                                    ),
                                  ),
                                  DataCell(
                                    Tooltip(
                                      message: canReturn
                                          ? 'Return units to stock'
                                          : 'Paid lines cannot be returned',
                                      child: TextButton(
                                        onPressed: canReturn
                                            ? () => _onDoReturn(row)
                                            : null,
                                        child: const Text('Do return'),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Page $_page of $totalPages'),
                const Spacer(),
                IconButton(
                  onPressed: _page > 1
                      ? () {
                          setState(() => _page -= 1);
                          _syncQueryState();
                          _fetchHistory();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: _page < totalPages
                      ? () {
                          setState(() => _page += 1);
                          _syncQueryState();
                          _fetchHistory();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReturnPurchaseLineDialog extends StatefulWidget {
  const _ReturnPurchaseLineDialog({
    required this.row,
    required this.invoicePurchasesApi,
  });

  final PurchaseUsageHistoryItem row;
  final InvoicePurchasesApiService invoicePurchasesApi;

  @override
  State<_ReturnPurchaseLineDialog> createState() =>
      _ReturnPurchaseLineDialogState();
}

class _ReturnPurchaseLineDialogState extends State<_ReturnPurchaseLineDialog> {
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
      await widget.invoicePurchasesApi.returnInvoiceItem(
        invoiceId: widget.row.invoiceUUID,
        itemId: widget.row.invoiceItemId,
        dto: ReturnPurchaseInvoiceItemDto(
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
      title: const Text('Return purchase line'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${r.purchaseItem.name} · up to ${r.quantity} units',
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

class _PurchaseItemPickerSheet extends StatefulWidget {
  const _PurchaseItemPickerSheet({required this.api});

  final PurchasesApiService api;

  @override
  State<_PurchaseItemPickerSheet> createState() =>
      _PurchaseItemPickerSheetState();
}

class _PurchaseItemPickerSheetState extends State<_PurchaseItemPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final List<PurchaseItem> _items = [];
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
      final resp = await widget.api.searchItems(
        SearchPurchaseItemParams(
          search: _searchCtrl.text.trim().isEmpty
              ? null
              : _searchCtrl.text.trim(),
          limit: 50,
          page: 1,
          pageSize: 50,
          sortOrder: 'asc',
        ),
      );
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(
            resp.items.where((i) => i.id != null && i.id!.isNotEmpty),
          );
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items.clear();
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
                hintText: 'Search purchase item',
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
                      itemCount: _items.length,
                      itemBuilder: (_, i) {
                        final item = _items[i];
                        return ListTile(
                          title: Text(item.itemName),
                          subtitle: item.sku != null && item.sku!.isNotEmpty
                              ? Text('SKU: ${item.sku}')
                              : null,
                          onTap: () => Navigator.of(context).pop(item),
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

class _LocationPickerSheet extends StatefulWidget {
  const _LocationPickerSheet({required this.api});

  final PurchasesApiService api;

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  List<PurchasesLocation> _locations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final resp = await widget.api.getLocations(
        const PurchasesQueryParams(pageSize: 100),
      );
      if (!mounted) return;
      setState(() {
        _locations = resp.items.where((l) => l.isActive).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locations = [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.5,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Select location',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      controller: controller,
                      itemCount: _locations.length,
                      itemBuilder: (_, i) {
                        final loc = _locations[i];
                        return ListTile(
                          title: Text(loc.name),
                          subtitle: Text(loc.type.name),
                          onTap: () => Navigator.of(context).pop(loc),
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
