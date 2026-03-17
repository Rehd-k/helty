import 'dart:async';
import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/services/service_service.dart';

// TODO: When O.P consumable store backend/API is ready, add a ConsumableService
// that calls PharmacyService.getConsumables() (or the dedicated consumables endpoint)
// and replace _stubSearchConsumables with real API-backed search. Build the
// Consumable model import from pharmacy/models/pharmacy_model.dart (Consumable).

@RoutePage()
class DoctorEncounterProceduresTab extends StatefulWidget {
  const DoctorEncounterProceduresTab({super.key});

  @override
  State<DoctorEncounterProceduresTab> createState() =>
      _DoctorEncounterProceduresTabState();
}

class _DoctorEncounterProceduresTabState
    extends State<DoctorEncounterProceduresTab> {
  final _encounterService = EncounterService();
  final _serviceService = ServiceService();
  final _notesCtrl = TextEditingController();
  final _complicationsCtrl = TextEditingController();

  bool _consentConfirmed = false;
  bool _saving = false;
  List<Map<String, dynamic>> _procedures = [];
  bool _loaded = false;
  bool _loadScheduled = false;

  // Procedure type: either a selected service, or "other" with free text
  ServiceModel? _selectedService;
  bool _isOtherProcedure = false;
  final _otherProcedureCtrl = TextEditingController();

  // Pending consumables for the current procedure (before Save)
  final List<Map<String, dynamic>> _pendingConsumables = [];

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

  @override
  void dispose() {
    _notesCtrl.dispose();
    _complicationsCtrl.dispose();
    _otherProcedureCtrl.dispose();
    super.dispose();
  }

  String? get _resolvedProcedureType {
    if (_selectedService != null) return _selectedService!.name;
    if (_isOtherProcedure) return _otherProcedureCtrl.text.trim();
    return null;
  }

  void _clearProcedureSelection() {
    setState(() {
      _selectedService = null;
      _isOtherProcedure = false;
      _otherProcedureCtrl.clear();
    });
  }

  void _selectOtherProcedure() {
    setState(() {
      _selectedService = null;
      _isOtherProcedure = true;
    });
  }

  Future<void> _load() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    try {
      final enc = await _encounterService.getById(scope.encounterId);
      if (!mounted) return;
      if (enc?.proceduresJson != null && enc!.proceduresJson!.isNotEmpty) {
        final list = jsonDecode(enc.proceduresJson!) as List;
        _procedures = list
            .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
            .toList();
      } else {
        _procedures = [];
      }
      setState(() => _loaded = true);
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _addProcedure() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    final type = _resolvedProcedureType;
    if (type == null || type.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Procedure type is required')),
      );
      return;
    }
    if (!_consentConfirmed) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please confirm consent')));
      return;
    }
    // Validate consumable quantities
    for (final c in _pendingConsumables) {
      final qty = c['qty']?.toString().trim() ?? '';
      final n = int.tryParse(qty);
      if (n == null || n < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Each consumable must have a quantity ≥ 1'),
          ),
        );
        return;
      }
    }
    setState(() => _saving = true);
    final procedureMap = <String, dynamic>{
      'type': type,
      'consent': 'Yes',
      'notes': _notesCtrl.text.trim(),
      'complications': _complicationsCtrl.text.trim(),
      if (_selectedService != null) 'serviceId': _selectedService!.id,
    };
    if (_pendingConsumables.isNotEmpty) {
      procedureMap['consumables'] = _pendingConsumables
          .map(
            (c) => {
              'id': c['id'] ?? '',
              'name': c['name'] ?? '',
              'qty': c['qty']?.toString().trim() ?? '1',
            },
          )
          .toList();
    }
    _procedures.add(procedureMap);
    try {
      await _encounterService.update(scope.encounterId, {
        'proceduresJson': jsonEncode(_procedures),
      });
      if (!mounted) return;
      _clearProcedureSelection();
      _notesCtrl.clear();
      _complicationsCtrl.clear();
      _pendingConsumables.clear();
      setState(() {
        _consentConfirmed = false;
        _saving = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Procedure saved')));
    } catch (e) {
      if (!mounted) return;
      _procedures.removeLast();
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
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

    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }

    final canSave =
        (_resolvedProcedureType != null &&
            _resolvedProcedureType!.isNotEmpty) &&
        _consentConfirmed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Procedure type',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _ProcedureTypeSelector(
            serviceService: _serviceService,
            selectedService: _selectedService,
            isOther: _isOtherProcedure,
            otherTextController: _otherProcedureCtrl,
            onServiceSelected: (s) => setState(() {
              _selectedService = s;
              _isOtherProcedure = false;
              _otherProcedureCtrl.clear();
            }),
            onOtherSelected: _selectOtherProcedure,
            onClear: () => setState(_clearProcedureSelection),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _consentConfirmed,
            title: const Text('Consent confirmed'),
            onChanged: (v) => setState(() => _consentConfirmed = v ?? false),
          ),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _complicationsCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Complications (if any)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Consumables',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _ConsumablesSelector(
            pendingConsumables: _pendingConsumables,
            onAdd: (c) => setState(() => _pendingConsumables.add(c)),
            onRemove: (c) => setState(() => _pendingConsumables.remove(c)),
            onUpdateQty: (index, qty) => setState(() {
              if (index >= 0 &&
                  index < _pendingConsumables.length &&
                  qty != null) {
                _pendingConsumables[index] = {
                  ..._pendingConsumables[index],
                  'qty': qty,
                };
              }
            }),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _saving ? null : (canSave ? _addProcedure : null),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Save procedure'),
          ),
          const SizedBox(height: 24),
          if (_procedures.isNotEmpty) ...[
            Text('Recorded procedures', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ..._procedures.map((p) => _ProcedureCard(procedure: p)),
          ],
        ],
      ),
    );
  }
}

/// Procedure type: searchable services list + "Other" option. When a service or
/// Other is selected, search is hidden and the selection is shown.
class _ProcedureTypeSelector extends StatefulWidget {
  const _ProcedureTypeSelector({
    required this.serviceService,
    required this.selectedService,
    required this.isOther,
    required this.otherTextController,
    required this.onServiceSelected,
    required this.onOtherSelected,
    required this.onClear,
  });

  final ServiceService serviceService;
  final ServiceModel? selectedService;
  final bool isOther;
  final TextEditingController otherTextController;
  final void Function(ServiceModel) onServiceSelected;
  final VoidCallback onOtherSelected;
  final VoidCallback onClear;

  @override
  State<_ProcedureTypeSelector> createState() => _ProcedureTypeSelectorState();
}

class _ProcedureTypeSelectorState extends State<_ProcedureTypeSelector> {
  static const int _pageSize = 10;

  final _searchCtrl = TextEditingController();
  List<ServiceModel> _suggestions = [];
  bool _loading = false;
  int _page = 0;
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _runSearch({int skip = 0, bool append = false}) async {
    setState(() => _loading = true);
    final list = await widget.serviceService.fetchServices(
      query: _searchCtrl.text.trim().isEmpty ? null : _searchCtrl.text.trim(),
      skip: skip,
      take: _pageSize,
    );
    if (!mounted) return;
    setState(() {
      if (append) {
        _suggestions = [..._suggestions, ...list];
      } else {
        _suggestions = list;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (widget.selectedService != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.selectedService!.name,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(onPressed: widget.onClear, child: const Text('Change')),
          ],
        ),
      );
    }
    if (widget.isOther) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: widget.otherTextController,
            decoration: const InputDecoration(
              labelText: 'Other procedure type',
              hintText: 'e.g. Suturing, I&D, Injection',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 6),
          TextButton(onPressed: widget.onClear, child: const Text('Change')),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search procedure type (10 at a time)...',
            border: const OutlineInputBorder(),
            suffixIcon: _loading
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
            _debounce?.cancel();
            _debounce = Timer(
              const Duration(milliseconds: 300),
              () => _runSearch(skip: 0),
            );
          },
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 220),
          child: ListView(
            shrinkWrap: true,
            children: [
              ..._suggestions.map(
                (s) => ListTile(
                  dense: true,
                  title: Text(s.name),
                  subtitle: s.departmentName != null
                      ? Text(
                          s.departmentName!,
                          style: theme.textTheme.bodySmall,
                        )
                      : null,
                  onTap: () => widget.onServiceSelected(s),
                ),
              ),
              if (_suggestions.length >= _pageSize)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: TextButton.icon(
                    onPressed: _loading
                        ? null
                        : () {
                            _page += 1;
                            _runSearch(skip: _page * _pageSize, append: true);
                          },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Load more'),
                  ),
                ),
              const Divider(height: 1),
              ListTile(
                dense: true,
                title: const Text('Other'),
                subtitle: const Text('Enter procedure type manually'),
                trailing: const Icon(Icons.edit),
                onTap: widget.onOtherSelected,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Stub: matches Pharmacy Consumable shape. Replace with ConsumableService
/// calling Pharmacy/OP consumables API when backend is ready.
Future<List<Map<String, dynamic>>> _stubSearchConsumables(
  String query, {
  int skip = 0,
  int take = 10,
}) async {
  await Future<void>.delayed(const Duration(milliseconds: 150));
  // TODO: Replace with real API, e.g.:
  // final service = ConsumableService(); // or ref.read(consumableServiceProvider);
  // final response = await service.getConsumables(query: query, skip: skip, take: take);
  // return response.items.map((c) => {'id': c.id, 'name': c.name, ...}).toList();
  return [];
}

/// Consumables selector: search (stubbed), add multiple, quantity + remove per row.
class _ConsumablesSelector extends StatefulWidget {
  const _ConsumablesSelector({
    required this.pendingConsumables,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdateQty,
  });

  final List<Map<String, dynamic>> pendingConsumables;
  final void Function(Map<String, dynamic> c) onAdd;
  final void Function(Map<String, dynamic> c) onRemove;
  final void Function(int index, String? qty) onUpdateQty;

  @override
  State<_ConsumablesSelector> createState() => _ConsumablesSelectorState();
}

class _ConsumablesSelectorState extends State<_ConsumablesSelector> {
  static const int _pageSize = 10;

  final _searchCtrl = TextEditingController();
  List<Map<String, dynamic>> _suggestions = [];
  bool _loading = false;
  int _page = 0;
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _runSearch({int skip = 0, bool append = false}) async {
    setState(() => _loading = true);
    final list = await _stubSearchConsumables(
      _searchCtrl.text.trim(),
      skip: skip,
      take: _pageSize,
    );
    if (!mounted) return;
    setState(() {
      if (append) {
        _suggestions = [..._suggestions, ...list];
      } else {
        _suggestions = list;
      }
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search O.P consumable store...',
            border: const OutlineInputBorder(),
            suffixIcon: _loading
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
            _debounce?.cancel();
            _debounce = Timer(
              const Duration(milliseconds: 300),
              () => _runSearch(skip: 0),
            );
          },
        ),
        const SizedBox(height: 6),
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
                  onPressed: _loading
                      ? null
                      : () {
                          _page += 1;
                          _runSearch(skip: _page * _pageSize, append: true);
                        },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Load more'),
                );
              }
              final c = _suggestions[i];
              final name = c['name']?.toString() ?? '';
              return ListTile(
                dense: true,
                title: Text(name),
                onTap: () {
                  widget.onAdd({'id': c['id'] ?? '', 'name': name, 'qty': '1'});
                  _searchCtrl.clear();
                  _suggestions = [];
                  setState(() {});
                },
              );
            },
          ),
        ),
        if (widget.pendingConsumables.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No consumables added. Search above to add from O.P consumable store.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          ...widget.pendingConsumables.asMap().entries.map((entry) {
            final i = entry.key;
            final c = entry.value;
            return _ConsumableRow(
              name: c['name']?.toString() ?? '',
              initialQty: c['qty']?.toString() ?? '1',
              onQtyChanged: (v) => widget.onUpdateQty(i, v),
              onRemove: () => widget.onRemove(c),
            );
          }),
      ],
    );
  }
}

class _ConsumableRow extends StatefulWidget {
  const _ConsumableRow({
    required this.name,
    required this.initialQty,
    required this.onQtyChanged,
    required this.onRemove,
  });

  final String name;
  final String initialQty;
  final void Function(String?) onQtyChanged;
  final VoidCallback onRemove;

  @override
  State<_ConsumableRow> createState() => _ConsumableRowState();
}

class _ConsumableRowState extends State<_ConsumableRow> {
  late TextEditingController _qtyCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: widget.initialQty);
  }

  @override
  void didUpdateWidget(_ConsumableRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQty != widget.initialQty &&
        _qtyCtrl.text != widget.initialQty) {
      _qtyCtrl.text = widget.initialQty;
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(
                widget.name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              width: 72,
              child: TextField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Qty',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: widget.onQtyChanged,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: widget.onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

/// One recorded procedure card with optional consumables summary.
class _ProcedureCard extends StatelessWidget {
  const _ProcedureCard({required this.procedure});

  final Map<String, dynamic> procedure;

  @override
  Widget build(BuildContext context) {
    final type = procedure['type']?.toString() ?? '';
    final notes = procedure['notes']?.toString() ?? '';
    final complications = procedure['complications']?.toString() ?? '';
    final consumables = procedure['consumables'] as List<dynamic>?;
    String subtitle = notes;
    if (complications.isNotEmpty) {
      subtitle +=
          '${subtitle.isNotEmpty ? ' • ' : ''}Complications: $complications';
    }
    if (consumables != null && consumables.isNotEmpty) {
      final parts = consumables.take(5).map((c) {
        final m = c is Map ? c : <String, dynamic>{};
        final n = m['name']?.toString() ?? '';
        final q = m['qty']?.toString() ?? '1';
        return '$n x$q';
      }).toList();
      final consStr = parts.join(', ');
      subtitle += '${subtitle.isNotEmpty ? ' • ' : ''}Consumables: $consStr';
      if (consumables.length > 5) {
        subtitle += ' (+${consumables.length - 5} more)';
      }
    }
    return Card(
      child: ListTile(
        title: Text(type),
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
      ),
    );
  }
}
