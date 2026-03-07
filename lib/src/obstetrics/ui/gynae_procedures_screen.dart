import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/obstetrics/models/obstetrics_models.dart';
import 'package:helty/src/obstetrics/services/obstetrics_service.dart';
import 'package:helty/src/providers/service_providers.dart';

@RoutePage()
class ObstetricsGynaeProceduresScreen extends ConsumerStatefulWidget {
  final String? patientId;

  const ObstetricsGynaeProceduresScreen({
    super.key,
    this.patientId,
  });

  @override
  ConsumerState<ObstetricsGynaeProceduresScreen> createState() =>
      _ObstetricsGynaeProceduresScreenState();
}

class _ObstetricsGynaeProceduresScreenState
    extends ConsumerState<ObstetricsGynaeProceduresScreen> {
  List<GynaeProcedure> _procedures = [];
  int _total = 0;
  int _skip = 0;
  static const int _take = 20;
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
      final res = await _service.listGynaeProcedures(
        patientId: widget.patientId,
        skip: _skip,
        take: _take,
      );
      if (!mounted) return;
      setState(() {
        _procedures = res.procedures;
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

  void _addProcedure() {
    context.router
        .push(ObstetricsAddGynaeProcedureRoute(patientId: widget.patientId))
        .then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gynaecology procedures'),
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
          Expanded(
            child: _loading && _procedures.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _procedures.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.medical_services_rounded,
                              size: 64,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No gynaecology procedures.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 24),
                            FilledButton.icon(
                              onPressed: _addProcedure,
                              icon: const Icon(Icons.add),
                              label: const Text('Add procedure'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _procedures.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _procedures.length) {
                              final hasMore =
                                  _skip + _procedures.length < _total;
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
                            final p = _procedures[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                title: Text(p.procedureType),
                                subtitle: Text(
                                  '${p.procedureDate}${p.notes != null && p.notes!.isNotEmpty ? ' · ${p.notes}' : ''}',
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () => context.router.push(
                                  ObstetricsEditGynaeProcedureRoute(
                                    procedureId: p.id,
                                  ),
                                ).then((_) => _load()),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProcedure,
        icon: const Icon(Icons.add),
        label: const Text('Add procedure'),
      ),
    );
  }
}
