import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
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
import '../services/pharmacy_head_dashboard_service.dart';
import '../services/pharmacy_reports_service.dart';
import '../services/pharmacy_service.dart';
import 'package:helty/src/shared/department_colors.dart';
import 'package:helty/src/shared/module_surface_styles.dart';

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
      backgroundColor: ModuleSurfaceStyles.departmentScaffoldBackground(
        theme,
        DepartmentColors.pharmacy,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _reload,
          child: ResponsiveBody(
            builder: (context, bp) => ListView(
              children: [
                _buildHeader(theme, bp),
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
                  ..._buildBody(theme, _dashboard!, bp),
              ],
            ),
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

  Widget _buildHeader(ThemeData theme, AppBreakpoints bp) {
    final updated = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: ModuleSurfaceStyles.borderedSurface(theme),
      child: Text(
        'Updated ${DateFormat.Hm().format(_lastUpdated)}',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
    final title = Column(
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
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
    if (bp.stackPanels) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 12),
          updated,
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: title),
        updated,
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
          padding: const EdgeInsets.all(12),
          decoration: ModuleSurfaceStyles.departmentFilterPanel(
            theme,
            DepartmentColors.pharmacy,
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
      decoration: ModuleSurfaceStyles.compactDropdown(theme),
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: ModuleSurfaceStyles.compactDropdown(theme),
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

  List<Widget> _buildBody(
    ThemeData theme,
    PharmacyHeadDashboardData data,
    AppBreakpoints bp,
  ) {
    final summary = data.summary;
    return [
      if (summary.profitUnknownCount > 0) ...[
        _profitUnknownNotice(summary.profitUnknownCount),
        const SizedBox(height: 12),
      ],
      _sectionHeader(theme, 'Executive summary'),
      const SizedBox(height: 12),
      _buildKpiGrid(theme, summary, bp),
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
      _quickActions(theme, bp),
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
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _profitUnknownNotice(int count) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ModuleSurfaceStyles.infoBanner(theme),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: cs.onTertiaryContainer, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${_count.format(count)} historical sale line(s) predate batch-cost '
              'tracking and are excluded from profit figures.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onTertiaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiGrid(
    ThemeData theme,
    PharmacyHeadSummary s,
    AppBreakpoints bp,
  ) {
    final tiles = <_HeadKpi>[
      _HeadKpi(
        'Total Sales',
        _money.format(s.totalSales),
        DepartmentColors.laboratory,
        Icons.point_of_sale_rounded,
        onTap: () => _openSales(PharmacySalesGroupBy.drug),
      ),
      _HeadKpi(
        'Quantity Sold',
        _count.format(s.totalQuantitySold),
        DepartmentColors.outpatientClinic,
        Icons.inventory_rounded,
        onTap: () => _openSales(PharmacySalesGroupBy.drug),
      ),
      _HeadKpi(
        'Gross Profit',
        _money.format(s.grossProfit),
        DepartmentColors.pharmacy,
        Icons.trending_up_rounded,
        onTap: () => _openSales(PharmacySalesGroupBy.drug),
      ),
      _HeadKpi(
        'Gross Margin',
        '${s.grossMarginPercent.toStringAsFixed(1)}%',
        DepartmentColors.physiotherapy,
        Icons.percent_rounded,
      ),
      _HeadKpi(
        'Cost of Goods Sold',
        _money.format(s.totalCogs),
        DepartmentColors.billing,
        Icons.local_shipping_rounded,
      ),
      _HeadKpi(
        'Net Collections',
        _money.format(s.netCollections),
        DepartmentColors.radiology,
        Icons.payments_rounded,
        onTap: () => context.router.push(DispenseHistoryRoute()),
      ),
      _HeadKpi(
        'Transactions',
        _count.format(s.transactionCount),
        DepartmentColors.pediatrics,
        Icons.receipt_long_rounded,
        onTap: () => context.router.push(DispenseHistoryRoute()),
      ),
      _HeadKpi(
        'Avg Profit / Txn',
        _money.format(s.avgProfitPerTransaction),
        DepartmentColors.frontDesk,
        Icons.calculate_rounded,
      ),
      _HeadKpi(
        'Inventory at Cost',
        _money.format(s.inventoryValueAtCost),
        DepartmentColors.itDepartment,
        Icons.warehouse_rounded,
        onTap: () => context.router.push(PharmacyInventoryValuationRoute()),
      ),
      _HeadKpi(
        'Inventory at Selling',
        _money.format(s.inventoryValueAtSellingPrice),
        DepartmentColors.eyeClinic,
        Icons.sell_rounded,
        onTap: () => context.router.push(PharmacyInventoryValuationRoute()),
      ),
      _HeadKpi(
        'Near-Expiry Value',
        _money.format(s.nearExpiryValueAtCost),
        DepartmentColors.accountingFinance,
        Icons.timelapse_rounded,
        onTap: () => context.router.push(PharmacyInventoryValuationRoute()),
      ),
      _HeadKpi(
        'Low / Out of Stock',
        '${_count.format(s.lowStockCount)} / ${_count.format(s.outOfStockCount)}',
        DepartmentColors.emergency,
        Icons.warning_amber_rounded,
        onTap: () => context.router.push(const MedicineInventoryRoute()),
      ),
    ];

    return ResponsiveWrapGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 4,
      spacing: bp.kpiSpacing,
      runSpacing: bp.kpiSpacing,
      children: tiles.map((kpi) => _kpiCard(theme, kpi)).toList(),
    );
  }

  Widget _kpiCard(ThemeData theme, _HeadKpi kpi) {
    final card = Container(
      padding: const EdgeInsets.all(12),
      decoration: ModuleSurfaceStyles.borderedSurface(theme, radius: 16),
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
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: theme.colorScheme.outline,
                ),
            ],
          ),
          Text(
            kpi.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          Text(
            kpi.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
      padding: const EdgeInsets.all(12),
      decoration: ModuleSurfaceStyles.borderedSurface(theme, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _legendDot(theme, DepartmentColors.laboratory, 'Sales'),
              const SizedBox(width: 16),
              _legendDot(theme, DepartmentColors.billing, 'COGS'),
              const SizedBox(width: 16),
              _legendDot(theme, DepartmentColors.pharmacy, 'Profit'),
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
                  line((p) => p.grossSales, DepartmentColors.laboratory),
                  line((p) => p.cogs, DepartmentColors.billing),
                  line((p) => p.grossProfit, DepartmentColors.pharmacy),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(ThemeData theme, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: theme.textTheme.labelSmall),
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
                padding: const EdgeInsets.all(12),
                decoration: ModuleSurfaceStyles.borderedSurface(theme, radius: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.store_rounded,
                          size: 18,
                          color: DepartmentColors.pharmacy,
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
                        Icon(
                          Icons.chevron_right_rounded,
                          color: theme.colorScheme.outline,
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
                          DepartmentColors.itDepartment,
                        ),
                        _valueChip(
                          'At selling',
                          _money.format(store.valueAtSellingPrice),
                          DepartmentColors.laboratory,
                        ),
                        _valueChip(
                          'Batches',
                          _count.format(store.batchCount),
                          DepartmentColors.pediatrics,
                        ),
                        _valueChip(
                          'Units',
                          _count.format(store.totalQuantity),
                          DepartmentColors.outpatientClinic,
                        ),
                        _valueChip(
                          'Near-expiry',
                          _money.format(store.nearExpiryValueAtCost),
                          DepartmentColors.accountingFinance,
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
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

  Widget _quickActions(ThemeData theme, AppBreakpoints bp) {
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
    return ResponsiveWrapGrid(
      mobileColumns: 2,
      tabletColumns: 3,
      desktopColumns: 4,
      spacing: 12,
      runSpacing: 12,
      children: actions.map((a) {
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.router.push(a.route),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: ModuleSurfaceStyles.borderedSurface(theme, radius: 14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(a.icon, color: DepartmentColors.pharmacy, size: 22),
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
      }).toList(),
    );
  }

  void _openSales(PharmacySalesGroupBy groupBy) {
    context.router.push(PharmacySalesBreakdownRoute(initialGroupBy: groupBy));
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
