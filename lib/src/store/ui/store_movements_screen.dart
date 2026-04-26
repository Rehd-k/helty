import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/services/department_service.dart';
import 'package:helty/src/store/models/store_models.dart';
import 'package:helty/src/store/providers/store_providers.dart';

@RoutePage()
class StoreMovementsScreen extends ConsumerStatefulWidget {
  const StoreMovementsScreen({super.key});

  @override
  ConsumerState<StoreMovementsScreen> createState() =>
      _StoreMovementsScreenState();
}

class _StoreMovementsScreenState extends ConsumerState<StoreMovementsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('Store movements'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Issue', icon: Icon(Icons.call_made_rounded)),
            Tab(text: 'Receive', icon: Icon(Icons.call_received_rounded)),
            Tab(text: 'Transfer', icon: Icon(Icons.swap_horiz_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _IssueTab(
            onSuccess: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Items issued'))),
          ),
          _ReceiveTab(
            onSuccess: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Items received'))),
          ),
          _TransferTab(
            onSuccess: () => ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Transfer completed'))),
          ),
        ],
      ),
    );
  }
}

class _IssueTab extends ConsumerStatefulWidget {
  const _IssueTab({required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  ConsumerState<_IssueTab> createState() => _IssueTabState();
}

class _IssueTabState extends ConsumerState<_IssueTab> {
  final _reasonController = TextEditingController();
  String? _departmentId;
  String? _fromLocationId;
  final List<({String itemId, double quantity, double? unitCost})> _lines = [];
  List<Department> _departments = [];
  List<StoreLocation> _locations = [];
  List<StoreItem> _items = [];
  bool _loadingOptions = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _loadingOptions = true);
    try {
      final api = ref.read(storeApiServiceProvider);
      final deptService = DepartmentService();
      final departments = await deptService.fetchDepartments();
      final locationsRes = await api.getLocations();
      final itemsRes = await api.getItems(limit: 100, skip: 0);
      if (!mounted) return;
      setState(() {
        _departments = departments;
        _locations = locationsRes.data;
        _items = itemsRes.data;
        _loadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingOptions = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _addLine() {
    setState(() {
      _lines.add((
        itemId: _items.isNotEmpty ? _items.first.id : '',
        quantity: 1,
        unitCost: null,
      ));
    });
  }

  void _removeLine(int index) {
    setState(() => _lines.removeAt(index));
  }

  Future<void> _submit() async {
    if (_departmentId == null || _fromLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select department and location')),
      );
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item line')),
      );
      return;
    }
    for (var i = 0; i < _lines.length; i++) {
      if (_lines[i].itemId.isEmpty || _lines[i].quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Line ${i + 1}: select item and quantity > 0'),
          ),
        );
        return;
      }
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(storeApiServiceProvider)
          .issueItems(
            IssueItemsRequest(
              departmentId: _departmentId!,
              fromLocationId: _fromLocationId!,
              reason: _reasonController.text.trim().isEmpty
                  ? null
                  : _reasonController.text.trim(),
              items: _lines
                  .map(
                    (l) => IssueItemLine(
                      itemId: l.itemId,
                      quantity: l.quantity,
                      unitCost: l.unitCost,
                    ),
                  )
                  .toList(),
            ),
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _lines.clear();
        _reasonController.clear();
      });
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loadingOptions) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _departmentId,
                    decoration: const InputDecoration(labelText: 'Department'),
                    items: _departments
                        .map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(d.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _departmentId = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _fromLocationId,
                    decoration: const InputDecoration(
                      labelText: 'From location (store)',
                    ),
                    items: _locations
                        .map(
                          (l) => DropdownMenuItem(
                            value: l.id,
                            child: Text(l.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _fromLocationId = v),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason (optional)',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items', style: theme.textTheme.titleMedium),
              TextButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add line'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...List.generate(_lines.length, (i) {
            final line = _lines[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: line.itemId.isEmpty ? null : line.itemId,
                        decoration: const InputDecoration(
                          labelText: 'Item',
                          isDense: true,
                        ),
                        items: _items
                            .map(
                              (it) => DropdownMenuItem(
                                value: it.id,
                                child: Text(it.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _lines[i] = (
                            itemId: v ?? '',
                            quantity: line.quantity,
                            unitCost: line.unitCost,
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: line.quantity.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final q = double.tryParse(v) ?? 0;
                          setState(() {
                            _lines[i] = (
                              itemId: line.itemId,
                              quantity: q,
                              unitCost: line.unitCost,
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: line.unitCost?.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Unit cost (opt)',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final c = double.tryParse(v);
                          setState(() {
                            _lines[i] = (
                              itemId: line.itemId,
                              quantity: line.quantity,
                              unitCost: c,
                            );
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: () => _removeLine(i),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Issue items'),
          ),
        ],
      ),
    );
  }
}

class _ReceiveTab extends ConsumerStatefulWidget {
  const _ReceiveTab({required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  ConsumerState<_ReceiveTab> createState() => _ReceiveTabState();
}

class _ReceiveTabState extends ConsumerState<_ReceiveTab> {
  final _reasonController = TextEditingController();
  final _refTypeController = TextEditingController();
  final _refIdController = TextEditingController();
  String? _toLocationId;
  String? _departmentId;
  final List<({String itemId, double quantity, double unitCost})> _lines = [];
  List<StoreLocation> _locations = [];
  List<Department> _departments = [];
  List<StoreItem> _items = [];
  bool _loadingOptions = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _refTypeController.dispose();
    _refIdController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _loadingOptions = true);
    try {
      final api = ref.read(storeApiServiceProvider);
      final deptService = DepartmentService();
      final locationsRes = await api.getLocations();
      final departments = await deptService.fetchDepartments();
      final itemsRes = await api.getItems(limit: 100, skip: 0);
      if (!mounted) return;
      setState(() {
        _locations = locationsRes.data;
        _departments = departments;
        _items = itemsRes.data;
        _loadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingOptions = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _addLine() {
    setState(() {
      _lines.add((
        itemId: _items.isNotEmpty ? _items.first.id : '',
        quantity: 1,
        unitCost: 0,
      ));
    });
  }

  void _removeLine(int index) {
    setState(() => _lines.removeAt(index));
  }

  Future<void> _submit() async {
    if (_toLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select receiving location')),
      );
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item line')),
      );
      return;
    }
    for (var i = 0; i < _lines.length; i++) {
      if (_lines[i].itemId.isEmpty || _lines[i].quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Line ${i + 1}: select item and quantity > 0'),
          ),
        );
        return;
      }
      if (_lines[i].unitCost < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Line ${i + 1}: unit cost must be >= 0')),
        );
        return;
      }
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(storeApiServiceProvider)
          .receiveItems(
            ReceiveItemsRequest(
              toLocationId: _toLocationId!,
              departmentId: _departmentId,
              reason: _reasonController.text.trim().isEmpty
                  ? null
                  : _reasonController.text.trim(),
              referenceType: _refTypeController.text.trim().isEmpty
                  ? null
                  : _refTypeController.text.trim(),
              referenceId: _refIdController.text.trim().isEmpty
                  ? null
                  : _refIdController.text.trim(),
              items: _lines
                  .map(
                    (l) => ReceiveItemLine(
                      itemId: l.itemId,
                      quantity: l.quantity,
                      unitCost: l.unitCost,
                    ),
                  )
                  .toList(),
            ),
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _lines.clear();
        _reasonController.clear();
        _refTypeController.clear();
        _refIdController.clear();
      });
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loadingOptions) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _toLocationId,
                    decoration: const InputDecoration(
                      labelText: 'To location (receiving)',
                    ),
                    items: _locations
                        .map(
                          (l) => DropdownMenuItem(
                            value: l.id,
                            child: Text(l.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _toLocationId = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    initialValue: _departmentId,
                    decoration: const InputDecoration(
                      labelText: 'Department (optional, for returns)',
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      ..._departments.map(
                        (d) =>
                            DropdownMenuItem(value: d.id, child: Text(d.name)),
                      ),
                    ],
                    onChanged: (v) => setState(() => _departmentId = v),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason (optional)',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _refTypeController,
                    decoration: const InputDecoration(
                      labelText: 'Reference type (e.g. PURCHASE_NOTE)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _refIdController,
                    decoration: const InputDecoration(
                      labelText: 'Reference ID (optional)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items', style: theme.textTheme.titleMedium),
              TextButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add line'),
              ),
            ],
          ),
          ...List.generate(_lines.length, (i) {
            final line = _lines[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: line.itemId.isEmpty ? null : line.itemId,
                        decoration: const InputDecoration(
                          labelText: 'Item',
                          isDense: true,
                        ),
                        items: _items
                            .map(
                              (it) => DropdownMenuItem(
                                value: it.id,
                                child: Text(it.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _lines[i] = (
                            itemId: v ?? '',
                            quantity: line.quantity,
                            unitCost: line.unitCost,
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: line.quantity.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final q = double.tryParse(v) ?? 0;
                          setState(() {
                            _lines[i] = (
                              itemId: line.itemId,
                              quantity: q,
                              unitCost: line.unitCost,
                            );
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: line.unitCost.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Unit cost',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final c = double.tryParse(v) ?? 0;
                          setState(() {
                            _lines[i] = (
                              itemId: line.itemId,
                              quantity: line.quantity,
                              unitCost: c,
                            );
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: () => _removeLine(i),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Receive items'),
          ),
        ],
      ),
    );
  }
}

class _TransferTab extends ConsumerStatefulWidget {
  const _TransferTab({required this.onSuccess});

  final VoidCallback onSuccess;

  @override
  ConsumerState<_TransferTab> createState() => _TransferTabState();
}

class _TransferTabState extends ConsumerState<_TransferTab> {
  final _reasonController = TextEditingController();
  String? _fromLocationId;
  String? _toLocationId;
  final List<({String itemId, double quantity})> _lines = [];
  List<StoreLocation> _locations = [];
  List<StoreItem> _items = [];
  bool _loadingOptions = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _loadingOptions = true);
    try {
      final api = ref.read(storeApiServiceProvider);
      final locationsRes = await api.getLocations();
      final itemsRes = await api.getItems(limit: 100, skip: 0);
      if (!mounted) return;
      setState(() {
        _locations = locationsRes.data;
        _items = itemsRes.data;
        _loadingOptions = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingOptions = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _addLine() {
    setState(() {
      _lines.add((
        itemId: _items.isNotEmpty ? _items.first.id : '',
        quantity: 1,
      ));
    });
  }

  void _removeLine(int index) {
    setState(() => _lines.removeAt(index));
  }

  Future<void> _submit() async {
    if (_fromLocationId == null || _toLocationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select from and to location')),
      );
      return;
    }
    if (_fromLocationId == _toLocationId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('From and to must be different')),
      );
      return;
    }
    if (_lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item line')),
      );
      return;
    }
    for (var i = 0; i < _lines.length; i++) {
      if (_lines[i].itemId.isEmpty || _lines[i].quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Line ${i + 1}: select item and quantity > 0'),
          ),
        );
        return;
      }
    }
    setState(() => _submitting = true);
    try {
      await ref
          .read(storeApiServiceProvider)
          .transferItems(
            TransferItemsRequest(
              fromLocationId: _fromLocationId!,
              toLocationId: _toLocationId!,
              reason: _reasonController.text.trim().isEmpty
                  ? null
                  : _reasonController.text.trim(),
              items: _lines
                  .map(
                    (l) => TransferItemLine(
                      itemId: l.itemId,
                      quantity: l.quantity,
                    ),
                  )
                  .toList(),
            ),
          );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _lines.clear();
        _reasonController.clear();
      });
      widget.onSuccess();
    } catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_loadingOptions) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _fromLocationId,
                    decoration: const InputDecoration(
                      labelText: 'From location',
                    ),
                    items: _locations
                        .map(
                          (l) => DropdownMenuItem(
                            value: l.id,
                            child: Text(l.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _fromLocationId = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _toLocationId,
                    decoration: const InputDecoration(labelText: 'To location'),
                    items: _locations
                        .map(
                          (l) => DropdownMenuItem(
                            value: l.id,
                            child: Text(l.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _toLocationId = v),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reasonController,
                    decoration: const InputDecoration(
                      labelText: 'Reason (optional)',
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Items', style: theme.textTheme.titleMedium),
              TextButton.icon(
                onPressed: _addLine,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add line'),
              ),
            ],
          ),
          ...List.generate(_lines.length, (i) {
            final line = _lines[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        initialValue: line.itemId.isEmpty ? null : line.itemId,
                        decoration: const InputDecoration(
                          labelText: 'Item',
                          isDense: true,
                        ),
                        items: _items
                            .map(
                              (it) => DropdownMenuItem(
                                value: it.id,
                                child: Text(it.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() {
                          _lines[i] = (
                            itemId: v ?? '',
                            quantity: line.quantity,
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        initialValue: line.quantity.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Qty',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (v) {
                          final q = double.tryParse(v) ?? 0;
                          setState(() {
                            _lines[i] = (itemId: line.itemId, quantity: q);
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline_rounded),
                      onPressed: () => _removeLine(i),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Transfer'),
          ),
        ],
      ),
    );
  }
}
