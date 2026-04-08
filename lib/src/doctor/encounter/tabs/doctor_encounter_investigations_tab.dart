import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/models/lab_order_model.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/services/service_category_service.dart';
import 'package:helty/src/services/lab_order_service.dart';
import 'package:helty/src/services/service_service.dart';

@RoutePage()
class DoctorEncounterInvestigationsTab extends StatefulWidget {
  const DoctorEncounterInvestigationsTab({super.key});

  @override
  State<DoctorEncounterInvestigationsTab> createState() =>
      _DoctorEncounterInvestigationsTabState();
}

class _DoctorEncounterInvestigationsTabState
    extends State<DoctorEncounterInvestigationsTab> {
  final _serviceService = ServiceService();
  final _labOrderService = LabOrderService();

  List<LabOrderModel> _orders = [];
  bool _loading = true;
  bool _loadScheduled = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadScheduled) {
      _loadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    setState(() => _loading = true);
    final list = await _labOrderService.getByEncounter(scope.encounterId);
    if (!mounted) return;
    setState(() {
      _orders = list;
      _loading = false;
    });
  }

  void _showLabOrderResults(
      BuildContext context, LabOrderModel order, ThemeData theme) {
    final hasResults = order.resultValues != null && order.resultValues!.isNotEmpty;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(order.testType),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ResultRow(label: 'Status', value: order.status),
                _ResultRow(label: 'Priority', value: order.priority ?? 'Routine'),
                if (order.clinicalNotes != null && order.clinicalNotes!.isNotEmpty)
                  _ResultRow(label: 'Notes', value: order.clinicalNotes!),
                const SizedBox(height: 16),
                Text(
                  'Results',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (hasResults)
                  ...order.resultValues!.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 140,
                            child: Text(
                              e.key,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              e.value,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text(
                    'No results yet.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _openOrderModal() async {
    final scope = EncounterScope.of(context);
    final patientId = scope?.patientId;
    final staffId = scope?.doctorId;
    if (scope == null) return;

    final result = await showDialog<_LabOrderDialogResult>(
      context: context,
      builder: (ctx) => _OrderLabTestDialog(serviceService: _serviceService),
    );

    if (result == null || result.selected.isEmpty || !mounted) return;

    final notes = result.notes.trim();
    for (final service in result.selected) {
      await _labOrderService.create(
        encounterId: scope.encounterId,
        patientId: patientId!,
        testType: service.name,
        staffId: staffId!,
        // Use canonical service template id to preserve invoice linkage behavior.
        serviceId: service.serviceId.isNotEmpty ? service.serviceId : service.id,
        priority: result.priority,
        notes: notes.isEmpty ? null : notes,
      );
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${result.selected.length} lab order(s) added')),
      );
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = EncounterScope.of(context);
    if (scope == null) {
      return const Padding(
        padding: EdgeInsets.all(24.0),
        child: Center(child: Text('Encounter context not available')),
      );
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _openOrderModal,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Order Lab Test'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _orders.isEmpty
                ? Center(
                    child: Text(
                      'No lab orders. Tap "Order Lab Test" to add.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _orders.length,
                    itemBuilder: (_, i) {
                      final o = _orders[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(o.testType),
                          subtitle: Text(
                            '${o.priority ?? "Routine"} • ${o.status}',
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Chip(
                            label: Text(o.status),
                            backgroundColor: theme.colorScheme.primaryContainer,
                          ),
                          onTap: () => _showLabOrderResults(context, o, theme),
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

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _LabOrderDialogResult {
  _LabOrderDialogResult({
    required this.selected,
    required this.priority,
    required this.notes,
  });
  final List<ServiceModel> selected;
  final String priority;
  final String notes;
}

class _OrderLabTestDialog extends StatefulWidget {
  const _OrderLabTestDialog({required this.serviceService});

  final ServiceService serviceService;

  @override
  State<_OrderLabTestDialog> createState() => _OrderLabTestDialogState();
}

class _OrderLabTestDialogState extends State<_OrderLabTestDialog> {
  static const int pageSize = 10;
  static const _labCategoryNames = <String>{'laboratory', 'laboratory tests'};

  final _searchCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _categoryService = ServiceCategoryService();
  final _selected = <ServiceModel>[];
  List<ServiceModel> _searchResults = [];
  bool _searchLoading = false;
  int _page = 0;
  String _priority = 'Routine';
  Timer? _searchDebounce;
  Set<String>? _labCategoryIds;

  bool _isLabService(ServiceModel s) {
    final byName = (s.categoryName ?? '').trim().toLowerCase();
    if (_labCategoryNames.contains(byName)) return true;
    final cid = s.categoryId?.trim();
    if (cid != null && cid.isNotEmpty && _labCategoryIds != null) {
      return _labCategoryIds!.contains(cid);
    }
    return false;
  }

  Future<void> _ensureLabCategoryIds() async {
    if (_labCategoryIds != null) return;
    final categories = await _categoryService.fetchCategories();
    final ids = categories
        .where((c) => _labCategoryNames.contains(c.name.trim().toLowerCase()))
        .map((c) => c.id)
        .toSet();
    _labCategoryIds = ids;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _notesCtrl.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _runSearch({int skip = 0, bool append = false}) async {
    setState(() => _searchLoading = true);
    await _ensureLabCategoryIds();
    final q = _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim();

    List<ServiceModel> list = const [];
    if (_labCategoryIds != null && _labCategoryIds!.isNotEmpty) {
      final batches = await Future.wait(
        _labCategoryIds!.map(
          (categoryId) => widget.serviceService.fetchServices(
            query: q,
            categoryId: categoryId,
            skip: skip,
            take: pageSize,
          ),
        ),
      );
      final seen = <String>{};
      final merged = <ServiceModel>[];
      for (final batch in batches) {
        for (final s in batch) {
          final key = s.id.isNotEmpty ? s.id : s.serviceId;
          if (key.isEmpty || seen.contains(key)) continue;
          seen.add(key);
          merged.add(s);
        }
      }
      list = merged;
    } else {
      // Fallback for environments where category records are missing.
      list = await widget.serviceService.fetchServices(
        query: q,
        skip: skip,
        take: pageSize,
      );
    }

    if (!mounted) return;
    final filtered = list.where(_isLabService).toList();
    setState(() {
      if (append) {
        _searchResults = [..._searchResults, ...filtered];
      } else {
        _searchResults = filtered;
      }
      _searchLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Order Lab Test'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Routine', child: Text('Routine')),
                  DropdownMenuItem(value: 'Urgent', child: Text('Urgent')),
                  DropdownMenuItem(value: 'STAT', child: Text('STAT')),
                ],
                onChanged: (v) => setState(() => _priority = v ?? _priority),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Clinical notes',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Search services (10 per page):',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Type to search...',
                  border: const OutlineInputBorder(),
                  suffixIcon: _searchLoading
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
                onChanged: (v) {
                  _searchDebounce?.cancel();
                  _searchDebounce = Timer(
                    const Duration(milliseconds: 300),
                    () => _runSearch(skip: 0),
                  );
                },
              ),
              const SizedBox(height: 8),
              if (_searchResults.isEmpty && !_searchLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'Enter a search term to load services.',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                  ),
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 220),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    itemBuilder: (_, i) {
                      final s = _searchResults[i];
                      final isSelected = _selected.any((e) => e.id == s.id);
                      return CheckboxListTile(
                        value: isSelected,
                        title: Text(s.name),
                        subtitle: Text(
                          s.departmentName ?? s.categoryName ?? "—",
                        ),
                        onChanged: (v) {
                          setState(() {
                            if (v == true) {
                              _selected.add(s);
                            } else {
                              _selected.removeWhere((e) => e.id == s.id);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),
              if (_searchResults.length >= pageSize)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton.icon(
                    onPressed: _searchLoading
                        ? null
                        : () {
                            _page += 1;
                            _runSearch(skip: _page * pageSize, append: true);
                          },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Load more'),
                  ),
                ),
              if (_selected.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Selected: ${_selected.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  _LabOrderDialogResult(
                    selected: List.from(_selected),
                    priority: _priority,
                    notes: _notesCtrl.text,
                  ),
                ),
          child: const Text('Order'),
        ),
      ],
    );
  }
}
