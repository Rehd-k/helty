import 'dart:async';

import 'package:flutter/material.dart';
import 'package:helty/src/pharmacy/models/pharmacy_model.dart';
import 'package:helty/src/pharmacy/models/pharmacy_queue_models.dart';
import 'package:helty/src/pharmacy/services/pharmacy_service.dart';

/// Doctor-style drug picker for replacing an out-of-stock invoice line.
/// Returns the selected [Drug] when the user confirms, or `null` if cancelled.
Future<Drug?> showSubstituteMedicationDialog(
  BuildContext context, {
  required PrescribedMedication currentLine,
  required PharmacyApiService pharmacyApi,
}) async {
  const searchLimit = 30;

  final searchCtrl = TextEditingController();
  List<Drug> results = [];
  Drug? selected;
  bool searchLoading = false;
  Timer? searchDebounce;

  final doseCtrl = TextEditingController(
    text: currentLine.dosage.trim() == '—' ? '' : currentLine.dosage,
  );
  final frequencyCtrl = TextEditingController(
    text: currentLine.frequency.trim() == '—' ? '' : currentLine.frequency,
  );
  final durationCtrl = TextEditingController(
    text: currentLine.duration.trim() == '—' ? '' : currentLine.duration,
  );
  final routeCtrl = TextEditingController(
    text: currentLine.route.trim().isEmpty || currentLine.route.trim() == '—'
        ? 'Oral'
        : currentLine.route,
  );
  final instructionsCtrl = TextEditingController();

  final result = await showDialog<Drug?>(
    context: context,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: const Text('Substitute medication'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Replacing: ${currentLine.name}',
                      style: Theme.of(ctx).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
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
                        'Check patient allergies before confirming.',
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
                      TextField(
                        controller: frequencyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Frequency',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. BD, TDS, QID',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: durationCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Duration',
                          border: OutlineInputBorder(),
                          hintText: 'e.g. 5 days, 2 weeks',
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
                onPressed: selected == null || selected!.id == null
                    ? null
                    : () => Navigator.of(ctx).pop(selected),
                child: const Text('Replace line'),
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
  frequencyCtrl.dispose();
  durationCtrl.dispose();
  routeCtrl.dispose();
  instructionsCtrl.dispose();

  return result;
}
