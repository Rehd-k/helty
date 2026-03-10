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
class RadiologyWorklistScreen extends ConsumerStatefulWidget {
  const RadiologyWorklistScreen({super.key});

  @override
  ConsumerState<RadiologyWorklistScreen> createState() =>
      _RadiologyWorklistScreenState();
}

class _RadiologyWorklistScreenState extends ConsumerState<RadiologyWorklistScreen> {
  List<RadiologyRequest> _requests = [];
  int _total = 0;
  bool _loading = true;
  String? _error;
  RadiologyRequestStatus? _filterStatus;
  static const int _take = 20;
  int _skip = 0;

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
      final res = await _service.getWorklist(
        status: _filterStatus,
        skip: _skip,
        take: _take,
      );
      if (!mounted) return;
      setState(() {
        _requests = res.requests;
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

  void _setFilter(RadiologyRequestStatus? status) {
    setState(() {
      _filterStatus = status;
      _skip = 0;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Radiology worklist'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
                    TextButton(
                      onPressed: () {
                        setState(() => _error = null);
                        _load();
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: [
                _StatusChip(
                  label: 'All',
                  selected: _filterStatus == null,
                  onTap: () => _setFilter(null),
                ),
                ...RadiologyRequestStatus.values.map((s) => _StatusChip(
                      label: _statusLabel(s),
                      selected: _filterStatus == s,
                      onTap: () => _setFilter(s),
                    )),
              ],
            ),
          ),
          Expanded(
            child: _loading && _requests.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 64,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No requests match the filter.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          _skip = 0;
                          await _load();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _requests.length + 1,
                          itemBuilder: (context, index) {
                            if (index == _requests.length) {
                              final hasMore =
                                  _skip + _requests.length < _total;
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
                            final req = _requests[index];
                            return _RequestCard(
                              request: req,
                              onTap: () => context.router.push(
                                RadiologyRequestDetailRoute(requestId: req.id),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  static String _statusLabel(RadiologyRequestStatus s) {
    switch (s) {
      case RadiologyRequestStatus.PENDING:
        return 'Pending';
      case RadiologyRequestStatus.SCHEDULED:
        return 'Scheduled';
      case RadiologyRequestStatus.IN_PROGRESS:
        return 'In progress';
      case RadiologyRequestStatus.COMPLETED:
        return 'Completed';
      case RadiologyRequestStatus.REPORTED:
        return 'Reported';
      case RadiologyRequestStatus.CANCELLED:
        return 'Cancelled';
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
      side: BorderSide(
        color: selected
            ? theme.colorScheme.primary
            : theme.colorScheme.outlineVariant,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({
    required this.request,
    required this.onTap,
  });

  final RadiologyRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = _statusColor(theme, request.status);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 56,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${request.scanType.name}${request.bodyPart != null && request.bodyPart!.isNotEmpty ? ' · ${request.bodyPart}' : ''}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.patient?.displayName ?? '—',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (request.createdAt != null)
                      Text(
                        DateFormatter.formatFromBackend(
                          request.createdAt,
                          DateFormatter.shortDate,
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  request.status.name.replaceAll('_', ' '),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(ThemeData theme, RadiologyRequestStatus s) {
    switch (s) {
      case RadiologyRequestStatus.PENDING:
        return theme.colorScheme.tertiary;
      case RadiologyRequestStatus.SCHEDULED:
      case RadiologyRequestStatus.IN_PROGRESS:
        return theme.colorScheme.primary;
      case RadiologyRequestStatus.COMPLETED:
      case RadiologyRequestStatus.REPORTED:
        return theme.colorScheme.primaryContainer;
      case RadiologyRequestStatus.CANCELLED:
        return theme.colorScheme.error;
    }
  }
}
