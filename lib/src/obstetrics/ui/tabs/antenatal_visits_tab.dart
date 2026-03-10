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
class ObstetricsAntenatalVisitsTab extends ConsumerStatefulWidget {
  final String? pregnancyId;

  const ObstetricsAntenatalVisitsTab({super.key, this.pregnancyId});

  @override
  ConsumerState<ObstetricsAntenatalVisitsTab> createState() =>
      _ObstetricsAntenatalVisitsTabState();
}

class _ObstetricsAntenatalVisitsTabState
    extends ConsumerState<ObstetricsAntenatalVisitsTab> {
  List<AntenatalVisit> _visits = [];
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
        _visits.isEmpty &&
        _loading &&
        _error == null) {
      _load(id);
    }
  }

  Future<void> _load(String id) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.listAntenatalVisits(id);
      final visits = res.visits.isNotEmpty
          ? res.visits
          : (await _service.getPregnancy(id)).antenatalVisits ?? const <AntenatalVisit>[];
      if (!mounted) return;
      setState(() {
        _visits = visits;
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
    final id = _pregnancyId;
    if (id == null) return;
    context.router
        .push(ObstetricsAddAntenatalVisitRoute(pregnancyId: id))
        .then((_) => _load(id));
  }

  @override
  Widget build(BuildContext context) {
    final pregnancyId = _pregnancyId;
    if (pregnancyId == null || pregnancyId.isEmpty) {
      return const Center(child: Text('Missing pregnancy context'));
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_error != null && _visits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  final id = _pregnancyId;
                  if (id != null) _load(id);
                },
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
                '${_visits.length} visit${_visits.length == 1 ? '' : 's'}',
                style: theme.textTheme.titleSmall,
              ),
              FilledButton.icon(
                onPressed: _addVisit,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add visit'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading && _visits.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _visits.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_note,
                        size: 48,
                        color: colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No antenatal visits yet.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _addVisit,
                        icon: const Icon(Icons.add),
                        label: const Text('Add first visit'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _visits.length,
                  itemBuilder: (context, index) {
                    final v = _visits[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          DateFormatter.formatFromBackend(
                            v.visitDate,
                            DateFormatter.shortDate,
                          ),
                        ),
                        subtitle: Text(
                          [
                            if (v.gestationWeeks != null)
                              '${v.gestationWeeks} wks',
                            if (v.systolicBP != null && v.diastolicBP != null)
                              'BP ${v.systolicBP}/${v.diastolicBP}',
                            if (v.weight != null) '${v.weight} kg',
                            if (v.presentation != null) v.presentation!.name,
                          ].join(' · '),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.router.push(
                          ObstetricsEditAntenatalVisitRoute(visitId: v.id),
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
