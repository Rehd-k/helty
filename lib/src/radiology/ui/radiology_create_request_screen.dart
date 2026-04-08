import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
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

  final _clinicalNotesCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  final _bodyPartCtrl = TextEditingController();

  RadiologyModality _scanType = RadiologyModality.X_RAY;
  RadiologyPriority _priority = RadiologyPriority.ROUTINE;
  bool _saving = false;
  String? _error;

  RadiologyService get _service => ref.read(radiologyServiceProvider);

  @override
  void dispose() {
    _patientIdCtrl.dispose();
    _clinicalNotesCtrl.dispose();
    _reasonCtrl.dispose();
    _bodyPartCtrl.dispose();
    super.dispose();
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
      final paidRadiologyLine = paidContext?.serviceLines.firstWhere(
        (line) => line.categoryName.toLowerCase() == 'radiology & imaging',
        orElse: () => const PaidInvoiceServiceLine(
          invoiceItemId: '',
          serviceName: '',
          categoryName: '',
        ),
      );
      final body = <String, dynamic>{
        'patientId': patientId,
        'requestedById': staff!.id,
        'scanType': _scanType.apiValue,
        'priority': _priority.apiValue,
        if (paidContext != null &&
            paidContext.moduleType == ModuleRequestFlowType.radiology) ...{
          'invoiceId': paidContext.invoiceId,
          if (paidRadiologyLine != null &&
              paidRadiologyLine.invoiceItemId.isNotEmpty)
            'invoiceItemId': paidRadiologyLine.invoiceItemId,
          if (paidRadiologyLine?.serviceId?.isNotEmpty ?? false)
            'serviceId': paidRadiologyLine!.serviceId!,
        },
        if (_clinicalNotesCtrl.text.trim().isNotEmpty)
          'clinicalNotes': _clinicalNotesCtrl.text.trim(),
        if (_reasonCtrl.text.trim().isNotEmpty)
          'reasonForInvestigation': _reasonCtrl.text.trim(),
        if (_bodyPartCtrl.text.trim().isNotEmpty)
          'bodyPart': _bodyPartCtrl.text.trim(),
      };

      final created = await _service.createRequest(body);
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
        _error = e.message;
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
              DropdownButtonFormField<RadiologyModality>(
                initialValue: _scanType,
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
                onChanged: (v) => setState(() => _scanType = v ?? _scanType),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyPartCtrl,
                decoration: const InputDecoration(
                  labelText: 'Body part',
                  hintText: 'e.g. Chest, Abdomen',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<RadiologyPriority>(
                initialValue: _priority,
                decoration: const InputDecoration(
                  labelText: 'Priority',
                  border: OutlineInputBorder(),
                ),
                items: RadiologyPriority.values
                    .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                    .toList(),
                onChanged: (v) => setState(() => _priority = v ?? _priority),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _clinicalNotesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Clinical notes',
                  hintText: 'Optional',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reason for investigation',
                  hintText: 'Optional',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 2,
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
                    : const Text('Create request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
