import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pharmacy_dashboard_model.dart';
import '../models/pharmacy_model.dart';
import '../services/pharmacy_dashboard_service.dart';
import '../services/pharmacy_service.dart';

enum _DatePreset { today, last7Days, last30Days, thisMonth }

class _KpiMetric {
  const _KpiMetric({
    required this.label,
    required this.value,
    required this.color,
    this.isCurrency = false,
  });

  final String label;
  final num value;
  final Color color;
  final bool isCurrency;
}

@RoutePage()
class PharmacyDashboardScreen extends StatefulWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  State<PharmacyDashboardScreen> createState() => _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends State<PharmacyDashboardScreen> {
  final PharmacyDashboardService _service = PharmacyDashboardService();
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

  _DatePreset _selectedPreset = _DatePreset.last30Days;
  String _selectedPayer = 'All';
  bool _isLoading = true;
  String? _error;
  DateTime _lastUpdated = DateTime.now();
  PharmacyDashboardData? _dashboard;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Loads pharmacy store locations first, selects the first store by default, then fetches dashboard data.
  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await _loadStores();
      await _fetchDashboard();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    setState(() {
      _storeLocations = stores;
      if (_storeLocations.isEmpty) {
        _selectedStoreId = null;
      } else if (_selectedStoreId == null ||
          !_storeLocations.any((s) => s.id == _selectedStoreId)) {
        _selectedStoreId = _storeLocations.first.id;
      }
    });
  }

  Future<void> _fetchDashboard() async {
    final range = _resolveDateRange(_selectedPreset);
    final query = PharmacyDashboardQuery(
      fromDate: range.$1,
      toDate: range.$2,
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

  Future<void> _loadDashboard() async {
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  (DateTime, DateTime) _resolveDateRange(_DatePreset preset) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (preset) {
      case _DatePreset.today:
        final start = DateTime(now.year, now.month, now.day);
        return (start, end);
      case _DatePreset.last7Days:
        final start = DateTime(now.year, now.month, now.day).subtract(
          const Duration(days: 6),
        );
        return (start, end);
      case _DatePreset.last30Days:
        final start = DateTime(now.year, now.month, now.day).subtract(
          const Duration(days: 29),
        );
        return (start, end);
      case _DatePreset.thisMonth:
        final start = DateTime(now.year, now.month, 1);
        return (start, end);
    }
  }

  List<_KpiMetric> _buildKpis(PharmacyDashboardSummary summary) {
    return [
      _KpiMetric(
        label: 'Prescriptions Processed',
        value: summary.prescriptionsProcessed,
        color: const Color(0xFF10B981),
      ),
      _KpiMetric(
        label: 'Pending Orders',
        value: summary.pendingOrders,
        color: const Color(0xFFF59E0B),
      ),
      _KpiMetric(
        label: 'Dispensed Orders',
        value: summary.dispensedOrders,
        color: const Color(0xFF3B82F6),
      ),
      _KpiMetric(
        label: 'Pharmacy Revenue',
        value: summary.revenue,
        color: const Color(0xFF8B5CF6),
        isCurrency: true,
      ),
      _KpiMetric(
        label: 'Inventory Value',
        value: summary.inventoryValue,
        color: const Color(0xFF6366F1),
        isCurrency: true,
      ),
      _KpiMetric(
        label: 'Low Stock Drugs',
        value: summary.lowStockCount,
        color: const Color(0xFFF59E0B),
      ),
      _KpiMetric(
        label: 'Out-of-Stock Drugs',
        value: summary.outOfStockCount,
        color: const Color(0xFFEF4444),
      ),
      _KpiMetric(
        label: 'Near-Expiry Drugs',
        value: summary.nearExpiryCount,
        color: const Color(0xFFF59E0B),
      ),
      _KpiMetric(
        label: 'Expired Drugs',
        value: summary.expiredCount,
        color: const Color(0xFFDC2626),
      ),
    ];
  }

  String _formatValue(num value, {bool isCurrency = false}) {
    if (isCurrency) {
      return NumberFormat.currency(symbol: 'NGN ', decimalDigits: 0).format(value);
    }
    return NumberFormat.decimalPattern().format(value);
  }

  String _presetLabel(_DatePreset preset) {
    switch (preset) {
      case _DatePreset.today:
        return 'Today';
      case _DatePreset.last7Days:
        return 'Last 7 Days';
      case _DatePreset.last30Days:
        return 'Last 30 Days';
      case _DatePreset.thisMonth:
        return 'This Month';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _bootstrap,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildHeader(theme),
              const SizedBox(height: 18),
              _buildFilterBar(theme),
              const SizedBox(height: 18),
              if (_isLoading && _dashboard == null)
                const Center(child: CircularProgressIndicator())
              else if (_error != null && _dashboard == null)
                _errorCard(_error!)
              else if (_dashboard != null)
                ..._buildDashboardBody(theme, _dashboard!),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDashboardBody(ThemeData theme, PharmacyDashboardData data) {
    return [
      _buildKpiGrid(theme, _buildKpis(data.summary)),
      const SizedBox(height: 18),
      _buildOperationsRow(theme, data),
      const SizedBox(height: 18),
      _buildBottomRow(theme, data),
      if (_error != null) ...[
        const SizedBox(height: 12),
        _errorCard(_error!),
      ],
    ];
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pharmacy Dashboard',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Live pharmacy operations, inventory and revenue insights.',
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
    return Container(
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
          ..._DatePreset.values.map(
            (preset) => ChoiceChip(
              selectedColor: const Color(0xFF4338CA),
              labelStyle: TextStyle(
                color: _selectedPreset == preset
                    ? Colors.white
                    : const Color(0xFF1E293B),
                fontWeight: FontWeight.w600,
              ),
              label: Text(_presetLabel(preset)),
              selected: _selectedPreset == preset,
              onSelected: (_) {
                setState(() => _selectedPreset = preset);
                _loadDashboard();
              },
            ),
          ),
          _storeDropdown(theme),
          _compactDropdown(
            value: _selectedPayer,
            items: _payerTypes,
            onChanged: (v) {
              setState(() => _selectedPayer = v);
              _loadDashboard();
            },
          ),
          FilledButton.icon(
            onPressed: _isLoading ? null : _loadDashboard,
            icon: _isLoading
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh, size: 16),
            label: Text(_isLoading ? 'Refreshing...' : 'Refresh'),
          ),
        ],
      ),
    );
  }

  Widget _storeDropdown(ThemeData theme) {
    if (_storeLocations.isEmpty) {
      return Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCBD5E1)),
        ),
        child: Text(
          'No stores',
          style: theme.textTheme.bodySmall?.copyWith(
            color: const Color(0xFF64748B),
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final validIds = _storeLocations.map((s) => s.id!).toList();
    final dropdownValue =
        _selectedStoreId != null && validIds.contains(_selectedStoreId)
            ? _selectedStoreId
            : validIds.first;

    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButton<String>(
        value: dropdownValue,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(12),
        items: _storeLocations
            .map(
              (loc) => DropdownMenuItem<String>(
                value: loc.id!,
                child: Text(loc.name),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) {
            setState(() => _selectedStoreId = v);
            _loadDashboard();
          }
        },
      ),
    );
  }

  Widget _compactDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox.shrink(),
        borderRadius: BorderRadius.circular(12),
        items: items
            .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  Widget _buildKpiGrid(ThemeData theme, List<_KpiMetric> kpis) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: kpis
          .map((kpi) => SizedBox(width: 260, child: _kpiCard(theme, kpi)))
          .toList(),
    );
  }

  Widget _kpiCard(ThemeData theme, _KpiMetric kpi) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kpi.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _formatValue(kpi.value, isCurrency: kpi.isCurrency),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: 1,
            color: kpi.color,
            backgroundColor: kpi.color.withValues(alpha: 0.15),
            minHeight: 6,
            borderRadius: BorderRadius.circular(10),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationsRow(ThemeData theme, PharmacyDashboardData data) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _panel(
            title: 'Order Status Breakdown',
            child: _statusBars(theme, data.orderStatuses),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: _panel(
            title: 'Top-Selling Medications',
            child: _topSellingTable(data.topSelling),
          ),
        ),
      ],
    );
  }

  Widget _statusBars(ThemeData theme, List<PharmacyOrderStatusItem> statuses) {
    if (statuses.isEmpty) {
      return const Text('No order status data available.');
    }
    final maxValue = statuses
        .map((e) => e.count)
        .fold<int>(0, (prev, curr) => curr > prev ? curr : prev);
    const colors = [
      Color(0xFFF59E0B),
      Color(0xFF0EA5E9),
      Color(0xFF10B981),
      Color(0xFFEF4444),
    ];

    return Column(
      children: statuses.asMap().entries.map((entry) {
        final idx = entry.key;
        final item = entry.value;
        final widthFactor = maxValue == 0 ? 0.0 : (item.count / maxValue);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.status,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    NumberFormat.decimalPattern().format(item.count),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF475569),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  minHeight: 10,
                  value: widthFactor,
                  color: colors[idx % colors.length],
                  backgroundColor: const Color(0xFFE2E8F0),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _topSellingTable(List<PharmacyTopSellingItem> rows) {
    if (rows.isEmpty) {
      return const Text('No top-selling medication data available.');
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF1F5F9)),
        columns: const [
          DataColumn(label: Text('Drug')),
          DataColumn(label: Text('Qty Sold')),
          DataColumn(label: Text('Revenue')),
          DataColumn(label: Text('Avg Price')),
          DataColumn(label: Text('Stock')),
        ],
        rows: rows
            .map(
              (drug) => DataRow(
                cells: [
                  DataCell(Text(drug.drugName)),
                  DataCell(Text(NumberFormat.decimalPattern().format(drug.quantitySold))),
                  DataCell(
                    Text(NumberFormat.currency(symbol: 'NGN ', decimalDigits: 0).format(drug.revenue)),
                  ),
                  DataCell(
                    Text(
                      NumberFormat.currency(symbol: 'NGN ', decimalDigits: 0).format(drug.avgSellingPrice),
                    ),
                  ),
                  DataCell(Text(NumberFormat.decimalPattern().format(drug.stockRemaining))),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildBottomRow(ThemeData theme, PharmacyDashboardData data) {
    final points = data.revenueTrend.map((e) => e.netRevenue).toList();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _panel(
            title: 'Revenue Trend (Net Revenue)',
            child: SizedBox(
              height: 170,
              child: points.length < 2
                  ? const Center(child: Text('No revenue trend data.'))
                  : CustomPaint(
                      painter: _SparklinePainter(
                        points: points,
                        color: const Color(0xFF4F46E5),
                        fillArea: true,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _panel(
            title: 'Safety & Compliance Alerts',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MiniAlertTile(
                  title: 'Total alerts',
                  value: data.safety.totalAlerts.toString(),
                  color: const Color(0xFFDC2626),
                ),
                const SizedBox(height: 10),
                _MiniAlertTile(
                  title: 'High-severity alerts',
                  value: data.safety.highSeverityAlerts.toString(),
                  color: const Color(0xFFB91C1C),
                ),
                const SizedBox(height: 10),
                _MiniAlertTile(
                  title: 'Overridden alerts',
                  value: data.safety.overriddenAlerts.toString(),
                  color: const Color(0xFFF59E0B),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _panel({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _errorCard(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF991B1B)),
      ),
    );
  }
}

class _MiniAlertTile extends StatelessWidget {
  const _MiniAlertTile({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({
    required this.points,
    required this.color,
    this.fillArea = false,
  });

  final List<double> points;
  final Color color;
  final bool fillArea;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final minPoint = points.reduce((a, b) => a < b ? a : b);
    final maxPoint = points.reduce((a, b) => a > b ? a : b);
    final range = (maxPoint - minPoint).abs() < 0.001 ? 1.0 : (maxPoint - minPoint);

    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = size.height - ((points[i] - minPoint) / range) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    if (fillArea) {
      final fillPath = Path.from(path)
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close();
      final fillPaint = Paint()
        ..color = color.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);
    }

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.fillArea != fillArea;
  }
}
