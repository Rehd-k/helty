import 'dart:async';

import 'package:flutter/material.dart';
import 'package:helty/src/medications/rx_schedule_utils.dart';
import 'package:helty/src/models/medication_order_model.dart';
import 'package:helty/src/pharmacy/models/pharmacy_model.dart';
import 'package:helty/src/pharmacy/models/pharmacy_queue_models.dart';
import 'package:helty/src/pharmacy/services/pharmacy_service.dart';

export 'package:helty/src/medications/rx_schedule_utils.dart';

class PrescriptionDrugFormInitialValues {
  PrescriptionDrugFormInitialValues({
    this.dose = '',
    RxFrequency? frequency,
    this.durationValue = 7,
    this.durationUnit = RxDurationUnit.days,
    this.route = 'Oral',
    this.specialInstructions = '',
    this.notes = '',
    this.administrationStatus = MedicationAdministrationStatus.active,
  }) : frequency = frequency ?? kRxFrequencies[1];

  final String dose;
  final RxFrequency frequency;
  final int durationValue;
  final RxDurationUnit durationUnit;
  final String route;
  final String specialInstructions;
  final String notes;
  final MedicationAdministrationStatus administrationStatus;

  factory PrescriptionDrugFormInitialValues.fromPrescribedLine(
    PrescribedMedication line,
  ) {
    final parsed = parseRxDurationPhrase(line.duration);
    return PrescriptionDrugFormInitialValues(
      dose: line.dosage.trim() == '—' ? '' : line.dosage.trim(),
      frequency: matchRxFrequency(line.frequency),
      durationValue: parsed?.value ?? 7,
      durationUnit: parsed?.unit ?? RxDurationUnit.days,
      route: line.route.trim().isEmpty || line.route.trim() == '—'
          ? 'Oral'
          : line.route.trim(),
    );
  }
}

class PrescriptionDrugFormResult {
  const PrescriptionDrugFormResult({
    required this.drug,
    required this.dose,
    required this.frequency,
    required this.duration,
    required this.quantity,
    required this.route,
    required this.specialInstructions,
    required this.notes,
    required this.administrationStatus,
    this.startDateTime,
    this.endDateTime,
    this.requestedQuantity,
  });

  final Drug drug;
  final String? dose;
  final String frequency;
  final String duration;
  final int quantity;
  final String? route;
  final String? specialInstructions;
  final String? notes;
  final MedicationAdministrationStatus administrationStatus;
  final DateTime? startDateTime;
  final DateTime? endDateTime;
  /// Billing / dispense units for outpatient prescribe (when required).
  final int? requestedQuantity;
}

enum PrescriptionDrugFormMode { add, substitute }

/// Doctor-style drug picker with frequency, duration, and computed quantity.
Future<PrescriptionDrugFormResult?> showPrescriptionDrugFormDialog(
  BuildContext context, {
  required PharmacyApiService pharmacyApi,
  PrescriptionDrugFormMode mode = PrescriptionDrugFormMode.add,
  PrescriptionDrugFormInitialValues? initial,
  String? replacingLineName,
}) {
  return showDialog<PrescriptionDrugFormResult?>(
    context: context,
    builder: (ctx) => _PrescriptionDrugFormDialog(
      pharmacyApi: pharmacyApi,
      mode: mode,
      initial: initial ?? PrescriptionDrugFormInitialValues(),
      replacingLineName: replacingLineName,
    ),
  );
}

class _PrescriptionDrugFormDialog extends StatefulWidget {
  const _PrescriptionDrugFormDialog({
    required this.pharmacyApi,
    required this.mode,
    required this.initial,
    this.replacingLineName,
  });

  final PharmacyApiService pharmacyApi;
  final PrescriptionDrugFormMode mode;
  final PrescriptionDrugFormInitialValues initial;
  final String? replacingLineName;

  @override
  State<_PrescriptionDrugFormDialog> createState() =>
      _PrescriptionDrugFormDialogState();
}

class _PrescriptionDrugFormDialogState extends State<_PrescriptionDrugFormDialog> {
  static const _searchLimit = 30;

  late final TextEditingController _searchCtrl;
  late final TextEditingController _doseCtrl;
  late final TextEditingController _durationValueCtrl;
  late final TextEditingController _routeCtrl;
  late final TextEditingController _instructionsCtrl;
  late final TextEditingController _notesCtrl;

  List<Drug> _results = [];
  Drug? _selected;
  int? _remainingStock;
  bool _stockLoading = false;
  String? _stockError;
  bool _searchLoading = false;
  Timer? _searchDebounce;
  late MedicationAdministrationStatus _adminStatus;
  late RxFrequency _selectedFreq;
  late RxDurationUnit _durationUnit;

  bool get _isSubstitute => widget.mode == PrescriptionDrugFormMode.substitute;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _searchCtrl = TextEditingController();
    _doseCtrl = TextEditingController(text: init.dose);
    _durationValueCtrl = TextEditingController(text: '${init.durationValue}');
    _routeCtrl = TextEditingController(text: init.route);
    _instructionsCtrl = TextEditingController(text: init.specialInstructions);
    _notesCtrl = TextEditingController(text: init.notes);
    _adminStatus = init.administrationStatus;
    _selectedFreq = init.frequency;
    _durationUnit = init.durationUnit;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    _doseCtrl.dispose();
    _durationValueCtrl.dispose();
    _routeCtrl.dispose();
    _instructionsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  int? _parsedDuration() {
    final n = int.tryParse(_durationValueCtrl.text.trim());
    if (n == null || n <= 0) return null;
    return n;
  }

  int? _computedQty() {
    final n = _parsedDuration();
    if (n == null) return null;
    return computedPrescriptionQuantity(
      frequency: _selectedFreq,
      durationValue: n,
      durationUnit: _durationUnit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final qtyForDisplay = _computedQty();
    final durForDisplay = _parsedDuration();
    final qDisp = qtyForDisplay;
    final rStock = _remainingStock;
    final lowStock = qDisp != null && rStock != null && qDisp > rStock;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final replacingLineName = widget.replacingLineName;

    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  _isSubstitute ? 'Substitute medication' : 'Add prescription',
                  style: theme.textTheme.titleLarge,
                ),
              ),
              if (_selected != null) ...[
                const SizedBox(width: 8),
                if (_stockLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Material(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: Text(
                        _remainingStock != null
                            ? 'Qty remaining: $_remainingStock'
                            : 'Stock: —',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
          if (_isSubstitute &&
              replacingLineName != null &&
              replacingLineName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Replacing: $replacingLineName',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (_selected != null &&
              _stockError != null &&
              _stockError!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _stockError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.error,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  labelText: 'Search drug',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchLoading
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
                  _searchDebounce?.cancel();
                  final query = v.trim();
                  if (query.isEmpty) {
                    setState(() {
                      _results = [];
                      _searchLoading = false;
                    });
                    return;
                  }
                  setState(() {
                    _searchLoading = true;
                    _results = [];
                  });
                  _searchDebounce = Timer(
                    const Duration(milliseconds: 300),
                    () async {
                      try {
                        final response = await widget.pharmacyApi.searchDrugs(
                          SearchDrugParams(
                            search: query,
                            limit: _searchLimit,
                            page: 1,
                            pageSize: _searchLimit,
                          ),
                        );
                        if (!mounted) return;
                        setState(() {
                          _results = response.items;
                          _searchLoading = false;
                        });
                      } catch (_) {
                        if (!mounted) return;
                        setState(() {
                          _results = [];
                          _searchLoading = false;
                        });
                      }
                    },
                  );
                },
              ),
              if (_results.isNotEmpty && _selected == null) ...[
                const SizedBox(height: 8),
                ..._results.map(
                  (e) => ListTile(
                    dense: true,
                    title: Text(
                      '${e.brandName} ${e.strength ?? ""} ${e.dosageForm ?? ""}',
                    ),
                    subtitle: e.genericName != e.brandName
                        ? Text(e.genericName)
                        : null,
                    onTap: () async {
                      setState(() {
                        _selected = e;
                        _remainingStock = null;
                        _stockError = null;
                        _stockLoading = true;
                      });
                      final id = e.id;
                      if (id == null || id.isEmpty) {
                        if (mounted) {
                          setState(() => _stockLoading = false);
                        }
                        return;
                      }
                      try {
                        final drug = await widget.pharmacyApi.getDrugById(
                          id,
                          'id,quantity',
                        );
                        if (!mounted) return;
                        setState(() {
                          _stockLoading = false;
                          _remainingStock = drug.stock ?? drug.displayStock;
                          _stockError = null;
                        });
                      } catch (err) {
                        if (!mounted) return;
                        setState(() {
                          _stockLoading = false;
                          _remainingStock = null;
                          _stockError = err.toString();
                        });
                      }
                    },
                  ),
                ),
              ],
              if (_selected != null) ...[
                const SizedBox(height: 12),
                ListTile(
                  tileColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                  title: Text(
                    _selected!.brandName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${_selected!.strength ?? ""} ${_selected!.dosageForm ?? ""}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() {
                      _selected = null;
                      _remainingStock = null;
                      _stockLoading = false;
                      _stockError = null;
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isSubstitute
                      ? 'Check patient allergies before confirming.'
                      : 'Check patient allergies before prescribing.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _doseCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dose',
                    border: OutlineInputBorder(),
                    hintText: 'e.g. 1 tablet, 500mg',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<RxFrequency>(
                  key: ValueKey(_selectedFreq),
                  initialValue: _selectedFreq,
                  decoration: const InputDecoration(
                    labelText: 'Frequency',
                    border: OutlineInputBorder(),
                  ),
                  isExpanded: true,
                  items: kRxFrequencies
                      .map(
                        (f) => DropdownMenuItem<RxFrequency>(
                          value: f,
                          child: Text(
                            f.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v == null) return;
                    setState(() => _selectedFreq = v);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _durationValueCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Duration (number)',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<RxDurationUnit>(
                        key: ValueKey(_durationUnit),
                        initialValue: _durationUnit,
                        decoration: const InputDecoration(
                          labelText: 'Unit',
                          border: OutlineInputBorder(),
                        ),
                        items: RxDurationUnit.values
                            .map(
                              (u) => DropdownMenuItem<RxDurationUnit>(
                                value: u,
                                child: Text(u.label),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _durationUnit = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.6,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calculate_outlined,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            durForDisplay == null
                                ? 'Enter a positive whole number for duration.'
                                : qtyForDisplay == null
                                ? 'Unable to compute quantity.'
                                : 'Quantity: $qtyForDisplay units\n'
                                      '(dose/day × duration)',
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (lowStock) ...[
                  const SizedBox(height: 8),
                  Material(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: colorScheme.onErrorContainer,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Prescribed quantity exceeds available stock',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Prescribed quantity ($qtyForDisplay units) exceeds available stock.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onErrorContainer,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                TextField(
                  controller: _routeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Route',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _instructionsCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Special instructions',
                    border: OutlineInputBorder(),
                  ),
                ),
                if (!_isSubstitute) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<MedicationAdministrationStatus>(
                    key: ValueKey(_adminStatus),
                    initialValue: _adminStatus,
                    decoration: const InputDecoration(
                      labelText: 'Administration status',
                      border: OutlineInputBorder(),
                    ),
                    items: MedicationAdministrationStatus.values
                        .map(
                          (s) => DropdownMenuItem(
                            value: s,
                            child: Text(s.label),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _adminStatus = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _notesCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Clinical notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
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
          onPressed: _selected == null ||
                  _selected!.id == null ||
                  qtyForDisplay == null
              ? null
              : () async {
                  final n = int.tryParse(_durationValueCtrl.text.trim());
                  if (n == null || n <= 0) return;
                  final qty = computedPrescriptionQuantity(
                    frequency: _selectedFreq,
                    durationValue: n,
                    durationUnit: _durationUnit,
                  );
                  if (_remainingStock != null && qty > _remainingStock!) {
                    final proceed =
                        await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Insufficient stock'),
                            content: Text(
                              'Prescribed quantity ($qty) is greater than '
                              'available stock ($_remainingStock). The pharmacy '
                              'may need to substitute or order stock.\n\n'
                              'Continue anyway?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(c).pop(false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.of(c).pop(true),
                                child: const Text('Continue anyway'),
                              ),
                            ],
                          ),
                        ) ??
                        false;
                    if (!proceed || !mounted) return;
                  }
                  if (!mounted) return;
                  final doseText = _doseCtrl.text.trim();
                  final routeText = _routeCtrl.text.trim();
                  final instructionsText = _instructionsCtrl.text.trim();
                  final notesText = _notesCtrl.text.trim();
                  Navigator.of(context).pop(
                    PrescriptionDrugFormResult(
                      drug: _selected!,
                      dose: doseText.isEmpty ? null : doseText,
                      frequency: _selectedFreq.label,
                      duration: formatRxDurationPhrase(n, _durationUnit),
                      quantity: qty,
                      route: routeText.isEmpty ? null : routeText,
                      specialInstructions: instructionsText.isEmpty
                          ? null
                          : instructionsText,
                      notes: notesText.isEmpty ? null : notesText,
                      administrationStatus: _adminStatus,
                      requestedQuantity: qty,
                    ),
                  );
                },
          child: Text(_isSubstitute ? 'Replace line' : 'Add'),
        ),
      ],
    );
  }
}
