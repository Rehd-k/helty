import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/pharmacy/models/pharmacy_model.dart';
import 'package:helty/src/store/models/consumable_models.dart';
import 'package:helty/src/store/models/store_models.dart';
import 'package:helty/src/store/providers/store_providers.dart';
import 'package:helty/src/theatre/models/theatre_models.dart';
import 'package:helty/src/theatre/providers/theatre_providers.dart';

Future<TheatreCaseConsumable?> showTheatreAddConsumableSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String surgeryRequestId,
}) {
  return showModalBottomSheet<TheatreCaseConsumable>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => _TheatreAddConsumableSheet(
      surgeryRequestId: surgeryRequestId,
    ),
  );
}

class _TheatreAddConsumableSheet extends ConsumerStatefulWidget {
  const _TheatreAddConsumableSheet({required this.surgeryRequestId});

  final String surgeryRequestId;

  @override
  ConsumerState<_TheatreAddConsumableSheet> createState() =>
      _TheatreAddConsumableSheetState();
}

class _TheatreAddConsumableSheetState
    extends ConsumerState<_TheatreAddConsumableSheet> {
  final _searchCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController(text: '0');
  Timer? _debounce;

  List<Consumable> _hits = [];
  bool _searching = false;
  Consumable? _selected;
  StoreLocation? _location;
  List<StoreLocation> _locations = [];
  bool _loadingLocs = true;
  bool _submitting = false;
  bool _billable = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final resp = await ref.read(storeApiServiceProvider).getLocations();
      if (!mounted) return;
      setState(() {
        _locations = resp.data;
        _loadingLocs = false;
        if (resp.data.isNotEmpty) _location = resp.data.first;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingLocs = false);
    }
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final trimmed = q.trim();
      if (trimmed.isEmpty) {
        if (mounted) setState(() => _hits = []);
        return;
      }
      setState(() => _searching = true);
      try {
        final api = ref.read(storeConsumableApiServiceProvider);
        final res = await api.listConsumables(
          StoreConsumableListParams(search: trimmed, pageSize: 20),
        );
        if (!mounted) return;
        setState(() {
          _hits = res.items;
          _searching = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() {
          _hits = [];
          _searching = false;
        });
      }
    });
  }

  Future<void> _submit() async {
    final sel = _selected;
    final loc = _location;
    if (sel?.id == null || sel!.id!.isEmpty) {
      setState(() => _error = 'Select a consumable.');
      return;
    }
    if (loc == null) {
      setState(() => _error = 'Select a store location.');
      return;
    }
    final qty = int.tryParse(_qtyCtrl.text.trim()) ?? 0;
    if (qty <= 0) {
      setState(() => _error = 'Enter a valid quantity.');
      return;
    }
    final unit = double.tryParse(_priceCtrl.text.trim()) ?? 0;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final row = await ref.read(theatreApiServiceProvider).addCaseConsumable(
        widget.surgeryRequestId,
        consumableId: sel.id!,
        storeLocationId: loc.id,
        quantity: qty,
        unitPrice: unit,
        billable: _billable,
      );
      if (!mounted) return;
      Navigator.of(context).pop(row);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Add consumable',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          if (_error != null) ...[
            Text(
              _error!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              labelText: 'Search consumable',
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
          ),
          if (_hits.isNotEmpty) ...[
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                itemCount: _hits.length,
                itemBuilder: (context, i) {
                  final c = _hits[i];
                  return ListTile(
                    dense: true,
                    title: Text(c.name),
                    subtitle: c.category != null ? Text(c.category!) : null,
                    selected: _selected?.id == c.id,
                    onTap: () => setState(() => _selected = c),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_loadingLocs)
            const LinearProgressIndicator()
          else
            DropdownButtonFormField<StoreLocation>(
              initialValue: _location,
              decoration: const InputDecoration(labelText: 'Store location'),
              items: _locations
                  .map((l) => DropdownMenuItem(value: l, child: Text(l.name)))
                  .toList(),
              onChanged: (v) => setState(() => _location = v),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Quantity'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _priceCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Unit price'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Billable'),
            subtitle: const Text(
              'Staged for billing when case is sent to billing',
            ),
            value: _billable,
            onChanged: (v) => setState(() => _billable = v),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            child: _submitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Add consumable'),
          ),
        ],
      ),
    );
  }
}
