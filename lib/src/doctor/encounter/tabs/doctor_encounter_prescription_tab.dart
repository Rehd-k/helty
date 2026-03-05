import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/models/drug_catalog_model.dart';
import 'package:helty/src/models/medication_order_model.dart';
import 'package:helty/src/services/drug_catalog_service.dart';
import 'package:helty/src/services/medication_order_service.dart';

@RoutePage()
class DoctorEncounterPrescriptionTab extends StatefulWidget {
  const DoctorEncounterPrescriptionTab({super.key});

  @override
  State<DoctorEncounterPrescriptionTab> createState() =>
      _DoctorEncounterPrescriptionTabState();
}

class _DoctorEncounterPrescriptionTabState
    extends State<DoctorEncounterPrescriptionTab> {
  final _drugCatalogService = DrugCatalogService();
  final _medicationOrderService = MedicationOrderService();

  List<MedicationOrderModel> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    setState(() => _loading = true);
    final list = await _medicationOrderService.getByEncounter(scope.encounterId);
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
    List<DrugCatalogModel> results = [];
    DrugCatalogModel? selected;
    final doseCtrl = TextEditingController();
    final frequencyCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final routeCtrl = TextEditingController(text: 'Oral');
    final instructionsCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
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
                        decoration: const InputDecoration(
                          labelText: 'Search drug',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (v) async {
                          final r = await _drugCatalogService.search(v);
                          setState(() => results = r);
                        },
                      ),
                      if (results.isNotEmpty && selected == null) ...[
                        const SizedBox(height: 8),
                        ...results.take(5).map((e) => ListTile(
                              dense: true,
                              title: Text('${e.name} ${e.strength ?? ""} ${e.form ?? ""}'),
                              onTap: () => setState(() => selected = e),
                            )),
                      ],
                      if (selected != null) ...[
                        const SizedBox(height: 12),
                        ListTile(
                          tileColor: Theme.of(ctx).colorScheme.primaryContainer.withValues(alpha: 0.3),
                          title: Text(selected!.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${selected!.strength ?? ""} ${selected!.form ?? ""}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => selected = null),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Check patient allergies before prescribing.', style: Theme.of(ctx).textTheme.bodySmall),
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
                  onPressed: selected == null
                      ? null
                      : () async {
                          await _medicationOrderService.create(
                            encounterId: scope.encounterId,
                            drugId: selected!.id,
                            drugName: selected!.name,
                            dose: doseCtrl.text.trim().isEmpty ? null : doseCtrl.text.trim(),
                            frequency: frequencyCtrl.text.trim().isEmpty ? null : frequencyCtrl.text.trim(),
                            duration: durationCtrl.text.trim().isEmpty ? null : durationCtrl.text.trim(),
                            route: routeCtrl.text.trim().isEmpty ? null : routeCtrl.text.trim(),
                            specialInstructions: instructionsCtrl.text.trim().isEmpty ? null : instructionsCtrl.text.trim(),
                          );
                          if (ctx.mounted) {
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Prescription added')),
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
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
                            '${o.dose ?? ""} ${o.frequency ?? ""} ${o.duration ?? ""} • ${o.status}',
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
