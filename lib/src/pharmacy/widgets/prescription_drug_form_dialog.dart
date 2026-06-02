import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:helty/src/models/medication_order_model.dart';
import 'package:helty/src/pharmacy/models/pharmacy_model.dart';
import 'package:helty/src/pharmacy/models/pharmacy_queue_models.dart';
import 'package:helty/src/pharmacy/services/pharmacy_service.dart';

// --- Prescribing helpers: frequency → doses/day, duration → days, quantity = ceil(doses × days) ---

class RxFrequency {
  const RxFrequency(this.label, this.dosesPerDay);
  final String label;
  final double dosesPerDay;
}

const List<RxFrequency> kRxFrequencies = <RxFrequency>[
  RxFrequency('Once daily (OD)', 1),
  RxFrequency('Twice daily (BD / BID)', 2),
  RxFrequency('Three times daily (TDS / TID)', 3),
  RxFrequency('Four times daily (QID)', 4),
  RxFrequency('Five times daily', 5),
  RxFrequency('Every 12 hours (Q12H)', 2),
  RxFrequency('Every 8 hours (Q8H)', 3),
  RxFrequency('Every 6 hours (Q6H)', 4),
  RxFrequency('Every 4 hours (Q4H)', 6),
  RxFrequency('At bedtime (HS)', 1),
  RxFrequency('Morning only (OM)', 1),
  RxFrequency('Once weekly', 1 / 7),
  RxFrequency('Twice weekly', 2 / 7),
  RxFrequency('Three times weekly', 3 / 7),
  RxFrequency('As needed (PRN) — estimate 1/day', 1),
];

enum RxDurationUnit {
  days('Days'),
  weeks('Weeks'),
  months('Months'),
  years('Years'),
  hours('Hours');

  const RxDurationUnit(this.label);
  final String label;
}

double rxDurationToDays(int value, RxDurationUnit unit) {
  switch (unit) {
    case RxDurationUnit.days:
      return value.toDouble();
    case RxDurationUnit.weeks:
      return value * 7.0;
    case RxDurationUnit.months:
      return value * 30.0;
    case RxDurationUnit.years:
      return value * 365.0;
    case RxDurationUnit.hours:
      return value / 24.0;
  }
}

String formatRxDurationPhrase(int value, RxDurationUnit unit) {
  if (value <= 0) return '';
  String noun(RxDurationUnit u) {
    switch (u) {
      case RxDurationUnit.days:
        return value == 1 ? 'day' : 'days';
      case RxDurationUnit.weeks:
        return value == 1 ? 'week' : 'weeks';
      case RxDurationUnit.months:
        return value == 1 ? 'month' : 'months';
      case RxDurationUnit.years:
        return value == 1 ? 'year' : 'years';
      case RxDurationUnit.hours:
        return value == 1 ? 'hour' : 'hours';
    }
  }

  return '$value ${noun(unit)}';
}

/// Total units (e.g. tablets) for the course: doses per day × duration in days, rounded up.
int computedPrescriptionQuantity({
  required RxFrequency frequency,
  required int durationValue,
  required RxDurationUnit durationUnit,
}) {
  if (durationValue <= 0) return 0;
  final days = rxDurationToDays(durationValue, durationUnit);
  if (days <= 0) return 0;
  final raw = frequency.dosesPerDay * days;
  if (raw <= 0) return 1;
  return math.max(1, raw.ceil());
}

({int value, RxDurationUnit unit})? parseRxDurationPhrase(String raw) {
  final s = raw.trim();
  if (s.isEmpty || s == '—') return null;
  final m = RegExp(
    r'^(\d+)\s*(day|days|week|weeks|month|months|year|years|hour|hours)$',
    caseSensitive: false,
  ).firstMatch(s);
  if (m == null) return null;
  final value = int.tryParse(m.group(1)!);
  if (value == null || value <= 0) return null;
  final unitWord = m.group(2)!.toLowerCase();
  final unit = switch (unitWord) {
    'day' || 'days' => RxDurationUnit.days,
    'week' || 'weeks' => RxDurationUnit.weeks,
    'month' || 'months' => RxDurationUnit.months,
    'year' || 'years' => RxDurationUnit.years,
    'hour' || 'hours' => RxDurationUnit.hours,
    _ => null,
  };
  if (unit == null) return null;
  return (value: value, unit: unit);
}

RxFrequency matchRxFrequency(String raw) {
  final t = raw.trim();
  if (t.isEmpty || t == '—') return kRxFrequencies[1];
  for (final f in kRxFrequencies) {
    if (f.label == t) return f;
  }
  final lower = t.toLowerCase();
  for (final f in kRxFrequencies) {
    if (f.label.toLowerCase() == lower) return f;
  }
  if (lower.contains('qid') || lower.contains('four times')) {
    return kRxFrequencies[3];
  }
  if (lower.contains('tds') ||
      lower.contains('tid') ||
      lower.contains('three times')) {
    return kRxFrequencies[2];
  }
  if (lower.contains('bd') ||
      lower.contains('bid') ||
      lower.contains('twice')) {
    return kRxFrequencies[1];
  }
  if (lower.contains('od') || lower.contains('once daily')) {
    return kRxFrequencies[0];
  }
  if (lower.contains('prn')) return kRxFrequencies.last;
  return kRxFrequencies[1];
}

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
}

enum PrescriptionDrugFormMode { add, substitute }

/// Doctor-style drug picker with frequency, duration, and computed quantity.
Future<PrescriptionDrugFormResult?> showPrescriptionDrugFormDialog(
  BuildContext context, {
  required PharmacyApiService pharmacyApi,
  PrescriptionDrugFormMode mode = PrescriptionDrugFormMode.add,
  PrescriptionDrugFormInitialValues? initial,
  String? replacingLineName,
}) async {
  const searchLimit = 30;
  final init = initial ?? PrescriptionDrugFormInitialValues();
  final isSubstitute = mode == PrescriptionDrugFormMode.substitute;

  final searchCtrl = TextEditingController();
  List<Drug> results = [];
  Drug? selected;
  int? remainingStock;
  bool stockLoading = false;
  String? stockError;
  bool searchLoading = false;
  Timer? searchDebounce;
  final doseCtrl = TextEditingController(text: init.dose);
  final durationValueCtrl = TextEditingController(
    text: '${init.durationValue}',
  );
  final routeCtrl = TextEditingController(text: init.route);
  final instructionsCtrl = TextEditingController(
    text: init.specialInstructions,
  );
  final notesCtrl = TextEditingController(text: init.notes);
  DateTime? startDateTime;
  DateTime? endDateTime;
  var adminStatus = init.administrationStatus;
  var selectedFreq = init.frequency;
  var durationUnit = init.durationUnit;

  final result = await showDialog<PrescriptionDrugFormResult?>(
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
            return computedPrescriptionQuantity(
              frequency: selectedFreq,
              durationValue: n,
              durationUnit: durationUnit,
            );
          }

          final qtyForDisplay = computedQty();
          final durForDisplay = parsedDuration();
          final invalidDateRange =
              startDateTime != null &&
              endDateTime != null &&
              endDateTime!.isBefore(startDateTime!);
          final qDisp = qtyForDisplay;
          final rStock = remainingStock;
          final lowStock = qDisp != null && rStock != null && qDisp > rStock;
          final theme = Theme.of(ctx);
          final colorScheme = theme.colorScheme;

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
                        isSubstitute
                            ? 'Substitute medication'
                            : 'Add prescription',
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    if (selected != null) ...[
                      const SizedBox(width: 8),
                      if (stockLoading)
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
                              remainingStock != null
                                  ? 'Qty remaining: ${remainingStock!}'
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
                if (isSubstitute &&
                    replacingLineName != null &&
                    replacingLineName.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Replacing: $replacingLineName',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
                if (selected != null &&
                    stockError != null &&
                    stockError!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    stockError!,
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
                              final response = await pharmacyApi.searchDrugs(
                                SearchDrugParams(
                                  search: query,
                                  limit: searchLimit,
                                  page: 1,
                                  pageSize: searchLimit,
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
                          onTap: () async {
                            setState(() {
                              selected = e;
                              remainingStock = null;
                              stockError = null;
                              stockLoading = true;
                            });
                            final id = e.id;
                            if (id == null || id.isEmpty) {
                              if (ctx.mounted) {
                                setState(() => stockLoading = false);
                              }
                              return;
                            }
                            try {
                              final drug = await pharmacyApi.getDrugById(
                                id,
                                'id,quantity',
                              );
                              if (!ctx.mounted) return;
                              setState(() {
                                stockLoading = false;
                                remainingStock =
                                    drug.stock ?? drug.displayStock;
                                stockError = null;
                              });
                            } catch (err) {
                              if (!ctx.mounted) return;
                              setState(() {
                                stockLoading = false;
                                remainingStock = null;
                                stockError = err.toString();
                              });
                            }
                          },
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
                          onPressed: () => setState(() {
                            selected = null;
                            remainingStock = null;
                            stockLoading = false;
                            stockError = null;
                          }),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isSubstitute
                            ? 'Check patient allergies before confirming.'
                            : 'Check patient allergies before prescribing.',
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
                      DropdownButtonFormField<RxFrequency>(
                        key: ValueKey(selectedFreq),
                        initialValue: selectedFreq,
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
                            child: DropdownButtonFormField<RxDurationUnit>(
                              key: ValueKey(durationUnit),
                              initialValue: durationUnit,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Prescribed quantity exceeds available stock',
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onErrorContainer,
                                              fontWeight: FontWeight.w800,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Prescribed: $qtyForDisplay units · Available: $remainingStock\n'
                                        'Pharmacy may delay dispensing or need a substitute.',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onErrorContainer,
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
                      if (!isSubstitute) ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<MedicationAdministrationStatus>(
                          key: ValueKey(adminStatus),
                          initialValue: adminStatus,
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
                            setState(() => adminStatus = v);
                          },
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: notesCtrl,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Clinical notes',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await _showDateTimePicker(
                                    context: ctx,
                                    initialDate:
                                        startDateTime ?? DateTime.now(),
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 3650),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 3650),
                                    ),
                                  );
                                  if (picked == null) return;
                                  setState(() => startDateTime = picked);
                                },
                                icon: const Icon(Icons.play_arrow_outlined),
                                label: Text(
                                  startDateTime == null
                                      ? 'Start'
                                      : DateFormat(
                                          'dd MMM yyyy, HH:mm',
                                        ).format(startDateTime!),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final picked = await _showDateTimePicker(
                                    context: ctx,
                                    initialDate:
                                        endDateTime ??
                                        (startDateTime ?? DateTime.now()),
                                    firstDate: DateTime.now().subtract(
                                      const Duration(days: 3650),
                                    ),
                                    lastDate: DateTime.now().add(
                                      const Duration(days: 3650),
                                    ),
                                  );
                                  if (picked == null) return;
                                  setState(() => endDateTime = picked);
                                },
                                icon: const Icon(Icons.stop_outlined),
                                label: Text(
                                  endDateTime == null
                                      ? 'End'
                                      : DateFormat(
                                          'dd MMM yyyy, HH:mm',
                                        ).format(endDateTime!),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (invalidDateRange) ...[
                          const SizedBox(height: 6),
                          Text(
                            'End date/time cannot be before start date/time.',
                            style: TextStyle(
                              color: Theme.of(ctx).colorScheme.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
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
                        qtyForDisplay == null ||
                        (!isSubstitute && invalidDateRange)
                    ? null
                    : () async {
                        final n = int.tryParse(durationValueCtrl.text.trim());
                        if (n == null || n <= 0) return;
                        final qty = computedPrescriptionQuantity(
                          frequency: selectedFreq,
                          durationValue: n,
                          durationUnit: durationUnit,
                        );
                        if (remainingStock != null && qty > remainingStock!) {
                          final proceed =
                              await showDialog<bool>(
                                context: ctx,
                                builder: (c) => AlertDialog(
                                  title: const Text('Insufficient stock'),
                                  content: Text(
                                    'Prescribed quantity ($qty) is greater than '
                                    'available stock ($remainingStock). The pharmacy '
                                    'may need to substitute or order stock.\n\n'
                                    'Continue anyway?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(c).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(c).pop(true),
                                      child: const Text('Continue anyway'),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                          if (!proceed || !ctx.mounted) return;
                        }
                        if (!ctx.mounted) return;
                        final doseText = doseCtrl.text.trim();
                        final routeText = routeCtrl.text.trim();
                        final instructionsText = instructionsCtrl.text.trim();
                        final notesText = notesCtrl.text.trim();
                        Navigator.of(ctx).pop(
                          PrescriptionDrugFormResult(
                            drug: selected!,
                            dose: doseText.isEmpty ? null : doseText,
                            frequency: selectedFreq.label,
                            duration: formatRxDurationPhrase(n, durationUnit),
                            quantity: qty,
                            route: routeText.isEmpty ? null : routeText,
                            specialInstructions: instructionsText.isEmpty
                                ? null
                                : instructionsText,
                            notes: notesText.isEmpty ? null : notesText,
                            administrationStatus: adminStatus,
                            startDateTime: startDateTime,
                            endDateTime: endDateTime,
                          ),
                        );
                      },
                child: Text(isSubstitute ? 'Replace line' : 'Add'),
              ),
            ],
          );
        },
      );
    },
  );

  searchDebounce?.cancel();
  searchCtrl.dispose();
  doseCtrl.dispose();
  durationValueCtrl.dispose();
  routeCtrl.dispose();
  instructionsCtrl.dispose();
  notesCtrl.dispose();

  return result;
}

Future<DateTime?> _showDateTimePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) async {
  final pickedDate = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
  );
  if (pickedDate == null) return null;
  if (!context.mounted) return null;
  final pickedTime = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initialDate),
  );
  if (pickedTime == null) return null;
  return DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    pickedTime.hour,
    pickedTime.minute,
  );
}
