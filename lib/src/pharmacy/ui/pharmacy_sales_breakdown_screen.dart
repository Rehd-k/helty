import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/helper/app_timezone.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/pharmacy/widgets/pharmacy_page_chrome.dart';
import 'package:helty/src/shared/department_colors.dart';
import 'package:helty/src/widgets/helty_surface.dart';
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
    _fromDate = AppTimezone.startOfDay();
    _toDate = AppTimezone.endOfDay();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _loadStores();
      await _fetch();
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

  String get _rangeLabel {
    final from = _fromDate == null ? '—' : DateFormatter.shortDate(_fromDate!);
    final to = _toDate == null ? '—' : DateFormatter.shortDate(_toDate!);
    return '$from – $to';
  }

  String? get _selectedStoreName {
    final id = _selectedStoreId;
    if (id == null) return null;
    for (final store in _storeLocations) {
      if (store.id == id) return store.name;
    }
    return null;
  }

  bool get _metricsReady => !_loading && _error == null;

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(authProvider).staff;
    final preview = ref.watch(superAdminPreviewProvider);
    if (!canViewPharmacyFinancialReports(staff, preview)) {
      return _denied();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final totals = _data.totals;
    final dash = '—';

    return Scaffold(
      backgroundColor: cs.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final useCards = width < PharmacyAccent.cardBreakpoint;
          final useSheet = width < PharmacyAccent.railBreakpoint;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PharmacyPageHeader(
                title: 'Sales breakdown',
                subtitle: '$_rangeLabel · ${_selectedStoreName ?? 'All stores'} · $_payer',
                icon: Icons.pie_chart_outline,
                iconColor: DepartmentColors.pharmacy,
                onRefresh: _loading ? null : _reload,
              ),
              const SizedBox(height: 10),
              PharmacyKpiStrip(
                items: [
                  PharmacyKpiItem(
                    label: 'Sales',
                    value: _metricsReady ? _money.format(totals.grossSales) : dash,
                    caption: _metricsReady
                        ? '${_count.format(totals.transactionCount)} transactions'
                        : 'Gross sales',
                    icon: Icons.payments_outlined,
                    accent: PharmacyAccent.purple,
                  ),
                  PharmacyKpiItem(
                    label: 'COGS',
                    value: _metricsReady ? _money.format(totals.cogs) : dash,
                    caption: 'Cost of goods',
                    icon: Icons.inventory_2_outlined,
                    accent: PharmacyAccent.amber,
                  ),
                  PharmacyKpiItem(
                    label: 'Profit',
                    value: _metricsReady ? _money.format(totals.grossProfit) : dash,
                    caption: _metricsReady
                        ? '${_count.format(totals.quantitySold)} units'
                        : 'Gross profit',
                    icon: Icons.trending_up,
                    accent: PharmacyAccent.green,
                  ),
                  PharmacyKpiItem(
                    label: 'Margin',
                    value: _metricsReady
                        ? '${totals.marginPercent.toStringAsFixed(1)}%'
                        : dash,
                    caption: 'On sales',
                    icon: Icons.percent,
                    accent: PharmacyAccent.teal,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _filterRow(),
              const SizedBox(height: 10),
              Expanded(child: _results(theme, useCards: useCards, useSheet: useSheet)),
            ],
          );
        },
      ),
    );
  }

  Widget _filterRow() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<PharmacySalesGroupBy>(
            initialValue: _groupBy,
            isExpanded: true,
            decoration: pharmacyFieldDecoration(
              context,
              label: 'Group by',
              icon: Icons.account_tree_outlined,
              iconColor: PharmacyAccent.indigo,
            ),
            items: [
              for (final group in PharmacySalesGroupBy.values)
                DropdownMenuItem(
                  value: group,
                  child: Text(
                    group.label,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: _loading
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _groupBy = value);
                    _reload();
                  },
          ),
        ),
        const SizedBox(width: 8),
        PharmacyFilterButton(onPressed: _loading ? null : _openFilters),
      ],
    );
  }

  Future<void> _openFilters() {
    return showPharmacyFilterDialog(
      context: context,
      body: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickDate({required bool from}) async {
              final current = from ? _fromDate : _toDate;
              final picked = await showDatePicker(
                context: context,
                initialDate: current ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked == null || !mounted) return;
              setState(() {
                if (from) {
                  _fromDate = AppTimezone.startOfDay(picked);
                } else {
                  _toDate = AppTimezone.endOfDay(picked);
                }
              });
              setDialogState(() {});
              _reload();
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Date range',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: () => pickDate(from: true),
                      child: Text(
                        'From ${_fromDate == null ? '—' : DateFormatter.shortDate(_fromDate!)}',
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () => pickDate(from: false),
                      child: Text(
                        'To ${_toDate == null ? '—' : DateFormatter.shortDate(_toDate!)}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedStoreId,
                  isExpanded: true,
                  decoration: pharmacyFieldDecoration(
                    context,
                    label: 'Store',
                    icon: Icons.storefront_outlined,
                    iconColor: PharmacyAccent.teal,
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All stores'),
                    ),
                    for (final store in _storeLocations)
                      DropdownMenuItem<String?>(
                        value: store.id,
                        child: Text(
                          store.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedStoreId = value);
                    setDialogState(() {});
                    _reload();
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _payer,
                  isExpanded: true,
                  decoration: pharmacyFieldDecoration(
                    context,
                    label: 'Payer',
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: PharmacyAccent.amber,
                  ),
                  items: [
                    for (final payer in _payerTypes)
                      DropdownMenuItem(value: payer, child: Text(payer)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _payer = value);
                    setDialogState(() {});
                    _reload();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _results(
    ThemeData theme, {
    required bool useCards,
    required bool useSheet,
  }) {
    final body = _loading && _data.rows.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _data.rows.isEmpty
        ? _errorCard(_error!)
        : _data.rows.isEmpty
        ? const Center(child: Text('No sales for the selected filters.'))
        : useCards
        ? _cards(useSheet: useSheet)
        : _table(theme, useSheet: useSheet);

    return HeltySurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: body),
          if (_loading && _data.rows.isNotEmpty)
            const LinearProgressIndicator(minHeight: 2),
        ],
      ),
    );
  }

  Widget _cards({required bool useSheet}) {
    final rows = _sortedRows;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final row = rows[index];
        final profitColor = row.grossProfit >= 0
            ? PharmacyAccent.green
            : const Color(0xFFDC2626);
        return Material(
          color: pharmacyZebra(Theme.of(context).colorScheme, index),
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: () => _onRow(row, useSheet: useSheet),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: HeltyEllipsisText(
                          text: row.groupLabel,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      HeltyStatusChip(
                        label: '${row.marginPercent.toStringAsFixed(1)}%',
                        color: profitColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  HeltyEllipsisText(
                    text:
                        '${_money.format(row.grossSales)} · Profit ${_money.format(row.grossProfit)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  HeltyEllipsisText(
                    text:
                        '${_count.format(row.quantitySold)} units · ${_count.format(row.transactionCount)} txns · ${row.percentOfTotalSales.toStringAsFixed(1)}% of sales',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _table(ThemeData theme, {required bool useSheet}) {
    final rows = _sortedRows;
    final cs = theme.colorScheme;
    const headers = <(int, String)>[
      (0, 'GROUP'),
      (1, 'QTY'),
      (2, 'SALES'),
      (3, 'COGS'),
      (4, 'PROFIT'),
      (5, 'MARGIN'),
      (6, 'TXNS'),
      (-1, '% SALES'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        const minWidth = 980.0;
        final width = constraints.maxWidth < minWidth
            ? minWidth
            : constraints.maxWidth;
        final sheet = SizedBox(
          width: width,
          height: constraints.maxHeight,
          child: Column(
            children: [
              Container(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    for (final header in headers) ...[
                      Expanded(
                        flex: header.$1 == 0 ? 3 : 2,
                        child: InkWell(
                          onTap: header.$1 < 0 ? null : () => _onSort(header.$1),
                          child: Text(
                            header.$1 == 0 ? _groupBy.label.toUpperCase() : header.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface.withValues(alpha: 0.55),
                            ),
                          ),
                        ),
                      ),
                      if (header != headers.last) const SizedBox(width: 12),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: rows.length,
                  itemBuilder: (context, index) {
                    final row = rows[index];
                    final profitColor = row.grossProfit >= 0
                        ? PharmacyAccent.green
                        : const Color(0xFFDC2626);
                    return Material(
                      color: pharmacyZebra(cs, index),
                      child: InkWell(
                        onTap: () => _onRow(row, useSheet: useSheet),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: HeltyEllipsisText(
                                  text: row.groupLabel,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Text(_count.format(row.quantitySold)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Text(_money.format(row.grossSales)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Text(_money.format(row.cogs)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  _money.format(row.grossProfit),
                                  style: TextStyle(
                                    color: profitColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${row.marginPercent.toStringAsFixed(1)}%',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Text(_count.format(row.transactionCount)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  '${row.percentOfTotalSales.toStringAsFixed(1)}%',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
        if (constraints.maxWidth >= minWidth) return sheet;
        return Scrollbar(
          thumbVisibility: true,
          notificationPredicate: (notification) => notification.depth == 0,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: sheet,
          ),
        );
      },
    );
  }

  void _onRow(PharmacySalesBreakdownRow row, {required bool useSheet}) {
    if (!useSheet) {
      _openDetail(row);
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final profitColor = row.grossProfit >= 0
            ? PharmacyAccent.green
            : const Color(0xFFDC2626);
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.32,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                Text(
                  row.groupLabel,
                  style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _sheetLine('Quantity', _count.format(row.quantitySold)),
                _sheetLine('Sales', _money.format(row.grossSales)),
                _sheetLine('COGS', _money.format(row.cogs)),
                _sheetLine(
                  'Profit',
                  _money.format(row.grossProfit),
                  valueColor: profitColor,
                ),
                _sheetLine(
                  'Margin',
                  '${row.marginPercent.toStringAsFixed(1)}%',
                ),
                _sheetLine(
                  'Transactions',
                  _count.format(row.transactionCount),
                ),
                _sheetLine(
                  'Share of sales',
                  '${row.percentOfTotalSales.toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      _openDetail(row);
                    });
                  },
                  icon: const Icon(Icons.receipt_long_outlined, size: 18),
                  label: const Text('View sale lines'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _sheetLine(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(fontWeight: FontWeight.w800, color: valueColor),
            ),
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
