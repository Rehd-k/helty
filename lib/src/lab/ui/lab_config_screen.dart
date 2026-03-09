import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/providers/lab_providers.dart';

@RoutePage()
class LabConfigScreen extends ConsumerStatefulWidget {
  const LabConfigScreen({super.key});

  @override
  ConsumerState<LabConfigScreen> createState() => _LabConfigScreenState();
}

class _LabConfigScreenState extends ConsumerState<LabConfigScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab configuration'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Categories', icon: Icon(Icons.category_rounded)),
            Tab(text: 'Tests', icon: Icon(Icons.science_rounded)),
            Tab(text: 'Versions', icon: Icon(Icons.history_rounded)),
            Tab(text: 'Fields', icon: Icon(Icons.list_alt_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_CategoriesTab(), _TestsTab(), _VersionsTab(), _FieldsTab()],
      ),
    );
  }
}

class _CategoriesTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncCategories = ref.watch(labCategoriesFutureProvider);
    return asyncCategories.when(
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
                onPressed: () => ref.invalidate(labCategoriesFutureProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (response) {
        final list = response.data;
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: list.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateCategory(context, ref),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add category'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              );
            }
            final cat = list[index - 1];
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
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.category_rounded,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(cat.name),
                subtitle: cat.description != null
                    ? Text(cat.description!)
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateCategory(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'e.g. Hematology',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              try {
                await ref
                    .read(labApiServiceProvider)
                    .createCategory(
                      name: name,
                      description: descController.text.trim().isEmpty
                          ? null
                          : descController.text.trim(),
                    );
                if (ctx.mounted) Navigator.pop(ctx);
                ref.invalidate(labCategoriesFutureProvider);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(
                    ctx,
                  ).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _TestsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncTests = ref.watch(labTestsFutureProvider);
    return asyncTests.when(
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
                onPressed: () => ref.invalidate(labTestsFutureProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (response) {
        final list = response.data;
        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: list.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ElevatedButton.icon(
                  onPressed: () => _showCreateTest(context, ref),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add test'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              );
            }
            final test = list[index - 1];
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
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.tertiaryContainer,
                  child: Icon(
                    Icons.science_rounded,
                    color: Theme.of(context).colorScheme.onTertiaryContainer,
                  ),
                ),
                title: Text(test.name),
                subtitle: Text(
                  '${test.category?.name ?? "—"} · ${test.sampleType}',
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCreateTest(BuildContext context, WidgetRef ref) async {
    final api = ref.read(labApiServiceProvider);
    final cats = await api.getCategories(take: 500);
    if (!context.mounted) return;
    final nameController = TextEditingController();
    final sampleController = TextEditingController();
    LabCategory? selectedCategory;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('New test'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<LabCategory>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: cats.data
                      .map(
                        (c) => DropdownMenuItem(value: c, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => selectedCategory = v),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Test name',
                    hintText: 'e.g. CBC',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: sampleController,
                  decoration: const InputDecoration(
                    labelText: 'Sample type',
                    hintText: 'e.g. Blood',
                  ),
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
              onPressed: () async {
                final name = nameController.text.trim();
                final sample = sampleController.text.trim();
                if (name.isEmpty ||
                    sample.isEmpty ||
                    selectedCategory == null) {
                  return;
                }
                try {
                  await api.createTest(
                    categoryId: selectedCategory!.id,
                    name: name,
                    sampleType: sample,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  ref.invalidate(labTestsFutureProvider);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(
                      ctx,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VersionsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_VersionsTab> createState() => _VersionsTabState();
}

class _VersionsTabState extends ConsumerState<_VersionsTab> {
  String? _selectedTestId;
  List<LabTestVersion>? _versions;
  bool _loadingVersions = false;
  String? _versionError;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final asyncTests = ref.watch(labTestsFutureProvider);
    return asyncTests.when(
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
                onPressed: () => ref.invalidate(labTestsFutureProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (response) {
        final tests = response.data;
        final selectedTest = _selectedTestId == null
            ? null
            : tests.where((t) => t.id == _selectedTestId).firstOrNull;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Select a test to manage versions',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LabTest>(
              initialValue: selectedTest,
              decoration: const InputDecoration(
                labelText: 'Test',
                border: OutlineInputBorder(),
              ),
              items: tests
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text('${t.name} (${t.category?.name ?? "—"})'),
                    ),
                  )
                  .toList(),
              onChanged: (t) {
                setState(() {
                  _selectedTestId = t?.id;
                  _versions = null;
                  _versionError = null;
                  if (t != null) _loadVersions(ref, t.id);
                });
              },
            ),
            if (_selectedTestId != null) ...[
              const SizedBox(height: 24),
              if (_loadingVersions)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_versionError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _versionError!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Versions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _selectedTestId == null
                          ? null
                          : () => _createVersion(context, ref),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Create version'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_versions == null || _versions!.isEmpty)
                  Card(
                    child: const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No versions yet. Create one to define result fields.',
                        ),
                      ),
                    ),
                  )
                else
                  ..._versions!.map(
                    (v) => Card(
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
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Text(
                            'v${v.versionNumber}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        title: Text(
                          'Version ${v.versionNumber}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          v.isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: v.isActive
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            fontWeight: v.isActive
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ],
        );
      },
    );
  }

  Future<void> _loadVersions(WidgetRef ref, String testId) async {
    setState(() {
      _loadingVersions = true;
      _versionError = null;
    });
    try {
      final list = await ref
          .read(labApiServiceProvider)
          .getTestVersions(testId);
      if (mounted) {
        setState(() {
          _versions = list;
          _loadingVersions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _versionError = e.toString();
          _loadingVersions = false;
        });
      }
    }
  }

  Future<void> _createVersion(BuildContext context, WidgetRef ref) async {
    final testId = _selectedTestId;
    if (testId == null) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    try {
      await ref
          .read(labApiServiceProvider)
          .createTestVersion(testId, setActive: true);
      if (!context.mounted) return;
      ref.invalidate(labTestsFutureProvider);
      setState(() {
        _versions = null;
      });
      _loadVersions(ref, testId);
      messenger?.showSnackBar(
        const SnackBar(content: Text('Version created and set active')),
      );
    } catch (e) {
      if (context.mounted && messenger != null) {
        messenger.showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }
}

class _FieldsTab extends ConsumerStatefulWidget {
  @override
  ConsumerState<_FieldsTab> createState() => _FieldsTabState();
}

class _FieldsTabState extends ConsumerState<_FieldsTab> {
  String? _selectedTestId;
  String? _selectedVersionId;
  List<LabTestVersion>? _versions;
  List<LabTestField>? _fields;
  bool _loadingVersions = false;
  bool _loadingFields = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final asyncTests = ref.watch(labTestsFutureProvider);
    return asyncTests.when(
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
                onPressed: () => ref.invalidate(labTestsFutureProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (response) {
        final tests = response.data;
        final selectedTest = _selectedTestId == null
            ? null
            : tests.where((t) => t.id == _selectedTestId).firstOrNull;
        final selectedVersion = _versions == null || _selectedVersionId == null
            ? null
            : _versions!.where((v) => v.id == _selectedVersionId).firstOrNull;
        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Select test and version to manage result fields',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<LabTest>(
              initialValue: selectedTest,
              decoration: const InputDecoration(
                labelText: 'Test',
                border: OutlineInputBorder(),
              ),
              items: tests
                  .map(
                    (t) => DropdownMenuItem(
                      value: t,
                      child: Text('${t.name} (${t.category?.name ?? "—"})'),
                    ),
                  )
                  .toList(),
              onChanged: (t) {
                setState(() {
                  _selectedTestId = t?.id;
                  _selectedVersionId = null;
                  _versions = null;
                  _fields = null;
                  _error = null;
                  if (t != null) _loadVersions(ref, t.id);
                });
              },
            ),
            if (_selectedTestId != null && _loadingVersions)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (_selectedTestId != null &&
                _versions != null &&
                !_loadingVersions) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<LabTestVersion>(
                initialValue: selectedVersion,
                decoration: const InputDecoration(
                  labelText: 'Version',
                  border: OutlineInputBorder(),
                ),
                items: _versions!
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(
                          'v${v.versionNumber}${v.isActive ? ' (active)' : ''}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedVersionId = v?.id;
                    _fields = null;
                    _error = null;
                    if (v != null) _loadFields(ref, v.id);
                  });
                },
              ),
            ],
            if (_selectedVersionId != null) ...[
              const SizedBox(height: 24),
              if (_loadingFields)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Result fields',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () => _showAddField(context, ref),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add field'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                if (_fields == null || _fields!.isEmpty)
                  Card(
                    child: const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'No fields yet. Add fields to build the result form (e.g. TEXT, NUMBER, DROPDOWN, DATE).',
                        ),
                      ),
                    ),
                  )
                else
                  ...(_fields!
                        ..sort((a, b) => a.position.compareTo(b.position)))
                      .map(
                        (f) => Card(
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
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.tertiaryContainer,
                              child: Icon(
                                _iconForFieldType(f.fieldType),
                                size: 20,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onTertiaryContainer,
                              ),
                            ),
                            title: Text(
                              f.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '${f.fieldType.name.toUpperCase()}${f.required ? ' · Required' : ''}${f.unit != null ? ' · ${f.unit}' : ''}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ),
                      ),
              ],
            ],
          ],
        );
      },
    );
  }

  static IconData _iconForFieldType(LabFieldType t) {
    switch (t) {
      case LabFieldType.text:
        return Icons.text_fields_rounded;
      case LabFieldType.number:
        return Icons.numbers_rounded;
      case LabFieldType.dropdown:
        return Icons.arrow_drop_down_rounded;
      case LabFieldType.checkbox:
        return Icons.check_box_rounded;
      case LabFieldType.multiselect:
        return Icons.checklist_rounded;
      case LabFieldType.date:
        return Icons.calendar_today_rounded;
    }
  }

  Future<void> _loadVersions(WidgetRef ref, String testId) async {
    setState(() {
      _loadingVersions = true;
      _error = null;
    });
    try {
      final list = await ref
          .read(labApiServiceProvider)
          .getTestVersions(testId);
      if (mounted) {
        final firstVersionId = list.isNotEmpty ? list.first.id : null;
        setState(() {
          _versions = list;
          _loadingVersions = false;
          _selectedVersionId = firstVersionId;
          _fields = null;
        });
        if (firstVersionId != null) {
          _loadFields(ref, firstVersionId);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadingVersions = false;
        });
      }
    }
  }

  Future<void> _loadFields(WidgetRef ref, String versionId) async {
    setState(() {
      _loadingFields = true;
      _error = null;
    });
    try {
      final list = await ref
          .read(labApiServiceProvider)
          .getTestFields(versionId);
      if (mounted) {
        setState(() {
          _fields = list;
          _loadingFields = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loadingFields = false;
        });
      }
    }
  }

  Future<void> _showAddField(BuildContext context, WidgetRef ref) async {
    if (_selectedVersionId == null) return;
    final labelController = TextEditingController();
    final unitController = TextEditingController();
    final refRangeController = TextEditingController();
    final optionsController = TextEditingController();
    final positionController = TextEditingController(
      text: (_fields?.length ?? 0).toString(),
    );
    LabFieldType selectedType = LabFieldType.text;
    bool required = false;

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add result field'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label',
                    hintText: 'e.g. Haemoglobin',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<LabFieldType>(
                  initialValue: selectedType,
                  decoration: const InputDecoration(labelText: 'Field type'),
                  items: LabFieldType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedType = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: unitController,
                  decoration: const InputDecoration(
                    labelText: 'Unit (optional)',
                    hintText: 'e.g. g/dL',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: refRangeController,
                  decoration: const InputDecoration(
                    labelText: 'Reference range (optional)',
                    hintText: 'e.g. 12-16',
                  ),
                ),
                const SizedBox(height: 12),
                if (selectedType == LabFieldType.dropdown ||
                    selectedType == LabFieldType.multiselect)
                  TextField(
                    controller: optionsController,
                    decoration: const InputDecoration(
                      labelText: 'Options (JSON)',
                      hintText: '["A","B"] or [{"value":"a","label":"A"}]',
                    ),
                    maxLines: 2,
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: positionController,
                  decoration: const InputDecoration(
                    labelText: 'Position (order)',
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Required'),
                  value: required,
                  onChanged: (v) => setDialogState(() => required = v ?? false),
                  contentPadding: EdgeInsets.zero,
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
              onPressed: () async {
                final label = labelController.text.trim();
                if (label.isEmpty) return;
                final api = ref.read(labApiServiceProvider);
                String? optionsJson;
                if (selectedType == LabFieldType.dropdown ||
                    selectedType == LabFieldType.multiselect) {
                  final opt = optionsController.text.trim();
                  if (opt.isNotEmpty) optionsJson = opt;
                }
                try {
                  final position =
                      int.tryParse(positionController.text.trim()) ??
                      (_fields?.length ?? 0);
                  await api.createTestField(
                    testVersionId: _selectedVersionId!,
                    label: label,
                    fieldType: selectedType.name.toUpperCase(),
                    unit: unitController.text.trim().isEmpty
                        ? null
                        : unitController.text.trim(),
                    referenceRange: refRangeController.text.trim().isEmpty
                        ? null
                        : refRangeController.text.trim(),
                    required: required,
                    position: position,
                    optionsJson: optionsJson,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  ref.invalidate(labTestsFutureProvider);
                  _loadFields(ref, _selectedVersionId!);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(
                      ctx,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }
}
