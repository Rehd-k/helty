import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:intl/intl.dart';

import '../models/purchases_dashboard_model.dart';
import '../models/purchases_model.dart';
import '../services/purchases_dashboard_service.dart';
import '../services/purchases_service.dart';

enum _DatePreset { today, last7Days, last30Days, thisMonth }

@RoutePage()
class PurchasesDashboardScreen extends StatefulWidget {
  const PurchasesDashboardScreen({super.key});

  @override
  State<PurchasesDashboardScreen> createState() =>
      _PurchasesDashboardScreenState();
}

class _PurchasesDashboardScreenState extends State<PurchasesDashboardScreen> {
  final PurchasesDashboardService _service = PurchasesDashboardService();
  final PurchasesApiService _api = PurchasesApiService();

  List<PurchasesLocation> _stores = [];
  String? _selectedStoreId;
  _DatePreset _preset = _DatePreset.last30Days;
  bool _loading = true;
  String? _error;
  PurchasesDashboardData? _data;

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
      final locs = await _api.getLocations(
        const PurchasesQueryParams(pageSize: 100),
      );
      _stores = locs.items.where((l) => l.isActive).toList();
      _selectedStoreId = _stores.isNotEmpty ? _stores.first.id : null;
      await _refresh();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  (DateTime, DateTime) _range() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (_preset) {
      case _DatePreset.today:
        return (DateTime(now.year, now.month, now.day), end);
      case _DatePreset.last7Days:
        return (end.subtract(const Duration(days: 6)), end);
      case _DatePreset.last30Days:
        return (end.subtract(const Duration(days: 29)), end);
      case _DatePreset.thisMonth:
        return (DateTime(now.year, now.month, 1), end);
    }
  }

  Future<void> _refresh() async {
    final (from, to) = _range();
    final query = PurchasesDashboardQuery(
      fromDate: from,
      toDate: to,
      storeId: _selectedStoreId,
    );
    final data = await _service.getDashboardData(query);
    if (!mounted) return;
    setState(() => _data = data);
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency();
    final summary = _data?.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchases Dashboard'),
        actions: [
          TextButton.icon(
            onPressed: () => context.router.push(PurchasesUsageHistoryRoute()),
            icon: const Icon(Icons.history),
            label: const Text('Usage History'),
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _bootstrap),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ResponsiveBody(
              expand: false,
              builder: (context, bp) => SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  Wrap(
                    spacing: 8,
                    children: _DatePreset.values.map((p) {
                      final label = switch (p) {
                        _DatePreset.today => 'Today',
                        _DatePreset.last7Days => '7 days',
                        _DatePreset.last30Days => '30 days',
                        _DatePreset.thisMonth => 'This month',
                      };
                      return ChoiceChip(
                        label: Text(label),
                        selected: _preset == p,
                        onSelected: (_) async {
                          setState(() => _preset = p);
                          await _refresh();
                        },
                      );
                    }).toList(),
                  ),
                  if (_stores.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedStoreId,
                      decoration: const InputDecoration(
                        labelText: 'Store',
                        border: OutlineInputBorder(),
                      ),
                      items: _stores
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            ),
                          )
                          .toList(),
                      onChanged: (v) async {
                        setState(() => _selectedStoreId = v);
                        await _refresh();
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (summary != null)
                    ResponsiveWrapGrid(
                      mobileColumns: 1,
                      tabletColumns: 2,
                      desktopColumns: 3,
                      children: [
                        _kpiCard(
                          'Pending Requisitions',
                          summary.pendingRequisitions.toString(),
                          Colors.orange,
                        ),
                        _kpiCard(
                          'Open POs',
                          summary.openPurchaseOrders.toString(),
                          Colors.blue,
                        ),
                        _kpiCard(
                          'Purchase Value',
                          currency.format(summary.totalPurchaseValue),
                          Colors.green,
                        ),
                        _kpiCard(
                          'Inventory Value',
                          currency.format(summary.inventoryValue),
                          Colors.purple,
                        ),
                        _kpiCard(
                          'Low Stock',
                          summary.lowStockCount.toString(),
                          Colors.amber,
                        ),
                        _kpiCard(
                          'Near Expiry',
                          summary.nearExpiryCount.toString(),
                          Colors.red,
                        ),
                      ],
                    ),
                  const SizedBox(height: 24),
                  if (_data != null && _data!.topItems.isNotEmpty) ...[
                    const Text(
                      'Top Purchased Items',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._data!.topItems
                        .take(5)
                        .map(
                          (item) => ListTile(
                            title: Text(item.itemName),
                            subtitle: Text(
                              'Qty: ${item.quantityPurchased} · '
                              '${currency.format(item.totalCost)}',
                            ),
                            trailing: Text('Stock: ${item.stockRemaining}'),
                          ),
                        ),
                  ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _kpiCard(String label, String value, Color color) {
    return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
    );
  }
}
