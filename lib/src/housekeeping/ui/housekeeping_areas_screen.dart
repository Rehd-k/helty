import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../models/housekeeping_models.dart';
import '../services/housekeeping_api_service.dart';

@RoutePage()
class HousekeepingAreasScreen extends StatefulWidget {
  const HousekeepingAreasScreen({super.key});

  @override
  State<HousekeepingAreasScreen> createState() =>
      _HousekeepingAreasScreenState();
}

class _HousekeepingAreasScreenState extends State<HousekeepingAreasScreen> {
  final _api = HousekeepingApiService();
  bool _loading = true;
  String? _error;
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
      final areas = await _api.listAreas();
      if (!mounted) return;
      setState(() {
        _areas = areas;
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
    final name = TextEditingController();
    var kind = HousekeepingAreaKind.room;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add area'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            DropdownButtonFormField<HousekeepingAreaKind>(
              initialValue: kind,
              items: HousekeepingAreaKind.values
                  .map((k) => DropdownMenuItem(value: k, child: Text(k.label)))
                  .toList(),
              onChanged: (v) => kind = v ?? kind,
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
    await _api.createArea({
      'name': name.text.trim(),
      'kind': kind.apiValue,
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Areas and rooms')),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.builder(
              itemCount: _areas.length,
              itemBuilder: (context, i) {
                final a = _areas[i];
                return ListTile(
                  title: Text(a.name),
                  subtitle: Text(a.kind.label),
                );
              },
            ),
    );
  }
}
