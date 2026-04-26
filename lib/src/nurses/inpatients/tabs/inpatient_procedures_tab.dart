import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/providers/invoices_providers.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/services/service_service.dart';

@RoutePage()
class InpatientProceduresScreen extends ConsumerStatefulWidget {
  const InpatientProceduresScreen({super.key});

  @override
  ConsumerState<InpatientProceduresScreen> createState() =>
      _InpatientProceduresScreenState();
}

class _InpatientProceduresScreenState
    extends ConsumerState<InpatientProceduresScreen> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SectionCard(
        title: 'Procedures',
        subtitle: 'Bedside and theatre procedures for this admission',
        actions: [
          FilledButton.icon(
            onPressed: () => _openAddProcedureDialog(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Procedure'),
          ),
          FilledButton.tonalIcon(
            onPressed: () => _openBillProcedureDialog(context),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Bill Procedure'),
          ),
        ],
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: ['Date/Time', 'Type', 'Clinician', 'Site', 'Outcome']
                .map(
                  (c) => DataColumn(
                    label: Text(
                      c,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
            rows: const [],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddProcedureDialog(BuildContext context) async {
    final typeCtrl = TextEditingController();
    final clinicianCtrl = TextEditingController();
    final siteCtrl = TextEditingController();
    final outcomeCtrl = TextEditingController();
    final complicationsCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text('Add Procedure'),
          content: SizedBox(
            width: inpatientDialogBodyWidth(dialogContext),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: typeCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Procedure type',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: clinicianCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Performing clinician',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: siteCtrl,
                    decoration: const InputDecoration(labelText: 'Site'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: outcomeCtrl,
                    decoration: const InputDecoration(labelText: 'Outcome'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: complicationsCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Complications',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Wound images (optional)',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Upload wound image'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openBillProcedureDialog(BuildContext context) async {
    final scope = InpatientViewScope.of(context);
    final patientId = scope?.patientId ?? '';
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(content: Text('Patient context not available yet.')),
      );
      return;
    }
    final result = await showDialog<_BillProcedureChoice>(
      context: context,
      builder: (ctx) => _AddBillableProcedureDialog(
        serviceService: ref.read(serviceServiceProvider),
      ),
    );
    if (result == null || !mounted) return;
    final serviceId = result.service.id.isNotEmpty
        ? result.service.id
        : result.service.serviceId;
    final unitPrice = result.service.cost;
    final quantity = result.quantity;
    if (serviceId.isEmpty || quantity <= 0) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text('Select a service and enter a valid quantity'),
        ),
      );
      return;
    }
    try {
      final notifier = ref.read(invoiceNotifierProvider.notifier);
      final invoice = await notifier.getOrCreateBillingInvoice(
        patientId: patientId,
        staffId: scope?.staffId,
        encounterId: scope?.encounterId,
      );
      await notifier.addBillingItem(
        invoiceId: invoice.id,
        payload: AddInvoiceItemPayload(
          serviceId: serviceId,
          unitPrice: unitPrice,
          quantity: quantity,
          isRecurringDaily: result.isRecurring,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(content: Text('Procedure charge added to invoice')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Could not add procedure charge: $e')),
      );
    }
  }
}

class _BillProcedureChoice {
  const _BillProcedureChoice({
    required this.service,
    required this.quantity,
    required this.isRecurring,
  });

  final ServiceModel service;
  final int quantity;
  final bool isRecurring;
}

class _AddBillableProcedureDialog extends StatefulWidget {
  const _AddBillableProcedureDialog({required this.serviceService});

  final ServiceService serviceService;

  @override
  State<_AddBillableProcedureDialog> createState() =>
      _AddBillableProcedureDialogState();
}

class _AddBillableProcedureDialogState
    extends State<_AddBillableProcedureDialog> {
  static const int _pageSize = 10;

  final _searchCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  ServiceModel? _selected;
  List<ServiceModel> _suggestions = [];
  bool _loading = false;
  int _page = 0;
  Timer? _debounce;
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSearch(skip: 0));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _quantityCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _runSearch({int skip = 0, bool append = false}) async {
    setState(() => _loading = true);
    try {
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (!append) _suggestions = [];
      });
    }
  }

  void _submit() {
    final selected = _selected;
    if (selected == null) return;
    final quantity = int.tryParse(_quantityCtrl.text.trim()) ?? 0;
    if (quantity <= 0) return;
    Navigator.of(context).pop(
      _BillProcedureChoice(
        service: selected,
        quantity: quantity,
        isRecurring: _isRecurring,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Add billable procedure'),
      content: SizedBox(
        width: inpatientDialogBodyWidth(context, preferred: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Service', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              if (_selected != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: InputChip(
                    label: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 300),
                      child: Text(
                        _selected!.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () => setState(() => _selected = null),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search services…',
                    border: const OutlineInputBorder(),
                    isDense: true,
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
                  onChanged: (_) {
                    _debounce?.cancel();
                    _page = 0;
                    _debounce = Timer(
                      const Duration(milliseconds: 280),
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
                          subtitle: Text(
                            [
                              if (s.departmentName != null &&
                                  s.departmentName!.isNotEmpty)
                                s.departmentName!,
                              s.cost.toStringAsFixed(2),
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                          onTap: () => setState(() {
                            _selected = s;
                            _suggestions = [];
                            _searchCtrl.clear();
                          }),
                        ),
                      ),
                      if (_suggestions.length >= _pageSize)
                        TextButton.icon(
                          onPressed: _loading
                              ? null
                              : () {
                                  _page += 1;
                                  _runSearch(
                                    skip: _page * _pageSize,
                                    append: true,
                                  );
                                },
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Load more'),
                        ),
                    ],
                  ),
                ),
              ],
              if (_selected != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Unit price: ${_selected!.cost.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                dense: true,
                contentPadding: EdgeInsets.zero,
                value: _isRecurring,
                title: const Text('Recurring daily billing'),
                onChanged: (value) => setState(() => _isRecurring = value),
              ),
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
          onPressed: _selected == null ? null : _submit,
          child: const Text('Add'),
        ),
      ],
    );
  }
}
