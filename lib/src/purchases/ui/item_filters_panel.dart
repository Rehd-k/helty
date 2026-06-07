import 'package:flutter/material.dart';

import '../models/purchases_model.dart';

class ItemFiltersPanel extends StatelessWidget {
  const ItemFiltersPanel({
    super.key,
    required this.params,
    required this.onChanged,
    required this.manufacturers,
    required this.suppliers,
    required this.onApply,
    required this.onClear,
  });

  final SearchPurchaseItemParams params;
  final ValueChanged<SearchPurchaseItemParams> onChanged;
  final List<PurchasesManufacturer> manufacturers;
  final List<PurchasesSupplier> suppliers;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => onChanged(
                SearchPurchaseItemParams(
                  itemName: v.isEmpty ? null : v,
                  search: params.search,
                  manufacturerId: params.manufacturerId,
                  supplierId: params.supplierId,
                  inStock: params.inStock,
                  lowStock: params.lowStock,
                  expiringSoon: params.expiringSoon,
                  page: params.page,
                  pageSize: params.pageSize,
                ),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: params.manufacturerId,
              decoration: const InputDecoration(
                labelText: 'Manufacturer',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('All')),
                ...manufacturers.map(
                  (m) => DropdownMenuItem(value: m.id, child: Text(m.name)),
                ),
              ],
              onChanged: (v) => onChanged(
                SearchPurchaseItemParams(
                  itemName: params.itemName,
                  search: params.search,
                  manufacturerId: v,
                  supplierId: params.supplierId,
                  inStock: params.inStock,
                  lowStock: params.lowStock,
                  expiringSoon: params.expiringSoon,
                  page: params.page,
                  pageSize: params.pageSize,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('In Stock'),
                  selected: params.inStock == true,
                  onSelected: (s) => onChanged(
                    SearchPurchaseItemParams(
                      itemName: params.itemName,
                      search: params.search,
                      manufacturerId: params.manufacturerId,
                      supplierId: params.supplierId,
                      inStock: s ? true : null,
                      lowStock: params.lowStock,
                      expiringSoon: params.expiringSoon,
                      page: params.page,
                      pageSize: params.pageSize,
                    ),
                  ),
                ),
                FilterChip(
                  label: const Text('Low Stock'),
                  selected: params.lowStock == true,
                  onSelected: (s) => onChanged(
                    SearchPurchaseItemParams(
                      itemName: params.itemName,
                      search: params.search,
                      manufacturerId: params.manufacturerId,
                      supplierId: params.supplierId,
                      inStock: params.inStock,
                      lowStock: s ? true : null,
                      expiringSoon: params.expiringSoon,
                      page: params.page,
                      pageSize: params.pageSize,
                    ),
                  ),
                ),
                FilterChip(
                  label: const Text('Expiring Soon'),
                  selected: params.expiringSoon == true,
                  onSelected: (s) => onChanged(
                    SearchPurchaseItemParams(
                      itemName: params.itemName,
                      search: params.search,
                      manufacturerId: params.manufacturerId,
                      supplierId: params.supplierId,
                      inStock: params.inStock,
                      lowStock: params.lowStock,
                      expiringSoon: s ? true : null,
                      page: params.page,
                      pageSize: params.pageSize,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(onPressed: onApply, child: const Text('Apply')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: onClear, child: const Text('Clear')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
