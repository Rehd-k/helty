import 'package:flutter/material.dart';
import 'package:helty/src/models/medication_request_model.dart';
import 'package:helty/src/pharmacy/models/pharmacy_model.dart';
import 'package:helty/src/pharmacy/services/pharmacy_service.dart';
import 'package:helty/src/pharmacy/widgets/medication_attribution_widgets.dart';
import 'package:helty/src/pharmacy/widgets/prescription_drug_form_dialog.dart';
import 'package:helty/src/services/medication_order_service.dart';
import 'package:helty/src/services/medication_request_service.dart';

class MedicationRequestEditResult {
  const MedicationRequestEditResult({required this.updated});

  final MedicationRequestModel updated;
}

Future<MedicationRequestEditResult?> showMedicationRequestEditDialog(
  BuildContext context, {
  required MedicationRequestModel request,
  required MedicationRequestService requestService,
  required MedicationOrderService medicationOrderService,
  required PharmacyApiService pharmacyApi,
  required String modifiedByStaffId,
  bool allowDrugSubstitute = true,
}) {
  return showDialog<MedicationRequestEditResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _MedicationRequestEditDialog(
      request: request,
      requestService: requestService,
      medicationOrderService: medicationOrderService,
      pharmacyApi: pharmacyApi,
      modifiedByStaffId: modifiedByStaffId,
      allowDrugSubstitute: allowDrugSubstitute,
    ),
  );
}

class _MedicationRequestEditDialog extends StatefulWidget {
  const _MedicationRequestEditDialog({
    required this.request,
    required this.requestService,
    required this.medicationOrderService,
    required this.pharmacyApi,
    required this.modifiedByStaffId,
    this.allowDrugSubstitute = true,
  });

  final MedicationRequestModel request;
  final MedicationRequestService requestService;
  final MedicationOrderService medicationOrderService;
  final PharmacyApiService pharmacyApi;
  final String modifiedByStaffId;
  final bool allowDrugSubstitute;

  @override
  State<_MedicationRequestEditDialog> createState() =>
      _MedicationRequestEditDialogState();
}

class _MedicationRequestEditDialogState
    extends State<_MedicationRequestEditDialog> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _notesCtrl;

  Drug? _alternativeDrug;
  PrescriptionDrugFormResult? _substituteForm;
  bool _saving = false;
  String? _error;

  String get _currentDrugName {
    final order = widget.request.medicationOrder;
    if (order == null) return '—';
    return order.wasSubstituted
        ? order.currentDrugLabel
        : order.currentDrugLabel;
  }

  String get _prescribedDrugName =>
      widget.request.medicationOrder?.prescribedDrugLabel ?? _currentDrugName;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
      text: widget.request.requestedQuantity.toString(),
    );
    _notesCtrl = TextEditingController(text: widget.request.notes ?? '');
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAlternative() async {
    final order = widget.request.medicationOrder;
    final form = await showPrescriptionDrugFormDialog(
      context,
      pharmacyApi: widget.pharmacyApi,
      mode: PrescriptionDrugFormMode.substitute,
      replacingLineName: _currentDrugName,
      initial: PrescriptionDrugFormInitialValues(
        dose: order?.dose ?? '',
        frequency: order?.frequency != null
            ? matchRxFrequency(order!.frequency!)
            : null,
        route: order?.route ?? 'Oral',
      ),
    );
    if (form == null || !mounted) return;
    setState(() {
      _alternativeDrug = form.drug;
      _substituteForm = form;
      _error = null;
    });
  }

  void _clearAlternative() {
    setState(() {
      _alternativeDrug = null;
      _substituteForm = null;
    });
  }

  Future<void> _save() async {
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _error = 'Enter a positive whole number for quantity.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final sub = _substituteForm;
      final updated = await widget.requestService.updateWithAlternative(
        request: widget.request,
        modifiedByStaffId: widget.modifiedByStaffId,
        requestedQuantity: qty,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        newDrugId: _alternativeDrug?.id,
        newDrugName: _alternativeDrug?.brandName,
        dose: sub?.dose,
        frequency: sub?.frequency,
        duration: sub?.duration,
        clinicalQuantity: sub?.quantity,
        route: sub?.route,
        specialInstructions: sub?.specialInstructions,
        medicationOrderService: widget.medicationOrderService,
      );
      if (!mounted) return;
      Navigator.pop(context, MedicationRequestEditResult(updated: updated));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Edit medication request'),
      content: SizedBox(
        width: 460,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.request.medicationOrder?.wasSubstituted == true)
              MedicationSubstitutionSummary(
                prescribedDrug: _prescribedDrugName,
                currentDrug: _currentDrugName,
                compact: true,
              )
            else
              Text(
                'Prescribed: $_prescribedDrugName',
                style: theme.textTheme.bodyMedium,
              ),
            const SizedBox(height: 8),
            MedicationRequestAttribution(
              request: widget.request,
              compact: true,
            ),
            if (widget.allowDrugSubstitute) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _pickAlternative,
                      icon: const Icon(Icons.swap_horiz, size: 18),
                      label: const Text('Suggest alternative'),
                    ),
                  ),
                  if (_alternativeDrug != null) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Clear alternative',
                      onPressed: _saving ? null : _clearAlternative,
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ],
              ),
              if (_alternativeDrug != null) ...[
                const SizedBox(height: 8),
                Material(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.35,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      'Alternative: ${_alternativeDrug!.brandName}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Requested quantity *',
                border: OutlineInputBorder(),
              ),
              enabled: !_saving,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              enabled: !_saving,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

/// Doctor edit for BILLED requests — quantity only (no drug substitute).
Future<MedicationRequestEditResult?> showMedicationRequestQtyEditDialog(
  BuildContext context, {
  required MedicationRequestModel request,
  required MedicationRequestService requestService,
  required String modifiedByStaffId,
}) {
  return showDialog<MedicationRequestEditResult>(
    context: context,
    builder: (ctx) => _MedicationRequestQtyEditDialog(
      request: request,
      requestService: requestService,
      modifiedByStaffId: modifiedByStaffId,
    ),
  );
}

class _MedicationRequestQtyEditDialog extends StatefulWidget {
  const _MedicationRequestQtyEditDialog({
    required this.request,
    required this.requestService,
    required this.modifiedByStaffId,
  });

  final MedicationRequestModel request;
  final MedicationRequestService requestService;
  final String modifiedByStaffId;

  @override
  State<_MedicationRequestQtyEditDialog> createState() =>
      _MedicationRequestQtyEditDialogState();
}

class _MedicationRequestQtyEditDialogState
    extends State<_MedicationRequestQtyEditDialog> {
  late final TextEditingController _qtyCtrl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(
      text: widget.request.requestedQuantity.toString(),
    );
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final qty = int.tryParse(_qtyCtrl.text.trim());
    if (qty == null || qty <= 0) {
      setState(() => _error = 'Enter a positive whole number for quantity.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final updated = await widget.requestService.update(
        id: widget.request.id,
        modifiedByStaffId: widget.modifiedByStaffId,
        requestedQuantity: qty,
      );
      if (!mounted) return;
      Navigator.pop(context, MedicationRequestEditResult(updated: updated));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      title: const Text('Adjust billed quantity'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MedicationRequestAttribution(
              request: widget.request,
              compact: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Requested quantity',
                border: OutlineInputBorder(),
              ),
              enabled: !_saving,
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
