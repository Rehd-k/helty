import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/widgets/date.filter.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/super_admin_preview_provider.dart';
import '../auth/pharmacy_permissions.dart';
import '../models/pharmacy_model.dart';
import '../models/pharmacy_reports_model.dart';
import '../services/pharmacy_head_dashboard_service.dart';
import '../services/pharmacy_reports_service.dart';
import '../services/pharmacy_service.dart';

@RoutePage()
class PharmacyHeadDashboardScreen extends ConsumerStatefulWidget {
  const PharmacyHeadDashboardScreen({super.key});

  @override
  ConsumerState<PharmacyHeadDashboardScreen> createState() =>
      _PharmacyHeadDashboardScreenState();
}

class _PharmacyHeadDashboardScreenState
    extends ConsumerState<PharmacyHeadDashboardScreen> {
  final PharmacyHeadDashboardService _service = PharmacyHeadDashboardService();
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

  DateTime? _fromDate;
  DateTime? _toDate;
  String _selectedPayer = 'All';
  bool _isLoading = true;
  String? _error;
  DateTime _lastUpdated = DateTime.now();
  PharmacyHeadDashboardData? _dashboard;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _loadStores();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
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

  Future<void> _fetchDashboard() async {
    if (_fromDate == null || _toDate == null) return;
    final query = PharmacyHeadDashboardQuery(
      fromDate: _fromDate!,
      toDate: _toDate!,
      storeId: _selectedStoreId,
      payerType: _selectedPayer,
    );
    final data = await _service.getDashboardData(query);
    if (!mounted) return;
    setState(() {
      _dashboard = data;
      _lastUpdated = DateTime.now();
    });
  }

  Future<void> _reload() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _fetchDashboard();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  NumberFormat get _money =>
      NumberFormat.currency(symbol: 'NGN ', decimalDigits: 0);

  NumberFormat get _count => NumberFormat.decimalPattern();

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(authProvider).staff;
    final preview = ref.watch(superAdminPreviewProvider);
    if (!isPharmacyHead(staff, preview)) {
      return _accessDenied();
    }

    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildHeader(theme),
              const SizedBox(height: 18),
              _buildFilterBar(theme),
              const SizedBox(height: 18),
              if (_isLoading && _dashboard == null)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null && _dashboard == null)
                _errorCard(_error!)
              else if (_dashboard != null)
                ..._buildBody(theme, _dashboard!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _accessDenied() {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Pharmacy Command'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'This dashboard is available to the head of pharmacy only.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pharmacy Command Center',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Sales, profit and inventory worth across all stores.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Text(
            'Updated ${DateFormat.Hm().format(_lastUpdated)}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar(ThemeData theme) {
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
            gradient: const LinearGradient(
              colors: [Color(0xFFEEF2FF), Color(0xFFF8FAFC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFDDE6FF)),
          ),
          child: Wrap(
            runSpacing: 10,
            spacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _storeDropdown(theme),
              _compactDropdown(
                value: _selectedPayer,
                items: _payerTypes,
                onChanged: (v) {
                  setState(() => _selectedPayer = v);
                  _reload();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _storeDropdown(ThemeData theme) {
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('All stores')),
      ..._storeLocations.map(
        (s) => DropdownMenuItem<String?>(value: s.id, child: Text(s.name)),
      ),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedStoreId,
          items: items,
          onChanged: (v) {
            setState(() => _selectedStoreId = v);
            _reload();
          },
        ),
      ),
    );
  }

  Widget _compactDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }

  List<Widget> _buildBody(ThemeData theme, PharmacyHeadDashboardData data) {
    final summary = data.summary;
    return [
      if (summary.profitUnknownCount > 0) ...[
        _profitUnknownNotice(summary.profitUnknownCount),
        const SizedBox(height: 12),
      ],
      _sectionHeader(theme, 'Executive summary'),
      const SizedBox(height: 12),
      _buildKpiGrid(theme, summary),
      const SizedBox(height: 24),
      _sectionHeader(theme, 'Sales & profit trend'),
      const SizedBox(height: 12),
      _salesProfitCard(theme, data.salesProfitTrend),
      const SizedBox(height: 24),
      _sectionHeader(theme, 'Inventory worth by store'),
      const SizedBox(height: 12),
      _storeValuationList(theme, data.storeValuations),
      const SizedBox(height: 24),
      _sectionHeader(theme, 'Quick actions'),
      const SizedBox(height: 12),
      _quickActions(theme),
      if (_error != null) ...[
        const SizedBox(height: 12),
        _errorCard(_error!),
      ],
    ];
  }

  Widget _sectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w800,
        color: const Color(0xFF1E293B),
      ),
    );
  }

  Widget _profitUnknownNotice(int count) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFC2410C), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_count.format(count)} historical sale line(s) predate batch-cost '
              'tracking and are excluded from profit figures.',
              style: const TextStyle(color: Color(0xFF9A3412), fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(ThemeData theme, PharmacyHeadSummary s) {
    final tiles = <_HeadKpi>[
      _HeadKpi(
        'Total Sales',
        _money.format(s.totalSales),
        const Color(0xFF8B5CF6),
        Icons.point_of_sale_rounded,
        onTap: () => _openSales(PharmacySalesGroupBy.drug),
      ),
      _HeadKpi(
        'Quantity Sold',
        _count.format(s.totalQuantitySold),
        const Color(0xFF3B82F6),
        Icons.inventory_rounded,
        onTap: () => _openSales(PharmacySalesGroupBy.drug),
      ),
      _HeadKpi(
        'Gross Profit',
        _money.format(s.grossProfit),
        const Color(0xFF10B981),
        Icons.trending_up_rounded,
        onTap: () => _openSales(PharmacySalesGroupBy.drug),
      ),
      _HeadKpi(
        'Gross Margin',
        '${s.grossMarginPercent.toStringAsFixed(1)}%',
        const Color(0xFF059669),
        Icons.percent_rounded,
      ),
      _HeadKpi(
        'Cost of Goods Sold',
        _money.format(s.totalCogs),
        const Color(0xFFF97316),
        Icons.local_shipping_rounded,
      ),
      _HeadKpi(
        'Net Collections',
        _money.format(s.netCollections),
        const Color(0xFF6366F1),
        Icons.payments_rounded,
        onTap: () => context.router.push(DispenseHistoryRoute()),
      ),
      _HeadKpi(
        'Transactions',
        _count.format(s.transactionCount),
        const Color(0xFF0EA5E9),
        Icons.receipt_long_rounded,
        onTap: () => context.router.push(DispenseHistoryRoute()),
      ),
      _HeadKpi(
        'Avg Profit / Txn',
        _money.format(s.avgProfitPerTransaction),
        const Color(0xFF14B8A6),
        Icons.calculate_rounded,
      ),
      _HeadKpi(
        'Inventory at Cost',
        _money.format(s.inventoryValueAtCost),
        const Color(0xFF4F46E5),
        Icons.warehouse_rounded,
        onTap: () => context.router.push(PharmacyInventoryValuationRoute()),
      ),
      _HeadKpi(
        'Inventory at Selling',
        _money.format(s.inventoryValueAtSellingPrice),
        const Color(0xFF7C3AED),
        Icons.sell_rounded,
        onTap: () => context.router.push(PharmacyInventoryValuationRoute()),
      ),
      _HeadKpi(
        'Near-Expiry Value',
        _money.format(s.nearExpiryValueAtCost),
        const Color(0xFFF59E0B),
        Icons.timelapse_rounded,
        onTap: () => context.router.push(PharmacyInventoryValuationRoute()),
      ),
      _HeadKpi(
        'Low / Out of Stock',
        '${_count.format(s.lowStockCount)} / ${_count.format(s.outOfStockCount)}',
        const Color(0xFFEF4444),
        Icons.warning_amber_rounded,
        onTap: () => context.router.push(const MedicineInventoryRoute()),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1100
            ? 4
            : width >= 760
            ? 3
            : width >= 480
            ? 2
            : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tiles.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.1,
          ),
          itemBuilder: (context, i) => _kpiCard(theme, tiles[i]),
        );
      },
    );
  }

  Widget _kpiCard(ThemeData theme, _HeadKpi kpi) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kpi.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(kpi.icon, color: kpi.color, size: 18),
              ),
              const Spacer(),
              if (kpi.onTap != null)
                const Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
            ],
          ),
          Text(
            kpi.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          Text(
            kpi.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
    if (kpi.onTap == null) return card;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: kpi.onTap,
      child: card,
    );
  }

  Widget _salesProfitCard(
    ThemeData theme,
    List<PharmacySalesProfitPoint> points,
  ) {
    if (points.isEmpty) {
      return _emptyCard('No sales in this period.');
    }

    final maxV = points
        .map((p) => p.grossSales)
        .fold<double>(0, (a, b) => a > b ? a : b);
    final maxY = maxV <= 0 ? 1.0 : maxV * 1.15;

    LineChartBarData line(
      double Function(PharmacySalesProfitPoint) sel,
      Color color,
    ) {
      return LineChartBarData(
        spots: [
          for (var i = 0; i < points.length; i++)
            FlSpot(i.toDouble(), sel(points[i])),
        ],
        isCurved: true,
        color: color,
        barWidth: 3,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _legendDot(const Color(0xFF8B5CF6), 'Sales'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFFF97316), 'COGS'),
              const SizedBox(width: 16),
              _legendDot(const Color(0xFF10B981), 'Profit'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                maxY: maxY,
                minY: 0,
                gridData: const FlGridData(show: true, drawVerticalLine: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 44),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: (points.length / 6).ceilToDouble().clamp(
                        1,
                        9999,
                      ),
                      getTitlesWidget: (v, _) {
                        final i = v.toInt();
                        if (i < 0 || i >= points.length) {
                          return const SizedBox.shrink();
                        }
                        final label = points[i].label;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            label.length > 6
                                ? label.substring(label.length - 5)
                                : label,
                            style: const TextStyle(fontSize: 9),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                ),
                lineBarsData: [
                  line((p) => p.grossSales, const Color(0xFF8B5CF6)),
                  line((p) => p.cogs, const Color(0xFFF97316)),
                  line((p) => p.grossProfit, const Color(0xFF10B981)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _storeValuationList(
    ThemeData theme,
    List<PharmacyInventoryStoreValuation> stores,
  ) {
    if (stores.isEmpty) {
      return _emptyCard('No store valuation available.');
    }
    return Column(
      children: [
        for (final store in stores)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.router.push(
                PharmacyInventoryValuationRoute(locationId: store.locationId),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
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
                            store.locationName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: Color(0xFF94A3B8),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 20,
                      runSpacing: 10,
                      children: [
                        _valueChip(
                          'At cost',
                          _money.format(store.valueAtCost),
                          const Color(0xFF4F46E5),
                        ),
                        _valueChip(
                          'At selling',
                          _money.format(store.valueAtSellingPrice),
                          const Color(0xFF7C3AED),
                        ),
                        _valueChip(
                          'Batches',
                          _count.format(store.batchCount),
                          const Color(0xFF0EA5E9),
                        ),
                        _valueChip(
                          'Units',
                          _count.format(store.totalQuantity),
                          const Color(0xFF3B82F6),
                        ),
                        _valueChip(
                          'Near-expiry',
                          _money.format(store.nearExpiryValueAtCost),
                          const Color(0xFFF59E0B),
                        ),
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

  Widget _valueChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
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

  Widget _quickActions(ThemeData theme) {
    final actions = <_Action>[
      _Action('Reports hub', Icons.assessment_rounded,
          const PharmacyReportsHubRoute()),
      _Action('Sales breakdown', Icons.pie_chart_outline_rounded,
          PharmacySalesBreakdownRoute()),
      _Action('Inventory valuation', Icons.warehouse_rounded,
          PharmacyInventoryValuationRoute()),
      _Action('Dispense history', Icons.receipt_long_outlined,
          DispenseHistoryRoute()),
      _Action('Supply history', Icons.list_alt_outlined,
          const SupplyHistoryRoute()),
      _Action('Stock transfer', Icons.move_to_inbox_outlined,
          const StockTransferRoute()),
      _Action('Create requisition', Icons.note_add_outlined,
          const CreateRequisitionRoute()),
      _Action('Medicine inventory', Icons.inventory_2_outlined,
          const MedicineInventoryRoute()),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 4
            : constraints.maxWidth >= 480
            ? 3
            : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: actions.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
          ),
          itemBuilder: (context, i) {
            final a = actions[i];
            return InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.router.push(a.route),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(a.icon, color: const Color(0xFF4338CA), size: 22),
                    const Spacer(),
                    Text(
                      a.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openSales(PharmacySalesGroupBy groupBy) {
    context.router.push(PharmacySalesBreakdownRoute(initialGroupBy: groupBy));
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
}

class _HeadKpi {
  const _HeadKpi(this.label, this.value, this.color, this.icon, {this.onTap});

  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final VoidCallback? onTap;
}

class _Action {
  const _Action(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final PageRouteInfo route;
}
