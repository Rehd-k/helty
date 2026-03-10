import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/providers/service_providers.dart';

@RoutePage()
class ObstetricsLabourDeliveryViewScreen extends ConsumerStatefulWidget {
  final String labourDeliveryId;

  const ObstetricsLabourDeliveryViewScreen({
    super.key,
    required this.labourDeliveryId,
  });

  @override
  ConsumerState<ObstetricsLabourDeliveryViewScreen> createState() =>
      _ObstetricsLabourDeliveryViewScreenState();
}

class _ObstetricsLabourDeliveryViewScreenState
    extends ConsumerState<ObstetricsLabourDeliveryViewScreen> {
  LabourDelivery? _delivery;
  List<PartogramEntry> _partogram = [];
  List<Baby> _babies = [];
  bool _loading = true;
  String? _error;

  ObstetricsService get _service => ref.read(obstetricsServiceProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final delivery = await _service.getLabourDelivery(
        widget.labourDeliveryId,
      );
      final partogram = await _service.listPartogram(widget.labourDeliveryId);
      final babiesRes = await _service.listBabies(
        labourDeliveryId: widget.labourDeliveryId,
      );
      if (!mounted) return;
      setState(() {
        _delivery = delivery;
        _partogram = partogram;
        _babies = babiesRes.babies;
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

  void _addPartogram() {
    context.router
        .push(
          ObstetricsAddPartogramEntryRoute(
            labourDeliveryId: widget.labourDeliveryId,
          ),
        )
        .then((_) => _load());
  }

  void _addBaby() {
    if (_delivery == null) return;
    context.router
        .push(
          ObstetricsAddBabyRoute(
            labourDeliveryId: widget.labourDeliveryId,
            pregnancyId: _delivery!.pregnancyId,
          ),
        )
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _delivery == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Labour & delivery')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _delivery == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Labour & delivery'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.router.maybePop(),
          ),
        ),
        body: Center(child: Text(_error!)),
      );
    }

    final d = _delivery!;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Delivery · ${DateFormatter.formatFromBackend(d.deliveryDateTime, DateFormatter.dateTime)} · ${d.mode.name}'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.router.maybePop(),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.family_restroom),
              tooltip: 'Postnatal visits',
              onPressed: () => context.router.push(
                ObstetricsPostnatalListRoute(
                  labourDeliveryId: widget.labourDeliveryId,
                ),
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Partogram'),
              Tab(text: 'Babies'),
            ],
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: TabBarView(
            children: [
              _PartogramList(entries: _partogram, onAdd: _addPartogram),
              _BabiesList(
                babies: _babies,
                onAdd: _addBaby,
                labourDeliveryId: widget.labourDeliveryId,
                onRefresh: _load,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartogramList extends StatelessWidget {
  const _PartogramList({required this.entries, required this.onAdd});

  final List<PartogramEntry> entries;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add entry'),
            ),
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 48,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No partogram entries.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add),
                        label: const Text('Add first entry'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final e = entries[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(DateFormatter.formatFromBackend(e.recordedAt, DateFormatter.dateTime)),
                        subtitle: Text(
                          [
                            if (e.cervicalDilationCm != null)
                              'Dilation: ${e.cervicalDilationCm} cm',
                            if (e.fetalHeartRate != null)
                              'FHR: ${e.fetalHeartRate}',
                            if (e.comments != null && e.comments!.isNotEmpty)
                              e.comments,
                          ].join(' · '),
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

class _BabiesList extends StatelessWidget {
  const _BabiesList({
    required this.babies,
    required this.onAdd,
    required this.labourDeliveryId,
    required this.onRefresh,
  });

  final List<Baby> babies;
  final VoidCallback onAdd;
  final String labourDeliveryId;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add baby'),
            ),
          ),
        ),
        Expanded(
          child: babies.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.child_care,
                        size: 48,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No babies recorded.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: onAdd,
                        icon: const Icon(Icons.add),
                        label: const Text('Add baby'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: babies.length,
                  itemBuilder: (context, index) {
                    final b = babies[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          'Baby ${b.birthOrder} · ${b.sex.name}'
                          '${b.birthWeightG != null ? ' · ${b.birthWeightG}g' : ''}',
                        ),
                        subtitle: Text(
                          b.registeredPatientId != null
                              ? 'Registered as patient'
                              : 'Not registered',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (b.registeredPatientId == null)
                              IconButton(
                                icon: const Icon(Icons.person_add),
                                tooltip: 'Register as patient',
                                onPressed: () => context.router
                                    .push(
                                      ObstetricsRegisterBabyRoute(babyId: b.id),
                                    )
                                    .then((_) => onRefresh()),
                              ),
                            const Icon(Icons.chevron_right),
                          ],
                        ),
                        onTap: () => context.router
                            .push(ObstetricsEditBabyRoute(babyId: b.id))
                            .then((_) => onRefresh()),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
