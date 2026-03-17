import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/store/models/store_models.dart';
import 'package:helty/src/store/providers/store_providers.dart';

@RoutePage()
class StoreCategoriesScreen extends ConsumerWidget {
  const StoreCategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncCategories = ref.watch(storeCategoriesFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateCategory(context, ref),
            tooltip: 'Add category',
          ),
        ],
      ),
      body: asyncCategories.when(
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
                  onPressed: () => ref.invalidate(storeCategoriesFutureProvider),
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
                    Icons.category_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No categories yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _showCreateCategory(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add category'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final cat = list[index];
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
                      Icons.category_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(cat.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (cat.code.isNotEmpty)
                        Text('Code: ${cat.code}',
                            style: theme.textTheme.bodySmall),
                      if (cat.description != null &&
                          cat.description!.isNotEmpty)
                        Text(cat.description!,
                            style: theme.textTheme.bodySmall),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Chip(
                        label: Text(
                          cat.isActive ? 'Active' : 'Inactive',
                          style: theme.textTheme.labelSmall,
                        ),
                        backgroundColor: cat.isActive
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () =>
                            _showEditCategory(context, ref, cat),
                      ),
                    ],
                  ),
                  onTap: () => _showEditCategory(context, ref, cat),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateCategory(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add category'),
      ),
    );
  }

  Future<void> _submitCreateCategory(
    BuildContext ctx,
    WidgetRef ref,
    TextEditingController nameController,
    TextEditingController codeController,
    TextEditingController descController,
    bool isActive,
  ) async {
    final name = nameController.text.trim();
    final code = codeController.text.trim();
    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Name and code are required')),
      );
      return;
    }
    try {
      await ref.read(storeApiServiceProvider).createCategory(
            CreateStoreCategoryDto(
              name: name,
              code: code,
              description: descController.text.trim().isEmpty
                  ? null
                  : descController.text.trim(),
              isActive: isActive,
            ),
          );
      if (ctx.mounted) Navigator.pop(ctx);
      ref.invalidate(storeCategoriesFutureProvider);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Category created')),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _showCreateCategory(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descController = TextEditingController();
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('New category'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Consumables',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Code',
                      hintText: 'e.g. CONS',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                    ),
                    maxLines: 2,
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
                onPressed: () => _submitCreateCategory(
                  ctx,
                  ref,
                  nameController,
                  codeController,
                  descController,
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

  Future<void> _submitEditCategory(
    BuildContext ctx,
    WidgetRef ref,
    String categoryId,
    TextEditingController nameController,
    TextEditingController codeController,
    TextEditingController descController,
    bool isActive,
  ) async {
    final name = nameController.text.trim();
    final code = codeController.text.trim();
    if (name.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Name and code are required')),
      );
      return;
    }
    try {
      await ref.read(storeApiServiceProvider).updateCategory(
            categoryId,
            UpdateStoreCategoryDto(
              name: name,
              code: code,
              description: descController.text.trim().isEmpty
                  ? null
                  : descController.text.trim(),
              isActive: isActive,
            ),
          );
      if (ctx.mounted) Navigator.pop(ctx);
      ref.invalidate(storeCategoriesFutureProvider);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Category updated')),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  void _showEditCategory(
      BuildContext context, WidgetRef ref, StoreCategory cat) {
    final nameController = TextEditingController(text: cat.name);
    final codeController = TextEditingController(text: cat.code);
    final descController =
        TextEditingController(text: cat.description ?? '');
    bool isActive = cat.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit category'),
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
                    controller: codeController,
                    decoration: const InputDecoration(labelText: 'Code'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(
                        labelText: 'Description (optional)'),
                    maxLines: 2,
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
                onPressed: () => _submitEditCategory(
                  ctx,
                  ref,
                  cat.id,
                  nameController,
                  codeController,
                  descController,
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
