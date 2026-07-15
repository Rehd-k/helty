import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/billing_analytics_models.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/api_service.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/services/billing_analytics_service.dart';
import 'patient_invoice.dart';

@RoutePage()
class BillingDashboardScreen extends ConsumerStatefulWidget {
  const BillingDashboardScreen({super.key});

  @override
  ConsumerState<BillingDashboardScreen> createState() =>
      _BillingDashboardScreenState();
}

class _BillingDashboardScreenState
    extends ConsumerState<BillingDashboardScreen> {
  String _selectedPeriod = 'Today';
  final TextEditingController _searchController = TextEditingController();
  final ApiService apiService = ApiService();
  final BillingAnalyticsService _analytics = BillingAnalyticsService();

  final TextEditingController firstName = TextEditingController();
  final TextEditingController surname = TextEditingController();
  final TextEditingController age = TextEditingController();
  final TextEditingController gender = TextEditingController();
  final TextEditingController wardId = TextEditingController();

  bool _loading = false;
  String? _error;
  DateTime? _lastLoadedAt;

  RevenueSummary? _revenue;
  UnpaidSummary? _unpaid;
  OverdueSummary? _overdue;
  RevenueSeries? _revenueSeries;
  RevenueByDepartment? _revenueByDept;
  List<RecentInvoiceRow> _recentInvoices = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!canViewBillingAnalyticsDashboard(ref.read(authProvider).staff)) {
        context.router.replace(const PendingBillsRoute());
        return;
      }
      _loadDashboard();
    });
  }

  Future<void> _loadDashboard() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final asOf = DateTime.now();
    final period = _apiPeriod(_selectedPeriod);
    try {
      final results = await Future.wait<Object>([
        _analytics.getRevenueSummary(period: period, asOf: asOf),
        _analytics.getUnpaidSummary(period: period, asOf: asOf),
        _analytics.getOverdueSummary(period: period, asOf: asOf),
        _analytics.getRevenueSeries(period: period, asOf: asOf),
        _analytics.getRevenueByDepartment(period: period, asOf: asOf),
        _analytics.getRecentInvoices(period: period, asOf: asOf, take: 20),
      ]);
      if (!mounted) return;
      setState(() {
        _revenue = results[0] as RevenueSummary;
        _unpaid = results[1] as UnpaidSummary;
        _overdue = results[2] as OverdueSummary;
        _revenueSeries = results[3] as RevenueSeries;
        _revenueByDept = results[4] as RevenueByDepartment;
        _recentInvoices = (results[5] as RecentInvoicesResponse).items.toList();
        _lastLoadedAt = DateTime.now();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_error!)));
    }
  }

  void createNewPatient() async {
    if (wardId.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a ward')));
      return;
    }
    try {
      var res = await apiService.dio.post(
        '/no-id-patient',
        data: {
          'firstName': firstName.text,
          'surname': surname.text,
          'age': age.text,
          'gender': gender.text,
          'wardId': wardId.text.trim(),
        },
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Patient created successfully')),
        );
      }
      firstName.clear();
      surname.clear();
      age.clear();
      gender.clear();
      wardId.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    firstName.dispose();
    surname.dispose();
    age.dispose();
    gender.dispose();
    wardId.dispose();
    super.dispose();
  }

  String _apiPeriod(String ui) {
    switch (ui) {
      case 'Today':
        return 'today';
      case 'This Week':
        return 'week';
      case 'This Month':
        return 'month';
      case 'This Quarter':
        return 'quarter';
      case 'This Year':
        return 'year';
      default:
        return 'month';
    }
  }

  String _revenueChartSubtitle() {
    switch (_selectedPeriod) {
      case 'Today':
        return 'By 4-hour segments (today)';
      case 'This Week':
        return 'Daily (Mon–Sun)';
      case 'This Month':
        return 'Four segments (this month)';
      case 'This Quarter':
        return 'By month in quarter';
      case 'This Year':
        return 'Bi-monthly buckets';
      default:
        return 'Cash in (current period)';
    }
  }

  String _vsPreviousLabel() {
    switch (_selectedPeriod) {
      case 'Today':
        return 'vs yesterday';
      case 'This Week':
        return 'vs prior week';
      case 'This Month':
        return 'vs prior month';
      case 'This Quarter':
        return 'vs prior quarter';
      case 'This Year':
        return 'vs prior year';
      default:
        return 'vs previous period';
    }
  }

  String _formatPercentChange(double pct, String direction) {
    if (direction == 'flat') return '0%';
    final abs = pct.abs();
    final s = abs >= 10 ? abs.toStringAsFixed(0) : abs.toStringAsFixed(2);
    if (direction == 'down') return '-$s%';
    return '+$s%';
  }

  Color _statusColor(String status, ColorScheme scheme) {
    final s = status.toUpperCase();
    if (s.contains('PAID')) return Colors.green;
    if (s.contains('PARTIAL')) return Colors.orange;
    if (s.contains('PEND')) return Colors.orange;
    if (s.contains('CANCEL')) return Colors.grey;
    return scheme.primary;
  }

  String _shortInvoiceId(String id) {
    if (id.length <= 12) return id;
    return '${id.substring(0, 8)}…';
  }

  List<RecentInvoiceRow> get _filteredRecent {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return _recentInvoices;
    return _recentInvoices.where((r) {
      return r.patientName.toLowerCase().contains(q) ||
          r.invoiceId.toLowerCase().contains(q) ||
          r.status.toLowerCase().contains(q);
    }).toList();
  }

  static const List<Color> _piePalette = [
    Color(0xFF1565C0),
    Color(0xFF42A5F5),
    Color(0xFF90CAF9),
    Color(0xFF546E7A),
    Color(0xFF7E57C2),
    Color(0xFF26A69A),
    Color(0xFFFFA726),
    Color(0xFF78909C),
  ];

  /// All endpoints succeeded and assigned (see [_loadDashboard]).
  bool get _hasFullDashboardData =>
      _revenue != null &&
      _unpaid != null &&
      _overdue != null &&
      _revenueSeries != null &&
      _revenueByDept != null;

  @override
  Widget build(BuildContext context) {
    if (!canViewBillingAnalyticsDashboard(ref.watch(authProvider).staff)) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final colorScheme = Theme.of(context).colorScheme;

    // Failed first load (or no cached data): show error — not the loading branch.
    if (!_hasFullDashboardData && _error != null) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _loadDashboard,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Initial frame (before post-frame callback), in-flight fetch, or incomplete data.
    if (!_hasFullDashboardData) {
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                'Loading billing analytics…',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final revenue = _revenue!;
    final unpaid = _unpaid!;
    final overdue = _overdue!;
    final series = _revenueSeries!;
    final byDept = _revenueByDept!;

    final revenuePct = _formatPercentChange(
      revenue.percentChange,
      revenue.direction,
    );
    final revenueNeutral = revenue.direction == 'flat';

    final unpaidPct = _formatPercentChange(
      unpaid.outstandingAmount.percentChange,
      unpaid.outstandingAmount.direction,
    );
    final unpaidNeutral = unpaid.outstandingAmount.direction == 'flat';

    final overdueTrend =
        overdue.newOverdueAmountTrend ?? overdue.newOverdueInvoiceTrend;
    String overduePct;
    bool overdueNeutral;
    if (overdueTrend != null) {
      overduePct = _formatPercentChange(
        overdueTrend.percentChange,
        overdueTrend.direction,
      );
      overdueNeutral = overdueTrend.direction == 'flat';
    } else {
      overduePct = '—';
      overdueNeutral = true;
    }

    final points = series.points;
    final maxYRaw = series.maxRevenue > 0
        ? series.maxRevenue
        : (points.isEmpty
              ? 1.0
              : points.map((p) => p.revenue).reduce(math.max));
    final maxY = maxYRaw <= 0 ? 1.0 : maxYRaw * 1.12;
    final spots = points.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.revenue);
    }).toList();
    final chartMaxX = spots.isEmpty
        ? 1.0
        : math.max(1.0, (spots.length - 1).toDouble());

    final slices = byDept.slices;
    final pieTotal = byDept.total;

    final filteredRecent = _filteredRecent;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ResponsiveBody(
        center: false,
        expand: false,
        builder: (context, bp) {
          final sectionGap = bp.isMobile ? 16.0 : 24.0;

          return Stack(
            children: [
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(bp, colorScheme),
                    SizedBox(height: sectionGap),
                    _buildToolbar(bp, colorScheme),
                    SizedBox(height: sectionGap),
                    _buildKpiSection(
                      bp,
                      context,
                      revenue: revenue,
                      revenuePct: revenuePct,
                      revenueNeutral: revenueNeutral,
                      unpaid: unpaid,
                      unpaidPct: unpaidPct,
                      unpaidNeutral: unpaidNeutral,
                      overdue: overdue,
                      overduePct: overduePct,
                      overdueNeutral: overdueNeutral,
                    ),
                    SizedBox(height: sectionGap),
                    _buildChartsSection(
                      bp,
                      colorScheme: colorScheme,
                      spots: spots,
                      points: points,
                      maxY: maxY,
                      chartMaxX: chartMaxX,
                      slices: slices,
                      pieTotal: pieTotal,
                    ),
                    SizedBox(height: sectionGap),
                    _buildRecentInvoicesSection(
                      bp,
                      colorScheme: colorScheme,
                      filteredRecent: filteredRecent,
                    ),
                  ],
                ),
              ),
              if (_loading && _hasFullDashboardData)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LinearProgressIndicator(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    color: colorScheme.primary,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(AppBreakpoints bp, ColorScheme colorScheme) {
    final title = Text(
      'Billing Overview',
      style: TextStyle(
        fontSize: bp.isMobile ? 20 : 24,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
      ),
    );

    final searchAndNotify = Row(
      children: [
        Expanded(child: _buildSearchField(colorScheme)),
        const SizedBox(width: 12),
        _buildNotificationButton(colorScheme),
      ],
    );

    if (bp.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [title, const SizedBox(height: 12), searchAndNotify],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        title,
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: searchAndNotify,
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(ColorScheme colorScheme) {
    return SizedBox(
      height: 40,
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: 'Search invoices, patients...',
          hintStyle: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          filled: true,
          fillColor: colorScheme.onSurface.withValues(alpha: 0.03),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationButton(ColorScheme colorScheme) {
    return IconButton(
      icon: const Icon(Icons.notifications_outlined),
      onPressed: () {},
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.onSurface.withValues(alpha: 0.03),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildToolbar(AppBreakpoints bp, ColorScheme colorScheme) {
    final lastUpdated = InkWell(
      onTap: _loading ? null : _loadDashboard,
      borderRadius: BorderRadius.circular(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Last updated: ',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          Flexible(
            child: Text(
              _lastLoadedAt != null
                  ? DateFormatter.dateTime(_lastLoadedAt!)
                  : '—',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.refresh,
            size: 14,
            color: _loading ? colorScheme.outline : colorScheme.primary,
          ),
        ],
      ),
    );

    final periodDropdown = _buildPeriodDropdown(colorScheme);
    final newPatientButton = _buildNewPatientButton(
      colorScheme,
      fullWidth: bp.isMobile,
    );

    if (bp.isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          lastUpdated,
          const SizedBox(height: 12),
          Row(children: [periodDropdown, const Spacer()]),
          const SizedBox(height: 12),
          newPatientButton,
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        lastUpdated,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            periodDropdown,
            const SizedBox(width: 12),
            newPatientButton,
          ],
        ),
      ],
    );
  }

  Widget _buildPeriodDropdown(ColorScheme colorScheme) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedPeriod,
          icon: Icon(
            Icons.keyboard_arrow_down,
            size: 16,
            color: colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          style: TextStyle(fontSize: 13, color: colorScheme.onSurface),
          items:
              const [
                'Today',
                'This Week',
                'This Month',
                'This Quarter',
                'This Year',
              ].map((period) {
                return DropdownMenuItem(value: period, child: Text(period));
              }).toList(),
          onChanged: _loading
              ? null
              : (val) {
                  if (val == null) return;
                  setState(() => _selectedPeriod = val);
                  _loadDashboard();
                },
        ),
      ),
    );
  }

  Widget _buildNewPatientButton(
    ColorScheme colorScheme, {
    bool fullWidth = false,
  }) {
    final button = ElevatedButton.icon(
      onPressed: () => showNewPatientInvoiceForm(
        context,
        firstName,
        surname,
        age,
        gender,
        wardId,
        createNewPatient,
      ),
      icon: const Icon(Icons.add, size: 16, color: Colors.white),
      label: const Text(
        'New Patient',
        style: TextStyle(color: Colors.white, fontSize: 13),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      ),
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }

  Widget _buildKpiSection(
    AppBreakpoints bp,
    BuildContext context, {
    required RevenueSummary revenue,
    required String revenuePct,
    required bool revenueNeutral,
    required UnpaidSummary unpaid,
    required String unpaidPct,
    required bool unpaidNeutral,
    required OverdueSummary overdue,
    required String overduePct,
    required bool overdueNeutral,
  }) {
    final cards = [
      _buildKpiCard(
        context,
        'Total revenue (${_selectedPeriod.toLowerCase()})',
        revenue.current.toFinancial(isMoney: true),
        revenuePct,
        _vsPreviousLabel(),
        Icons.payments,
        Colors.green,
        trendNeutral: revenueNeutral,
      ),
      _buildKpiCard(
        context,
        'Open unpaid invoices',
        unpaid.openStock.invoiceCount.toFinancial(isMoney: false),
        unpaidPct,
        _vsPreviousLabel(),
        Icons.receipt_long,
        Colors.orange,
        subtitleExtra:
            '(${unpaid.openStock.outstandingTotal.toFinancial(isMoney: true)} outstanding)',
        trendNeutral: unpaidNeutral,
      ),
      _buildKpiCard(
        context,
        'Overdue (>30d)',
        overdue.overdueStock.outstandingTotal.toFinancial(isMoney: true),
        overduePct,
        _vsPreviousLabel(),
        Icons.warning_amber_rounded,
        Colors.red,
        subtitleExtra: '(${overdue.overdueStock.invoiceCount} invoices)',
        trendNeutral: overdueNeutral,
      ),
    ];

    return ResponsiveWrapGrid(
      mobileColumns: 1,
      tabletColumns: 2,
      desktopColumns: 3,
      spacing: bp.kpiSpacing,
      runSpacing: bp.kpiSpacing,
      children: cards,
    );
  }

  Widget _buildChartsSection(
    AppBreakpoints bp, {
    required ColorScheme colorScheme,
    required List<FlSpot> spots,
    required List<RevenueSeriesPoint> points,
    required double maxY,
    required double chartMaxX,
    required List<DepartmentSlice> slices,
    required double pieTotal,
  }) {
    final chartHeight = bp.chartHeight;
    final revenueChart = _buildRevenueChartCard(
      colorScheme: colorScheme,
      height: chartHeight,
      spots: spots,
      points: points,
      maxY: maxY,
      chartMaxX: chartMaxX,
    );
    final deptChart = _buildDeptChartCard(
      colorScheme: colorScheme,
      height: bp.isDesktop ? chartHeight : null,
      slices: slices,
      pieTotal: pieTotal,
    );

    if (bp.isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 5, child: revenueChart),
          SizedBox(width: bp.isMobile ? 16 : 24),
          Expanded(flex: 3, child: deptChart),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        revenueChart,
        SizedBox(height: bp.kpiSpacing),
        deptChart,
      ],
    );
  }

  Widget _buildRevenueChartCard({
    required ColorScheme colorScheme,
    required double height,
    required List<FlSpot> spots,
    required List<RevenueSeriesPoint> points,
    required double maxY,
    required double chartMaxX,
  }) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue Trends',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _revenueChartSubtitle(),
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              _buildLegendIndicator(colorScheme.primary, 'Cash in'),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: spots.isEmpty
                ? Center(
                    child: Text(
                      'No revenue data for this period',
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (value) => FlLine(
                          color: colorScheme.outline.withValues(alpha: 0.1),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final i = value.round().clamp(
                                0,
                                points.length - 1,
                              );
                              final label = points.isNotEmpty
                                  ? points[i].label
                                  : '';
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 48,
                            interval: maxY / 4,
                            getTitlesWidget: (value, meta) {
                              if (value <= 0) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                value.toFinancial(isMoney: true),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: chartMaxX,
                      minY: 0,
                      maxY: maxY,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: colorScheme.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: colorScheme.primary.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  double _deptChartDisplayTotal(List<DepartmentSlice> slices, double pieTotal) {
    if (slices.isEmpty) return pieTotal;
    final sliceSum = slices.fold<double>(0, (sum, slice) => sum + slice.amount);
    return sliceSum > 0 ? sliceSum : pieTotal;
  }

  Widget _buildDeptChartCard({
    required ColorScheme colorScheme,
    double? height,
    required List<DepartmentSlice> slices,
    required double pieTotal,
  }) {
    final displayTotal = _deptChartDisplayTotal(slices, pieTotal);
    final legend = slices.isNotEmpty ? _buildDeptLegend(slices) : null;
    final pieAreaHeight = height != null ? null : 220.0;
    final outerRadius = height != null
        ? (height * 0.18).clamp(56.0, 80.0)
        : 72.0;
    final centerRadius = (outerRadius * 0.62).clamp(36.0, 50.0);

    final pie = slices.isEmpty
        ? Center(
            child: Text(
              'No department breakdown',
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          )
        : Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(enabled: true),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: centerRadius,
                  sections: [
                    for (var i = 0; i < slices.length; i++)
                      PieChartSectionData(
                        color: _piePalette[i % _piePalette.length],
                        value: slices[i].amount > 0 ? slices[i].amount : 0.01,
                        title: '',
                        radius: outerRadius,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  Text(
                    displayTotal.toFinancial(isMoney: true),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ],
          );

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Revenue by Dept',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Invoice-based cash in (current period)',
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );

    if (height == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            header,
            const SizedBox(height: 24),
            SizedBox(height: pieAreaHeight, child: pie),
            if (legend != null) ...[const SizedBox(height: 16), legend],
          ],
        ),
      );
    }

    return Container(
      height: height,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(height: 24),
          Expanded(
            child: Column(
              children: [
                Expanded(child: pie),
                if (legend != null)
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.only(top: 8),
                      child: legend,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeptLegend(List<DepartmentSlice> slices) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: [
        for (var i = 0; i < slices.length; i++)
          _buildLegendIndicator(
            _piePalette[i % _piePalette.length],
            '${slices[i].name} (${slices[i].percent.toStringAsFixed(0)}%)',
          ),
      ],
    );
  }

  Widget _buildRecentInvoicesSection(
    AppBreakpoints bp, {
    required ColorScheme colorScheme,
    required List<RecentInvoiceRow> filteredRecent,
  }) {
    final tableContent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: colorScheme.onSurface.withValues(alpha: 0.01),
          child: _buildInvoiceTableHeader(colorScheme),
        ),
        Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
        if (filteredRecent.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                _recentInvoices.isEmpty
                    ? 'No recent invoices'
                    : 'No matches for your search',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredRecent.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: colorScheme.outline.withValues(alpha: 0.05),
            ),
            itemBuilder: (context, index) {
              return _buildInvoiceTableRow(
                colorScheme: colorScheme,
                row: filteredRecent[index],
              );
            },
          ),
        const SizedBox(height: 8),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent invoices',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${filteredRecent.length} shown',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colorScheme.outline.withValues(alpha: 0.2)),
          if (bp.isMobile)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: bp.tableMinWidth, child: tableContent),
            )
          else
            tableContent,
        ],
      ),
    );
  }

  Widget _buildInvoiceTableHeader(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text('STATUS', style: _tableHeaderStyle(colorScheme)),
        ),
        Expanded(
          flex: 3,
          child: Text('INVOICE ID', style: _tableHeaderStyle(colorScheme)),
        ),
        Expanded(
          flex: 4,
          child: Text('PATIENT NAME', style: _tableHeaderStyle(colorScheme)),
        ),
        Expanded(
          flex: 3,
          child: Text('DATE', style: _tableHeaderStyle(colorScheme)),
        ),
        Expanded(
          flex: 3,
          child: Text('AMOUNT', style: _tableHeaderStyle(colorScheme)),
        ),
      ],
    );
  }

  Widget _buildInvoiceTableRow({
    required ColorScheme colorScheme,
    required RecentInvoiceRow row,
  }) {
    final c = _statusColor(row.status, colorScheme);
    final dateStr = DateFormatter.medicalDate(row.date);

    final nameParts = row.patientName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: c,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      row.status,
                      style: TextStyle(
                        fontSize: 11,
                        color: c,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _shortInvoiceId(row.invoiceId),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Row(
              children: [
                PatientAvatar(
                  firstName: nameParts.isNotEmpty ? nameParts.first : null,
                  surname: nameParts.length > 1 ? nameParts.last : null,
                  size: 28,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.1),
                  foregroundColor: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    row.patientName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              dateStr,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.amount.toFinancial(isMoney: true),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context,
    String title,
    String value,
    String percent,
    String vsText,
    IconData icon,
    Color color, {
    String? subtitleExtra,
    bool isNegativeGood = false,
    bool trendNeutral = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final isIncrease = percent.startsWith('+');
    final isDecrease = percent.startsWith('-');
    Color trendColor;
    if (trendNeutral || percent == '—') {
      trendColor = Colors.grey;
    } else {
      trendColor =
          (isIncrease && !isNegativeGood) || (isDecrease && isNegativeGood)
          ? Colors.green
          : Colors.red;
    }

    IconData trendIcon;
    if (trendNeutral || percent == '—') {
      trendIcon = Icons.trending_flat;
    } else if (isIncrease) {
      trendIcon = Icons.trending_up;
    } else {
      trendIcon = Icons.trending_down;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              if (subtitleExtra != null) ...[
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    subtitleExtra,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Row(
                children: [
                  Icon(trendIcon, size: 14, color: trendColor),
                  const SizedBox(width: 4),
                  Text(
                    percent,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  vsText,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendIndicator(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  TextStyle _tableHeaderStyle(ColorScheme colorScheme) {
    return TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      letterSpacing: 0.5,
      color: colorScheme.onSurface.withValues(alpha: 0.5),
    );
  }
}
