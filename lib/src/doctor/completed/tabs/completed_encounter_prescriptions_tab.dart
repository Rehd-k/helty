import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounter_scope.dart';
import 'package:helty/src/models/medication_order_model.dart';
import 'package:helty/src/services/medication_order_service.dart';

@RoutePage()
class CompletedEncounterPrescriptionsTab extends StatefulWidget {
  const CompletedEncounterPrescriptionsTab({super.key});

  @override
  State<CompletedEncounterPrescriptionsTab> createState() =>
      _CompletedEncounterPrescriptionsTabState();
}

class _CompletedEncounterPrescriptionsTabState
    extends State<CompletedEncounterPrescriptionsTab> {
  final _medicationOrderService = MedicationOrderService();

  List<MedicationOrderModel> _orders = [];
  bool _loading = true;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_scheduled) {
      _scheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
  }

  Future<void> _load() async {
    final scope = CompletedEncounterScope.of(context);
    if (scope == null) return;
    setState(() => _loading = true);
    final list =
        await _medicationOrderService.getByEncounter(scope.encounter.id);
    if (!mounted) return;
    setState(() {
      _orders = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = CompletedEncounterScope.of(context);
    if (scope == null) {
      return const Center(child: Text('Encounter context not available'));
    }

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No prescriptions for this encounter.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView.builder(
        itemCount: _orders.length,
        itemBuilder: (_, i) {
          final o = _orders[i];
          final detail = [
            if (o.dose != null && o.dose!.isNotEmpty) o.dose,
            if (o.quantity != null) 'Qty ${o.quantity}',
            if (o.frequency != null && o.frequency!.isNotEmpty) o.frequency,
            if (o.duration != null && o.duration!.isNotEmpty) o.duration,
            if (o.route != null && o.route!.isNotEmpty) o.route,
          ].whereType<String>().join(' · ');
          final hasNotes = o.specialInstructions != null &&
              o.specialInstructions!.trim().isNotEmpty;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: hasNotes
                ? ExpansionTile(
                    title: Text(o.drugName),
                    subtitle: Text(
                      detail.isEmpty ? o.status : '$detail · ${o.status}',
                      style: theme.textTheme.bodySmall,
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            o.specialInstructions!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ),
                    ],
                  )
                : ListTile(
                    title: Text(o.drugName),
                    subtitle: Text(
                      detail.isEmpty ? o.status : '$detail · ${o.status}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
          );
        },
      ),
    );
  }
}
