import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/store/models/store_models.dart';
import 'package:helty/src/store/providers/store_providers.dart';

@RoutePage()
class StoreAnalyticsScreen extends ConsumerStatefulWidget {
  const StoreAnalyticsScreen({super.key});

  @override
  ConsumerState<StoreAnalyticsScreen> createState() =>
      _StoreAnalyticsScreenState();
}

class _StoreAnalyticsScreenState extends ConsumerState<StoreAnalyticsScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _categoryId;
  String? _departmentId;
  bool _loading = true;
  StoreAnalytics? _analytics;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = ref.read(storeApiServiceProvider);
      final response = await api.getAnalyticsDashboard(
        fromDate: _fromDate?.toIso8601String(),
        toDate: _toDate?.toIso8601String(),
        categoryId: _categoryId,
        departmentId: _departmentId,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _analytics = response;
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

  Future<void> _pickFromDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _fromDate = picked);
  }

  Future<void> _pickToDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _toDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(storeCategoriesFutureProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Store analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loading ? null : _loadAnalytics,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ResponsiveBody(
        builder: (context, bp) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            margin: const EdgeInsets.all(24),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filters',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _pickFromDate(context),
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text(
                          _fromDate != null
                              ? 'From: ${_fromDate!.day}/${_fromDate!.month}/${_fromDate!.year}'
                              : 'From date',
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _pickToDate(context),
                        icon: const Icon(Icons.calendar_today_rounded, size: 18),
                        label: Text(
                          _toDate != null
                              ? 'To: ${_toDate!.day}/${_toDate!.month}/${_toDate!.year}'
                              : 'To date',
                        ),
                      ),
                      categoriesAsync.when(
                        data: (res) {
                          final list = res.data;
                          return DropdownButton<String?>(
                            value: _categoryId,
                            hint: const Text('Category'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All categories'),
                              ),
                              ...list.map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  )),
                            ],
                            onChanged: (v) =>
                                setState(() => _categoryId = v),
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      FilledButton.icon(
                        onPressed: _loading ? null : _loadAnalytics,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.analytics_rounded, size: 18),
                        label: const Text('Apply'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildBody(theme),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_loading && _analytics == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadAnalytics,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final a = _analytics ?? const StoreAnalytics();
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (a.issueCount != null || a.receiveCount != null || a.transferCount != null) ...[
            Row(
              children: [
                if (a.issueCount != null)
                  Expanded(
                    child: _SummaryCard(
                      label: 'Issues',
                      value: a.issueCount.toString(),
                      icon: Icons.call_made_rounded,
                      theme: theme,
                    ),
                  ),
                if (a.issueCount != null) const SizedBox(width: 12),
                if (a.receiveCount != null)
                  Expanded(
                    child: _SummaryCard(
                      label: 'Receives',
                      value: a.receiveCount.toString(),
                      icon: Icons.call_received_rounded,
                      theme: theme,
                    ),
                  ),
                if (a.receiveCount != null) const SizedBox(width: 12),
                if (a.transferCount != null)
                  Expanded(
                    child: _SummaryCard(
                      label: 'Transfers',
                      value: a.transferCount.toString(),
                      icon: Icons.swap_horiz_rounded,
                      theme: theme,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: theme.colorScheme.error,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Low stock items',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (a.lowStockItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No low stock items',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2),
                        1: FlexColumnWidth(2),
                        2: FlexColumnWidth(1),
                        3: FlexColumnWidth(1),
                      },
                      children: [
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Item',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Location',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Qty',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Reorder',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...a.lowStockItems.map((e) => TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(e.itemName),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(e.locationName),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(e.quantity.toStringAsFixed(0)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(e.reorderLevel.toStringAsFixed(0)),
                                ),
                              ],
                            )),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Top moving items',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (a.topMovingItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No data',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Table(
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(1),
                      },
                      children: [
                        TableRow(
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Item',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Qty moved',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                'Type',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        ...a.topMovingItems.map((e) => TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(e.itemName),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(e.quantityMoved.toStringAsFixed(0)),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Text(e.movementType ?? '–'),
                                ),
                              ],
                            )),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.theme,
  });

  final String label;
  final String value;
  final IconData icon;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
