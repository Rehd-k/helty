import 'package:auto_route/auto_route.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/models/procedure_record_model.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/models/staff_attribution.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_layout_constants.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/providers/invoices_providers.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/services/procedure_record_service.dart';
import 'package:helty/src/services/service_service.dart';
import 'package:helty/src/services/widgets/searchable_service_selector.dart';

@RoutePage()
class InpatientProceduresScreen extends ConsumerStatefulWidget {
  const InpatientProceduresScreen({super.key});

  @override
  ConsumerState<InpatientProceduresScreen> createState() =>
      _InpatientProceduresScreenState();
}

class _InpatientProceduresScreenState
    extends ConsumerState<InpatientProceduresScreen> {
  final _procedureService = ProcedureRecordService();
  List<ProcedureRecordModel> _records = [];
  bool _loading = true;
  String? _error;
  String? _lastAdmissionId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = InpatientViewScope.of(context)?.admissionId;
    if (id == null || id.isEmpty) {
      if (_lastAdmissionId != null) {
        setState(() {
          _records = [];
          _loading = false;
          _error = null;
          _lastAdmissionId = null;
        });
      }
      return;
    }
    if (id != _lastAdmissionId) {
      _lastAdmissionId = id;
      _load(id);
    }
  }

  Future<void> _load(String admissionId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _procedureService.list(admissionId);
      list.sort((a, b) {
        final ta =
            a.recordedAt ??
            a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final tb =
            b.recordedAt ??
            b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      if (!mounted) return;
      setState(() {
        _records = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _records = [];
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _dioMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }
    return e.message ?? 'Request failed';
  }

  Future<String?> _saveProcedureAndBill({
    required String admissionId,
    required String nurseId,
    required String patientId,
    required String? staffId,
    required String? encounterId,
    required ServiceModel service,
    required int quantity,
    required String description,
    String? outcome,
    String? complications,
  }) async {
    await _procedureService.create(
      admissionId: admissionId,
      nurseId: nurseId,
      procedureType: service.name,
      description: description,
      outcome: outcome,
      complications: complications,
    );

    final serviceId = service.id.isNotEmpty ? service.id : service.serviceId;
    if (serviceId.isEmpty) {
      return 'Procedure recorded; service id missing for billing';
    }

    try {
      final notifier = ref.read(invoiceNotifierProvider.notifier);
      final invoice = await notifier.getOrCreateBillingInvoice(
        patientId: patientId,
        staffId: staffId,
        encounterId: encounterId,
      );
      await notifier.addBillingItem(
        invoiceId: invoice.id,
        payload: AddInvoiceItemPayload(
          serviceId: serviceId,
          unitPrice: service.cost,
          quantity: quantity,
        ),
      );
      return null;
    } catch (e) {
      return 'Procedure recorded; could not add to invoice: $e';
    }
  }

  @override
  Widget build(BuildContext context) {
    final admissionId = InpatientViewScope.of(context)?.admissionId;

    if (admissionId == null || admissionId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Open this patient with an admission to view procedures.',
          ),
        ),
      );
    }

    Widget tableChild;
    if (_loading) {
      tableChild = const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (_error != null) {
      tableChild = Column(
        children: [
          Text(_error!, textAlign: TextAlign.center),
          TextButton(
            onPressed: () => _load(admissionId),
            child: const Text('Retry'),
          ),
        ],
      );
    } else {
      tableChild = SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns:
              [
                    'Date/Time',
                    'Type',
                    'Description',
                    'Outcome',
                    'Complications',
                    'Recorded by',
                  ]
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
          rows: _records
              .map(
                (r) => DataRow(
                  cells: [
                    DataCell(
                      Text(
                        DateFormatter.dateTime(
                          r.recordedAt ?? r.createdAt ?? DateTime.now(),
                        ),
                      ),
                    ),
                    DataCell(Text(r.procedureType ?? '—')),
                    DataCell(Text(r.description ?? '—')),
                    DataCell(Text(r.outcome ?? '—')),
                    DataCell(Text(r.complications ?? '—')),
                    DataCell(Text(r.nurseDisplayName ?? '—')),
                  ],
                ),
              )
              .toList(),
        ),
      );
    }

    return ResponsiveBody(
      expand: false,
      builder: (context, bp) => SingleChildScrollView(
        child: SectionCard(
        title: 'Procedures',
        subtitle: 'Bedside and theatre procedures for this admission',
        actions: [
          FilledButton.icon(
            onPressed: () => _openAddProcedureDialog(context, admissionId),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add Procedure'),
          ),
        ],
        child: tableChild,
      ),
      ),
    );
  }

  Future<void> _openAddProcedureDialog(
    BuildContext context,
    String admissionId,
  ) async {
    final nurseId = requireNurseIdFromScope(context);
    if (nurseId == null) return;

    final scope = InpatientViewScope.of(context);
    final patientId = scope?.patientId ?? '';
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient context not available yet.')),
      );
      return;
    }

    // Empty string = full success; non-empty = partial billing failure; null = cancelled.
    final result = await showDialog<String?>(
      context: context,
      builder: (dialogContext) => _AddInpatientProcedureDialog(
        serviceService: ref.read(serviceServiceProvider),
        dioMessage: _dioMessage,
        onSave:
            ({
              required service,
              required quantity,
              required description,
              outcome,
              complications,
            }) => _saveProcedureAndBill(
              admissionId: admissionId,
              nurseId: nurseId,
              patientId: patientId,
              staffId: scope?.staffId,
              encounterId: scope?.encounterId,
              service: service,
              quantity: quantity,
              description: description,
              outcome: outcome,
              complications: complications,
            ),
      ),
    );

    if (!mounted || result == null) return;

    await _load(admissionId);
    if (!mounted || !context.mounted) return;

    if (result.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Procedure recorded and billed')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result), duration: const Duration(seconds: 8)),
      );
    }
  }
}

class _AddInpatientProcedureDialog extends StatefulWidget {
  const _AddInpatientProcedureDialog({
    required this.serviceService,
    required this.onSave,
    required this.dioMessage,
  });

  final ServiceService serviceService;
  final Future<String?> Function({
    required ServiceModel service,
    required int quantity,
    required String description,
    String? outcome,
    String? complications,
  })
  onSave;
  final String Function(DioException e) dioMessage;

  @override
  State<_AddInpatientProcedureDialog> createState() =>
      _AddInpatientProcedureDialogState();
}

class _AddInpatientProcedureDialogState
    extends State<_AddInpatientProcedureDialog> {
  ServiceModel? _selectedService;
  final _quantityCtrl = TextEditingController(text: '1');
  final _descriptionCtrl = TextEditingController();
  final _outcomeCtrl = TextEditingController();
  final _complicationsCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _descriptionCtrl.dispose();
    _outcomeCtrl.dispose();
    _complicationsCtrl.dispose();
    super.dispose();
  }

  int? get _parsedQuantity {
    final quantity = int.tryParse(_quantityCtrl.text.trim()) ?? 0;
    return quantity > 0 ? quantity : null;
  }

  bool get _canSave => _selectedService != null && _parsedQuantity != null;

  Future<void> _submit() async {
    final service = _selectedService;
    final quantity = _parsedQuantity;
    if (service == null || quantity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a service and enter a valid quantity.'),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final partialError = await widget.onSave(
        service: service,
        quantity: quantity,
        description: _descriptionCtrl.text.trim(),
        outcome: _outcomeCtrl.text.trim().isEmpty
            ? null
            : _outcomeCtrl.text.trim(),
        complications: _complicationsCtrl.text.trim().isEmpty
            ? null
            : _complicationsCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(partialError ?? '');
    } on DioException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.dioMessage(e))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Procedure'),
      content: SizedBox(
        width: inpatientDialogBodyWidth(context, preferred: 420),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Service', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SearchableServiceSelector(
                serviceService: widget.serviceService,
                selectedService: _selectedService,
                searchHint: 'Search services…',
                onServiceSelected: (s) => setState(() => _selectedService = s),
                onClear: () => setState(() => _selectedService = null),
              ),
              if (_selectedService != null) ...[
                const SizedBox(height: 12),
                Text(
                  'Unit price: ${_selectedService!.cost.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Description / site',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _outcomeCtrl,
                decoration: const InputDecoration(labelText: 'Outcome'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _complicationsCtrl,
                decoration: const InputDecoration(labelText: 'Complications'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving || !_canSave ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
