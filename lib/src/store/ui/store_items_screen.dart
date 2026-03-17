import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/store/models/store_models.dart';
import 'package:helty/src/store/providers/store_providers.dart';

@RoutePage()
class StoreItemsScreen extends ConsumerStatefulWidget {
  const StoreItemsScreen({super.key});

  @override
  ConsumerState<StoreItemsScreen> createState() => _StoreItemsScreenState();
}

class _StoreItemsScreenState extends ConsumerState<StoreItemsScreen> {
  String? _filterCategoryId;
  bool? _filterIsActive = true;
  int _skip = 0;
  static const int _limit = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(storeCategoriesFutureProvider);
    final itemsParams = StoreItemsParams(
      categoryId: _filterCategoryId,
      isActive: _filterIsActive,
      limit: _limit,
      skip: _skip,
    );
    final asyncItems = ref.watch(storeItemsFutureProvider(itemsParams));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () {
              final list = categoriesAsync.valueOrNull?.data ?? [];
              _showCreateItem(context, ref, list);
            },
            tooltip: 'Add item',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                categoriesAsync.when(
                  data: (cats) {
                    final list = cats.data;
                    return DropdownButton<String?>(
                      value: _filterCategoryId,
                      hint: const Text('All categories'),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All categories'),
                        ),
                        ...list.map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _filterCategoryId = v),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 16),
                SegmentedButton<bool?>(
                  segments: const [
                    ButtonSegment(value: null, label: Text('All')),
                    ButtonSegment(value: true, label: Text('Active')),
                    ButtonSegment(value: false, label: Text('Inactive')),
                  ],
                  selected: {_filterIsActive},
                  onSelectionChanged: (s) =>
                      setState(() => _filterIsActive = s.first),
                ),
              ],
            ),
          ),
          Expanded(
            child: asyncItems.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(err.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => ref.invalidate(
                          storeItemsFutureProvider(itemsParams),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (response) {
                final list = response.data;
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No items yet',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: () {
                            final list =
                                categoriesAsync.valueOrNull?.data ?? [];
                            _showCreateItem(context, ref, list);
                          },
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add item'),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: list.length + 1,
                  itemBuilder: (context, index) {
                    if (index == list.length) {
                      final hasMore =
                          (response.skip ?? 0) + list.length < response.total;
                      if (!hasMore) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Center(
                          child: TextButton(
                            onPressed: () => setState(() => _skip += _limit),
                            child: const Text('Load more'),
                          ),
                        ),
                      );
                    }
                    final item = list[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Icon(
                            Icons.inventory_rounded,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(item.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.sku != null && item.sku!.isNotEmpty)
                              Text(
                                'SKU: ${item.sku}',
                                style: theme.textTheme.bodySmall,
                              ),
                            Text(
                              '${item.unitOfMeasure} • Reorder: ${item.reorderLevel}',
                              style: theme.textTheme.bodySmall,
                            ),
                            if (item.category != null)
                              Text(
                                item.category!.name,
                                style: theme.textTheme.bodySmall,
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                item.isActive ? 'Active' : 'Inactive',
                                style: theme.textTheme.labelSmall,
                              ),
                              backgroundColor: item.isActive
                                  ? theme.colorScheme.primaryContainer
                                  : theme.colorScheme.surfaceContainerHighest,
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded),
                              onPressed: () {
                                final list =
                                    categoriesAsync.valueOrNull?.data ?? [];
                                _showEditItem(context, ref, item, list);
                              },
                            ),
                          ],
                        ),
                        onTap: () {
                          final list = categoriesAsync.valueOrNull?.data ?? [];
                          _showEditItem(context, ref, item, list);
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final list = categoriesAsync.valueOrNull?.data ?? [];
          _showCreateItem(context, ref, list);
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add item'),
      ),
    );
  }

  Future<void> _submitCreateItem(
    BuildContext ctx,
    WidgetRef ref,
    TextEditingController nameController,
    TextEditingController skuController,
    TextEditingController uomController,
    TextEditingController reorderController,
    String? categoryId,
    bool isActive,
  ) async {
    final name = nameController.text.trim();
    final uom = uomController.text.trim();
    if (name.isEmpty || categoryId == null || uom.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Name, category and unit of measure are required'),
        ),
      );
      return;
    }
    final reorder = double.tryParse(reorderController.text.trim()) ?? 0;
    try {
      await ref
          .read(storeApiServiceProvider)
          .createItem(
            CreateStoreItemDto(
              name: name,
              sku: skuController.text.trim().isEmpty
                  ? null
                  : skuController.text.trim(),
              categoryId: categoryId,
              unitOfMeasure: uom,
              reorderLevel: reorder < 0 ? 0 : reorder,
              isActive: isActive,
            ),
          );
      if (ctx.mounted) Navigator.pop(ctx);
      ref.invalidate(
        storeItemsFutureProvider(
          StoreItemsParams(
            categoryId: _filterCategoryId,
            isActive: _filterIsActive,
            limit: _limit,
            skip: _skip,
          ),
        ),
      );
      if (ctx.mounted) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(const SnackBar(content: Text('Item created')));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _submitEditItem(
    BuildContext ctx,
    WidgetRef ref,
    String itemId,
    TextEditingController nameController,
    TextEditingController skuController,
    TextEditingController uomController,
    TextEditingController reorderController,
    String? categoryId,
    bool isActive,
  ) async {
    final name = nameController.text.trim();
    final uom = uomController.text.trim();
    if (name.isEmpty || categoryId == null || uom.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(
          content: Text('Name, category and unit of measure are required'),
        ),
      );
      return;
    }
    final reorder = double.tryParse(reorderController.text.trim()) ?? 0;
    try {
      await ref
          .read(storeApiServiceProvider)
          .updateItem(
            itemId,
            UpdateStoreItemDto(
              name: name,
              sku: skuController.text.trim().isEmpty
                  ? null
                  : skuController.text.trim(),
              categoryId: categoryId,
              unitOfMeasure: uom,
              reorderLevel: reorder < 0 ? 0 : reorder,
              isActive: isActive,
            ),
          );
      if (ctx.mounted) Navigator.pop(ctx);
      ref.invalidate(
        storeItemsFutureProvider(
          StoreItemsParams(
            categoryId: _filterCategoryId,
            isActive: _filterIsActive,
            limit: _limit,
            skip: _skip,
          ),
        ),
      );
      if (ctx.mounted) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(const SnackBar(content: Text('Item updated')));
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(
          ctx,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  void _showCreateItem(
    BuildContext context,
    WidgetRef ref,
    List<StoreCategory> categories,
  ) {
    if (categories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create at least one category first')),
      );
      return;
    }
    final nameController = TextEditingController();
    final skuController = TextEditingController();
    final uomController = TextEditingController(text: 'unit');
    final reorderController = TextEditingController(text: '0');
    String? categoryId = categories.first.id;
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('New item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Item name',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: skuController,
                    decoration: const InputDecoration(
                      labelText: 'SKU (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => categoryId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: uomController,
                    decoration: const InputDecoration(
                      labelText: 'Unit of measure',
                      hintText: 'e.g. unit, box, pack',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reorderController,
                    decoration: const InputDecoration(
                      labelText: 'Reorder level',
                      hintText: '0',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: isActive,
                    onChanged: (v) =>
                        setDialogState(() => isActive = v ?? true),
                    title: const Text('Active'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => _submitCreateItem(
                  ctx,
                  ref,
                  nameController,
                  skuController,
                  uomController,
                  reorderController,
                  categoryId,
                  isActive,
                ),
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showEditItem(
    BuildContext context,
    WidgetRef ref,
    StoreItem item,
    List<StoreCategory> categories,
  ) {
    final nameController = TextEditingController(text: item.name);
    final skuController = TextEditingController(text: item.sku ?? '');
    final uomController = TextEditingController(text: item.unitOfMeasure);
    final reorderController = TextEditingController(
      text: item.reorderLevel.toString(),
    );
    String? categoryId = item.categoryId;
    bool isActive = item.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: skuController,
                    decoration: const InputDecoration(
                      labelText: 'SKU (optional)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map(
                          (c) => DropdownMenuItem(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setDialogState(() => categoryId = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: uomController,
                    decoration: const InputDecoration(
                      labelText: 'Unit of measure',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reorderController,
                    decoration: const InputDecoration(
                      labelText: 'Reorder level',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  CheckboxListTile(
                    value: isActive,
                    onChanged: (v) =>
                        setDialogState(() => isActive = v ?? true),
                    title: const Text('Active'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => _submitEditItem(
                  ctx,
                  ref,
                  item.id,
                  nameController,
                  skuController,
                  uomController,
                  reorderController,
                  categoryId,
                  isActive,
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
