import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../../helper/date.formatter.dart';
import '../models/purchases_model.dart';
import '../services/purchases_service.dart';

enum _QuickRange { today, last7, thisMonth }

@RoutePage()
class PurchasesTransferHistoryScreen extends StatefulWidget {
  const PurchasesTransferHistoryScreen({super.key});

  @override
  State<PurchasesTransferHistoryScreen> createState() =>
      _PurchasesTransferHistoryScreenState();
}

class _PurchasesTransferHistoryScreenState
    extends State<PurchasesTransferHistoryScreen> {
  final PurchasesApiService _api = PurchasesApiService();
  final int _take = 25;

  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();
  int _page = 1;

  List<PurchasesStockTransfer> _rows = [];
  int _total = 0;
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final skip = (_page - 1) * _take;
      final resp = await _api.getTransferHistory(
        TransferHistoryQuery(
          fromDate: _from,
          toDate: _to,
          status: 'COMPLETED',
          skip: skip,
          take: _take,
        ),
      );
      if (!mounted) return;
      setState(() {
        _rows = resp.items;
        _total = resp.total;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _applyQuickRange(_QuickRange range) {
    final now = DateTime.now();
    switch (range) {
      case _QuickRange.today:
        _from = DateTime(now.year, now.month, now.day);
        _to = now;
      case _QuickRange.last7:
        _from = now.subtract(const Duration(days: 7));
        _to = now;
      case _QuickRange.thisMonth:
        _from = DateTime(now.year, now.month, 1);
        _to = now;
    }
    _page = 1;
    _fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchHistory,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Today'),
                  selected: false,
                  onSelected: (_) => _applyQuickRange(_QuickRange.today),
                ),
                ChoiceChip(
                  label: const Text('Last 7 days'),
                  selected: false,
                  onSelected: (_) => _applyQuickRange(_QuickRange.last7),
                ),
                ChoiceChip(
                  label: const Text('This month'),
                  selected: false,
                  onSelected: (_) => _applyQuickRange(_QuickRange.thisMonth),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error.isNotEmpty)
              Text(_error, style: const TextStyle(color: Colors.red)),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _rows.isEmpty
                  ? const Center(child: Text('No transfer history found.'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Date')),
                          DataColumn(label: Text('Item')),
                          DataColumn(label: Text('From')),
                          DataColumn(label: Text('To')),
                          DataColumn(label: Text('Qty')),
                          DataColumn(label: Text('Status')),
                          DataColumn(label: Text('Requested By')),
                        ],
                        rows: _rows.map((r) {
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  r.completedAt != null
                                      ? DateFormatter.dateTime(r.completedAt!)
                                      : (r.createdAt != null
                                            ? DateFormatter.dateTime(r.createdAt!)
                                            : '-'),
                                ),
                              ),
                              DataCell(Text(r.item?.itemName ?? r.itemId)),
                              DataCell(
                                Text(r.fromLocation?.name ?? r.fromLocationId),
                              ),
                              DataCell(
                                Text(r.toLocation?.name ?? r.toLocationId),
                              ),
                              DataCell(Text(r.quantity.toString())),
                              DataCell(Text(r.status.name)),
                              DataCell(Text(r.requestedByName ?? '-')),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('Page $_page · $_total total'),
                IconButton(
                  onPressed: _page > 1
                      ? () {
                          _page--;
                          _fetchHistory();
                        }
                      : null,
                  icon: const Icon(Icons.chevron_left),
                ),
                IconButton(
                  onPressed: _page * _take < _total
                      ? () {
                          _page++;
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
