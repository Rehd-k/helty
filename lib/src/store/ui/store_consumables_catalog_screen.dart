import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/pharmacy/models/pharmacy_model.dart';
import 'package:helty/src/store/models/consumable_models.dart';
import 'package:helty/src/store/providers/store_providers.dart';

/// Store staff — catalog CRUD for hospital consumables (`/store/consumables`).
@RoutePage()
class StoreConsumablesCatalogScreen extends ConsumerStatefulWidget {
  const StoreConsumablesCatalogScreen({super.key});

  @override
  ConsumerState<StoreConsumablesCatalogScreen> createState() =>
      _StoreConsumablesCatalogScreenState();
}

class _StoreConsumablesCatalogScreenState
    extends ConsumerState<StoreConsumablesCatalogScreen> {
  final _searchCtrl = TextEditingController();
  bool _loading = true;
  String? _error;
  List<Consumable> _items = [];
  int _page = 1;
  static const int _pageSize = 25;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    if (reset) {
      _page = 1;
      _items = [];
      _hasMore = true;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(storeConsumableApiServiceProvider);
      final resp = await api.listConsumables(
        StoreConsumableListParams(
          page: _page,
          pageSize: _pageSize,
          search: _searchCtrl.text.trim().isEmpty
              ? null
              : _searchCtrl.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() {
        if (reset) {
          _items = List<Consumable>.from(resp.items);
        } else {
          _items = [..._items, ...resp.items];
        }
        _hasMore = resp.items.length >= _pageSize && _items.length < resp.total;
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

  Future<void> _showCreateDialog() async {
    final nameCtrl = TextEditingController();
    final catCtrl = TextEditingController();
    final reorderCtrl = TextEditingController(text: '0');
    var billable = true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New consumable'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: catCtrl,
                decoration: const InputDecoration(
                  labelText: 'Category (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reorderCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reorder level',
                  border: OutlineInputBorder(),
                ),
              ),
              StatefulBuilder(
                builder: (ctx, setLocal) => SwitchListTile(
                  title: const Text('Billable'),
                  value: billable,
                  onChanged: (v) => setLocal(() => billable = v),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name is required')),
      );
      return;
    }
    try {
      await ref.read(storeConsumableApiServiceProvider).createConsumable(
            Consumable(
              name: name,
              category: catCtrl.text.trim().isEmpty ? null : catCtrl.text.trim(),
              reorderLevel: int.tryParse(reorderCtrl.text.trim()),
              isBillable: billable,
            ),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consumable created')),
      );
      await _load(reset: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consumables catalog'),
        actions: [
          IconButton(
            tooltip: 'Consumable analytics',
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () =>
                context.router.push(const StoreConsumableAnalyticsRoute()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add consumable'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search catalog…',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _load(reset: true),
                ),
              ),
              onSubmitted: (_) => _load(reset: true),
            ),
          ),
          Expanded(
            child: _loading && _items.isEmpty
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
                              FilledButton(
                                onPressed: () => _load(reset: true),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _items.length + (_hasMore ? 1 : 0),
                        itemBuilder: (ctx, i) {
                          if (i == _items.length) {
                            return Padding(
                              padding: const EdgeInsets.all(16),
                              child: Center(
                                child: TextButton.icon(
                                  onPressed: _loading
                                      ? null
                                      : () {
                                          _page += 1;
                                          _load(reset: false);
                                        },
                                  icon: const Icon(Icons.expand_more),
                                  label: const Text('Load more'),
                                ),
                              ),
                            );
                          }
                          final c = _items[i];
                          final id = c.id?.trim() ?? '';
                          return ListTile(
                            title: Text(c.name),
                            subtitle: Text(
                              '${c.category ?? '—'} · ${c.isBillable ? 'Billable' : 'Non-billable'} · reorder ${c.reorderLevel ?? 0}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: id.isEmpty
                                ? null
                                : () => context.router.push(
                                      StoreConsumableDetailRoute(consumableId: id),
                                    ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
