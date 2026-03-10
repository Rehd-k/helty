import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/services/radiology_service.dart';

@RoutePage()
class RadiologyPatientHistoryScreen extends ConsumerStatefulWidget {
  final String patientId;

  const RadiologyPatientHistoryScreen({
    super.key,
    required this.patientId,
  });

  @override
  ConsumerState<RadiologyPatientHistoryScreen> createState() =>
      _RadiologyPatientHistoryScreenState();
}

class _RadiologyPatientHistoryScreenState
    extends ConsumerState<RadiologyPatientHistoryScreen> {
  RadiologyPatientHistoryResponse? _data;
  bool _loading = true;
  String? _error;

  RadiologyService get _service => ref.read(radiologyServiceProvider);

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
      final data = await _service.getPatientRadiologyHistory(widget.patientId);
      if (!mounted) return;
      setState(() {
        _data = data;
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
        title: Text(_data?.patient?.displayName ?? 'Radiology history'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.router.maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New request',
            onPressed: () => context.router
                .push(RadiologyCreateRequestRoute(patientId: widget.patientId))
                .then((_) => _load()),
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _load,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : _loading && _data == null
              ? const Center(child: CircularProgressIndicator())
              : _data?.requests.isEmpty ?? true
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.radar_rounded,
                            size: 64,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No radiology requests for this patient.',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () => context.router
                                .push(RadiologyCreateRequestRoute(patientId: widget.patientId))
                                .then((_) => _load()),
                            icon: const Icon(Icons.add),
                            label: const Text('New request'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _data!.requests.length,
                        itemBuilder: (context, index) {
                          final req = _data!.requests[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              title: Text(
                                '${req.scanType.name.replaceAll('_', ' ')}${req.bodyPart != null && req.bodyPart!.isNotEmpty ? ' · ${req.bodyPart}' : ''}',
                              ),
                              subtitle: Text(
                                '${req.status.name.replaceAll('_', ' ')} · ${req.createdAt != null ? DateFormatter.formatFromBackend(req.createdAt, DateFormatter.shortDate) : '—'}',
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => context.router.push(
                                RadiologyRequestDetailRoute(requestId: req.id),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
