import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/store/models/store_models.dart';
import 'package:helty/src/store/providers/store_providers.dart';

@RoutePage()
class StoreStockScreen extends ConsumerStatefulWidget {
  const StoreStockScreen({super.key});

  @override
  ConsumerState<StoreStockScreen> createState() => _StoreStockScreenState();
}

class _StoreStockScreenState extends ConsumerState<StoreStockScreen> {
  String? _filterLocationId;
  String? _filterItemId;
  int _skip = 0;
  static const int _limit = 20;
  bool _loading = true;
  StoreStockResponse? _response;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStock();
  }

  Future<void> _loadStock() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(storeApiServiceProvider);
      final response = await api.getStock(
        locationId: _filterLocationId,
        itemId: _filterItemId,
        limit: _limit,
        skip: _skip,
      );
      if (!mounted) return;
      setState(() {
        _response = response;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locationsAsync = ref.watch(storeLocationsFutureProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Stock')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.6,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: locationsAsync.when(
                        data: (res) {
                          final list = res.data;
                          return DropdownButtonFormField<String?>(
                            initialValue: _filterLocationId,
                            decoration: const InputDecoration(
                              labelText: 'Location',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All locations'),
                              ),
                              ...list.map(
                                (l) => DropdownMenuItem(
                                  value: l.id,
                                  child: Text(l.name),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              setState(() {
                                _filterLocationId = v;
                                _skip = 0;
                              });
                              _loadStock();
                            },
                          );
                        },
                        loading: () => const SizedBox(
                          height: 56,
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        error: (_, __) =>
                            const Text('Failed to load locations'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ref
                          .watch(
                            storeItemsFutureProvider(
                              const StoreItemsParams(
                                isActive: true,
                                limit: 500,
                                skip: 0,
                              ),
                            ),
                          )
                          .when(
                            data: (res) {
                              final list = res.data;
                              return DropdownButtonFormField<String?>(
                                initialValue: _filterItemId,
                                decoration: const InputDecoration(
                                  labelText: 'Item',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: null,
                                    child: Text('All items'),
                                  ),
                                  ...list.map(
                                    (i) => DropdownMenuItem(
                                      value: i.id,
                                      child: Text(i.name),
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  setState(() {
                                    _filterItemId = v;
                                    _skip = 0;
                                  });
                                  _loadStock();
                                },
                              );
                            },
                            loading: () => const SizedBox(
                              height: 56,
                              child: Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                            ),
                            error: (_, __) =>
                                const Text('Failed to load items'),
                          ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: _loading ? null : _loadStock,
                      icon: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                      label: const Text('Apply'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildBody(theme)),
        ],
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading && _response == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(onPressed: _loadStock, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    final list = _response?.data ?? [];
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warehouse_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text('No stock records', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Stock is created when you receive or transfer items.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: list.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'Location',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Item',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Quantity',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Unit cost',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 80),
              ],
            ),
          );
        }
        final stock = list[index - 1];
        final locationName = stock.location?.name ?? stock.locationId;
        final itemName = stock.item?.name ?? stock.itemId;
        final reorderLevel = stock.item?.reorderLevel ?? 0;
        final isLowStock = stock.quantity <= reorderLevel;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(locationName)),
                Expanded(flex: 2, child: Text(itemName)),
                Expanded(child: Text(stock.quantity.toStringAsFixed(0))),
                Expanded(
                  child: Text(
                    stock.unitCost != null
                        ? stock.unitCost!.toStringAsFixed(2)
                        : '–',
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: isLowStock
                      ? Chip(
                          label: Text(
                            'Low stock',
                            style: theme.textTheme.labelSmall,
                          ),
                          backgroundColor: theme.colorScheme.errorContainer,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
