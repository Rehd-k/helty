import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:intl/intl.dart';
import 'package:helty/src/shared/department_colors.dart';
import 'package:helty/src/shared/module_surface_styles.dart';

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
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;

  static const int _pageSize = 50;
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

  // Batch drill-down state.
  bool _batchesLoading = false;
  PharmacyInventoryBatchPage _batches = PharmacyInventoryBatchPage.empty;
  int _batchSkip = 0;

  @override
  void initState() {
    super.initState();
    _focusLocationId = widget.locationId;
    _bootstrap();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _fetchSummary();
    if (_focusLocationId != null) {
      await _fetchBatches();
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

  Future<void> _fetchBatches() async {
    setState(() => _batchesLoading = true);
    try {
      final page = await _service.getInventoryValuationBatches(
        PharmacyValuationQuery(
          locationId: _focusLocationId,
          expiryWithinDays: _expiry.days,
          search: _searchCtrl.text,
          skip: _batchSkip,
          take: _pageSize,
        ),
      );
      if (!mounted) return;
      setState(() => _batches = page);
    } catch (_) {
      if (!mounted) return;
      setState(() => _batches = PharmacyInventoryBatchPage.empty);
    } finally {
      if (mounted) setState(() => _batchesLoading = false);
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _batchSkip = 0;
      _fetchBatches();
    });
  }

  void _focusStore(String? locationId) {
    setState(() {
      _focusLocationId = locationId;
      _batchSkip = 0;
      _batches = PharmacyInventoryBatchPage.empty;
      _searchCtrl.clear();
    });
    if (locationId != null) _fetchBatches();
  }

  NumberFormat get _money =>
      NumberFormat.currency(symbol: 'NGN ', decimalDigits: 0);
  NumberFormat get _count => NumberFormat.decimalPattern();
  DateFormat get _date => DateFormat('dd MMM yyyy');

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
        title: const Text('Inventory valuation'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _bootstrap,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ResponsiveBody(
        builder: (context, bp) => ListView(
          children: [
            _expiryBar(),
            const SizedBox(height: 16),
            if (_loading && _valuation.stores.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null && _valuation.stores.isEmpty)
              _errorCard(_error!)
            else ...[
              _totalsCard(theme),
              const SizedBox(height: 16),
              _storeList(theme),
              if (_focusLocationId != null) ...[
                const SizedBox(height: 20),
                _batchSection(theme),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _expiryBar() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Wrap(
      spacing: 8,
      children: _expiryFilters
          .map(
            (f) => ChoiceChip(
              label: Text(f.label),
              selected: _expiry.label == f.label,
              selectedColor: DepartmentColors.pharmacy,
              labelStyle: TextStyle(
                color: _expiry.label == f.label ? cs.onPrimary : cs.onSurface,
                fontWeight: FontWeight.w600,
              ),
              onSelected: (_) {
                setState(() {
                  _expiry = f;
                  _batchSkip = 0;
                });
                _fetchSummary();
                if (_focusLocationId != null) _fetchBatches();
              },
            ),
          )
          .toList(),
    );
  }

  Widget _totalsCard(ThemeData theme) {
    final t = _valuation.totals;
    final onGradient = theme.colorScheme.onPrimary;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DepartmentColors.pharmacy,
            DepartmentColors.pharmacy.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total inventory worth',
            style: theme.textTheme.bodySmall?.copyWith(
              color: onGradient.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _money.format(t.valueAtCost),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: onGradient,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'at cost · ${_money.format(t.valueAtSellingPrice)} at selling price',
            style: theme.textTheme.bodySmall?.copyWith(
              color: onGradient.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 22,
            runSpacing: 8,
            children: [
              _whiteChip('Batches', _count.format(t.batchCount)),
              _whiteChip('Units', _count.format(t.totalQuantity)),
              _whiteChip(
                'Near-expiry',
                _money.format(t.nearExpiryValueAtCost),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _whiteChip(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _storeList(ThemeData theme) {
    if (_valuation.stores.isEmpty) {
      return _emptyCard('No inventory found.');
    }
    return Column(
      children: [
        for (final s in _valuation.stores)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _focusStore(
                _focusLocationId == s.locationId ? null : s.locationId,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _focusLocationId == s.locationId
                        ? const Color(0xFF4F46E5)
                        : const Color(0xFFE2E8F0),
                    width: _focusLocationId == s.locationId ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.store_rounded,
                          size: 18,
                          color: Color(0xFF4F46E5),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            s.locationName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          s.locationType,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        Icon(
                          _focusLocationId == s.locationId
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: const Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: [
                        _chip('At cost', _money.format(s.valueAtCost),
                            const Color(0xFF4F46E5)),
                        _chip('At selling', _money.format(s.valueAtSellingPrice),
                            const Color(0xFF7C3AED)),
                        _chip('Batches', _count.format(s.batchCount),
                            const Color(0xFF0EA5E9)),
                        _chip('Units', _count.format(s.totalQuantity),
                            const Color(0xFF3B82F6)),
                        _chip('Near-expiry',
                            _money.format(s.nearExpiryValueAtCost),
                            const Color(0xFFF59E0B)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _chip(String label, String value, Color color) {
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
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _batchSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Batch detail',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _searchCtrl,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search drug',
            prefixIcon: const Icon(Icons.search),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_batchesLoading && _batches.rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_batches.rows.isEmpty)
          _emptyCard('No batches for this location.')
        else
          _batchTable(theme),
      ],
    );
  }

  Widget _batchTable(ThemeData theme) {
    return Column(
      children: [
        ResponsiveDataTable(
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Drug')),
              DataColumn(label: Text('Batch')),
              DataColumn(label: Text('Expiry')),
              DataColumn(label: Text('Qty'), numeric: true),
              DataColumn(label: Text('Unit cost'), numeric: true),
              DataColumn(label: Text('Value at cost'), numeric: true),
              DataColumn(label: Text('Supplier')),
            ],
            rows: [
              for (final b in _batches.rows)
                DataRow(
                  cells: [
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          b.drugName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(Text(b.batchNumber)),
                    DataCell(
                      Text(
                        b.expiryDate == null
                            ? '—'
                            : _date.format(b.expiryDate!),
                      ),
                    ),
                    DataCell(Text(_count.format(b.quantityRemaining))),
                    DataCell(Text(_money.format(b.unitCost))),
                    DataCell(Text(_money.format(b.lineValueAtCost))),
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          b.supplierName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        _batchPager(),
      ],
    );
  }

  Widget _batchPager() {
    final total = _batches.total;
    final start = total == 0 ? 0 : _batchSkip + 1;
    final end = (_batchSkip + _batches.rows.length).clamp(0, total);
    final canPrev = _batchSkip > 0;
    final canNext = _batchSkip + _pageSize < total;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            '$start–$end of ${_count.format(total)}',
            style: const TextStyle(color: Color(0xFF64748B)),
          ),
          const Spacer(),
          IconButton(
            onPressed: canPrev && !_batchesLoading
                ? () {
                    setState(() => _batchSkip -= _pageSize);
                    _fetchBatches();
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
          ),
          IconButton(
            onPressed: canNext && !_batchesLoading
                ? () {
                    setState(() => _batchSkip += _pageSize);
                    _fetchBatches();
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: ModuleSurfaceStyles.borderedSurface(theme, radius: 16),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
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
