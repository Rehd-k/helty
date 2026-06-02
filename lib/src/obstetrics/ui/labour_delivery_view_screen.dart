import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_cards.dart';
import 'package:helty/src/obstetrics/ui/widgets/obstetrics_theme.dart';

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
                    final recordedAt = DateFormatter.formatFromBackend(
                      e.recordedAt,
                      DateFormatter.dateTime,
                    );

                    final dilation = e.cervicalDilationCm != null
                        ? '${e.cervicalDilationCm} cm'
                        : null;
                    final fhr = e.fetalHeartRate != null
                        ? '${e.fetalHeartRate}'
                        : null;
                    final comments = e.comments != null && e.comments!.isNotEmpty
                        ? e.comments
                        : null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: ObstetricsTheme.borderRadius,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recordedAt,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (dilation != null)
                                  ObStatChip(
                                    label: 'Dilation $dilation',
                                    icon: Icons.height_rounded,
                                    backgroundColor: colorScheme.primaryContainer,
                                    color: colorScheme.onPrimaryContainer,
                                  ),
                                if (fhr != null)
                                  ObStatChip(
                                    label: 'FHR $fhr',
                                    icon: Icons.monitor_heart_rounded,
                                    backgroundColor:
                                        colorScheme.tertiaryContainer,
                                    color: colorScheme.onTertiaryContainer,
                                  ),
                              ],
                            ),
                            if (comments != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                comments,
                                style:
                                    theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
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
                    final sexLabel = b.sex.name;
                    final weightLabel =
                        b.birthWeightG != null ? '${b.birthWeightG}g' : null;
                    final apgar1 = b.apgar1;
                    final apgar5 = b.apgar5;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: ObstetricsTheme.borderRadius,
                      ),
                      child: InkWell(
                        borderRadius: ObstetricsTheme.borderRadius,
                        onTap: () => context.router
                            .push(ObstetricsEditBabyRoute(babyId: b.id))
                            .then((_) => onRefresh()),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Baby ${b.birthOrder}',
                                          style: theme.textTheme.titleSmall
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        ObStatChip(
                                          label: sexLabel,
                                          icon: Icons.child_care_rounded,
                                          backgroundColor:
                                              colorScheme.primaryContainer,
                                          color: colorScheme.onPrimaryContainer,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: [
                                        if (weightLabel != null)
                                          ObStatChip(
                                            label: 'Weight $weightLabel',
                                            icon:
                                                Icons.monitor_weight_rounded,
                                            backgroundColor:
                                                colorScheme.tertiaryContainer,
                                            color: colorScheme.onTertiaryContainer,
                                          ),
                                        if (apgar1 != null)
                                          ObStatChip(
                                            label: 'Apgar1 $apgar1',
                                            icon: Icons.favorite_rounded,
                                            backgroundColor:
                                                colorScheme.secondaryContainer,
                                            color:
                                                colorScheme.onSecondaryContainer,
                                          ),
                                        if (apgar5 != null)
                                          ObStatChip(
                                            label: 'Apgar5 $apgar5',
                                            icon: Icons.favorite_rounded,
                                            backgroundColor:
                                                colorScheme.secondaryContainer,
                                            color:
                                                colorScheme.onSecondaryContainer,
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      b.registeredPatientId != null
                                          ? 'Registered as patient'
                                          : 'Not registered',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  if (b.registeredPatientId == null)
                                    IconButton(
                                      icon: const Icon(Icons.person_add),
                                      tooltip: 'Register as patient',
                                      onPressed: () => context.router
                                          .push(
                                            ObstetricsRegisterBabyRoute(
                                              babyId: b.id,
                                            ),
                                          )
                                          .then((_) => onRefresh()),
                                    ),
                                  const Icon(Icons.chevron_right),
                                ],
                              ),
                            ],
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
