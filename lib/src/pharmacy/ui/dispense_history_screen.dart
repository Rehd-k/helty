import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:intl/intl.dart';

import '../models/pharmacy_model.dart';
import '../services/pharmacy_service.dart';

enum _QuickRange { today, last7, thisMonth }

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
    _selectedDrugId = widget.drugId?.trim().isEmpty == true ? null : widget.drugId;
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
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = e.toString();
        _loading = false;
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

  @override
  Widget build(BuildContext context) {
    final totalPages = (_total / _take).ceil().clamp(1, 1000000);
    return Scaffold(
      appBar: AppBar(title: const Text('Dispense History')),
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
                  onPressed: _pickDrug,
                  icon: const Icon(Icons.medication_outlined),
                  label: Text(_selectedDrugName ?? 'Drug'),
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
                if (_selectedDrugId != null)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedDrugId = null;
                        _selectedDrugName = null;
                        _page = 1;
                      });
                      _syncQueryState();
                      _fetchHistory();
                    },
                    child: const Text('Clear drug'),
                  ),
              ],
            ),
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
                  ? const Center(child: Text('No dispense records found.'))
                  : SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Dispensed At')),
                          DataColumn(label: Text('Drug')),
                          DataColumn(label: Text('Patient')),
                          DataColumn(label: Text('Invoice')),
                          DataColumn(label: Text('Qty')),
                          DataColumn(label: Text('Unit Price')),
                          DataColumn(label: Text('Amount Paid')),
                        ],
                        rows: _rows
                            .map(
                              (row) => DataRow(
                                cells: [
                                  DataCell(
                                    Text(
                                      row.dispensedAt == null
                                          ? '—'
                                          : DateFormat(
                                              'dd MMM yyyy HH:mm',
                                            ).format(row.dispensedAt!.toLocal()),
                                    ),
                                  ),
                                  DataCell(Text(row.drug.name)),
                                  DataCell(
                                    Text('${row.patient.name} (${row.patient.patientId})'),
                                  ),
                                  DataCell(Text(row.invoiceId)),
                                  DataCell(Text('${row.quantity}')),
                                  DataCell(
                                    Text(row.unitPrice.toFinancial(isMoney: true)),
                                  ),
                                  DataCell(
                                    Text(row.amountPaid.toFinancial(isMoney: true)),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
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
          search: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
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
