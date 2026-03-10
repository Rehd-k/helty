import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/obstetrics/ui/pregnancy_view_screen.dart';
import 'package:helty/src/providers/service_providers.dart';

@RoutePage()
class ObstetricsLabourDeliveryTab extends ConsumerStatefulWidget {
  final String? pregnancyId;

  const ObstetricsLabourDeliveryTab({
    super.key,
    this.pregnancyId,
  });

  @override
  ConsumerState<ObstetricsLabourDeliveryTab> createState() =>
      _ObstetricsLabourDeliveryTabState();
}

class _ObstetricsLabourDeliveryTabState
    extends ConsumerState<ObstetricsLabourDeliveryTab> {
  List<LabourDelivery> _deliveries = [];
  bool _loading = true;
  String? _error;

  ObstetricsService get _service => ref.read(obstetricsServiceProvider);

  String? get _pregnancyId =>
      widget.pregnancyId ?? PregnancyViewScope.of(context)?.pregnancyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = _pregnancyId;
    if (id != null && id.isNotEmpty && _deliveries.isEmpty && _loading && _error == null) {
      _load(id);
    }
  }

  Future<void> _load(String id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.listLabourDeliveries(id);
      final deliveries = res.labourDeliveries.isNotEmpty
          ? res.labourDeliveries
          : (await _service.getPregnancy(id)).labourDeliveries ??
              const <LabourDelivery>[];
      if (!mounted) return;
      setState(() {
        _deliveries = deliveries;
        _loading = false;
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _addDelivery() {
    final id = _pregnancyId;
    if (id == null) return;
    context.router
        .push(ObstetricsAddLabourDeliveryRoute(pregnancyId: id))
        .then((_) {
      final pid = _pregnancyId;
      if (pid != null) _load(pid);
    });
  }

  @override
  Widget build(BuildContext context) {
    final pregnancyId = _pregnancyId;
    if (pregnancyId == null || pregnancyId.isEmpty) {
      return const Center(child: Text('Missing pregnancy context'));
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_error != null && _deliveries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _load(pregnancyId),
                child: const Text('Retry'),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _addDelivery,
                icon: const Icon(Icons.add),
                label: const Text('Record delivery'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (_error != null)
          Material(
            color: colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: Text(_error!)),
                  TextButton(
                    onPressed: () => setState(() => _error = null),
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _deliveries.isEmpty
                    ? 'No deliveries recorded'
                    : '${_deliveries.length} delivery${_deliveries.length == 1 ? '' : 's'}',
                style: theme.textTheme.titleSmall,
              ),
              FilledButton.icon(
                onPressed: _addDelivery,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Record delivery'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading && _deliveries.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _deliveries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.child_care_rounded,
                              size: 64,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No labour & delivery records yet.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add delivery details, partogram entries, and babies.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _addDelivery,
                              icon: const Icon(Icons.add),
                              label: const Text('Record delivery'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _deliveries.length,
                      itemBuilder: (context, index) {
                        final d = _deliveries[index];
                        final dateStr = DateFormatter.formatFromBackend(
                          d.deliveryDateTime,
                          DateFormatter.dateTime,
                        );
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(dateStr),
                            subtitle: Text(
                              '${d.mode.name} · ${d.outcome.name}',
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => context.router.push(
                              ObstetricsLabourDeliveryViewRoute(
                                labourDeliveryId: d.id,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
