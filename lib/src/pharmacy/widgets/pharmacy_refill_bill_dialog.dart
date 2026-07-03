import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/models/encounter_model.dart';
import 'package:helty/src/pharmacy/models/pharmacy_refill_models.dart';
import 'package:helty/src/pharmacy/services/pharmacy_refill_service.dart';
import 'package:helty/src/services/encounter_service.dart';

/// Bill an approved refill to the patient's encounter invoice.
///
/// Auto-resolves the patient's open encounter; falls back to a manual encounter
/// picker/entry when none (or several) are found. Returns the bill result on
/// success, or `null` when dismissed.
Future<RefillBillResult?> showPharmacyRefillBillDialog(
  BuildContext context, {
  required PrescriptionRefillRequest request,
  required PharmacyRefillService service,
  required String billedByStaffId,
  EncounterService? encounterService,
}) {
  return showDialog<RefillBillResult>(
    context: context,
    builder: (_) => _PharmacyRefillBillDialog(
      request: request,
      service: service,
      billedByStaffId: billedByStaffId,
      encounterService: encounterService ?? EncounterService(),
    ),
  );
}

class _PharmacyRefillBillDialog extends StatefulWidget {
  const _PharmacyRefillBillDialog({
    required this.request,
    required this.service,
    required this.billedByStaffId,
    required this.encounterService,
  });

  final PrescriptionRefillRequest request;
  final PharmacyRefillService service;
  final String billedByStaffId;
  final EncounterService encounterService;

  @override
  State<_PharmacyRefillBillDialog> createState() =>
      _PharmacyRefillBillDialogState();
}

class _PharmacyRefillBillDialogState extends State<_PharmacyRefillBillDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityCtrl = TextEditingController();
  final _manualEncounterCtrl = TextEditingController();

  bool _loadingEncounters = true;
  bool _submitting = false;
  String? _error;

  List<EncounterModel> _encounters = const [];
  String? _selectedEncounterId;
  bool _manualEntry = false;

  @override
  void initState() {
    super.initState();
    final defaultQty = widget.request.defaultBillQuantity;
    if (defaultQty != null) _quantityCtrl.text = defaultQty.toString();
    _loadEncounters();
  }

  @override
  void dispose() {
    _quantityCtrl.dispose();
    _manualEncounterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEncounters() async {
    final patientUuid = widget.request.patient?.id ?? '';
    if (patientUuid.isEmpty) {
      setState(() {
        _loadingEncounters = false;
        _manualEntry = true;
      });
      return;
    }
    try {
      final encounters = await widget.encounterService.fetchByPatient(
        patientId: patientUuid,
      );
      if (!mounted) return;
      setState(() {
        _encounters = encounters;
        _loadingEncounters = false;
        if (encounters.length == 1) {
          _selectedEncounterId = encounters.first.id;
        } else if (encounters.isEmpty) {
          _manualEntry = true;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingEncounters = false;
        _manualEntry = true;
      });
    }
  }

  String? get _resolvedEncounterId {
    if (_manualEntry) {
      final manual = _manualEncounterCtrl.text.trim();
      return manual.isEmpty ? null : manual;
    }
    return _selectedEncounterId;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final encounterId = _resolvedEncounterId;
    if (encounterId == null || encounterId.isEmpty) {
      setState(() => _error = 'Select or enter an encounter to bill against');
      return;
    }
    final quantity = int.tryParse(_quantityCtrl.text.trim());
    if (quantity == null || quantity <= 0) {
      setState(() => _error = 'Quantity must be a positive number');
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await widget.service.bill(
        id: widget.request.id,
        billedByStaffId: widget.billedByStaffId,
        encounterId: encounterId,
        quantity: quantity,
      );
      if (!mounted) return;
      Navigator.of(context).pop(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prescription = widget.request.prescription;
    final drugName = prescription?.drug ??
        prescription?.firstItem?.drug?.displayName ??
        'Prescription';

    return AlertDialog(
      title: const Text('Bill refill'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(drugName, style: theme.textTheme.titleMedium),
              if (widget.request.patient != null)
                Text(
                  widget.request.patient!.displayName,
                  style: theme.textTheme.bodySmall,
                ),
              const SizedBox(height: 16),
              if (_loadingEncounters)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Finding open encounter…'),
                    ],
                  ),
                )
              else
                _buildEncounterField(theme),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Quantity to dispense',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final qty = int.tryParse(value?.trim() ?? '');
                  if (qty == null || qty <= 0) {
                    return 'Enter a positive quantity';
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submitting || _loadingEncounters ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Bill'),
        ),
      ],
    );
  }

  Widget _buildEncounterField(ThemeData theme) {
    if (_manualEntry) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_encounters.isEmpty)
            Text(
              'No open encounter found for this patient. Enter the encounter ID to bill against.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.error),
            ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _manualEncounterCtrl,
            decoration: const InputDecoration(
              labelText: 'Encounter ID',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (!_manualEntry) return null;
              if (value == null || value.trim().isEmpty) {
                return 'Encounter ID is required';
              }
              return null;
            },
          ),
          if (_encounters.isNotEmpty)
            TextButton.icon(
              onPressed: () => setState(() => _manualEntry = false),
              icon: const Icon(Icons.list_alt, size: 18),
              label: const Text('Pick from open encounters'),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _selectedEncounterId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Encounter',
            border: OutlineInputBorder(),
          ),
          items: [
            for (final e in _encounters)
              DropdownMenuItem(
                value: e.id,
                child: Text(_encounterLabel(e), overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (value) => setState(() => _selectedEncounterId = value),
          validator: (value) {
            if (_manualEntry) return null;
            if (value == null || value.isEmpty) {
              return 'Select an encounter';
            }
            return null;
          },
        ),
        TextButton.icon(
          onPressed: () => setState(() => _manualEntry = true),
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Enter encounter ID manually'),
        ),
      ],
    );
  }

  String _encounterLabel(EncounterModel encounter) {
    final type = encounter.encounterType ?? encounter.visitType ?? 'Encounter';
    final started = DateFormatter.medicalDate(encounter.startedAt);
    return '$type · $started';
  }
}
