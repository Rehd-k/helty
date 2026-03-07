import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/providers/service_providers.dart';

@RoutePage()
class ObstetricsPostnatalListScreen extends ConsumerStatefulWidget {
  final String? labourDeliveryId;

  const ObstetricsPostnatalListScreen({
    super.key,
    this.labourDeliveryId,
  });

  @override
  ConsumerState<ObstetricsPostnatalListScreen> createState() =>
      _ObstetricsPostnatalListScreenState();
}

class _ObstetricsPostnatalListScreenState
    extends ConsumerState<ObstetricsPostnatalListScreen> {
  List<PostnatalVisit> _visits = [];
  int _total = 0;
  bool _loading = true;
  String? _error;
  PostnatalVisitType? _filterType;

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
      final res = await _service.listPostnatalVisits(
        labourDeliveryId: widget.labourDeliveryId,
        type: _filterType,
        take: 100,
      );
      if (!mounted) return;
      setState(() {
        _visits = res.visits;
        _total = res.total;
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Postnatal visits'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.maybePop(),
        ),
        actions: [
          if (widget.labourDeliveryId != null)
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => context.router.push(
                ObstetricsAddPostnatalVisitRoute(
                  labourDeliveryId: widget.labourDeliveryId!,
                ),
              ).then((_) => _load()),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Material(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(child: Text(_error!)),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _error = null),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.labourDeliveryId == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Open a labour delivery to see and add postnatal visits, or filter by delivery ID.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Expanded(
            child: _loading && _visits.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _visits.isEmpty
                    ? Center(
                        child: Text(
                          'No postnatal visits.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _visits.length,
                        itemBuilder: (context, index) {
                          final v = _visits[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              title: Text('${v.type.name} · ${v.visitDate}'),
                              subtitle: Text(
                                [
                                  if (v.notes != null && v.notes!.isNotEmpty)
                                    v.notes,
                                  if (v.weight != null) '${v.weight} kg',
                                ].join(' · '),
                              ),
                              trailing: const Icon(Icons.chevron_right),
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
