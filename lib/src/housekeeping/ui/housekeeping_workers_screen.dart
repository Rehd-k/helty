import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../models/housekeeping_models.dart';
import '../services/housekeeping_api_service.dart';

@RoutePage()
class HousekeepingWorkersScreen extends StatefulWidget {
  const HousekeepingWorkersScreen({super.key});

  @override
  State<HousekeepingWorkersScreen> createState() =>
      _HousekeepingWorkersScreenState();
}

class _HousekeepingWorkersScreenState extends State<HousekeepingWorkersScreen> {
  final _api = HousekeepingApiService();
  bool _loading = true;
  String? _error;
  List<HousekeepingWorker> _workers = [];
  List<HousekeepingArea> _areas = [];

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
        _api.listWorkers(),
        _api.listAreas(),
      ]);
      if (!mounted) return;
      setState(() {
        _workers = results[0] as List<HousekeepingWorker>;
        _areas = results[1] as List<HousekeepingArea>;
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

  Future<void> _addWorker() async {
    final first = TextEditingController();
    final last = TextEditingController();
    final phone = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add janitorial staff'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: first,
              decoration: const InputDecoration(labelText: 'First name'),
            ),
            TextField(
              controller: last,
              decoration: const InputDecoration(labelText: 'Last name'),
            ),
            TextField(
              controller: phone,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
          ],
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
    await _api.createWorker({
      'firstName': first.text.trim(),
      'lastName': last.text.trim(),
      if (phone.text.trim().isNotEmpty) 'phone': phone.text.trim(),
    });
    await _load();
  }

  Future<void> _assign(HousekeepingWorker worker) async {
    if (_areas.isEmpty) return;
    var areaId = _areas.first.id;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Assign area to ${worker.fullName}'),
        content: DropdownButtonFormField<String>(
          initialValue: areaId,
          items: _areas
              .map(
                (a) => DropdownMenuItem(value: a.id, child: Text(a.name)),
              )
              .toList(),
          onChanged: (v) => areaId = v ?? areaId,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Assign'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _api.assignArea(worker.id, areaId);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Janitorial staff')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addWorker,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.builder(
              itemCount: _workers.length,
              itemBuilder: (context, i) {
                final w = _workers[i];
                return ListTile(
                  title: Text(w.fullName),
                  subtitle: Text(
                    w.areas.isEmpty
                        ? 'No areas assigned'
                        : w.areas.map((a) => a.name).join(', '),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.place_outlined),
                    onPressed: () => _assign(w),
                  ),
                );
              },
            ),
    );
  }
}
