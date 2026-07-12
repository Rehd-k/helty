import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/store/models/store_models.dart';
import 'package:helty/src/store/providers/store_providers.dart';

/// Period summary from `GET /store/consumables/analytics/summary`.
@RoutePage()
class StoreConsumableAnalyticsScreen extends ConsumerStatefulWidget {
  const StoreConsumableAnalyticsScreen({super.key});

  @override
  ConsumerState<StoreConsumableAnalyticsScreen> createState() =>
      _StoreConsumableAnalyticsScreenState();
}

class _StoreConsumableAnalyticsScreenState
    extends ConsumerState<StoreConsumableAnalyticsScreen> {
  DateTime _from = DateTime.now().subtract(const Duration(days: 30));
  DateTime _to = DateTime.now();
  String? _locationId;
  List<StoreLocation> _locations = [];
  Map<String, dynamic> _summary = {};
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations() async {
    try {
      final r = await ref.read(storeApiServiceProvider).getLocations();
      if (mounted) setState(() => _locations = r.data);
    } catch (_) {}
  }

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(storeConsumableApiServiceProvider);
      final map = await api.getAnalyticsSummary(
        fromDate: _from.toUtc().toIso8601String(),
        toDate: _to.toUtc().toIso8601String(),
        storeLocationId: _locationId,
        topLimit: 15,
      );
      if (!mounted) return;
      setState(() {
        _summary = map;
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

  Future<void> _pickFrom() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2000),
      lastDate: _to,
    );
    if (d != null) setState(() => _from = d);
  }

  Future<void> _pickTo() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: _from,
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _to = d);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consumable analytics')),
      body: ResponsiveBody(
        builder: (context, bp) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickFrom,
                  child: Text('From ${_from.toString().split(' ').first}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickTo,
                  child: Text('To ${_to.toString().split(' ').first}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_locations.isNotEmpty)
            DropdownButtonFormField<String?>(
              // ignore: deprecated_member_use
              value: _locationId,
              decoration: const InputDecoration(
                labelText: 'Store location (optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All locations'),
                ),
                ..._locations.map(
                  (l) => DropdownMenuItem(value: l.id, child: Text(l.name)),
                ),
              ],
              onChanged: (v) => setState(() => _locationId = v),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _loading ? null : _run,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.query_stats),
            label: Text(_loading ? 'Loading…' : 'Load summary'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          if (_summary.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Response', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ..._summary.entries.map(
              (e) => Card(
                child: ListTile(
                  title: Text(e.key, style: const TextStyle(fontFamily: 'monospace')),
                  subtitle: Text(
                    e.value?.toString() ?? 'null',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}
