import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/pharmacy/widgets/pharmacy_page_chrome.dart';
import 'package:intl/intl.dart';
import 'package:helty/src/shared/department_colors.dart';
import 'package:helty/src/shared/module_surface_styles.dart';
import 'package:helty/src/widgets/helty_surface.dart';

import '../../providers/auth_provider.dart';
import '../../providers/super_admin_preview_provider.dart';
import '../auth/pharmacy_permissions.dart';
import '../models/pharmacy_reports_model.dart';
import '../services/pharmacy_reports_service.dart';

class _ExpiryFilter {
  const _ExpiryFilter(this.label, this.days);
  final String label;
  final int? days;
}

@RoutePage()
class PharmacyInventoryValuationScreen extends ConsumerStatefulWidget {
  const PharmacyInventoryValuationScreen({super.key, this.locationId});

  /// When set, opens focused on a single location's batches.
  final String? locationId;

  @override
  ConsumerState<PharmacyInventoryValuationScreen> createState() =>
      _PharmacyInventoryValuationScreenState();
}

class _PharmacyInventoryValuationScreenState
    extends ConsumerState<PharmacyInventoryValuationScreen> {
  final PharmacyReportsService _service = PharmacyReportsService();

  static const _expiryFilters = <_ExpiryFilter>[
    _ExpiryFilter('All', null),
    _ExpiryFilter('Expiring 30d', 30),
    _ExpiryFilter('Expiring 90d', 90),
    _ExpiryFilter('Expired', 0),
  ];

  bool _loading = true;
  String? _error;
  PharmacyInventoryValuation _valuation = PharmacyInventoryValuation.empty;

  String? _focusLocationId;
  _ExpiryFilter _expiry = _expiryFilters.first;

  @override
  void initState() {
    super.initState();
    _focusLocationId = widget.locationId;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _fetchSummary();
    if (!mounted || widget.locationId == null) return;
    if (MediaQuery.sizeOf(context).width >= PharmacyAccent.railBreakpoint) {
      return;
    }
    for (final store in _valuation.stores) {
      if (store.locationId == widget.locationId) {
        _openBatches(store);
        break;
      }
    }
  }

  Future<void> _fetchSummary() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final v = await _service.getInventoryValuation(
        PharmacyValuationQuery(expiryWithinDays: _expiry.days),
      );
      if (!mounted) return;
      setState(() => _valuation = v);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _selectStore(
    PharmacyInventoryStoreValuation store, {
    required bool useSheet,
  }) {
    if (useSheet) {
      _openBatches(store);
      return;
    }
    setState(() {
      _focusLocationId = _focusLocationId == store.locationId
          ? null
          : store.locationId;
    });
  }

  void _openBatches(PharmacyInventoryStoreValuation store) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final height = MediaQuery.sizeOf(sheetContext).height * 0.9;
        return SizedBox(
          height: height,
          child: _ValuationBatchesPanel(
            service: _service,
            locationId: store.locationId,
            locationName: store.locationName,
            expiryDays: _expiry.days,
          ),
        );
      },
    );
  }

  NumberFormat get _money =>
      NumberFormat.currency(symbol: 'NGN ', decimalDigits: 0);
  NumberFormat get _count => NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(authProvider).staff;
    final preview = ref.watch(superAdminPreviewProvider);
    if (!canViewPharmacyFinancialReports(staff, preview)) {
      return _denied();
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final totals = _valuation.totals;
    final ready = !_loading && _error == null;
    const dash = '—';

    return Scaffold(
      backgroundColor: cs.surface,
      body: ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final showRail = width >= PharmacyAccent.railBreakpoint;
          final stores = _storeList(theme, useSheet: !showRail);
          final main = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PharmacyPageHeader(
                title: 'Inventory valuation',
                subtitle: _expiry.days == null
                    ? 'Stock value by location'
                    : 'Filtered · ${_expiry.label}',
                icon: Icons.account_balance_wallet_outlined,
                iconColor: DepartmentColors.pharmacy,
                onRefresh: _loading ? null : _fetchSummary,
              ),
              const SizedBox(height: 10),
              PharmacyKpiStrip(
                items: [
                  PharmacyKpiItem(
                    label: 'At cost',
                    value: ready ? _money.format(totals.valueAtCost) : dash,
                    caption: ready
                        ? '${_count.format(totals.batchCount)} batches'
                        : 'Inventory worth',
                    icon: Icons.payments_outlined,
                    accent: PharmacyAccent.indigo,
                  ),
                  PharmacyKpiItem(
                    label: 'At selling',
                    value: ready
                        ? _money.format(totals.valueAtSellingPrice)
                        : dash,
                    caption: 'List price',
                    icon: Icons.sell_outlined,
                    accent: PharmacyAccent.purple,
                  ),
                  PharmacyKpiItem(
                    label: 'Units',
                    value: ready ? _count.format(totals.totalQuantity) : dash,
                    caption: 'On hand',
                    icon: Icons.inventory_2_outlined,
                    accent: PharmacyAccent.teal,
                  ),
                  PharmacyKpiItem(
                    label: 'Near expiry',
                    value: ready
                        ? _money.format(totals.nearExpiryValueAtCost)
                        : dash,
                    caption: 'Value at cost',
                    icon: Icons.event_busy_outlined,
                    accent: PharmacyAccent.amber,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _expiryBar(),
              const SizedBox(height: 10),
              Expanded(child: stores),
            ],
          );

          if (!showRail) return main;

          PharmacyInventoryStoreValuation? focused;
          for (final store in _valuation.stores) {
            if (store.locationId == _focusLocationId) focused = store;
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 5, child: main),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: HeltySurfaceCard(
                  child: focused == null
                      ? const Center(
                          child: Text('Select a location to view batches'),
                        )
                      : _ValuationBatchesPanel(
                          key: ValueKey('${focused.locationId}-${_expiry.days}'),
                          service: _service,
                          locationId: focused.locationId,
                          locationName: focused.locationName,
                          expiryDays: _expiry.days,
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _expiryBar() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _expiryFilters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = _expiryFilters[index];
          return FilterChip(
            label: Text(filter.label),
            selected: _expiry.label == filter.label,
            visualDensity: VisualDensity.compact,
            onSelected: (_) {
              setState(() => _expiry = filter);
              _fetchSummary();
            },
          );
        },
      ),
    );
  }

  Widget _storeList(ThemeData theme, {required bool useSheet}) {
    final body = _loading && _valuation.stores.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : _error != null && _valuation.stores.isEmpty
        ? _errorCard(_error!)
        : _valuation.stores.isEmpty
        ? const Center(child: Text('No inventory found.'))
        : ListView.separated(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            itemCount: _valuation.stores.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final store = _valuation.stores[index];
              final selected = _focusLocationId == store.locationId;
              return Material(
                color: selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.06)
                    : theme.colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.35,
                      ),
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: () => _selectStore(store, useSheet: useSheet),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const HeltySolidIcon(
                              icon: Icons.storefront_outlined,
                              color: PharmacyAccent.indigo,
                              size: 32,
                              iconSize: 16,
                              radius: 8,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: HeltyEllipsisText(
                                text: store.locationName,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            HeltyStatusChip(
                              label: store.locationType,
                              color: PharmacyAccent.teal,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        HeltyEllipsisText(
                          text:
                              '${_money.format(store.valueAtCost)} at cost · ${_count.format(store.totalQuantity)} units',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        HeltyEllipsisText(
                          text:
                              '${_count.format(store.batchCount)} batches · Near expiry ${_money.format(store.nearExpiryValueAtCost)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );

    return HeltySurfaceCard(child: body);
  }

  Widget _errorCard(String message) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ModuleSurfaceStyles.errorBanner(theme),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: cs.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: cs.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _denied() {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Inventory valuation')),
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

class _ValuationBatchesPanel extends StatefulWidget {
  const _ValuationBatchesPanel({
    super.key,
    required this.service,
    required this.locationId,
    required this.locationName,
    required     this.expiryDays,
  });

  final PharmacyReportsService service;
  final String locationId;
  final String locationName;
  final int? expiryDays;

  @override
  State<_ValuationBatchesPanel> createState() => _ValuationBatchesPanelState();
}

class _ValuationBatchesPanelState extends State<_ValuationBatchesPanel> {
  static const _pageSize = 50;
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _money = NumberFormat.currency(
    symbol: 'NGN ',
    decimalDigits: 0,
  );
  final NumberFormat _count = NumberFormat.decimalPattern();
  Timer? _debounce;

  bool _loading = true;
  PharmacyInventoryBatchPage _page = PharmacyInventoryBatchPage.empty;
  int _skip = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant _ValuationBatchesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.locationId != widget.locationId ||
        oldWidget.expiryDays != widget.expiryDays) {
      _skip = 0;
      _fetch();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _loading = true);
    try {
      final page = await widget.service.getInventoryValuationBatches(
        PharmacyValuationQuery(
          locationId: widget.locationId,
          expiryWithinDays: widget.expiryDays,
          search: _searchCtrl.text,
          skip: _skip,
          take: _pageSize,
        ),
      );
      if (!mounted) return;
      setState(() => _page = page);
    } catch (_) {
      if (!mounted) return;
      setState(() => _page = PharmacyInventoryBatchPage.empty);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _skip = 0;
      _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _page.total;
    final start = total == 0 ? 0 : _skip + 1;
    final end = (_skip + _page.rows.length).clamp(0, total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
          child: HeltyEllipsisText(
            text: widget.locationName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: _onSearch,
            style: const TextStyle(fontSize: 13),
            decoration: pharmacyFieldDecoration(
              context,
              label: 'Search',
              hint: 'Drug name',
              icon: Icons.search,
              iconColor: PharmacyAccent.indigo,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final useCards =
                  constraints.maxWidth < PharmacyAccent.cardBreakpoint;
              if (_loading && _page.rows.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }
              if (_page.rows.isEmpty) {
                return const Center(
                  child: Text('No batches for this location.'),
                );
              }
              if (useCards) {
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                  itemCount: _page.rows.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) =>
                      _batchCard(_page.rows[index]),
                );
              }
              return _batchTable(theme);
            },
          ),
        ),
        PharmacyPaginationFooter(
          label: total == 0
              ? 'No batches to display'
              : 'Showing $start–$end of ${_count.format(total)}',
          page: (_skip ~/ _pageSize) + 1,
          canPrev: _skip > 0 && !_loading,
          canNext: _skip + _pageSize < total && !_loading,
          onPrev: () {
            setState(() => _skip -= _pageSize);
            _fetch();
          },
          onNext: () {
            setState(() => _skip += _pageSize);
            _fetch();
          },
        ),
      ],
    );
  }

  Widget _batchCard(PharmacyInventoryBatchRow row) {
    final theme = Theme.of(context);
    final expiry = row.expiryDate == null
        ? 'No expiry'
        : DateFormatter.shortDate(row.expiryDate!);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => _openBatch(row),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeltyEllipsisText(
                text: row.drugName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              HeltyEllipsisText(
                text:
                    'Batch ${row.batchNumber.isEmpty ? '—' : row.batchNumber} · $expiry',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              HeltyEllipsisText(
                text:
                    '${_count.format(row.quantityRemaining)} left · ${_money.format(row.lineValueAtCost)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _batchTable(ThemeData theme) {
    final cs = theme.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        const minWidth = 820.0;
        final width = constraints.maxWidth < minWidth
            ? minWidth
            : constraints.maxWidth;
        final sheet = SizedBox(
          width: width,
          height: constraints.maxHeight,
          child: ListView.builder(
            itemCount: _page.rows.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Container(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      _head(theme, 'DRUG', 3),
                      const SizedBox(width: 12),
                      _head(theme, 'EXPIRY', 2),
                      const SizedBox(width: 12),
                      _head(theme, 'QTY', 1),
                      const SizedBox(width: 12),
                      _head(theme, 'VALUE', 2),
                    ],
                  ),
                );
              }
              final row = _page.rows[index - 1];
              final expiry = row.expiryDate == null
                  ? '—'
                  : DateFormatter.shortDate(row.expiryDate!);
              return Material(
                color: pharmacyZebra(cs, index),
                child: InkWell(
                  onTap: () => _openBatch(row),
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
                            text: row.drugName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(flex: 2, child: Text(expiry)),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: Text(_count.format(row.quantityRemaining)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Text(_money.format(row.lineValueAtCost)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
        if (constraints.maxWidth >= minWidth) return sheet;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: sheet,
        );
      },
    );
  }

  Widget _head(ThemeData theme, String label, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  void _openBatch(PharmacyInventoryBatchRow row) {
    final expiry = row.expiryDate == null
        ? '—'
        : DateFormatter.shortDate(row.expiryDate!);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.85;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                row.drugName,
                style: Theme.of(sheetContext).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _detail('Batch', row.batchNumber),
              _detail('Expiry', expiry),
              _detail('Location', row.locationName),
              _detail('Supplier', row.supplierName),
              _detail('Quantity', _count.format(row.quantityRemaining)),
              _detail('Unit cost', _money.format(row.unitCost)),
              _detail('Unit sell', _money.format(row.unitSellingPrice)),
              _detail('Value at cost', _money.format(row.lineValueAtCost)),
              _detail(
                'Value at selling',
                _money.format(row.lineValueAtSelling),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _detail(String label, String value) {
    final shown = value.trim().isEmpty ? '—' : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              shown,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
