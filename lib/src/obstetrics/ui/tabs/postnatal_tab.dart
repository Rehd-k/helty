import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/obstetrics/ui/pregnancy_view_screen.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_cards.dart';
import 'package:helty/src/providers/service_providers.dart';

@RoutePage()
class ObstetricsPostnatalTab extends ConsumerStatefulWidget {
  final String? pregnancyId;

  const ObstetricsPostnatalTab({super.key, this.pregnancyId});

  @override
  ConsumerState<ObstetricsPostnatalTab> createState() =>
      _ObstetricsPostnatalTabState();
}

class _ObstetricsPostnatalTabState extends ConsumerState<ObstetricsPostnatalTab> {
  List<LabourDelivery> _deliveries = [];
  List<PostnatalVisit> _visits = [];
  bool _loading = true;
  String? _error;

  ObstetricsService get _service => ref.read(obstetricsServiceProvider);

  String? get _pregnancyId =>
      widget.pregnancyId ?? PregnancyViewScope.of(context)?.pregnancyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final id = _pregnancyId;
    if (id != null &&
        id.isNotEmpty &&
        _deliveries.isEmpty &&
        _visits.isEmpty &&
        _loading &&
        _error == null) {
      _load(id);
    }
  }

  Future<void> _load(String pregnancyId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final deliveriesRes = await _service.listLabourDeliveries(pregnancyId);
      final deliveries = deliveriesRes.labourDeliveries.isNotEmpty
          ? deliveriesRes.labourDeliveries
          : (await _service.getPregnancy(pregnancyId)).labourDeliveries ??
              const <LabourDelivery>[];
      final List<PostnatalVisit> allVisits = [];
      for (final d in deliveries) {
        final visitsRes = await _service.listPostnatalVisits(
          labourDeliveryId: d.id,
          take: 100,
        );
        allVisits.addAll(visitsRes.visits);
      }
      if (!mounted) return;
      setState(() {
        _deliveries = deliveries;
        _visits = allVisits;
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

  void _addVisit() {
    if (_deliveries.isEmpty) return;
    if (_deliveries.length == 1) {
      context.router
          .push(ObstetricsAddPostnatalVisitRoute(
            labourDeliveryId: _deliveries[0].id,
          ))
          .then((_) {
        final id = _pregnancyId;
        if (id != null) _load(id);
      });
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Select delivery for postnatal visit',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ..._deliveries.map((d) {
              final dateStr = DateFormatter.formatFromBackend(
                d.deliveryDateTime,
                DateFormatter.shortDate,
              );
              return ListTile(
                title: Text('$dateStr · ${d.mode.name}'),
                onTap: () {
                  Navigator.pop(context);
                  context.router
                      .push(ObstetricsAddPostnatalVisitRoute(
                        labourDeliveryId: d.id,
                      ))
                      .then((_) {
                    final id = _pregnancyId;
                    if (id != null) _load(id);
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _openPostnatalList(String labourDeliveryId) {
    context.router
        .push(ObstetricsPostnatalListRoute(
          labourDeliveryId: labourDeliveryId,
        ))
        .then((_) {
      final id = _pregnancyId;
      if (id != null) _load(id);
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
                _visits.isEmpty
                    ? 'No postnatal visits'
                    : '${_visits.length} visit${_visits.length == 1 ? '' : 's'}',
                style: theme.textTheme.titleSmall,
              ),
              if (_deliveries.isNotEmpty)
                FilledButton.icon(
                  onPressed: _addVisit,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add visit'),
                ),
            ],
          ),
        ),
        Expanded(
          child: _loading && _deliveries.isEmpty && _visits.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _deliveries.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.family_restroom_rounded,
                              size: 64,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Postnatal visits',
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Postnatal visits are linked to a labour delivery. Record a delivery first from the Labour & delivery tab, then add mother or baby postnatal visits.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : _visits.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.family_restroom_rounded,
                                  size: 48,
                                  color: colorScheme.outline,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No postnatal visits yet.',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  onPressed: _addVisit,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add visit'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _visits.length,
                          itemBuilder: (context, index) {
                            final v = _visits[index];
                            return PostnatalVisitCard(
                              visit: v,
                              onTap: () =>
                                  _openPostnatalList(v.labourDeliveryId),
                            );
                          },
                        ),
        ),
      ],
    );
  }
}
