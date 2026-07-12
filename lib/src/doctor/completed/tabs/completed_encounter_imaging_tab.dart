import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounter_order_dialogs.dart';
import 'package:helty/src/doctor/completed/widgets/completed_encounter_scope.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/services/radiology_service.dart';

@RoutePage()
class CompletedEncounterImagingTab extends StatefulWidget {
  const CompletedEncounterImagingTab({super.key});

  @override
  State<CompletedEncounterImagingTab> createState() =>
      _CompletedEncounterImagingTabState();
}

class _CompletedEncounterImagingTabState
    extends State<CompletedEncounterImagingTab> {
  final _orderService = RadiologyService();

  List<RadiologyOrder> _orders = [];
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
    final res = await _orderService.listOrders(
      encounterId: scope.encounter.id,
      take: 100,
    );
    if (!mounted) return;
    setState(() {
      _orders = res.orders;
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
            'No imaging orders for this encounter.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ResponsiveBody(
      center: false,
      builder: (context, bp) => ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: _orders.length,
        itemBuilder: (_, i) {
          final o = _orders[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(
                o.items.isNotEmpty
                    ? o.items.first.scanType.displayLabel
                    : 'Imaging order',
              ),
              subtitle: Text(
                '${DateFormatter.formatFromBackend(o.createdAt, DateFormatter.medicalDate)} • ${o.items.length} item(s) • ${o.status.name}',
                style: theme.textTheme.bodySmall,
              ),
              trailing: Chip(
                label: Text(o.status.name),
                backgroundColor: theme.colorScheme.primaryContainer,
              ),
              onTap: () => showCompletedEncounterRadiologyDialog(context, o),
            ),
          );
        },
      ),
    );
  }
}
