import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/services/radiology_service.dart';
import 'package:helty/src/radiology/ui/radiology_ui_helpers.dart';

@RoutePage()
class RadiologyWorklistScreen extends ConsumerStatefulWidget {
  const RadiologyWorklistScreen({super.key});

  @override
  ConsumerState<RadiologyWorklistScreen> createState() =>
      _RadiologyWorklistScreenState();
}

class _RadiologyWorklistScreenState
    extends ConsumerState<RadiologyWorklistScreen> {
  List<RadiologyOrder> _orders = [];
  int _total = 0;
  bool _loading = true;
  String? _error;
  RadiologyOrderStatus? _filterStatus;
  DateTime? _fromDate;
  DateTime? _toDate;
  static const int _take = 20;
  int _skip = 0;

  RadiologyService get _service => ref.read(radiologyServiceProvider);

  @override
  void initState() {
    super.initState();
    final today = DateUtils.dateOnly(DateTime.now());
    _fromDate = today;
    _toDate = today;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.listOrders(
        status: _filterStatus,
        fromDate: _fromDate == null ? null : _asIsoDate(_fromDate!),
        toDate: _toDate == null ? null : _asIsoDate(_toDate!),
        skip: _skip,
        take: _take,
      );
      if (!mounted) return;
      setState(() {
        _orders = res.orders;
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

  void _setFilter(RadiologyOrderStatus? status) {
    setState(() {
      _filterStatus = status;
      _skip = 0;
    });
    _load();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final now = DateTime.now();
    final initial = isFrom ? (_fromDate ?? now) : (_toDate ?? _fromDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 2),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _fromDate = DateUtils.dateOnly(picked);
        if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
          _toDate = _fromDate;
        }
      } else {
        _toDate = DateUtils.dateOnly(picked);
      }
      _skip = 0;
    });
  }

  void _applyDateFilter() {
    if (_fromDate != null && _toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select both from and to dates.')),
      );
      return;
    }
    if (_toDate != null && _fromDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select both from and to dates.')),
      );
      return;
    }
    _load();
  }

  void _clearFilters() {
    setState(() {
      _filterStatus = null;
      _fromDate = null;
      _toDate = null;
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
                    Icon(
                      Icons.error_outline,
                      color: colorScheme.onErrorContainer,
                    ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatusChip(
                      label: 'All',
                      selected: _filterStatus == null,
                      onTap: () => _setFilter(null),
                    ),
                    ...RadiologyOrderStatus.values.map(
                      (s) => _StatusChip(
                        label: orderStatusLabel(s),
                        selected: _filterStatus == s,
                        onTap: () => _setFilter(s),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(isFrom: true),
                      icon: const Icon(Icons.calendar_month_outlined),
                      label: Text(
                        _fromDate == null
                            ? 'From date'
                            : DateFormatter.shortDate(_fromDate!),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _pickDate(isFrom: false),
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        _toDate == null
                            ? 'To date'
                            : DateFormatter.shortDate(_toDate!),
                      ),
                    ),
                    FilledButton.tonal(
                      onPressed: _loading ? null : _applyDateFilter,
                      child: const Text('Apply dates'),
                    ),
                    TextButton(
                      onPressed: _loading ? null : _clearFilters,
                      child: const Text('Clear filters'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Text(
                  '$_total request(s)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (_loading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading && _orders.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
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
                      itemCount: _orders.length + 1,
                      itemBuilder: (context, index) {
                        if (index == _orders.length) {
                          final hasMore = _skip + _orders.length < _total;
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
                        final order = _orders[index];
                        return _OrderCard(
                          order: order,
                          onTap: () => context.router.push(
                            RadiologyRequestDetailRoute(requestId: order.id),
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

  String _asIsoDate(DateTime value) => value.toIso8601String().split('T').first;
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final RadiologyOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final statusColor = orderStatusColor(theme, order.status);
    final firstItem = order.items.isNotEmpty ? order.items.first : null;
    final requestedByName = (order.requestedBy?.displayName ?? '').trim();
    final requestedByLabel = requestedByName.isNotEmpty
        ? requestedByName
        : (order.requestedById.isNotEmpty ? order.requestedById : '-');

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
                      firstItem == null
                          ? 'Order with no items'
                          : '${firstItem.scanType.displayLabel}${firstItem.bodyPart != null && firstItem.bodyPart!.isNotEmpty ? ' · ${firstItem.bodyPart}' : ''}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.patient?.displayName ?? '—',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      'Requested by: $requestedByLabel',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${order.items.length} item(s)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.outline,
                      ),
                    ),
                    if (firstItem != null)
                      Text(
                        'Priority: ${firstItem.priority.name}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: priorityColor(firstItem.priority),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    if (order.createdAt != null)
                      Text(
                        DateFormatter.formatFromBackend(
                          order.createdAt,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  orderStatusLabel(order.status),
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
}
