import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/models/lab_catalog_model.dart';
import 'package:helty/src/models/lab_order_model.dart';
import 'package:helty/src/services/lab_catalog_service.dart';
import 'package:helty/src/services/lab_order_service.dart';

@RoutePage()
class DoctorEncounterInvestigationsTab extends StatefulWidget {
  const DoctorEncounterInvestigationsTab({super.key});

  @override
  State<DoctorEncounterInvestigationsTab> createState() =>
      _DoctorEncounterInvestigationsTabState();
}

class _DoctorEncounterInvestigationsTabState
    extends State<DoctorEncounterInvestigationsTab> {
  final _labCatalogService = LabCatalogService();
  final _labOrderService = LabOrderService();

  List<LabOrderModel> _orders = [];
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
    final list = await _labOrderService.getByEncounter(scope.encounterId);
    if (!mounted) return;
    setState(() {
      _orders = list;
      _loading = false;
    });
  }

  Future<void> _openOrderModal() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    final catalog = await _labCatalogService.list();
    if (!mounted) return;
    final selected = <LabCatalogModel>[];
    String priority = 'Routine';
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Order Lab Test'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: priority,
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Routine',
                            child: Text('Routine'),
                          ),
                          DropdownMenuItem(
                            value: 'Urgent',
                            child: Text('Urgent'),
                          ),
                          DropdownMenuItem(value: 'STAT', child: Text('STAT')),
                        ],
                        onChanged: (v) =>
                            setState(() => priority = v ?? priority),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Clinical notes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Select tests:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...catalog.map(
                        (e) => CheckboxListTile(
                          value: selected.contains(e),
                          title: Text('${e.name} (${e.department ?? "Lab"})'),
                          subtitle: Text(
                            '${e.sampleType ?? ""} • ${e.turnaround ?? ""}',
                          ),
                          onChanged: (v) {
                            setState(() {
                              if (v == true) {
                                selected.add(e);
                              } else {
                                selected.remove(e);
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: selected.isEmpty
                      ? null
                      : () {
                          Navigator.of(ctx).pop(true);
                        },
                  child: const Text('Order'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && selected.isNotEmpty && mounted) {
      final notes = notesCtrl.text.trim();
      for (final test in selected) {
        await _labOrderService.create(
          encounterId: scope.encounterId,
          catalogTestId: test.id,
          testName: test.name,
          priority: priority,
          clinicalNotes: notes.isEmpty ? null : notes,
        );
      }
      notesCtrl.dispose();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selected.length} lab order(s) added')),
        );
        _load();
      }
    }
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
              onPressed: _openOrderModal,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Order Lab Test'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _orders.isEmpty
                ? Center(
                    child: Text(
                      'No lab orders. Tap "Order Lab Test" to add.',
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
                          title: Text(o.testName),
                          subtitle: Text(
                            '${o.priority ?? "Routine"} • ${o.status}',
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
