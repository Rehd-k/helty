import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/pharmacy/models/pharmacy_model.dart';
import 'package:helty/src/store/models/consumable_models.dart';
import 'package:helty/src/store/models/store_models.dart';
import 'package:helty/src/store/providers/store_providers.dart';

/// Batches for one consumable (`GET/POST …/store/consumables/:id/batches`).
@RoutePage()
class StoreConsumableDetailScreen extends ConsumerStatefulWidget {
  const StoreConsumableDetailScreen({
    super.key,
    @PathParam('consumableId') required this.consumableId,
  });

  final String consumableId;

  @override
  ConsumerState<StoreConsumableDetailScreen> createState() =>
      _StoreConsumableDetailScreenState();
}

class _StoreConsumableDetailScreenState
    extends ConsumerState<StoreConsumableDetailScreen> {
  Consumable? _consumable;
  List<ConsumableBatch> _batches = [];
  List<StoreLocation> _locations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final storeApi = ref.read(storeApiServiceProvider);
      final consApi = ref.read(storeConsumableApiServiceProvider);
      final locs = await storeApi.getLocations();
      final c = await consApi.getConsumable(widget.consumableId);
      final batches = await consApi.listBatches(widget.consumableId);
      if (!mounted) return;
      setState(() {
        _locations = locs.data;
        _consumable = c;
        _batches = batches.items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _showAddBatchDialog() async {
    if (_locations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a store location first (Store → Locations).'),
        ),
      );
      return;
    }
    StoreLocation? loc = _locations.first;
    final qtyRecv = TextEditingController(text: '1');
    final qtyRem = TextEditingController(text: '1');
    final cost = TextEditingController(text: '0');
    final sell = TextEditingController(text: '0');
    final batchNo = TextEditingController();
    DateTime? expiry;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add batch'),
        content: SingleChildScrollView(
          child: StatefulBuilder(
            builder: (ctx2, setLocal) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<StoreLocation>(
                  // ignore: deprecated_member_use
                  value: loc,
                  decoration: const InputDecoration(
                    labelText: 'Store location',
                    border: OutlineInputBorder(),
                  ),
                  items: _locations
                      .map(
                        (l) => DropdownMenuItem(value: l, child: Text(l.name)),
                      )
                      .toList(),
                  onChanged: (v) => setLocal(() => loc = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyRecv,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity received',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: qtyRem,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Quantity remaining',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: cost,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cost price',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: sell,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Selling price',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: batchNo,
                  decoration: const InputDecoration(
                    labelText: 'Batch number (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Expiry date'),
                  subtitle: Text(
                    expiry == null
                        ? 'None'
                        : expiry!.toIso8601String().split('T').first,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: ctx2,
                        initialDate: expiry ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                      );
                      if (d != null) setLocal(() => expiry = d);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true || !mounted || loc == null) return;
    try {
      await ref.read(storeConsumableApiServiceProvider).createBatch(
            widget.consumableId,
            ConsumableBatch(
              consumableId: widget.consumableId,
              storeLocationId: loc!.id,
              quantityReceived: int.tryParse(qtyRecv.text.trim()) ?? 0,
              quantityRemaining: int.tryParse(qtyRem.text.trim()),
              costPrice: double.tryParse(cost.text.trim()),
              sellingPrice: double.tryParse(sell.text.trim()),
              batchNumber: batchNo.text.trim().isEmpty ? null : batchNo.text.trim(),
              expiryDate: expiry,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Batch created')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _consumable;
    return Scaffold(
      appBar: AppBar(
        title: Text(c?.name ?? 'Consumable'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _showAddBatchDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add batch'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (c != null)
                      Card(
                        child: ListTile(
                          title: Text(c.name),
                          subtitle: Text(
                            'Category: ${c.category ?? '—'}\n'
                            'Billable: ${c.isBillable}\n'
                            'Reorder: ${c.reorderLevel ?? 0}',
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    Text(
                      'Batches (${_batches.length})',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    if (_batches.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No batches yet.'),
                      )
                    else
                      ..._batches.map(
                        (b) => Card(
                          child: ListTile(
                            title: Text(
                              b.storeLocation?.name ??
                                  b.storeLocationId ??
                                  'Location',
                            ),
                            subtitle: Text(
                              'Remaining: ${b.quantityRemaining ?? b.quantityReceived} · '
                              'Received: ${b.quantityReceived}\n'
                              'Sell: ${b.sellingPrice ?? 0} · Cost: ${b.costPrice ?? 0}',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
