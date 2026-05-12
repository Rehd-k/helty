import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/enlist_services/selected.user.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/paitients/patient_notifier.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:helty/src/pharmacy/models/pharmacy_model.dart';
import 'package:helty/src/services/invoice_service.dart';
import 'package:helty/src/store/models/consumable_models.dart';
import 'package:helty/src/store/models/store_models.dart';
import 'package:helty/src/store/providers/store_providers.dart';
import 'package:helty/src/store/utils/consumable_invoice_helper.dart';

/// Nurses & doctors — non-billable FIFO **usage** vs **billable** invoice lines.
@RoutePage()
class NurseConsumableUsageScreen extends ConsumerStatefulWidget {
  const NurseConsumableUsageScreen({super.key});

  @override
  ConsumerState<NurseConsumableUsageScreen> createState() =>
      _NurseConsumableUsageScreenState();
}

class _NurseConsumableUsageScreenState extends ConsumerState<NurseConsumableUsageScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late final PatientNotifier _patientNotifier;

  final _admissionIdCtrl = TextEditingController();
  final _encounterIdCtrl = TextEditingController();

  // —— Stock use (non-billable) ——
  final _usageSearchCtrl = TextEditingController();
  Timer? _usageDebounce;
  List<Consumable> _usageHits = [];
  bool _usageSearching = false;
  Consumable? _usageSelected; 
  StoreLocation? _usageLocation;
  List<StoreLocation> _locations = [];
  bool _loadingLocs = true;
  final _usageQtyCtrl = TextEditingController(text: '1');
  bool _usageSubmitting = false;
  List<ConsumableUsageEvent> _recentReturns = [];

  // —— Billable invoice ——
  final _billSearchCtrl = TextEditingController();
  Timer? _billDebounce;
  List<Consumable> _billHits = [];
  bool _billSearching = false;
  Consumable? _billSelected;
  StoreLocation? _billLocation;
  final _billQtyCtrl = TextEditingController(text: '1');
  final _billPriceCtrl = TextEditingController(text: '0');
  bool _billSubmitting = false;

  @override
  void initState() {
    super.initState();
    _patientNotifier = ref.read(patientProvider.notifier);
    _tabs = TabController(length: 2, vsync: this);
    _loadLocations();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _usageDebounce?.cancel();
    _billDebounce?.cancel();
    _admissionIdCtrl.dispose();
    _encounterIdCtrl.dispose();
    _usageSearchCtrl.dispose();
    _usageQtyCtrl.dispose();
    _billSearchCtrl.dispose();
    _billQtyCtrl.dispose();
    _billPriceCtrl.dispose();
    _patientNotifier.clearPatient();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    try {
      final resp = await ref.read(storeApiServiceProvider).getLocations();
      if (!mounted) return;
      setState(() {
        _locations = resp.data;
        _loadingLocs = false;
        if (_usageLocation == null && _locations.isNotEmpty) {
          _usageLocation = _locations.first;
        }
        if (_billLocation == null && _locations.isNotEmpty) {
          _billLocation = _locations.first;
        }
      });
    } catch (_) {
      if (mounted) setState(() => _loadingLocs = false);
    }
  }

  void _onUsageSearchChanged() {
    _usageDebounce?.cancel();
    _usageDebounce = Timer(const Duration(milliseconds: 350), _runUsageSearch);
  }

  Future<void> _runUsageSearch() async {
    final q = _usageSearchCtrl.text.trim();
    if (q.length < 2) {
      if (mounted) setState(() => _usageHits = []);
      return;
    }
    setState(() => _usageSearching = true);
    try {
      final api = ref.read(storeConsumableApiServiceProvider);
      final page = await api.listConsumables(
        StoreConsumableListParams(search: q, pageSize: 20),
      );
      final list = page.items.where((c) => !c.isBillable).toList(growable: false);
      if (!mounted) return;
      setState(() {
        _usageHits = list;
        _usageSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _usageSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  void _onBillSearchChanged() {
    _billDebounce?.cancel();
    _billDebounce = Timer(const Duration(milliseconds: 350), _runBillSearch);
  }

  Future<void> _runBillSearch() async {
    final q = _billSearchCtrl.text.trim();
    if (q.length < 2) {
      if (mounted) setState(() => _billHits = []);
      return;
    }
    setState(() => _billSearching = true);
    try {
      final api = ref.read(storeConsumableApiServiceProvider);
      final page = await api.listConsumables(
        StoreConsumableListParams(search: q, pageSize: 20),
      );
      final list = page.items.where((c) => c.isBillable).toList(growable: false);
      if (!mounted) return;
      setState(() {
        _billHits = list;
        _billSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _billSearching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    }
  }

  String? _selectedPatientId() {
    final p = ref.read(patientProvider).selectedPatient;
    final id = p?.id?.trim() ?? '';
    return patientIdLooksLikeUuid(id) ? id : null;
  }

  Future<void> _submitUsage() async {
    final patientId = _selectedPatientId();
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a patient with a server id (search by name, id, or phone).'),
        ),
      );
      return;
    }
    final sel = _usageSelected;
    if (sel == null || sel.id == null || sel.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a non-billable consumable')),
      );
      return;
    }
    final loc = _usageLocation;
    if (loc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a store location')),
      );
      return;
    }
    final qty = int.tryParse(_usageQtyCtrl.text.trim()) ?? 0;
    if (qty < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be ≥ 1')),
      );
      return;
    }

    setState(() => _usageSubmitting = true);
    try {
      final api = ref.read(storeConsumableApiServiceProvider);
      final ev = await api.recordUsage(
        RecordConsumableUsageDto(
          consumableId: sel.id!,
          storeLocationId: loc.id,
          patientId: patientId,
          encounterId: _encounterIdCtrl.text.trim().isEmpty
              ? null
              : _encounterIdCtrl.text.trim(),
          admissionId: _admissionIdCtrl.text.trim().isEmpty
              ? null
              : _admissionIdCtrl.text.trim(),
          source: ConsumableUsageSource.nursing,
          quantity: qty,
        ),
      );
      if (!mounted) return;
      setState(() {
        _usageSubmitting = false;
        _recentReturns = [ev, ..._recentReturns].take(8).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Consumable use recorded')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _usageSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _submitBillable() async {
    final patientId = _selectedPatientId();
    if (patientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a patient with a server id (search by name, id, or phone).'),
        ),
      );
      return;
    }
    final sel = _billSelected;
    if (sel == null || sel.id == null || sel.id!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a billable consumable')),
      );
      return;
    }
    final loc = _billLocation;
    if (loc == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a store location')),
      );
      return;
    }
    final qty = int.tryParse(_billQtyCtrl.text.trim()) ?? 0;
    if (qty < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quantity must be ≥ 1')),
      );
      return;
    }
    final unit = double.tryParse(_billPriceCtrl.text.trim()) ?? 0;
    if (unit < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unit price must be ≥ 0')),
      );
      return;
    }

    setState(() => _billSubmitting = true);
    try {
      final invoiceId = await resolveOrCreateOpenInvoiceId(ref, patientId);
      final svc = InvoiceService();
      await svc.addBillingItem(
        invoiceId: invoiceId,
        payload: AddInvoiceItemPayload(
          consumableId: sel.id,
          storeLocationId: loc.id,
          unitPrice: unit,
          quantity: qty,
        ),
      );
      if (!mounted) return;
      setState(() => _billSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added consumable line to patient invoice')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _billSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed: $e')),
      );
    }
  }

  Future<void> _returnEvent(ConsumableUsageEvent ev) async {
    if (ev.direction != ConsumableUsageDirection.use) return;
    setState(() => _usageSubmitting = true);
    try {
      final api = ref.read(storeConsumableApiServiceProvider);
      await api.returnUsageEvent(ev.id);
      if (!mounted) return;
      setState(() => _usageSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Return recorded')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _usageSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Return failed: $e')),
      );
    }
  }

  Widget _buildSelectedPatientHeader() {
    return const SelectedPatientCard();
  }

  Widget _buildNoPatientSelectedState(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_search, size: 40),
                  const SizedBox(height: 12),
                  const Text(
                    'No patient selected',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select a patient from the consumables enlist flow before recording usage or billing.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      context.router.push(
                        EnlistPaitientRoute(serviceName: 'Consumables'),
                      );
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Select patient'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(patientProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consumables'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Stock use'),
            Tab(text: 'Bill to invoice'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildStockUseTab(context),
          _buildInvoiceTab(context),
        ],
      ),
    );
  }

  Widget _buildStockUseTab(BuildContext context) {
    final theme = Theme.of(context);
    if (_selectedPatientId() == null) {
      return _buildNoPatientSelectedState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Non-billable items only. FIFO stock is reduced when you save (not when the invoice is paid).',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _buildSelectedPatientHeader(),
              const SizedBox(height: 12),
              TextField(
                controller: _admissionIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Admission id (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _encounterIdCtrl,
                decoration: const InputDecoration(
                  labelText: 'Encounter id (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (_loadingLocs)
                const LinearProgressIndicator()
              else
                DropdownButtonFormField<StoreLocation>(
                  // ignore: deprecated_member_use
                  value: _usageLocation,
                  decoration: const InputDecoration(
                    labelText: 'Store location',
                    border: OutlineInputBorder(),
                  ),
                  items: _locations
                      .map(
                        (l) => DropdownMenuItem(
                          value: l,
                          child: Text(l.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _usageLocation = v),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _usageSearchCtrl,
                decoration: InputDecoration(
                  labelText: 'Search non-billable consumable',
                  border: const OutlineInputBorder(),
                  suffixIcon: _usageSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.search),
                ),
                onChanged: (_) => _onUsageSearchChanged(),
              ),
              if (_usageHits.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _usageHits.length,
                    itemBuilder: (ctx, i) {
                      final c = _usageHits[i];
                      return ListTile(
                        title: Text(c.name),
                        subtitle: Text(c.category ?? '—'),
                        selected: _usageSelected?.id == c.id,
                        onTap: () => setState(() => _usageSelected = c),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _usageQtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _usageSubmitting ? null : _submitUsage,
                icon: _usageSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check),
                label: Text(_usageSubmitting ? 'Saving…' : 'Record use'),
              ),
              if (_recentReturns.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('Recent USE events', style: theme.textTheme.titleSmall),
                ..._recentReturns.map(
                  (e) => ListTile(
                    dense: true,
                    title: Text('${e.direction.json} ×${e.quantity}  ${e.id}'),
                    subtitle: Text(e.createdAt?.toIso8601String() ?? ''),
                    trailing: e.direction == ConsumableUsageDirection.use
                        ? TextButton(
                            onPressed:
                                _usageSubmitting ? null : () => _returnEvent(e),
                            child: const Text('Return'),
                          )
                        : null,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceTab(BuildContext context) {
    final theme = Theme.of(context);
    if (_selectedPatientId() == null) {
      return _buildNoPatientSelectedState(context);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Billable consumables are added as lines on the patient’s open billing invoice (FIFO at save).',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              _buildSelectedPatientHeader(),
              const SizedBox(height: 12),
              if (_loadingLocs)
                const LinearProgressIndicator()
              else
                DropdownButtonFormField<StoreLocation>(
                  // ignore: deprecated_member_use
                  value: _billLocation,
                  decoration: const InputDecoration(
                    labelText: 'Store location',
                    border: OutlineInputBorder(),
                  ),
                  items: _locations
                      .map(
                        (l) => DropdownMenuItem(
                          value: l,
                          child: Text(l.name),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _billLocation = v),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: _billSearchCtrl,
                decoration: InputDecoration(
                  labelText: 'Search billable consumable',
                  border: const OutlineInputBorder(),
                  suffixIcon: _billSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : const Icon(Icons.search),
                ),
                onChanged: (_) => _onBillSearchChanged(),
              ),
              if (_billHits.isNotEmpty) ...[
                const SizedBox(height: 8),
                Card(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _billHits.length,
                    itemBuilder: (ctx, i) {
                      final c = _billHits[i];
                      return ListTile(
                        title: Text(c.name),
                        subtitle: Text(c.category ?? '—'),
                        selected: _billSelected?.id == c.id,
                        onTap: () => setState(() => _billSelected = c),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _billQtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _billPriceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Unit price',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _billSubmitting ? null : _submitBillable,
                icon: _billSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.receipt_long),
                label: Text(_billSubmitting ? 'Saving…' : 'Add to invoice'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
