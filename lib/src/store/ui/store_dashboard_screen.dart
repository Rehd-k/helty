import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/store/models/store_models.dart';
import 'package:helty/src/store/providers/store_providers.dart';

@RoutePage()
class StoreDashboardScreen extends ConsumerStatefulWidget {
  const StoreDashboardScreen({super.key});

  @override
  ConsumerState<StoreDashboardScreen> createState() =>
      _StoreDashboardScreenState();
}

class _StoreDashboardScreenState extends ConsumerState<StoreDashboardScreen> {
  bool _loadingSummary = true;
  String? _summaryError;
  int _categoriesCount = 0;
  int _itemsCount = 0;
  int _locationsCount = 0;
  int _lowStockCount = 0;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    setState(() {
      _loadingSummary = true;
      _summaryError = null;
    });
    try {
      final api = ref.read(storeApiServiceProvider);
      final categories = await api.getCategories();
      final items = await api.getItems(limit: 1, skip: 0);
      final locations = await api.getLocations();
      StoreAnalytics? analytics;
      try {
        analytics = await api.getAnalyticsDashboard(limit: 100);
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _categoriesCount = categories.data.length;
        _itemsCount = items.total;
        _locationsCount = locations.data.length;
        _lowStockCount = analytics?.lowStockItems.length ?? 0;
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, theme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryRow(theme),
                  const SizedBox(height: 24),
                  _buildQuickActions(context, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: true,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Store',
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
                  Icons.inventory_2_rounded,
                  size: 64,
                  color: theme.colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(ThemeData theme) {
    if (_loadingSummary) {
      return const SizedBox(
        height: 100,
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
                  'Unable to load store summary.\n$_summaryError',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              TextButton(
                onPressed: _loadSummary,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final cards = <Widget>[
      _SummaryCard(
        label: 'Categories',
        value: _categoriesCount.toString(),
        accent: theme.colorScheme.primary,
        icon: Icons.category_rounded,
      ),
      _SummaryCard(
        label: 'Items',
        value: _itemsCount.toString(),
        accent: theme.colorScheme.tertiary,
        icon: Icons.inventory_rounded,
      ),
      _SummaryCard(
        label: 'Locations',
        value: _locationsCount.toString(),
        accent: theme.colorScheme.primaryContainer,
        icon: Icons.place_rounded,
      ),
      _SummaryCard(
        label: 'Low stock',
        value: _lowStockCount.toString(),
        accent: _lowStockCount > 0
            ? theme.colorScheme.error
            : theme.colorScheme.secondary,
        icon: Icons.warning_amber_rounded,
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
              itemBuilder: (context, index) => SizedBox(
                width: 200,
                child: cards[index],
              ),
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

  Widget _buildQuickActions(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick actions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionChip(
                  icon: Icons.category_rounded,
                  label: 'Categories',
                  onTap: () => context.router.push(const StoreCategoriesRoute()),
                ),
                _ActionChip(
                  icon: Icons.inventory_rounded,
                  label: 'Items',
                  onTap: () => context.router.push(const StoreItemsRoute()),
                ),
                _ActionChip(
                  icon: Icons.place_rounded,
                  label: 'Locations',
                  onTap: () => context.router.push(const StoreLocationsRoute()),
                ),
                _ActionChip(
                  icon: Icons.warehouse_rounded,
                  label: 'Stock',
                  onTap: () => context.router.push(const StoreStockRoute()),
                ),
                _ActionChip(
                  icon: Icons.call_made_rounded,
                  label: 'Issue items',
                  onTap: () => context.router.push(const StoreMovementsRoute()),
                ),
                _ActionChip(
                  icon: Icons.call_received_rounded,
                  label: 'Receive items',
                  onTap: () => context.router.push(const StoreMovementsRoute()),
                ),
                _ActionChip(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Transfer',
                  onTap: () => context.router.push(const StoreMovementsRoute()),
                ),
                _ActionChip(
                  icon: Icons.analytics_rounded,
                  label: 'Analytics',
                  onTap: () => context.router.push(const StoreAnalyticsRoute()),
                ),
                _ActionChip(
                  icon: Icons.medical_services_outlined,
                  label: 'Consumables',
                  onTap: () =>
                      context.router.push(const StoreConsumablesCatalogRoute()),
                ),
                _ActionChip(
                  icon: Icons.insights_outlined,
                  label: 'Consumable analytics',
                  onTap: () => context.router.push(
                    const StoreConsumableAnalyticsRoute(),
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
              child: Icon(icon, color: accent, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.headlineSmall?.copyWith(
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
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
