import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/lab/models/lab_models.dart';
import 'package:helty/src/lab/providers/lab_providers.dart';
import 'package:helty/src/printing/pdf/lab_order_pdf.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:printing/printing.dart';

@RoutePage()
class LabDashboardScreen extends ConsumerStatefulWidget {
  const LabDashboardScreen({super.key});

  @override
  ConsumerState<LabDashboardScreen> createState() => _LabDashboardScreenState();
}

class _LabDashboardScreenState extends ConsumerState<LabDashboardScreen> {
  LabOrderStatus? _filterStatus;
  static const _skip = 0;
  static const _take = 100;

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
  }

  LabOrdersParams _ordersParams() {
    final r = _ordersDateRange;
    return LabOrdersParams(
      from: DateTime(r.start.year, r.start.month, r.start.day),
      to: DateTime(r.end.year, r.end.month, r.end.day, 23, 59, 59, 999),
      skip: _skip,
      take: _take,
    );
  }

  Map<LabOrderStatus, int> _statusCounts(List<LabOrder> orders) {
    final counts = {for (final s in LabOrderStatus.values) s: 0};
    for (final o in orders) {
      counts[o.status] = (counts[o.status] ?? 0) + 1;
    }
    return counts;
  }

  List<LabOrder> _filteredOrders(List<LabOrder> orders) {
    if (_filterStatus == null) return orders;
    return orders.where((o) => o.status == _filterStatus).toList();
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
  }

  void _retryOrdersLoad() {
    invalidateLabOrderCaches(ref, listParams: _ordersParams());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final staff = ref.watch(currentStaffProvider);
    final isLabManager =
        staff?.staffRole.toLowerCase() == 'admin' ||
        staff?.accountType?.name.toLowerCase() == 'laboratory' ||
        staff?.accountType?.name.toLowerCase() == 'lab';
    final ordersAsync = ref.watch(labOrdersFutureProvider(_ordersParams()));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, theme, isLabManager),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: ordersAsync.when(
                loading: () => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      height: 80,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    const SizedBox(height: 20),
                    const SizedBox(height: 24),
                    _buildOrdersSection(
                      context,
                      theme,
                      ordersLoading: true,
                      orders: const [],
                    ),
                  ],
                ),
                error: (error, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrdersErrorCard(theme, error),
                    const SizedBox(height: 20),
                    const SizedBox(height: 24),
                    _buildOrdersSection(
                      context,
                      theme,
                      ordersLoading: true,
                      orders: const [],
                    ),
                  ],
                ),
                data: (response) {
                  final allOrders = response.data;
                  final filteredOrders = _filteredOrders(allOrders);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryRow(theme, allOrders),
                      const SizedBox(height: 20),
                      const SizedBox(height: 24),
                      _buildOrdersSection(
                        context,
                        theme,
                        orders: filteredOrders,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersErrorCard(ThemeData theme, Object error) {
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
                'Unable to load lab orders.\n$error',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
            TextButton(onPressed: _retryOrdersLoad, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme, List<LabOrder> orders) {
    final statusCounts = _statusCounts(orders);
    final cards = <Widget>[
      _SummaryCard(
        label: 'Orders in range',
        value: orders.length.toString(),
        accent: theme.colorScheme.primary,
        icon: Icons.receipt_long_rounded,
      ),
      _SummaryCard(
        label: 'Pending',
        value: (statusCounts[LabOrderStatus.pending] ?? 0).toString(),
        accent: theme.colorScheme.tertiary,
        icon: Icons.schedule_rounded,
      ),
      _SummaryCard(
        label: 'Completed',
        value: (statusCounts[LabOrderStatus.completed] ?? 0).toString(),
        accent: theme.colorScheme.primaryContainer,
        icon: Icons.check_circle_rounded,
      ),
      _SummaryCard(
        label: 'Verified',
        value: (statusCounts[LabOrderStatus.verified] ?? 0).toString(),
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

  Widget _buildOrdersSection(
    BuildContext context,
    ThemeData theme, {
    required List<LabOrder> orders,
    bool ordersLoading = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: ordersLoading ? null : _pickOrdersDateRange,
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
        if (ordersLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else
          _PatientOrdersList(
            orders: orders,
            onOrderTap: (order) => context.router
                .push(LabOrderDetailRoute(orderId: order.id))
                .then((_) {
              if (mounted) {
                invalidateLabOrderCaches(ref, listParams: _ordersParams());
              }
            }),
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

class _PatientOrderGroup {
  const _PatientOrderGroup({
    required this.patientKey,
    required this.patient,
    required this.orders,
  });

  final String patientKey;
  final LabOrderPatient? patient;
  final List<LabOrder> orders;

  String get displayName => patient?.displayName.trim().isNotEmpty == true
      ? patient!.displayName
      : 'Unknown patient';

  int get totalTests =>
      orders.fold(0, (sum, order) => sum + order.items.length);
}

List<_PatientOrderGroup> _groupOrdersByPatient(List<LabOrder> orders) {
  final map = <String, _PatientOrderGroup>{};
  for (final order in orders) {
    final key = order.patient?.id.isNotEmpty == true
        ? order.patient!.id
        : 'unknown-${order.id}';
    final existing = map[key];
    if (existing == null) {
      map[key] = _PatientOrderGroup(
        patientKey: key,
        patient: order.patient,
        orders: [order],
      );
    } else {
      map[key] = _PatientOrderGroup(
        patientKey: key,
        patient: existing.patient ?? order.patient,
        orders: [...existing.orders, order],
      );
    }
  }

  for (final entry in map.entries) {
    entry.value.orders.sort((a, b) {
      final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bTime.compareTo(aTime);
    });
  }

  final groups = map.values.toList()
    ..sort(
      (a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
    );
  return groups;
}

class _PatientOrdersList extends StatelessWidget {
  const _PatientOrdersList({
    required this.orders,
    required this.onOrderTap,
  });

  final List<LabOrder> orders;
  final void Function(LabOrder order) onOrderTap;

  @override
  Widget build(BuildContext context) {
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

    final groups = _groupOrdersByPatient(orders);
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return _PatientOrdersTile(
          group: groups[index],
          onOrderTap: onOrderTap,
        );
      },
    );
  }
}

class _PatientOrdersTile extends ConsumerStatefulWidget {
  const _PatientOrdersTile({required this.group, required this.onOrderTap});

  final _PatientOrderGroup group;
  final void Function(LabOrder order) onOrderTap;

  @override
  ConsumerState<_PatientOrdersTile> createState() => _PatientOrdersTileState();
}

class _PatientOrdersTileState extends ConsumerState<_PatientOrdersTile> {
  final Set<String> _selectedItemIds = {};
  bool _printing = false;

  Iterable<LabOrderItem> get _allItems sync* {
    for (final order in widget.group.orders) {
      yield* order.items;
    }
  }

  List<LabOrderItem> get _printableItems =>
      _allItems.where((item) => labOrderItemHasPrintableResults(item)).toList();

  bool get _hasPrintableSelection => _selectedItemIds.any(
    (id) => _printableItems.any((item) => item.id == id),
  );

  void _toggleItem(LabOrderItem item, bool? selected) {
    if (!labOrderItemHasPrintableResults(item)) return;
    setState(() {
      if (selected == true) {
        _selectedItemIds.add(item.id);
      } else {
        _selectedItemIds.remove(item.id);
      }
    });
  }

  void _toggleSelectAllPrintable(bool? selected) {
    setState(() {
      if (selected == true) {
        _selectedItemIds.addAll(_printableItems.map((i) => i.id));
      } else {
        _selectedItemIds.removeAll(_printableItems.map((i) => i.id));
      }
    });
  }

  Future<void> _printSelected() async {
    if (!_hasPrintableSelection || _printing) return;

    final messenger = ScaffoldMessenger.maybeOf(context);
    setState(() => _printing = true);

    try {
      final api = ref.read(labApiServiceProvider);
      final orderIds = widget.group.orders
          .where(
            (order) =>
                order.items.any((item) => _selectedItemIds.contains(item.id)),
          )
          .map((order) => order.id)
          .toSet();

      final fullOrders = <String, LabOrder>{};
      for (final orderId in orderIds) {
        fullOrders[orderId] = await api.getOrderById(orderId);
      }

      final patient = widget.group.patient;
      if (patient == null) {
        messenger?.showSnackBar(
          const SnackBar(content: Text('Patient information is missing.')),
        );
        return;
      }

      final entries = <({LabOrder order, LabOrderItem item})>[];
      for (final order in fullOrders.values) {
        for (final item in order.items) {
          if (_selectedItemIds.contains(item.id) &&
              labOrderItemHasPrintableResults(item)) {
            entries.add((order: order, item: item));
          }
        }
      }

      if (entries.isEmpty) {
        messenger?.showSnackBar(
          const SnackBar(
            content: Text('No printable results in the current selection.'),
          ),
        );
        return;
      }

      await Printing.layoutPdf(
        onLayout: (format) async {
          final bytes = await buildLabPatientItemsPdf(
            patient: patient,
            entries: entries,
            format: format,
          );
          return Uint8List.fromList(bytes);
        },
      );
    } catch (e) {
      if (!mounted) return;
      messenger?.showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final group = widget.group;
    final printableCount = _printableItems.length;
    final allPrintableSelected =
        printableCount > 0 &&
        _printableItems.every((item) => _selectedItemIds.contains(item.id));

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              _patientInitials(group.displayName),
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          title: Text(
            group.displayName,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            '${group.orders.length} order${group.orders.length == 1 ? '' : 's'} · '
            '${group.totalTests} test${group.totalTests == 1 ? '' : 's'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (printableCount > 0)
                IconButton(
                  tooltip: 'Print selected tests',
                  onPressed: _hasPrintableSelection && !_printing
                      ? _printSelected
                      : null,
                  icon: _printing
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: theme.colorScheme.primary,
                          ),
                        )
                      : const Icon(Icons.print_rounded),
                ),
              const Icon(Icons.expand_more_rounded),
            ],
          ),
          children: [
            if (printableCount > 0)
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
                child: CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: allPrintableSelected,
                  tristate: true,
                  onChanged: (value) {
                    if (value == null) {
                      _toggleSelectAllPrintable(false);
                    } else {
                      _toggleSelectAllPrintable(value);
                    }
                  },
                  title: Text(
                    'Select all printable tests',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
            ...group.orders.map((order) {
              return _OrderItemsSection(
                order: order,
                selectedItemIds: _selectedItemIds,
                onItemToggle: _toggleItem,
                onOrderTap: () => widget.onOrderTap(order),
              );
            }),
          ],
        ),
      ),
    );
  }

  static String _patientInitials(String name) {
    final parts = name.split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final list = parts.toList();
    if (list.isEmpty) return '?';
    if (list.length == 1) return list[0][0].toUpperCase();
    return '${list[0][0]}${list[1][0]}'.toUpperCase();
  }
}

class _OrderItemsSection extends StatelessWidget {
  const _OrderItemsSection({
    required this.order,
    required this.selectedItemIds,
    required this.onItemToggle,
    required this.onOrderTap,
  });

  final LabOrder order;
  final Set<String> selectedItemIds;
  final void Function(LabOrderItem item, bool? selected) onItemToggle;
  final VoidCallback onOrderTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _LabOrderUi.statusColor(theme, order.status);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.35,
            ),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: onOrderTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #${order.id.substring(0, 8)}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _LabOrderUi.statusLabel(order.status),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ),
          ...order.items.map((item) {
            final printable = labOrderItemHasPrintableResults(item);
            final testName = item.testVersion?.test?.name ?? 'Test';
            return CheckboxListTile(
              dense: true,
              contentPadding: const EdgeInsets.only(left: 8, right: 8),
              value: selectedItemIds.contains(item.id),
              onChanged: printable ? (v) => onItemToggle(item, v) : null,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                testName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: printable
                      ? null
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.6,
                        ),
                ),
              ),
              subtitle: printable
                  ? null
                  : Text(
                      'No results to print',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
            );
          }),
        ],
      ),
    );
  }
}

class _LabOrderUi {
  static Color statusColor(ThemeData theme, LabOrderStatus s) {
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

  static String statusLabel(LabOrderStatus s) {
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
