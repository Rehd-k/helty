import 'dart:async';
import 'dart:math' as math;

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/models/medication_order_model.dart';
import 'package:helty/src/pharmacy/models/pharmacy_model.dart';
import 'package:helty/src/pharmacy/services/pharmacy_service.dart';
import 'package:helty/src/services/medication_order_service.dart';

// --- Prescribing helpers: frequency → doses/day, duration → days, quantity = ceil(doses × days) ---

class _RxFrequency {
  const _RxFrequency(this.label, this.dosesPerDay);
  final String label;
  final double dosesPerDay;
}

const List<_RxFrequency> _kFrequencies = <_RxFrequency>[
  _RxFrequency('Once daily (OD)', 1),
  _RxFrequency('Twice daily (BD / BID)', 2),
  _RxFrequency('Three times daily (TDS / TID)', 3),
  _RxFrequency('Four times daily (QID)', 4),
  _RxFrequency('Five times daily', 5),
  _RxFrequency('Every 12 hours (Q12H)', 2),
  _RxFrequency('Every 8 hours (Q8H)', 3),
  _RxFrequency('Every 6 hours (Q6H)', 4),
  _RxFrequency('Every 4 hours (Q4H)', 6),
  _RxFrequency('At bedtime (HS)', 1),
  _RxFrequency('Morning only (OM)', 1),
  _RxFrequency('Once weekly', 1 / 7),
  _RxFrequency('Twice weekly', 2 / 7),
  _RxFrequency('Three times weekly', 3 / 7),
  _RxFrequency('As needed (PRN) — estimate 1/day', 1),
];

enum _DurationUnit {
  days('Days'),
  weeks('Weeks'),
  months('Months'),
  years('Years'),
  hours('Hours');

  const _DurationUnit(this.label);
  final String label;
}

double _durationToDays(int value, _DurationUnit unit) {
  switch (unit) {
    case _DurationUnit.days:
      return value.toDouble();
    case _DurationUnit.weeks:
      return value * 7.0;
    case _DurationUnit.months:
      return value * 30.0;
    case _DurationUnit.years:
      return value * 365.0;
    case _DurationUnit.hours:
      return value / 24.0;
  }
}

String _formatDurationPhrase(int value, _DurationUnit unit) {
  if (value <= 0) return '';
  String noun(_DurationUnit u) {
    switch (u) {
      case _DurationUnit.days:
        return value == 1 ? 'day' : 'days';
      case _DurationUnit.weeks:
        return value == 1 ? 'week' : 'weeks';
      case _DurationUnit.months:
        return value == 1 ? 'month' : 'months';
      case _DurationUnit.years:
        return value == 1 ? 'year' : 'years';
      case _DurationUnit.hours:
        return value == 1 ? 'hour' : 'hours';
    }
  }

  return '$value ${noun(unit)}';
}

/// Total units (e.g. tablets) for the course: doses per day × duration in days, rounded up.
int _computedQuantity({
  required _RxFrequency frequency,
  required int durationValue,
  required _DurationUnit durationUnit,
}) {
  if (durationValue <= 0) return 0;
  final days = _durationToDays(durationValue, durationUnit);
  if (days <= 0) return 0;
  final raw = frequency.dosesPerDay * days;
  if (raw <= 0) return 1;
  return math.max(1, raw.ceil());
}

@RoutePage()
class DoctorEncounterPrescriptionTab extends StatefulWidget {
  const DoctorEncounterPrescriptionTab({super.key});

  @override
  State<DoctorEncounterPrescriptionTab> createState() =>
      _DoctorEncounterPrescriptionTabState();
}

class _DoctorEncounterPrescriptionTabState
    extends State<DoctorEncounterPrescriptionTab> {
  final _pharmacyService = PharmacyApiService();
  final _medicationOrderService = MedicationOrderService();

  static const int _searchDrugLimit = 30;

  List<MedicationOrderModel> _orders = [];
  bool _loading = true;
  bool _loadScheduled = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadScheduled) {
      _loadScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    setState(() => _loading = true);
    final list = await _medicationOrderService.getByEncounter(
      scope.encounterId,
    );
    if (!mounted) return;
    setState(() {
      _orders = list;
      _loading = false;
    });
  }

  Future<void> _openAddModal() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;

    final searchCtrl = TextEditingController();
    List<Drug> results = [];
    Drug? selected;
    bool searchLoading = false;
    Timer? searchDebounce;
    final doseCtrl = TextEditingController();
    final durationValueCtrl = TextEditingController(text: '7');
    final routeCtrl = TextEditingController(text: 'Oral');
    final instructionsCtrl = TextEditingController();
    var selectedFreq = _kFrequencies[1];
    var durationUnit = _DurationUnit.days;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            int? parsedDuration() {
              final n = int.tryParse(durationValueCtrl.text.trim());
              if (n == null || n <= 0) return null;
              return n;
            }

            int? computedQty() {
              final n = parsedDuration();
              if (n == null) return null;
              return _computedQuantity(
                frequency: selectedFreq,
                durationValue: n,
                durationUnit: durationUnit,
              );
            }

            final qtyForDisplay = computedQty();
            final durForDisplay = parsedDuration();

            return AlertDialog(
              title: const Text('Add prescription'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          labelText: 'Search drug',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: searchLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        onChanged: (v) {
                          searchDebounce?.cancel();
                          final query = v.trim();
                          if (query.isEmpty) {
                            setState(() {
                              results = [];
                              searchLoading = false;
                            });
                            return;
                          }
                          setState(() {
                            searchLoading = true;
                            results = [];
                          });
                          searchDebounce = Timer(
                            const Duration(milliseconds: 300),
                            () async {
                              try {
                                final response = await _pharmacyService
                                    .searchDrugs(
                                      SearchDrugParams(
                                        search: query,
                                        limit: _searchDrugLimit,
                                        page: 1,
                                        pageSize: _searchDrugLimit,
                                      ),
                                    );
                                if (ctx.mounted) {
                                  setState(() {
                                    results = response.items;
                                    searchLoading = false;
                                  });
                                }
                              } catch (_) {
                                if (ctx.mounted) {
                                  setState(() {
                                    results = [];
                                    searchLoading = false;
                                  });
                                }
                              }
                            },
                          );
                        },
                      ),
                      if (results.isNotEmpty && selected == null) ...[
                        const SizedBox(height: 8),
                        ...results.map(
                          (e) => ListTile(
                            dense: true,
                            title: Text(
                              '${e.brandName} ${e.strength ?? ""} ${e.dosageForm ?? ""}',
                            ),
                            subtitle: e.genericName != e.brandName
                                ? Text(e.genericName)
                                : null,
                            onTap: () => setState(() => selected = e),
                          ),
                        ),
                      ],
                      if (selected != null) ...[
                        const SizedBox(height: 12),
                        ListTile(
                          tileColor: Theme.of(
                            ctx,
                          ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          title: Text(
                            selected!.brandName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${selected!.strength ?? ""} ${selected!.dosageForm ?? ""}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => selected = null),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check patient allergies before prescribing.',
                          style: Theme.of(ctx).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: doseCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Dose',
                            border: OutlineInputBorder(),
                            hintText: 'e.g. 1 tablet, 500mg',
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<_RxFrequency>(
                          key: ValueKey(selectedFreq),
                          initialValue: selectedFreq,
                          decoration: const InputDecoration(
                            labelText: 'Frequency',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: _kFrequencies
                              .map(
                                (f) => DropdownMenuItem<_RxFrequency>(
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
                            setState(() => selectedFreq = v);
                          },
                        ),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: TextField(
                                controller: durationValueCtrl,
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
                              child: DropdownButtonFormField<_DurationUnit>(
                                key: ValueKey(durationUnit),
                                initialValue: durationUnit,
                                decoration: const InputDecoration(
                                  labelText: 'Unit',
                                  border: OutlineInputBorder(),
                                ),
                                items: _DurationUnit.values
                                    .map(
                                      (u) => DropdownMenuItem<_DurationUnit>(
                                        value: u,
                                        child: Text(u.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => durationUnit = v);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(ctx)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.6),
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
                                  color: Theme.of(ctx).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    durForDisplay == null
                                        ? 'Enter a positive whole number for duration.'
                                        : qtyForDisplay == null
                                        ? 'Unable to compute quantity.'
                                        : 'Quantity to dispense (sent to pharmacy): $qtyForDisplay\n'
                                              '(doses/day × duration in days, rounded up)',
                                    style: Theme.of(ctx).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: routeCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Route',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: instructionsCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Special instructions',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed:
                      selected == null ||
                          selected!.id == null ||
                          qtyForDisplay == null
                      ? null
                      : () async {
                          final n = int.tryParse(durationValueCtrl.text.trim());
                          if (n == null || n <= 0) return;
                          final qty = _computedQuantity(
                            frequency: selectedFreq,
                            durationValue: n,
                            durationUnit: durationUnit,
                          );
                          await _medicationOrderService.create(
                            staffId: scope.doctorId!,
                            encounterId: scope.encounterId,
                            patientId: scope.patientId,
                            drugId: selected!.id!,
                            drugName: selected!.brandName,
                            dose: doseCtrl.text.trim().isEmpty
                                ? null
                                : doseCtrl.text.trim(),
                            frequency: selectedFreq.label,
                            duration: _formatDurationPhrase(n, durationUnit),
                            quantity: qty,
                            route: routeCtrl.text.trim().isEmpty
                                ? null
                                : routeCtrl.text.trim(),
                            specialInstructions:
                                instructionsCtrl.text.trim().isEmpty
                                ? null
                                : instructionsCtrl.text.trim(),
                          );
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text('Prescription added'),
                              ),
                            );
                            _load();
                          }
                        },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
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

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _openAddModal,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add prescription'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _orders.isEmpty
                ? Center(
                    child: Text(
                      'No prescriptions. Tap "Add prescription" to add.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _orders.length,
                    itemBuilder: (_, i) {
                      final o = _orders[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(o.drugName),
                          subtitle: Text(
                            [
                              if (o.dose != null && o.dose!.isNotEmpty) o.dose,
                              if (o.quantity != null) 'Qty ${o.quantity}',
                              if (o.frequency != null && o.frequency!.isNotEmpty)
                                o.frequency,
                              if (o.duration != null && o.duration!.isNotEmpty)
                                o.duration,
                              o.status,
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Chip(
                            label: Text(o.status),
                            backgroundColor: theme.colorScheme.primaryContainer,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
