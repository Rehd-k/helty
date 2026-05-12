import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:helty/src/providers/service_providers.dart';

@RoutePage()
class ObstetricsPregnanciesListScreen extends ConsumerStatefulWidget {
  /// When null, patient comes from [patientProvider].selectedPatient.
  final String? patientId;

  /// Optional OPD encounter to link antenatal visits created from this flow.
  final String? encounterId;

  const ObstetricsPregnanciesListScreen({
    super.key,
    this.patientId,
    this.encounterId,
  });

  @override
  ConsumerState<ObstetricsPregnanciesListScreen> createState() =>
      _ObstetricsPregnanciesListScreenState();
}

class _ObstetricsPregnanciesListScreenState
    extends ConsumerState<ObstetricsPregnanciesListScreen> {
  List<Pregnancy> _pregnancies = [];
  int _total = 0;
  int _skip = 0;
  static const int _take = 20;
  bool _loading = false;
  String? _error;

  ObstetricsService get _service => ref.read(obstetricsServiceProvider);

  /// Patient from state; for API we use id (not patientId) per backend.
  String? get _effectivePatientId {
    final selected = ref.watch(patientProvider).selectedPatient;
    return selected?.id ?? (widget.patientId?.trim().isEmpty == false ? widget.patientId : null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // ref.watch is only valid after initState; trigger initial load here.
    final patientId = _effectivePatientId;
    if (patientId != null &&
        patientId.isNotEmpty &&
        _pregnancies.isEmpty &&
        _skip == 0 &&
        !_loading) {
      _load();
    }
  }

  Future<void> _load() async {
    final patientId = _effectivePatientId;
    if (patientId == null || patientId.isEmpty) {
      if (mounted) setState(() { _pregnancies = []; _total = 0; _loading = false; });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.listPregnancies(
        patientId: patientId,
        skip: _skip,
        take: _take,
      );
      if (!mounted) return;
      setState(() {
        _pregnancies = res.pregnancies;
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

  void _openPregnancy(Pregnancy p) {
    context.router.push(
      ObstetricsPregnancyViewRoute(
        pregnancyId: p.id,
        encounterId: widget.encounterId,
      ),
    );
  }

  void _addPregnancy() {
    context.router.push(ObstetricsAddPregnancyRoute()).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final patientId = _effectivePatientId;

    if (patientId == null || patientId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pregnancies'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.router.maybePop(),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Select a patient to view pregnancies.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pregnancies'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.encounterId != null && widget.encounterId!.isNotEmpty)
            Material(
              color: colorScheme.primaryContainer.withValues(alpha: 0.45),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.link, color: colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Opened from an OPD visit. New antenatal visits will link to encounter ${widget.encounterId}.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (_error != null)
            Material(
              color: colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => setState(() => _error = null),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _loading && _pregnancies.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _pregnancies.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.pregnant_woman_rounded,
                              size: 64,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No pregnancies recorded for this patient.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _addPregnancy,
                              icon: const Icon(Icons.add),
                              label: const Text('Add pregnancy'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _pregnancies.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _pregnancies.length) {
                              final hasMore = _skip + _pregnancies.length < _total;
                              if (!hasMore) return const SizedBox(height: 16);
                              return Padding(
                                padding: const EdgeInsets.all(8),
                                child: TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () {
                                          setState(() => _skip += _take);
                                          _load();
                                        },
                                  child: const Text('Load more'),
                                ),
                              );
                            }
                            final p = _pregnancies[index];
                            final status = p.status?.name ?? '—';
                            final patientName = p.patient?.displayName ?? '';
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(
                                  'G${p.gravida}P${p.para} · ${DateFormatter.formatFromBackend(p.lmp, DateFormatter.shortDate)} – ${DateFormatter.formatFromBackend(p.edd, DateFormatter.shortDate)}',
                                ),
                                subtitle: Text(
                                  'Status: $status${patientName.isNotEmpty ? ' · $patientName' : ''}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => _openPregnancy(p),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addPregnancy,
        icon: const Icon(Icons.add),
        label: const Text('Add pregnancy'),
      ),
    );
  }
}
