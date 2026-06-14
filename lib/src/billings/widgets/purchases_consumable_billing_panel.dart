import 'dart:async';

import 'package:flutter/material.dart';
import 'package:helty/src/billings/widgets/catalog_sales_widgets.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/purchases/models/purchases_model.dart';
import 'package:helty/src/purchases/services/purchases_service.dart';

Future<int> purchasesStockAtLocation(
  PurchasesApiService api,
  String purchaseItemId,
  String locationId,
) async {
  final rows = await api.getItemLocationQuantities(
    purchaseItemId,
    locationId: locationId,
  );
  if (rows.isEmpty) return 0;
  return rows.fold<int>(0, (sum, row) => sum + row.quantity);
}

/// Store-first purchase item search with quantity and price before confirm.
class PurchasesConsumableBillingPanel extends StatefulWidget {
  const PurchasesConsumableBillingPanel({
    super.key,
    this.purchasesApi,
    this.purchasesLocations,
    required this.onConfirm,
    this.confirmButtonLabel = 'Add',
    this.busy = false,
  });

  final PurchasesApiService? purchasesApi;
  final List<PurchasesLocation>? purchasesLocations;
  final void Function(
    PurchaseItem item,
    String locationId,
    int qty,
    double unitPrice,
  )
  onConfirm;
  final String confirmButtonLabel;
  final bool busy;

  @override
  State<PurchasesConsumableBillingPanel> createState() =>
      _PurchasesConsumableBillingPanelState();
}

class _PurchasesConsumableBillingPanelState
    extends State<PurchasesConsumableBillingPanel> {
  static const int _pageSize = 10;

  late final PurchasesApiService _api;
  final _searchCtrl = TextEditingController();
  final _priceCtrl = TextEditingController(text: '0');

  List<PurchasesLocation> _locations = [];
  bool _loadingLocations = false;
  String? _selectedLocationId;

  List<PurchaseItem> _suggestions = [];
  final Map<String, int> _stockByItemId = {};
  final Set<String> _loadingStockIds = {};
  bool _loadingSearch = false;
  int _page = 1;
  Timer? _debounce;

  PurchaseItem? _selectedItem;
  int _selectedStock = 0;
  int _quantity = 1;
  bool _loadingSelectedStock = false;

  @override
  void initState() {
    super.initState();
    _api = widget.purchasesApi ?? PurchasesApiService();
    if (widget.purchasesLocations != null) {
      _locations = widget.purchasesLocations!;
      _selectedLocationId = _defaultStoreId(_locations);
    } else {
      _loadLocations();
    }
  }

  @override
  void didUpdateWidget(covariant PurchasesConsumableBillingPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.purchasesLocations != null &&
        widget.purchasesLocations != oldWidget.purchasesLocations) {
      _locations = widget.purchasesLocations!;
      if (_selectedLocationId == null ||
          !_locations.any((l) => l.id == _selectedLocationId)) {
        _selectedLocationId = _defaultStoreId(_locations);
      }
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  String? _defaultStoreId(List<PurchasesLocation> locs) {
    if (locs.isEmpty) return null;
    for (final l in locs) {
      if (l.type == PurchasesLocationType.STORE) return l.id;
    }
    return locs.first.id;
  }

  Future<void> _loadLocations() async {
    setState(() => _loadingLocations = true);
    try {
      final r = await _api.getLocations(
        const PurchasesQueryParams(pageSize: 50),
      );
      final active = r.items.where((l) => l.isActive).toList();
      final stores = active
          .where((l) => l.type == PurchasesLocationType.STORE)
          .toList();
      final locs = stores.isNotEmpty ? stores : active;
      if (!mounted) return;
      setState(() {
        _locations = locs;
        _selectedLocationId = _defaultStoreId(locs);
        _loadingLocations = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locations = [];
        _loadingLocations = false;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedItem = null;
      _selectedStock = 0;
      _quantity = 1;
    });
  }

  void _onStoreChanged(String? locationId) {
    if (locationId == null || locationId == _selectedLocationId) return;
    setState(() {
      _selectedLocationId = locationId;
      _suggestions = [];
      _stockByItemId.clear();
      _clearSelection();
    });
    final q = _searchCtrl.text.trim();
    if (q.length >= 2) {
      _page = 1;
      _runSearch(page: 1, append: false);
    }
  }

  Future<void> _refreshStockForItems(List<PurchaseItem> items) async {
    final locId = _selectedLocationId?.trim() ?? '';
    if (locId.isEmpty) return;
    final ids = items
        .map((i) => i.id?.trim() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    if (ids.isEmpty) return;

    setState(() => _loadingStockIds.addAll(ids));

    await Future.wait(
      ids.map((itemId) async {
        try {
          final stock = await purchasesStockAtLocation(_api, itemId, locId);
          if (mounted) {
            setState(() => _stockByItemId[itemId] = stock);
          }
        } catch (_) {
          if (mounted) {
            setState(() => _stockByItemId[itemId] = 0);
          }
        } finally {
          if (mounted) {
            setState(() => _loadingStockIds.remove(itemId));
          }
        }
      }),
    );
  }

  Future<void> _runSearch({int page = 1, bool append = false}) async {
    final q = _searchCtrl.text.trim();
    if (q.length < 2) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _loadingSearch = false;
        });
      }
      return;
    }
    if (_selectedLocationId == null || _selectedLocationId!.isEmpty) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _loadingSearch = false;
        });
      }
      return;
    }
    setState(() => _loadingSearch = true);
    try {
      final resp = await _api.searchItems(
        SearchPurchaseItemParams(
          search: q,
          page: page,
          pageSize: _pageSize,
          sortOrder: 'asc',
          inStock: true,
        ),
      );
      final list = resp.items
          .where((item) => (item.sellingPrice ?? 0) > 0)
          .toList();
      if (!mounted) return;
      setState(() {
        if (append) {
          _suggestions = [..._suggestions, ...list];
        } else {
          _suggestions = list;
        }
        _loadingSearch = false;
      });
      await _refreshStockForItems(list);
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingSearch = false);
    }
  }

  Future<void> _selectItem(PurchaseItem item) async {
    final itemId = item.id?.trim() ?? '';
    final locId = _selectedLocationId?.trim() ?? '';
    if (itemId.isEmpty || locId.isEmpty) return;

    setState(() {
      _loadingSelectedStock = true;
      _selectedItem = item;
    });

    try {
      final stock = await purchasesStockAtLocation(_api, itemId, locId);
      if (!mounted) return;
      if (stock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot add "${item.itemName}" — out of stock at the selected store.',
            ),
          ),
        );
        setState(() {
          _selectedItem = null;
          _selectedStock = 0;
          _loadingSelectedStock = false;
        });
        return;
      }
      _priceCtrl.text = (item.sellingPrice ?? 0).toString();
      setState(() {
        _selectedStock = stock;
        _quantity = 1;
        _loadingSelectedStock = false;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not check stock — try again')),
      );
      setState(() {
        _selectedItem = null;
        _loadingSelectedStock = false;
      });
    }
  }

  void _submit() {
    final item = _selectedItem;
    final locId = _selectedLocationId?.trim() ?? '';
    if (item == null || locId.isEmpty) return;
    if (_selectedStock <= 0) return;
    final qty = _quantity.clamp(1, _selectedStock);
    final unit = double.tryParse(_priceCtrl.text.trim()) ?? -1;
    if (unit < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid unit price ≥ 0')),
      );
      return;
    }
    widget.onConfirm(item, locId, qty, unit);
    _searchCtrl.clear();
    setState(() {
      _suggestions = [];
      _stockByItemId.clear();
      _clearSelection();
    });
  }

  int _stockForItem(PurchaseItem item) {
    final id = item.id?.trim() ?? '';
    if (id.isEmpty) return 0;
    return _stockByItemId[id] ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locs = widget.purchasesLocations ?? _locations;
    final locId = _selectedLocationId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_loadingLocations)
          const LinearProgressIndicator()
        else if (locs.isEmpty)
          Text(
            'No purchases store locations — add locations under Purchases first.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          )
        else
          DropdownButtonFormField<String>(
            // ignore: deprecated_member_use
            value: locId != null && locs.any((l) => l.id == locId)
                ? locId
                : locs.first.id,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Purchases store',
              border: OutlineInputBorder(),
            ),
            items: locs
                .map(
                  (l) => DropdownMenuItem(
                    value: l.id,
                    child: Text(l.name, overflow: TextOverflow.ellipsis),
                  ),
                )
                .toList(),
            onChanged: locs.length <= 1 ? null : _onStoreChanged,
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchCtrl,
          enabled: locs.isNotEmpty && locId != null,
          decoration: InputDecoration(
            hintText:
                'Search purchase items with selling price (min 2 chars)...',
            border: const OutlineInputBorder(),
            suffixIcon: _loadingSearch
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          onChanged: (_) {
            _debounce?.cancel();
            _debounce = Timer(const Duration(milliseconds: 300), () {
              _page = 1;
              _runSearch(page: 1, append: false);
            });
          },
        ),
        const SizedBox(height: 6),
        if (_selectedItem == null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount:
                  _suggestions.length +
                  (_suggestions.length >= _pageSize ? 1 : 0),
              itemBuilder: (_, i) {
                if (i == _suggestions.length) {
                  return TextButton.icon(
                    onPressed: _loadingSearch
                        ? null
                        : () {
                            _page += 1;
                            _runSearch(page: _page, append: true);
                          },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Load more'),
                  );
                }
                final item = _suggestions[i];
                final sell = item.sellingPrice ?? 0;
                final itemId = item.id?.trim() ?? '';
                final stock = _stockForItem(item);
                final stockLoading =
                    itemId.isNotEmpty && _loadingStockIds.contains(itemId);
                final enabled = !stockLoading && stock > 0;
                return ListTile(
                  dense: true,
                  enabled: enabled,
                  title: Text(item.itemName),
                  subtitle: stockLoading
                      ? const Text('Checking stock...')
                      : Text(
                          sell > 0
                              ? '${sell.toFinancial(isMoney: true)} • Stock: $stock'
                              : 'Stock: $stock',
                          style: TextStyle(
                            color: enabled
                                ? null
                                : theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                          ),
                        ),
                  onTap: enabled ? () => _selectItem(item) : null,
                );
              },
            ),
          )
        else
          _SelectedItemPanel(
            item: _selectedItem!,
            stock: _selectedStock,
            quantity: _quantity,
            priceController: _priceCtrl,
            loadingStock: _loadingSelectedStock,
            confirmLabel: widget.confirmButtonLabel,
            busy: widget.busy,
            onQuantityChanged: (q) => setState(() => _quantity = q),
            onCancel: _clearSelection,
            onConfirm: _submit,
          ),
      ],
    );
  }
}

class _SelectedItemPanel extends StatelessWidget {
  const _SelectedItemPanel({
    required this.item,
    required this.stock,
    required this.quantity,
    required this.priceController,
    required this.loadingStock,
    required this.confirmLabel,
    required this.busy,
    required this.onQuantityChanged,
    required this.onCancel,
    required this.onConfirm,
  });

  final PurchaseItem item;
  final int stock;
  final int quantity;
  final TextEditingController priceController;
  final bool loadingStock;
  final String confirmLabel;
  final bool busy;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.itemName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(onPressed: onCancel, child: const Text('Change')),
              ],
            ),
            if (loadingStock)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else ...[
              Text(
                'Available at store: $stock',
                style: theme.textTheme.labelSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Qty', style: theme.textTheme.labelMedium),
                  const SizedBox(width: 8),
                  QuantityEditor(
                    quantity: quantity,
                    maxQuantity: stock,
                    onChanged: onQuantityChanged,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: priceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Unit price',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: busy || stock <= 0 ? null : onConfirm,
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_shopping_cart, size: 18),
                label: Text(confirmLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
