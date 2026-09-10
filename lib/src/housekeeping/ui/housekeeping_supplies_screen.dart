import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../helper/date.formatter.dart';
import '../models/housekeeping_models.dart';
import '../services/housekeeping_api_service.dart';

@RoutePage()
class HousekeepingSuppliesScreen extends StatefulWidget {
  const HousekeepingSuppliesScreen({super.key});

  @override
  State<HousekeepingSuppliesScreen> createState() =>
      _HousekeepingSuppliesScreenState();
}

class _HousekeepingSuppliesScreenState
    extends State<HousekeepingSuppliesScreen> {
  final _api = HousekeepingApiService();
  bool _loading = true;
  String? _error;
  List<HousekeepingSupplyLog> _logs = [];
  List<HousekeepingWorker> _workers = [];

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
      final results = await Future.wait([
        _api.listSupplies(),
        _api.listWorkers(),
      ]);
      if (!mounted) return;
      setState(() {
        _logs = results[0] as List<HousekeepingSupplyLog>;
        _workers = results[1] as List<HousekeepingWorker>;
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

  Future<void> _add() async {
    final item = TextEditingController();
    final qty = TextEditingController(text: '1');
    final unit = TextEditingController(text: 'pcs');
    var action = HousekeepingSupplyAction.used;
    String? workerId;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log supply'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: item,
                decoration: const InputDecoration(
                  labelText: 'Item (e.g. detergent)',
                ),
              ),
              TextField(
                controller: qty,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              TextField(
                controller: unit,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              DropdownButtonFormField<HousekeepingSupplyAction>(
                initialValue: action,
                items: HousekeepingSupplyAction.values
                    .map(
                      (a) => DropdownMenuItem(value: a, child: Text(a.label)),
                    )
                    .toList(),
                onChanged: (v) => action = v ?? action,
              ),
              DropdownButtonFormField<String?>(
                initialValue: workerId,
                items: [
                  const DropdownMenuItem(value: null, child: Text('No worker')),
                  ..._workers.map(
                    (w) => DropdownMenuItem(
                      value: w.id,
                      child: Text(w.fullName),
                    ),
                  ),
                ],
                onChanged: (v) => workerId = v,
                decoration: const InputDecoration(labelText: 'Issued to'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _api.createSupply({
      'itemName': item.text.trim(),
      'quantity': num.tryParse(qty.text.trim()) ?? 1,
      'unit': unit.text.trim(),
      'action': action.apiValue,
      if (workerId != null) 'workerId': workerId,
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supply logs')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.builder(
              itemCount: _logs.length,
              itemBuilder: (context, i) {
                final log = _logs[i];
                return ListTile(
                  title: Text('${log.itemName} · ${log.action.label}'),
                  subtitle: Text(
                    [
                      '${log.quantity} ${log.unit}',
                      if (log.workerName != null) log.workerName!,
                      if (log.createdAt != null)
                        DateFormatter.dateTime(log.createdAt!),
                    ].join(' · '),
                  ),
                );
              },
            ),
    );
  }
}
