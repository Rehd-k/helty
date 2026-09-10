import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

import '../../helper/app_timezone.dart';
import '../../nursing/models/nursing_models.dart';
import '../models/housekeeping_models.dart';
import '../services/housekeeping_api_service.dart';

@RoutePage()
class HousekeepingShiftsScreen extends StatefulWidget {
  const HousekeepingShiftsScreen({super.key});

  @override
  State<HousekeepingShiftsScreen> createState() =>
      _HousekeepingShiftsScreenState();
}

class _HousekeepingShiftsScreenState extends State<HousekeepingShiftsScreen> {
  final _api = HousekeepingApiService();
  DateTime _date = DateTime.now();
  bool _loading = true;
  String? _error;
  List<HousekeepingShiftEntry> _shifts = [];
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
        _api.listShifts(shiftDate: _date),
        _api.listWorkers(),
      ]);
      if (!mounted) return;
      setState(() {
        _shifts = results[0] as List<HousekeepingShiftEntry>;
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
    if (_workers.isEmpty) return;
    var workerId = _workers.first.id;
    var shift = ShiftType.morning;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Assign shift'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              initialValue: workerId,
              items: _workers
                  .map(
                    (w) => DropdownMenuItem(
                      value: w.id,
                      child: Text(w.fullName),
                    ),
                  )
                  .toList(),
              onChanged: (v) => workerId = v ?? workerId,
            ),
            DropdownButtonFormField<ShiftType>(
              initialValue: shift,
              items: ShiftType.values
                  .map(
                    (s) => DropdownMenuItem(value: s, child: Text(s.label)),
                  )
                  .toList(),
              onChanged: (v) => shift = v ?? shift,
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
    await _api.createShift(
      workerId: workerId,
      shiftDate: _date,
      shiftType: shift,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Housekeeping shifts'),
        actions: [
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _date = picked);
                await _load();
              }
            },
            child: Text(AppTimezone.dateOnlyKey(_date)),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _add,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : ListView.builder(
              itemCount: _shifts.length,
              itemBuilder: (context, i) {
                final s = _shifts[i];
                return ListTile(
                  title: Text(s.workerName),
                  subtitle: Text(s.shiftType),
                  trailing: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () async {
                      await _api.removeShift(s.id);
                      await _load();
                    },
                  ),
                );
              },
            ),
    );
  }
}
