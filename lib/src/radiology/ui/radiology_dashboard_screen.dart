import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/core/errors/app_exception.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/radiology/models/radiology_models.dart';
import 'package:helty/src/radiology/services/radiology_service.dart';
import 'package:helty/src/shared/department_colors.dart';

const double _contentMaxWidth = 1200;
const double _cardRadius = 20;

enum _DatePreset { today, last7Days, last30Days, custom }

@RoutePage()
class RadiologyDashboardScreen extends ConsumerStatefulWidget {
  const RadiologyDashboardScreen({super.key});

  @override
  ConsumerState<RadiologyDashboardScreen> createState() =>
      _RadiologyDashboardScreenState();
}

class _RadiologyDashboardScreenState
    extends ConsumerState<RadiologyDashboardScreen> {
  RadiologyDashboardResponse? _dashboard;
  bool _loading = true;
  String? _error;
  _DatePreset _selectedPreset = _DatePreset.today;
  DateTimeRange? _customDateRange;

  RadiologyService get _service => ref.read(radiologyServiceProvider);

  @override
  void initState() {
    super.initState();
    _load();
  }

  (DateTime, DateTime) _resolveDateRange() {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    switch (_selectedPreset) {
      case _DatePreset.today:
        final start = DateTime(now.year, now.month, now.day);
        return (start, end);
      case _DatePreset.last7Days:
        final start = DateTime(now.year, now.month, now.day).subtract(
          const Duration(days: 6),
        );
        return (start, end);
      case _DatePreset.last30Days:
        final start = DateTime(now.year, now.month, now.day).subtract(
          const Duration(days: 29),
        );
        return (start, end);
      case _DatePreset.custom:
        final range = _customDateRange;
        if (range != null) {
          return (
            DateTime(
              range.start.year,
              range.start.month,
              range.start.day,
            ),
            DateTime(
              range.end.year,
              range.end.month,
              range.end.day,
              23,
              59,
              59,
            ),
          );
        }
        final start = DateTime(now.year, now.month, now.day);
        return (start, end);
    }
  }

  RadiologyDashboardQuery _dashboardQuery() {
    final (from, to) = _resolveDateRange();
    return RadiologyDashboardQuery(fromDate: from, toDate: to);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.getDashboard(query: _dashboardQuery());
      if (!mounted) return;
      setState(() {
        _dashboard = data;
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

  Future<void> _pickCustomDateRange() async {
    final now = DateTime.now();
    final initial = _customDateRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: DateTime(now.year, now.month, now.day, 23, 59, 59, 999),
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: initial,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedPreset = _DatePreset.custom;
      _customDateRange = DateTimeRange(
        start: DateTime(picked.start.year, picked.start.month, picked.start.day),
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
    _load();
  }

  String _presetLabel(_DatePreset preset) {
    switch (preset) {
      case _DatePreset.today:
        return 'Today';
      case _DatePreset.last7Days:
        return 'Last 7 Days';
      case _DatePreset.last30Days:
        return 'Last 30 Days';
      case _DatePreset.custom:
        if (_customDateRange != null) {
          final r = _customDateRange!;
          return '${DateFormatter.shortDate(r.start)} – ${DateFormatter.shortDate(r.end)}';
        }
        return 'Custom';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: true,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh',
                onPressed: _loading ? null : _load,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Radiology',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      DepartmentColors.radiology.withValues(alpha: 0.22),
                      colorScheme.primaryContainer,
                      colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24, bottom: 16),
                      child: Icon(
                        Icons.radar_rounded,
                        size: 64,
                        color: colorScheme.primary.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_error != null)
            SliverToBoxAdapter(
              child: Material(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Imaging & reports',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildFilterBar(theme, colorScheme),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: _contentMaxWidth),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: _loading && _dashboard == null
                      ? const Padding(
                          padding: EdgeInsets.all(48),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (_dashboard != null) _buildStatsGrid(context),
                            const SizedBox(height: 24),
                            _buildQuickActions(context),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Wrap(
        runSpacing: 10,
        spacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          ..._DatePreset.values.where((p) => p != _DatePreset.custom).map(
            (preset) => ChoiceChip(
              label: Text(_presetLabel(preset)),
              selected: _selectedPreset == preset,
              onSelected: _loading
                  ? null
                  : (_) {
                      setState(() => _selectedPreset = preset);
                      _load();
                    },
            ),
          ),
          ChoiceChip(
            label: Text(_presetLabel(_DatePreset.custom)),
            selected: _selectedPreset == _DatePreset.custom,
            onSelected: _loading ? null : (_) => _pickCustomDateRange(),
          ),
          if (_loading)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final d = _dashboard!;
    final scansLabel =
        _selectedPreset == _DatePreset.today ? 'Scans today' : 'Total scans';

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossCount = constraints.maxWidth > 600 ? 3 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.4,
          children: [
            _StatCard(
              icon: Icons.today_rounded,
              value: '${d.totalScansToday}',
              label: scansLabel,
              color: colorScheme.primary,
            ),
            _StatCard(
              icon: Icons.pending_actions_rounded,
              value: '${d.pending}',
              label: 'Pending',
              color: colorScheme.tertiary,
            ),
            _StatCard(
              icon: Icons.check_circle_outline_rounded,
              value: '${d.completed}',
              label: 'Completed',
              color: colorScheme.secondary,
            ),
            _StatCard(
              icon: Icons.description_outlined,
              value: '${d.waitingReports}',
              label: 'Waiting reports',
              color: colorScheme.primaryContainer,
            ),
            _StatCard(
              icon: Icons.warning_amber_rounded,
              value: '${d.urgentCases}',
              label: 'Urgent cases',
              color: colorScheme.error,
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
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
            Row(
              children: [
                Expanded(
                  child: _ActionChip(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'New request',
                    onTap: () =>
                        context.router.push(RadiologyCreateRequestRoute()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActionChip(
                    icon: Icons.list_alt_rounded,
                    label: 'Worklist',
                    onTap: () => context.router.push(RadiologyWorklistRoute()),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _ActionChip(
                    icon: Icons.person_search_rounded,
                    label: 'By patient',
                    onTap: () => context.router.push(
                      EnlistPaitientRoute(serviceName: 'Radiology'),
                    ),
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardRadius),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
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
