import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/encounter/doctor_encounter_view_screen.dart';
import 'package:helty/src/models/medication_order_model.dart';
import 'package:helty/src/pharmacy/services/pharmacy_service.dart';
import 'package:helty/src/pharmacy/widgets/prescription_drug_form_dialog.dart';
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
  final _pharmacyService = PharmacyApiService();
  final _medicationOrderService = MedicationOrderService();

  List<MedicationOrderModel> _orders = [];
  bool _loading = true;
  bool _loadScheduled = false;
  final Set<String> _updatingOrderIds = {};

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

  Future<void> _toggleAdministrationStatus(MedicationOrderModel order) async {
    if (order.id.isEmpty || _updatingOrderIds.contains(order.id)) return;

    final next = order.administrationStatus ==
            MedicationAdministrationStatus.active
        ? MedicationAdministrationStatus.stopped
        : MedicationAdministrationStatus.active;

    setState(() => _updatingOrderIds.add(order.id));
    try {
      await _medicationOrderService.update(
        id: order.id,
        administrationStatus: next,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            next == MedicationAdministrationStatus.active
                ? '${order.drugName} activated for nursing administration'
                : '${order.drugName} deactivated — nurses cannot administer',
          ),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update prescription: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _updatingOrderIds.remove(order.id));
      }
    }
  }

  Future<void> _openAddModal() async {
    final scope = EncounterScope.of(context);
    if (scope == null) return;

    final form = await showPrescriptionDrugFormDialog(
      context,
      pharmacyApi: _pharmacyService,
      mode: PrescriptionDrugFormMode.add,
    );
    if (form == null || !mounted) return;

    final drugId = form.drug.id;
    if (drugId == null || drugId.isEmpty) return;

    try {
      await _medicationOrderService.create(
        staffId: scope.doctorId!,
        encounterId: scope.encounterId,
        patientId: scope.patientId,
        drugId: drugId,
        drugName: form.drug.brandName,
        dose: form.dose,
        frequency: form.frequency,
        duration: form.duration,
        quantity: form.quantity,
        route: form.route,
        specialInstructions: form.specialInstructions,
        startDateTime: form.startDateTime,
        endDateTime: form.endDateTime,
        notes: form.notes,
        administrationStatus: form.administrationStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription added')),
        );
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not add prescription: $e')),
        );
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
                      final isActive = o.administrationStatus ==
                          MedicationAdministrationStatus.active;
                      final isUpdating = _updatingOrderIds.contains(o.id);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(o.drugName),
                          subtitle: Text(
                            [
                              if (o.dose != null && o.dose!.isNotEmpty) o.dose,
                              if (o.quantity != null) 'Qty ${o.quantity}',
                              if (o.frequency != null &&
                                  o.frequency!.isNotEmpty)
                                o.frequency,
                              if (o.duration != null && o.duration!.isNotEmpty)
                                o.duration,
                              'Admin ${o.administrationStatus.label}',
                            ].join(' · '),
                            style: theme.textTheme.bodySmall,
                          ),
                          trailing: Wrap(
                            spacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Chip(
                                label: Text(o.status),
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                              ),
                              Chip(
                                label: Text(o.administrationStatus.label),
                                backgroundColor: isActive
                                    ? Colors.green.withValues(alpha: 0.15)
                                    : Colors.grey.withValues(alpha: 0.2),
                              ),
                              if (isUpdating)
                                const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                OutlinedButton.icon(
                                  onPressed: o.id.isEmpty
                                      ? null
                                      : () => _toggleAdministrationStatus(o),
                                  icon: Icon(
                                    isActive
                                        ? Icons.pause_circle_outline
                                        : Icons.play_circle_outline,
                                    size: 18,
                                  ),
                                  label: Text(isActive ? 'Deactivate' : 'Activate'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isActive
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                            ],
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
