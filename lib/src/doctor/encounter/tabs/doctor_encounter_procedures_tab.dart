import 'dart:convert';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/core/utils/api_decimal.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/doctor/encounter/encounter_amend_helper.dart';
import 'package:helty/src/doctor/encounter/encounter_tab_reload.dart';
import 'package:helty/src/billings/widgets/purchases_consumable_billing_panel.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/purchases/models/purchases_model.dart';
import 'package:helty/src/purchases/services/purchases_service.dart';
import 'package:helty/src/services/encounter_service.dart';
import 'package:helty/src/services/invoice_service.dart';
import 'package:helty/src/services/service_service.dart';
import 'package:helty/src/services/widgets/searchable_service_selector.dart';
import 'package:helty/src/store/utils/consumable_invoice_helper.dart';

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
  int _lastReloadGeneration = 0;

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
    reloadEncounterTabIfTemplateApplied(
      context: context,
      lastReloadGeneration: _lastReloadGeneration,
      updateLastReloadGeneration: (v) => _lastReloadGeneration = v,
      loaded: _loaded,
      reload: _load,
    );
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
      final up = tryParseApiDecimal(c['unitPrice']) ?? -1;
      if (up < 0) {
        return 'Each consumable needs a unit price ≥ 0';
      }
      final itemId = c['purchaseItemId']?.toString().trim() ?? '';
      if (itemId.isNotEmpty) {
        try {
          final liveStock = await purchasesStockAtLocation(
            _purchasesApi,
            itemId,
            loc,
          );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(consumableError)));
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
            final unit = parseApiDecimal(c['unitPrice']);
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Procedure saved')));
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
      showEncounterEditErrorSnackBar(context, e);
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

    final readOnly = !scope.canEdit;

    final canSave =
        !readOnly &&
        (_resolvedProcedureType != null &&
            _resolvedProcedureType!.isNotEmpty) &&
        _consentConfirmed;

    return ResponsiveBody(
      center: false,
      builder: (context, bp) => AbsorbPointer(
      absorbing: readOnly,
      child: SingleChildScrollView(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Procedure type',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          SearchableServiceSelector(
            serviceService: _serviceService,
            selectedService: _selectedService,
            isOther: _isOtherProcedure,
            otherTextController: _otherProcedureCtrl,
            showOther: true,
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
          if (!readOnly)
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
    ),
    ),
    );
  }
}

/// Purchase item selector: searches catalog items with a selling price > 0.
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
  Future<void> _onConfirm(
    PurchaseItem item,
    String locationId,
    int qty,
    double unitPrice,
  ) async {
    final itemId = item.id?.trim() ?? '';
    if (itemId.isEmpty) return;
    try {
      final stock = await purchasesStockAtLocation(
        widget.purchasesApi,
        itemId,
        locationId,
      );
      if (!mounted) return;
      if (stock <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot add "${item.itemName}" — out of stock at the selected store.',
            ),
          ),
        );
        return;
      }
      final clampedQty = qty.clamp(1, stock);
      widget.onAdd({
        'purchaseItemId': itemId,
        'name': item.itemName,
        'qty': clampedQty.toString(),
        'purchasesLocationId': locationId,
        'maxQuantity': stock,
        'unitPrice': unitPrice.toString(),
      });
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
        PurchasesConsumableBillingPanel(
          purchasesApi: widget.purchasesApi,
          purchasesLocations: widget.purchasesLocations,
          confirmButtonLabel: 'Add to procedure',
          onConfirm: _onConfirm,
        ),
        if (widget.pendingConsumables.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No consumables added. Search purchases items above.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
      final stock = await purchasesStockAtLocation(
        widget.purchasesApi,
        itemId,
        locId,
      );
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
      _qtyCtrl.selection = TextSelection.collapsed(
        offset: _qtyCtrl.text.length,
      );
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
                  color: theme.colorScheme.onSurfaceVariant,
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
