import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/providers/lab_providers.dart';
import 'package:helty/src/lab/services/lab_api_service.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/helper/date.formatter.dart';

@RoutePage()
class LabDashboardScreen extends ConsumerStatefulWidget {
  const LabDashboardScreen({super.key});

  @override
  ConsumerState<LabDashboardScreen> createState() => _LabDashboardScreenState();
}

class _LabDashboardScreenState extends ConsumerState<LabDashboardScreen> {
  LabOrderStatus? _filterStatus;
  static const _skip = 0;
  static const _take = 20;
  bool _loadingSummary = true;
  String? _summaryError;
  Map<LabOrderStatus, int> _statusCounts = {};
  int _totalOrdersInRange = 0;

  /// Summary + order list (aligned with [view_waiting_patient] defaults).
  late DateTimeRange _ordersDateRange;

  @override
  void initState() {
    super.initState();
    final n = DateTime.now();
    _ordersDateRange = DateTimeRange(
      start: DateTime(n.year, n.month, n.day),
      end: DateTime(n.year, n.month, n.day, 23, 59, 59, 999),
    );
    _loadSummary();
  }

  (DateTime, DateTime) _ordersQueryBounds() {
    final r = _ordersDateRange;
    return (
      DateTime(r.start.year, r.start.month, r.start.day),
      DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59, 999),
    );
  }

  Future<void> _pickOrdersDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: _ordersDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(
            context,
          ).copyWith(colorScheme: Theme.of(context).colorScheme),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _ordersDateRange = DateTimeRange(
        start: DateTime(
          picked.start.year,
          picked.start.month,
          picked.start.day,
        ),
        end: DateTime(
          picked.end.year,
          picked.end.month,
          picked.end.day,
          23,
          59,
          59,
          999,
        ),
      );
    });
    await _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loadingSummary = true;
      _summaryError = null;
    });
    try {
      final api = ref.read(labApiServiceProvider);
      final (from, to) = _ordersQueryBounds();
      final response = await api.getOrders(
        fromDate: from,
        toDate: to,
        skip: 0,
        take: 100,
      );
      final Map<LabOrderStatus, int> counts = {
        for (final s in LabOrderStatus.values) s: 0,
      };
      for (final o in response.data) {
        counts[o.status] = (counts[o.status] ?? 0) + 1;
      }
      if (!mounted) return;
      setState(() {
        _statusCounts = counts;
        _totalOrdersInRange = response.data.length;
        _loadingSummary = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _summaryError = e.toString();
        _loadingSummary = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final staff = ref.watch(currentStaffProvider);
    final isLabManager =
        staff?.role.toLowerCase() == 'admin' ||
        staff?.accountType?.name.toLowerCase() == 'laboratory' ||
        staff?.accountType?.name.toLowerCase() == 'lab';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, theme, isLabManager),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow(theme),
                  const SizedBox(height: 20),
                  // _buildQuickActions(context, theme, isLabManager),
                  const SizedBox(height: 24),
                  _buildOrdersSection(context, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    if (_loadingSummary) {
      return const SizedBox(
        height: 80,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_summaryError != null) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.error.withValues(alpha: 0.4),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Unable to load lab summary.\n${_summaryError!}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              TextButton(onPressed: _loadSummary, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final cards = <Widget>[
      _SummaryCard(
        label: 'Orders in range',
        value: _totalOrdersInRange.toString(),
        accent: theme.colorScheme.primary,
        icon: Icons.receipt_long_rounded,
      ),
      _SummaryCard(
        label: 'Pending',
        value: (_statusCounts[LabOrderStatus.pending] ?? 0).toString(),
        accent: theme.colorScheme.tertiary,
        icon: Icons.schedule_rounded,
      ),
      _SummaryCard(
        label: 'Completed',
        value: (_statusCounts[LabOrderStatus.completed] ?? 0).toString(),
        accent: theme.colorScheme.primaryContainer,
        icon: Icons.check_circle_rounded,
      ),
      _SummaryCard(
        label: 'Verified',
        value: (_statusCounts[LabOrderStatus.verified] ?? 0).toString(),
        accent: theme.colorScheme.secondary,
        icon: Icons.verified_rounded,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        if (isNarrow) {
          return SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cards.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) =>
                  SizedBox(width: 200, child: cards[index]),
            ),
          );
        }
        return Row(
          children: cards
              .map(
                (c) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: c,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildAppBar(
    BuildContext context,
    ThemeData theme,
    bool isLabManager,
  ) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Laboratory',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.tertiaryContainer.withValues(alpha: 0.7),
              ],
            ),
          ),
          child: SafeArea(
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 24, bottom: 16),
                child: Icon(
                  Icons.biotech_rounded,
                  size: 64,
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
      actions: [
        if (isLabManager)
          TextButton.icon(
            onPressed: () => context.router.push(const LabConfigRoute()),
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Config'),
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  // Widget _buildQuickActions(
  //   BuildContext context,
  //   ThemeData theme,
  //   bool isLabManager,
  // ) {
  //   return Card(
  //     elevation: 0,
  //     shape: RoundedRectangleBorder(
  //       borderRadius: BorderRadius.circular(20),
  //       side: BorderSide(
  //         color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
  //       ),
  //     ),
  //     child: Padding(
  //       padding: const EdgeInsets.all(20),
  //       child: Row(
  //         children: [
  //           Expanded(
  //             child: _ActionChip(
  //               icon: Icons.add_circle_outline_rounded,
  //               label: 'New order',
  //               onTap: () => {},
  //             ),
  //           ),
  //           const SizedBox(width: 16),
  //           Expanded(
  //             child: _ActionChip(
  //               icon: Icons.list_alt_rounded,
  //               label: 'All orders',
  //               onTap: () => _filterStatus = null,
  //             ),
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildOrdersSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: _loadingSummary ? null : _pickOrdersDateRange,
            icon: const Icon(Icons.date_range_outlined, size: 20),
            label: Text(
              'Date range: ${DateFormatter.shortDate(_ordersDateRange.start)} – ${DateFormatter.shortDate(_ordersDateRange.end)}',
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Orders',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            Wrap(
              spacing: 8,
              children: [
                _StatusChip(
                  label: 'All',
                  selected: _filterStatus == null,
                  onTap: () => setState(() => _filterStatus = null),
                ),
                ...LabOrderStatus.values.map(
                  (s) => _StatusChip(
                    label: _statusLabel(s),
                    selected: _filterStatus == s,
                    onTap: () => setState(() => _filterStatus = s),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        _OrdersList(
          dateRange: _ordersDateRange,
          status: _filterStatus,
          skip: _skip,
          take: _take,
          onOrderTap: (order) =>
              context.router.push(LabOrderDetailRoute(orderId: order.id)),
        ),
      ],
    );
  }

  static String _statusLabel(LabOrderStatus s) {
    switch (s) {
      case LabOrderStatus.pending:
        return 'Pending';
      case LabOrderStatus.sampleCollected:
        return 'Collected';
      case LabOrderStatus.processing:
        return 'Processing';
      case LabOrderStatus.completed:
        return 'Completed';
      case LabOrderStatus.verified:
        return 'Verified';
    }
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.icon,
  });

  final String label;
  final String value;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: accent, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    );
  }
}

class _OrdersList extends ConsumerWidget {
  const _OrdersList({
    required this.dateRange,
    required this.status,
    required this.skip,
    required this.take,
    required this.onOrderTap,
  });

  final DateTimeRange dateRange;
  final LabOrderStatus? status;
  final int skip;
  final int take;
  final void Function(LabOrder order) onOrderTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final api = ref.watch(labApiServiceProvider);
    final r = dateRange;
    final from = DateTime(r.start.year, r.start.month, r.start.day);
    final to = DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59, 999);
    return FutureBuilder<LabOrdersResponse>(
      key: ObjectKey(dateRange),
      future: api.getOrders(
        status: status,
        fromDate: from,
        toDate: to,
        skip: skip,
        take: take,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }
        final response = snapshot.data!;
        final orders = response.data;
        if (orders.isEmpty) {
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            child: const Padding(
              padding: EdgeInsets.all(48),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.inbox_rounded, size: 56),
                    SizedBox(height: 16),
                    Text('No orders yet'),
                  ],
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: orders.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final order = orders[index];
            return _OrderCard(order: order, onTap: () => onOrderTap(order));
          },
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final LabOrder order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(theme, order.status);
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
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
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      order.patient?.displayName ?? '—',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (order.items.isNotEmpty)
                      Text(
                        '${order.items.length} test(s)',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _statusLabel(order.status),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(ThemeData theme, LabOrderStatus s) {
    switch (s) {
      case LabOrderStatus.pending:
        return theme.colorScheme.tertiary;
      case LabOrderStatus.sampleCollected:
      case LabOrderStatus.processing:
        return theme.colorScheme.primary;
      case LabOrderStatus.completed:
      case LabOrderStatus.verified:
        return theme.colorScheme.primaryContainer;
    }
  }

  static String _statusLabel(LabOrderStatus s) {
    switch (s) {
      case LabOrderStatus.pending:
        return 'Pending';
      case LabOrderStatus.sampleCollected:
        return 'Collected';
      case LabOrderStatus.processing:
        return 'Processing';
      case LabOrderStatus.completed:
        return 'Completed';
      case LabOrderStatus.verified:
        return 'Verified';
    }
  }
}
