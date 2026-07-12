import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/widgets/date.filter.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/super_admin_preview_provider.dart';
import '../auth/pharmacy_permissions.dart';
import '../models/pharmacy_model.dart';
import '../models/pharmacy_reports_model.dart';
import '../services/pharmacy_reports_service.dart';
import '../services/pharmacy_service.dart';

@RoutePage()
class PharmacySalesBreakdownScreen extends ConsumerStatefulWidget {
  const PharmacySalesBreakdownScreen({
    super.key,
    this.initialGroupBy = PharmacySalesGroupBy.drug,
  });

  final PharmacySalesGroupBy initialGroupBy;

  @override
  ConsumerState<PharmacySalesBreakdownScreen> createState() =>
      _PharmacySalesBreakdownScreenState();
}

class _PharmacySalesBreakdownScreenState
    extends ConsumerState<PharmacySalesBreakdownScreen> {
  final PharmacyReportsService _service = PharmacyReportsService();
  final PharmacyApiService _pharmacyApi = PharmacyApiService();

  List<PharmacyLocation> _storeLocations = [];
  String? _selectedStoreId;
  final List<String> _payerTypes = const [
    'All',
    'Cash',
    'Insurance',
    'Corporate',
    'HMO',
  ];

  late PharmacySalesGroupBy _groupBy = widget.initialGroupBy;
  DateTime? _fromDate;
  DateTime? _toDate;
  String _payer = 'All';

  bool _loading = true;
  String? _error;
  PharmacySalesBreakdown _data = PharmacySalesBreakdown.empty;

  int _sortColumn = 2;
  bool _sortAsc = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _loadStores();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadStores() async {
    final resp = await _pharmacyApi.getPharmacyLocations(
      const PharmacyQueryParams(pageSize: 200),
    );
    final stores = resp.items
        .where(
          (l) =>
              l.type == PharmacyLocationType.STORE &&
              l.isActive &&
              l.id != null &&
              l.id!.trim().isNotEmpty,
        )
        .toList();
    if (!mounted) return;
    setState(() => _storeLocations = stores);
  }

  Future<void> _fetch() async {
    if (_fromDate == null || _toDate == null) return;
    final data = await _service.getSalesBreakdown(
      PharmacySalesBreakdownQuery(
        fromDate: _fromDate!,
        toDate: _toDate!,
        groupBy: _groupBy,
        storeId: _selectedStoreId,
        payerType: _payer,
      ),
    );
    if (!mounted) return;
    setState(() => _data = data);
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _fetch();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  NumberFormat get _money =>
      NumberFormat.currency(symbol: 'NGN ', decimalDigits: 0);
  NumberFormat get _count => NumberFormat.decimalPattern();

  List<PharmacySalesBreakdownRow> get _sortedRows {
    final rows = [..._data.rows];
    int cmp(PharmacySalesBreakdownRow a, PharmacySalesBreakdownRow b) {
      switch (_sortColumn) {
        case 0:
          return a.groupLabel.toLowerCase().compareTo(
            b.groupLabel.toLowerCase(),
          );
        case 1:
          return a.quantitySold.compareTo(b.quantitySold);
        case 2:
          return a.grossSales.compareTo(b.grossSales);
        case 3:
          return a.cogs.compareTo(b.cogs);
        case 4:
          return a.grossProfit.compareTo(b.grossProfit);
        case 5:
          return a.marginPercent.compareTo(b.marginPercent);
        case 6:
          return a.transactionCount.compareTo(b.transactionCount);
        default:
          return 0;
      }
    }

    rows.sort((a, b) => _sortAsc ? cmp(a, b) : cmp(b, a));
    return rows;
  }

  void _onSort(int col) {
    setState(() {
      if (_sortColumn == col) {
        _sortAsc = !_sortAsc;
      } else {
        _sortColumn = col;
        _sortAsc = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(authProvider).staff;
    final preview = ref.watch(superAdminPreviewProvider);
    if (!canViewPharmacyFinancialReports(staff, preview)) {
      return _denied();
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Sales breakdown'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ResponsiveBody(
        builder: (context, bp) => ListView(
          children: [
            _filterBar(theme),
            const SizedBox(height: 16),
            if (_loading && _data.rows.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _data.rows.isEmpty)
              _errorCard(_error!)
            else ...[
              _totalsCard(theme),
              const SizedBox(height: 16),
              _table(theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _filterBar(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FromToDateFilter(
          doRefresh: _reload,
          dateFilter: true,
          labelStyle: DateFilterLabelStyle.shortUs,
          onFilterChanged: (query, category, from, to) {
            setState(() {
              _fromDate = from;
              _toDate = to;
            });
            _reload();
          },
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDE6FF)),
          ),
          child: Wrap(
            runSpacing: 10,
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _dropdown<PharmacySalesGroupBy>(
                value: _groupBy,
                items: PharmacySalesGroupBy.values
                    .map(
                      (g) => DropdownMenuItem(
                        value: g,
                        child: Text('By ${g.label}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _groupBy = v);
                  _reload();
                },
              ),
              _storeDropdown(),
              _dropdown<String>(
                value: _payer,
                items: _payerTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _payer = v);
                  _reload();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _storeDropdown() {
    return _dropdown<String?>(
      value: _selectedStoreId,
      items: [
        const DropdownMenuItem<String?>(value: null, child: Text('All stores')),
        ..._storeLocations.map(
          (s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.name)),
        ),
      ],
      onChanged: (v) {
        setState(() => _selectedStoreId = v);
        _reload();
      },
    );
  }

  Widget _dropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _totalsCard(ThemeData theme) {
    final t = _data.totals;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        spacing: 28,
        runSpacing: 12,
        children: [
          _total('Total sales', _money.format(t.grossSales),
              const Color(0xFF8B5CF6)),
          _total('COGS', _money.format(t.cogs), const Color(0xFFF97316)),
          _total('Gross profit', _money.format(t.grossProfit),
              const Color(0xFF10B981)),
          _total('Margin', '${t.marginPercent.toStringAsFixed(1)}%',
              const Color(0xFF059669)),
          _total('Qty sold', _count.format(t.quantitySold),
              const Color(0xFF3B82F6)),
          _total('Transactions', _count.format(t.transactionCount),
              const Color(0xFF0EA5E9)),
        ],
      ),
    );
  }

  Widget _total(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _table(ThemeData theme) {
    if (_data.rows.isEmpty) {
      return _emptyCard('No sales for the selected filters.');
    }
    final rows = _sortedRows;
    return ResponsiveDataTable(
      child: DataTable(
        sortColumnIndex: _sortColumn,
        sortAscending: _sortAsc,
        columns: [
            DataColumn(
              label: Text(_groupBy.label),
              onSort: (i, _) => _onSort(0),
            ),
            DataColumn(
              label: const Text('Qty'),
              numeric: true,
              onSort: (i, _) => _onSort(1),
            ),
            DataColumn(
              label: const Text('Sales'),
              numeric: true,
              onSort: (i, _) => _onSort(2),
            ),
            DataColumn(
              label: const Text('COGS'),
              numeric: true,
              onSort: (i, _) => _onSort(3),
            ),
            DataColumn(
              label: const Text('Profit'),
              numeric: true,
              onSort: (i, _) => _onSort(4),
            ),
            DataColumn(
              label: const Text('Margin'),
              numeric: true,
              onSort: (i, _) => _onSort(5),
            ),
            DataColumn(
              label: const Text('Txns'),
              numeric: true,
              onSort: (i, _) => _onSort(6),
            ),
            const DataColumn(label: Text('% of sales'), numeric: true),
          ],
          rows: [
            for (final r in rows)
              DataRow(
                onSelectChanged: (_) => _openDetail(r),
                cells: [
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: Text(
                        r.groupLabel,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  DataCell(Text(_count.format(r.quantitySold))),
                  DataCell(Text(_money.format(r.grossSales))),
                  DataCell(Text(_money.format(r.cogs))),
                  DataCell(
                    Text(
                      _money.format(r.grossProfit),
                      style: TextStyle(
                        color: r.grossProfit >= 0
                            ? const Color(0xFF059669)
                            : const Color(0xFFDC2626),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  DataCell(Text('${r.marginPercent.toStringAsFixed(1)}%')),
                  DataCell(Text(_count.format(r.transactionCount))),
                  DataCell(
                    Text('${r.percentOfTotalSales.toStringAsFixed(1)}%'),
                  ),
                ],
              ),
          ],
        ),
    );
  }

  void _openDetail(PharmacySalesBreakdownRow row) {
    if (_fromDate == null || _toDate == null) return;
    context.router.push(
      PharmacySalesBreakdownDetailRoute(
        groupBy: _groupBy,
        groupKey: row.groupKey,
        groupLabel: row.groupLabel,
        fromDate: _fromDate!,
        toDate: _toDate!,
        storeId: _selectedStoreId,
        payerType: _payer,
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Color(0xFF64748B)),
        ),
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFF991B1B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _denied() {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Sales breakdown'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'This report is available to the head of pharmacy only.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
