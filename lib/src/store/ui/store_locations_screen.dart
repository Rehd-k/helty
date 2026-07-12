import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/store/models/store_models.dart';
import 'package:helty/src/store/providers/store_providers.dart';

@RoutePage()
class StoreLocationsScreen extends ConsumerWidget {
  const StoreLocationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final asyncLocations = ref.watch(storeLocationsFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _showCreateLocation(context, ref),
            tooltip: 'Add location',
          ),
        ],
      ),
      body: ResponsiveBody(
        builder: (context, bp) => asyncLocations.when(
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
                  onPressed: () => ref.invalidate(storeLocationsFutureProvider),
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
                    Icons.place_outlined,
                    size: 64,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No locations yet',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _showCreateLocation(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add location'),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final loc = list[index];
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
                      Icons.place_rounded,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: Text(loc.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (loc.code.isNotEmpty)
                        Text('Code: ${loc.code}',
                            style: theme.textTheme.bodySmall),
                      if (loc.description != null &&
                          loc.description!.isNotEmpty)
                        Text(loc.description!,
                            style: theme.textTheme.bodySmall),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (loc.isPrimary)
                        Chip(
                          label: Text(
                            'Primary',
                            style: theme.textTheme.labelSmall,
                          ),
                          backgroundColor:
                              theme.colorScheme.tertiaryContainer,
                        ),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(
                          loc.isActive ? 'Active' : 'Inactive',
                          style: theme.textTheme.labelSmall,
                        ),
                        backgroundColor: loc.isActive
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_rounded),
                        onPressed: () =>
                            _showEditLocation(context, ref, loc),
                      ),
                    ],
                  ),
                  onTap: () => _showEditLocation(context, ref, loc),
                ),
              );
            },
          );
        },
      ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateLocation(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add location'),
      ),
    );
  }

  void _showCreateLocation(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final codeController = TextEditingController();
    final descController = TextEditingController();
    bool isPrimary = false;
    bool isActive = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('New location'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'e.g. Main store',
                    ),
                    autofocus: true,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Code',
                      hintText: 'e.g. MAIN',
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
                    value: isPrimary,
                    onChanged: (v) =>
                        setDialogState(() => isPrimary = v ?? false),
                    title: const Text('Primary location'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
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
                onPressed: () => _submitCreateLocation(
                  ctx,
                  ref,
                  nameController,
                  codeController,
                  descController,
                  isPrimary,
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

  Future<void> _submitCreateLocation(
    BuildContext ctx,
    WidgetRef ref,
    TextEditingController nameController,
    TextEditingController codeController,
    TextEditingController descController,
    bool isPrimary,
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
      await ref.read(storeApiServiceProvider).createLocation(
            CreateStoreLocationDto(
              name: name,
              code: code,
              description: descController.text.trim().isEmpty
                  ? null
                  : descController.text.trim(),
              isPrimary: isPrimary,
              isActive: isActive,
            ),
          );
      if (ctx.mounted) Navigator.pop(ctx);
      ref.invalidate(storeLocationsFutureProvider);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Location created')),
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

  Future<void> _submitEditLocation(
    BuildContext ctx,
    WidgetRef ref,
    String locationId,
    TextEditingController nameController,
    TextEditingController codeController,
    TextEditingController descController,
    bool isPrimary,
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
      await ref.read(storeApiServiceProvider).updateLocation(
            locationId,
            UpdateStoreLocationDto(
              name: name,
              code: code,
              description: descController.text.trim().isEmpty
                  ? null
                  : descController.text.trim(),
              isPrimary: isPrimary,
              isActive: isActive,
            ),
          );
      if (ctx.mounted) Navigator.pop(ctx);
      ref.invalidate(storeLocationsFutureProvider);
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Location updated')),
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

  void _showEditLocation(
      BuildContext context, WidgetRef ref, StoreLocation loc) {
    final nameController = TextEditingController(text: loc.name);
    final codeController = TextEditingController(text: loc.code);
    final descController =
        TextEditingController(text: loc.description ?? '');
    bool isPrimary = loc.isPrimary;
    bool isActive = loc.isActive;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Edit location'),
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
                    value: isPrimary,
                    onChanged: (v) =>
                        setDialogState(() => isPrimary = v ?? false),
                    title: const Text('Primary location'),
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
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
                onPressed: () => _submitEditLocation(
                  ctx,
                  ref,
                  loc.id,
                  nameController,
                  codeController,
                  descController,
                  isPrimary,
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
