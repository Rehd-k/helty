import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/models/imaging_catalog_model.dart';
import 'package:helty/src/models/imaging_order_model.dart';
import 'package:helty/src/services/imaging_catalog_service.dart';
import 'package:helty/src/services/imaging_order_service.dart';

@RoutePage()
class DoctorEncounterImagingTab extends StatefulWidget {
  const DoctorEncounterImagingTab({super.key});

  @override
  State<DoctorEncounterImagingTab> createState() =>
      _DoctorEncounterImagingTabState();
}

class _DoctorEncounterImagingTabState extends State<DoctorEncounterImagingTab> {
  final _catalogService = ImagingCatalogService();
  final _orderService = ImagingOrderService();

  List<ImagingOrderModel> _orders = [];
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
    final list = await _orderService.getByEncounter(scope.encounterId);
    if (!mounted) return;
    setState(() {
      _orders = list;
      _loading = false;
    });
  }

  Future<void> _openOrderModal() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;
    final catalog = await _catalogService.list();
    if (!mounted) return;

    ImagingCatalogModel? selected;
    String area = '';
    bool contrast = false;
    String urgency = 'Routine';
    final notesCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Order Imaging'),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Study',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ImagingCatalogModel>(
                        initialValue: selected,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Select study'),
                        items: catalog
                            .map(
                              (e) => DropdownMenuItem(
                                value: e,
                                child: Text('${e.name} (${e.area ?? ""})'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => selected = v),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Area',
                          hintText: selected?.area ?? 'e.g. Chest, Abdomen',
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: (v) => setState(() => area = v),
                      ),
                      const SizedBox(height: 8),
                      CheckboxListTile(
                        value: contrast,
                        title: const Text('Contrast'),
                        onChanged: (v) => setState(() => contrast = v ?? false),
                      ),
                      DropdownButtonFormField<String>(
                        initialValue: urgency,
                        decoration: const InputDecoration(
                          labelText: 'Urgency',
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
                            setState(() => urgency = v ?? urgency),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: notesCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes to radiologist',
                          border: OutlineInputBorder(),
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
                  onPressed: selected == null
                      ? null
                      : () => Navigator.of(ctx).pop(true),
                  child: const Text('Order'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && selected != null && mounted) {
      await _orderService.create(
        encounterId: scope.encounterId,
        catalogId: selected!.id,
        studyName: selected!.name,
        area: area.isEmpty ? selected!.area : area,
        contrast: contrast,
        urgency: urgency,
        notesToRadiologist: notesCtrl.text.trim().isEmpty
            ? null
            : notesCtrl.text.trim(),
      );
      notesCtrl.dispose();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Imaging order added')));
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
              label: const Text('Order Imaging'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _orders.isEmpty
                ? Center(
                    child: Text(
                      'No imaging orders. Tap "Order Imaging" to add.',
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
                          title: Text(o.studyName),
                          subtitle: Text(
                            '${o.urgency ?? "Routine"} • ${o.status}',
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
