import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/providers/module_request_flow_provider.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/services/radiology_service.dart';

@RoutePage()
class RadiologyCreateRequestScreen extends ConsumerStatefulWidget {
  final String? patientId;

  const RadiologyCreateRequestScreen({super.key, this.patientId});

  @override
  ConsumerState<RadiologyCreateRequestScreen> createState() =>
      _RadiologyCreateRequestScreenState();
}

class _RadiologyCreateRequestScreenState
    extends ConsumerState<RadiologyCreateRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patientIdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.patientId != null && widget.patientId!.isNotEmpty) {
      _patientIdCtrl.text = widget.patientId!;
    }
  }

  PaidModuleRequestContext? get _paidContext =>
      ref.read(paidModuleRequestContextProvider);

  final List<_OrderItemDraft> _items = [const _OrderItemDraft()];
  bool _saving = false;
  String? _error;

  RadiologyService get _service => ref.read(radiologyServiceProvider);

  @override
  void dispose() {
    _patientIdCtrl.dispose();
    super.dispose();
  }

  String _extractInlineError(AppException e) {
    return e.message;
  }

  void _addItem() {
    setState(() {
      _items.add(const _OrderItemDraft());
    });
  }

  void _removeItem(int index) {
    if (_items.length == 1) return;
    setState(() {
      _items.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final patientId = _patientIdCtrl.text.trim();
    if (patientId.isEmpty) {
      setState(() => _error = 'Please select a patient.');
      return;
    }

    final staff = ref.read(authProvider).staff;
    if (staff?.id == null) {
      setState(() => _error = 'Not logged in as staff.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final paidContext = _paidContext;
      final body = <String, dynamic>{
        'patientId': patientId,
        'requestedById': staff!.id,
        'items': _items.map((item) {
          return {
            'scanType': item.scanType.apiValue,
            if (item.bodyPart.trim().isNotEmpty) 'bodyPart': item.bodyPart.trim(),
            'priority': item.priority.apiValue,
            if (item.clinicalNotes.trim().isNotEmpty)
              'clinicalNotes': item.clinicalNotes.trim(),
            if (item.reasonForInvestigation.trim().isNotEmpty)
              'reasonForInvestigation': item.reasonForInvestigation.trim(),
          };
        }).toList(),
      };

      final created = await _service.createOrder(body);
      if (paidContext != null &&
          paidContext.moduleType == ModuleRequestFlowType.radiology) {
        ref.read(paidModuleRequestContextProvider.notifier).state = null;
      }
      if (!mounted) return;
      context.router.replace(
        RadiologyRequestDetailRoute(requestId: created.id),
      );
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _extractInlineError(e);
        _saving = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New radiology request'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.maybePop(),
        ),
      ),
      body: ResponsiveBody(
        expand: false,
        builder: (context, bp) => SingleChildScrollView(
          child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Material(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              TextFormField(
                controller: _patientIdCtrl,
                enabled: _paidContext == null,
                decoration: InputDecoration(
                  labelText: 'Patient ID (UUID)',
                  hintText: _paidContext == null
                      ? 'Enter or select patient'
                      : 'Patient fixed from paid invoice',
                  border: const OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              if (_paidContext != null) ...[
                const SizedBox(height: 12),
                InputChip(
                  label: Text(
                    'Paid invoice: ${_paidContext!.invoiceDisplayId}',
                  ),
                  avatar: const Icon(Icons.lock_rounded, size: 16),
                  onDeleted: null,
                ),
              ],
              const SizedBox(height: 16),
              const SizedBox(height: 8),
              Text(
                'Order items',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...List.generate(_items.length, (index) {
                final item = _items[index];
                return _OrderItemCard(
                  key: ValueKey('order-item-$index'),
                  index: index,
                  item: item,
                  onChanged: (next) => setState(() => _items[index] = next),
                  onRemove: () => _removeItem(index),
                  canRemove: _items.length > 1,
                );
              }),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add item'),
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create order'),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _OrderItemDraft {
  const _OrderItemDraft({
    this.scanType = RadiologyModality.X_RAY,
    this.priority = RadiologyPriority.ROUTINE,
    this.bodyPart = '',
    this.clinicalNotes = '',
    this.reasonForInvestigation = '',
  });

  final RadiologyModality scanType;
  final RadiologyPriority priority;
  final String bodyPart;
  final String clinicalNotes;
  final String reasonForInvestigation;

  _OrderItemDraft copyWith({
    RadiologyModality? scanType,
    RadiologyPriority? priority,
    String? bodyPart,
    String? clinicalNotes,
    String? reasonForInvestigation,
  }) {
    return _OrderItemDraft(
      scanType: scanType ?? this.scanType,
      priority: priority ?? this.priority,
      bodyPart: bodyPart ?? this.bodyPart,
      clinicalNotes: clinicalNotes ?? this.clinicalNotes,
      reasonForInvestigation: reasonForInvestigation ?? this.reasonForInvestigation,
    );
  }
}

class _OrderItemCard extends StatelessWidget {
  const _OrderItemCard({
    super.key,
    required this.index,
    required this.item,
    required this.onChanged,
    required this.onRemove,
    required this.canRemove,
  });

  final int index;
  final _OrderItemDraft item;
  final ValueChanged<_OrderItemDraft> onChanged;
  final VoidCallback onRemove;
  final bool canRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('Item ${index + 1}'),
                const Spacer(),
                IconButton(
                  onPressed: canRemove ? onRemove : null,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
            DropdownButtonFormField<RadiologyModality>(
              initialValue: item.scanType,
              decoration: const InputDecoration(
                labelText: 'Scan type',
                border: OutlineInputBorder(),
              ),
              items: RadiologyModality.values
                  .map(
                    (e) => DropdownMenuItem(
                      value: e,
                      child: Text(e.name.replaceAll('_', ' ')),
                    ),
                  )
                  .toList(),
              onChanged: (v) => onChanged(item.copyWith(scanType: v)),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<RadiologyPriority>(
              initialValue: item.priority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
              ),
              items: RadiologyPriority.values
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (v) => onChanged(item.copyWith(priority: v)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: item.bodyPart,
              decoration: const InputDecoration(
                labelText: 'Body part (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => onChanged(item.copyWith(bodyPart: v)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: item.clinicalNotes,
              decoration: const InputDecoration(
                labelText: 'Clinical notes (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => onChanged(item.copyWith(clinicalNotes: v)),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: item.reasonForInvestigation,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => onChanged(item.copyWith(reasonForInvestigation: v)),
            ),
          ],
        ),
      ),
    );
  }
}
