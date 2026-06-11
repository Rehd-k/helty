import 'dart:async';
import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/doctor/encounter/encounter_amend_helper.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/purchases/models/purchases_model.dart';
import 'package:helty/src/purchases/services/purchases_service.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/services/invoice_service.dart';
import 'package:helty/src/services/service_service.dart';
import 'package:helty/src/store/utils/consumable_invoice_helper.dart';

bool _isPurchaseConsumableCategory(String? category) {
  final c = category?.trim().toLowerCase();
  return c == 'consumable' || c == 'consumables';
}

Future<int> _stockAtLocation(
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

@RoutePage()
class DoctorEncounterProceduresTab extends ConsumerStatefulWidget {
  const DoctorEncounterProceduresTab({super.key});

  @override
  ConsumerState<DoctorEncounterProceduresTab> createState() =>
      _DoctorEncounterProceduresTabState();
}

class _DoctorEncounterProceduresTabState
    extends ConsumerState<DoctorEncounterProceduresTab> {
  final _encounterService = EncounterService();
  final _serviceService = ServiceService();
  final _purchasesApi = PurchasesApiService();
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

  List<PurchasesLocation> _purchasesLocations = [];
  bool _purchasesLocsRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_purchasesLocsRequested && EncounterScope.of(context) != null) {
      _purchasesLocsRequested = true;
      _loadPurchasesLocations();
    }
    if (!_loadScheduled) {
      _loadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _loadPurchasesLocations() async {
    try {
      final r = await _purchasesApi.getLocations(
        const PurchasesQueryParams(pageSize: 50),
      );
      final active = r.items.where((l) => l.isActive).toList();
      final stores = active
          .where((l) => l.type == PurchasesLocationType.STORE)
          .toList();
      if (!mounted) return;
      setState(() => _purchasesLocations = stores.isNotEmpty ? stores : active);
    } catch (_) {
      if (mounted) setState(() => _purchasesLocations = []);
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

  Future<String?> _validatePendingConsumables() async {
    for (final c in _pendingConsumables) {
      final qty = c['qty']?.toString().trim() ?? '';
      final n = int.tryParse(qty);
      if (n == null || n < 1) {
        return 'Each consumable must have a quantity ≥ 1';
      }
      final loc = c['purchasesLocationId']?.toString().trim() ?? '';
      if (loc.isEmpty) {
        return 'Each consumable needs a purchases store location';
      }
      final maxQty = c['maxQuantity'] is int
          ? c['maxQuantity'] as int
          : int.tryParse(c['maxQuantity']?.toString() ?? '') ?? 0;
      if (n > maxQty) {
        return 'Quantity for ${c['name']} cannot exceed available stock ($maxQty)';
      }
      final up = double.tryParse(c['unitPrice']?.toString().trim() ?? '') ?? -1;
      if (up < 0) {
        return 'Each consumable needs a unit price ≥ 0';
      }
      final itemId = c['purchaseItemId']?.toString().trim() ?? '';
      if (itemId.isNotEmpty) {
        try {
          final liveStock = await _stockAtLocation(_purchasesApi, itemId, loc);
          if (n > liveStock) {
            return 'Only $liveStock of ${c['name']} available at the selected store';
          }
        } catch (_) {
          return 'Could not verify stock — try again';
        }
      }
    }
    return null;
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
    final consumableError = await _validatePendingConsumables();
    if (consumableError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(consumableError)),
      );
      return;
    }
    setState(() => _saving = true);
    final procedureMap = <String, dynamic>{
      'type': type,
      'consent': 'Yes',
      'notes': _notesCtrl.text.trim(),
      'complications': _complicationsCtrl.text.trim(),
      if (_selectedService != null) 'serviceId': _selectedService!.id,
    };
    final pendingCopy = List<Map<String, dynamic>>.from(_pendingConsumables);
    if (pendingCopy.isNotEmpty) {
      procedureMap['consumables'] = pendingCopy
          .map(
            (c) => {
              'purchaseItemId': c['purchaseItemId'] ?? '',
              'name': c['name'] ?? '',
              'qty': c['qty']?.toString().trim() ?? '1',
              'purchasesLocationId': c['purchasesLocationId'] ?? '',
              'unitPrice': c['unitPrice']?.toString().trim() ?? '0',
            },
          )
          .toList();
    }
    _procedures.add(procedureMap);
    try {
      await _encounterService.update(
        scope.encounterId,
        encounterPatchWithAmend(scope, {
          'proceduresJson': jsonEncode(_procedures),
        }),
      );
      final invoiceErrors = <String>[];
      if (pendingCopy.isNotEmpty) {
        String? invoiceId;
        try {
          invoiceId = await resolveOrCreateOpenInvoiceId(ref, scope.patientId);
        } catch (e) {
          invoiceErrors.add('$e');
        }
        if (invoiceId != null) {
          final svc = InvoiceService();
          for (final c in pendingCopy) {
            final pid = c['purchaseItemId']?.toString().trim() ?? '';
            final loc = c['purchasesLocationId']?.toString().trim() ?? '';
            if (pid.isEmpty || loc.isEmpty) continue;
            final qty = int.tryParse(c['qty']?.toString().trim() ?? '1') ?? 1;
            final unit =
                double.tryParse(c['unitPrice']?.toString().trim() ?? '0') ?? 0;
            try {
              await svc.addBillingItem(
                invoiceId: invoiceId,
                payload: AddInvoiceItemPayload(
                  purchaseItemId: pid,
                  purchasesLocationId: loc,
                  unitPrice: unit,
                  quantity: qty,
                ),
              );
            } catch (e) {
              invoiceErrors.add('$e');
            }
          }
        }
      }

      if (!mounted) return;
      _clearProcedureSelection();
      _notesCtrl.clear();
      _complicationsCtrl.clear();
      _pendingConsumables.clear();
      setState(() {
        _consentConfirmed = false;
        _saving = false;
      });
      if (invoiceErrors.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Procedure saved')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Procedure saved; invoice step failed (${invoiceErrors.first})',
            ),
            duration: const Duration(seconds: 8),
          ),
        );
      }
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
            purchasesApi: _purchasesApi,
            purchasesLocations: _purchasesLocations,
            pendingConsumables: _pendingConsumables,
            onAdd: (c) => setState(() => _pendingConsumables.add(c)),
            onRemove: (c) => setState(() => _pendingConsumables.remove(c)),
            onUpdateRow: (index, updates) => setState(() {
              if (index >= 0 && index < _pendingConsumables.length) {
                _pendingConsumables[index] = {
                  ..._pendingConsumables[index],
                  ...updates,
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

/// Consumables selector: purchases/items with consumable category, stock-capped qty.
class _ConsumablesSelector extends StatefulWidget {
  const _ConsumablesSelector({
    required this.purchasesApi,
    required this.purchasesLocations,
    required this.pendingConsumables,
    required this.onAdd,
    required this.onRemove,
    required this.onUpdateRow,
  });

  final PurchasesApiService purchasesApi;
  final List<PurchasesLocation> purchasesLocations;
  final List<Map<String, dynamic>> pendingConsumables;
  final void Function(Map<String, dynamic> c) onAdd;
  final void Function(Map<String, dynamic> c) onRemove;
  final void Function(int index, Map<String, dynamic> updates) onUpdateRow;

  @override
  State<_ConsumablesSelector> createState() => _ConsumablesSelectorState();
}

class _ConsumablesSelectorState extends State<_ConsumablesSelector> {
  static const int _pageSize = 10;

  final _searchCtrl = TextEditingController();
  List<PurchaseItem> _suggestions = [];
  bool _loading = false;
  int _page = 1;
  Timer? _debounce;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _runSearch({int page = 1, bool append = false}) async {
    final q = _searchCtrl.text.trim();
    if (q.length < 2) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _loading = false;
        });
      }
      return;
    }
    setState(() => _loading = true);
    try {
      final resp = await widget.purchasesApi.searchItems(
        SearchPurchaseItemParams(
          search: q,
          category: 'consumable',
          inStock: true,
          page: page,
          pageSize: _pageSize,
          sortOrder: 'asc',
        ),
      );
      final list = resp.items
          .where((item) => _isPurchaseConsumableCategory(item.category))
          .toList();
      if (!mounted) return;
      setState(() {
        if (append) {
          _suggestions = [..._suggestions, ...list];
        } else {
          _suggestions = list;
        }
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  String? _defaultLocationId() {
    if (widget.purchasesLocations.isEmpty) return null;
    return widget.purchasesLocations.first.id;
  }

  Future<void> _addItem(PurchaseItem item) async {
    final itemId = item.id?.trim() ?? '';
    final locId = _defaultLocationId() ?? '';
    if (itemId.isEmpty) return;
    if (locId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No purchases store location — configure under Purchases'),
        ),
      );
      return;
    }
    try {
      final stock = await _stockAtLocation(widget.purchasesApi, itemId, locId);
      if (stock <= 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot add "${item.itemName}" — out of stock at the selected store.',
            ),
          ),
        );
        return;
      }
      if (!mounted) return;
      widget.onAdd({
        'purchaseItemId': itemId,
        'name': item.itemName,
        'qty': '1',
        'purchasesLocationId': locId,
        'maxQuantity': stock,
        'unitPrice': (item.sellingPrice ?? 0).toString(),
      });
      _searchCtrl.clear();
      setState(() => _suggestions = []);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not check stock — try again')),
      );
    }
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
            hintText:
                'Search purchases consumables (min 2 chars)...',
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
              () {
                _page = 1;
                _runSearch(page: 1, append: false);
              },
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
                          _runSearch(page: _page, append: true);
                        },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Load more'),
                );
              }
              final item = _suggestions[i];
              return ListTile(
                dense: true,
                title: Text(item.itemName),
                subtitle: Text(item.category ?? 'Consumable'),
                onTap: () => _addItem(item),
              );
            },
          ),
        ),
        if (widget.purchasesLocations.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'No purchases store locations — add locations under Purchases first.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        if (widget.pendingConsumables.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No consumables added. Search purchases items above.',
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
              purchasesApi: widget.purchasesApi,
              purchaseItemId: c['purchaseItemId']?.toString() ?? '',
              name: c['name']?.toString() ?? '',
              initialQty: c['qty']?.toString() ?? '1',
              initialUnitPrice: c['unitPrice']?.toString() ?? '0',
              initialMaxQuantity: c['maxQuantity'] is int
                  ? c['maxQuantity'] as int
                  : int.tryParse(c['maxQuantity']?.toString() ?? '') ?? 0,
              purchasesLocations: widget.purchasesLocations,
              selectedLocationId: c['purchasesLocationId']?.toString(),
              onRowUpdated: (updates) => widget.onUpdateRow(i, updates),
              onRemove: () => widget.onRemove(c),
            );
          }),
      ],
    );
  }
}

class _ConsumableRow extends StatefulWidget {
  const _ConsumableRow({
    required this.purchasesApi,
    required this.purchaseItemId,
    required this.name,
    required this.initialQty,
    required this.initialUnitPrice,
    required this.initialMaxQuantity,
    required this.purchasesLocations,
    required this.selectedLocationId,
    required this.onRowUpdated,
    required this.onRemove,
  });

  final PurchasesApiService purchasesApi;
  final String purchaseItemId;
  final String name;
  final String initialQty;
  final String initialUnitPrice;
  final int initialMaxQuantity;
  final List<PurchasesLocation> purchasesLocations;
  final String? selectedLocationId;
  final void Function(Map<String, dynamic> updates) onRowUpdated;
  final VoidCallback onRemove;

  @override
  State<_ConsumableRow> createState() => _ConsumableRowState();
}

class _ConsumableRowState extends State<_ConsumableRow> {
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  int _maxQuantity = 0;
  bool _loadingStock = false;

  @override
  void initState() {
    super.initState();
    _maxQuantity = widget.initialMaxQuantity;
    _qtyCtrl = TextEditingController(text: widget.initialQty);
    _priceCtrl = TextEditingController(text: widget.initialUnitPrice);
    _refreshStock(widget.selectedLocationId);
  }

  @override
  void didUpdateWidget(_ConsumableRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQty != widget.initialQty &&
        _qtyCtrl.text != widget.initialQty) {
      _qtyCtrl.text = widget.initialQty;
    }
    if (oldWidget.initialUnitPrice != widget.initialUnitPrice &&
        _priceCtrl.text != widget.initialUnitPrice) {
      _priceCtrl.text = widget.initialUnitPrice;
    }
    if (oldWidget.initialMaxQuantity != widget.initialMaxQuantity) {
      _maxQuantity = widget.initialMaxQuantity;
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshStock(String? locationId) async {
    final locId = locationId?.trim() ?? '';
    final itemId = widget.purchaseItemId.trim();
    if (locId.isEmpty || itemId.isEmpty) return;
    setState(() => _loadingStock = true);
    try {
      final stock = await _stockAtLocation(widget.purchasesApi, itemId, locId);
      if (!mounted) return;
      final currentQty = int.tryParse(_qtyCtrl.text.trim()) ?? 1;
      final clamped = stock > 0 ? currentQty.clamp(1, stock) : 0;
      if (clamped != currentQty) {
        _qtyCtrl.text = clamped.toString();
      }
      setState(() => _maxQuantity = stock);
      widget.onRowUpdated({
        'purchasesLocationId': locId,
        'maxQuantity': stock,
        'qty': clamped > 0 ? clamped.toString() : '1',
      });
    } catch (_) {
      if (mounted) setState(() => _maxQuantity = 0);
    } finally {
      if (mounted) setState(() => _loadingStock = false);
    }
  }

  void _onQtyChanged(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null) {
      widget.onRowUpdated({'qty': value});
      return;
    }
    if (_maxQuantity <= 0) return;
    final clamped = parsed.clamp(1, _maxQuantity);
    if (clamped != parsed) {
      _qtyCtrl.text = clamped.toString();
      _qtyCtrl.selection = TextSelection.collapsed(offset: _qtyCtrl.text.length);
    }
    widget.onRowUpdated({'qty': clamped.toString()});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locs = widget.purchasesLocations;
    final locId = widget.selectedLocationId?.trim().isNotEmpty == true
        ? widget.selectedLocationId
        : (locs.isNotEmpty ? locs.first.id : null);
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
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
                  width: 88,
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => widget.onRowUpdated({'unitPrice': v}),
                  ),
                ),
                SizedBox(
                  width: 72,
                  child: TextField(
                    controller: _qtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Qty',
                      isDense: true,
                      border: const OutlineInputBorder(),
                      helperText: _loadingStock
                          ? '...'
                          : (_maxQuantity > 0 ? 'Max $_maxQuantity' : null),
                      helperMaxLines: 1,
                    ),
                    onChanged: _onQtyChanged,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            if (_maxQuantity > 0 && !_loadingStock)
              Text(
                'Available: $_maxQuantity',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            if (locs.isNotEmpty) ...[
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: locId != null && locs.any((l) => l.id == locId)
                    ? locId
                    : locs.first.id,
                isDense: true,
                decoration: const InputDecoration(
                  labelText: 'Purchases store',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: locs
                    .map(
                      (l) => DropdownMenuItem(
                        value: l.id,
                        child: Text(l.name, overflow: TextOverflow.ellipsis),
                      ),
                    )
                    .toList(),
                onChanged: (loc) => _refreshStock(loc),
              ),
            ],
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
