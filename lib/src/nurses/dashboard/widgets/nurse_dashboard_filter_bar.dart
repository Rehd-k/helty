import 'package:flutter/material.dart';

import '../../../helper/theme.dart';
import '../../../widgets/helty_surface.dart';
import '../nurse_dashboard_metrics.dart';

/// One-row time range (and optional search). Extra copy lives in the filter menu.
class NurseDashboardFilterBar extends StatelessWidget {
  const NurseDashboardFilterBar({
    super.key,
    required this.timeRange,
    required this.onTimeRangeChanged,
    required this.compact,
    this.searchController,
    this.showSearch = false,
    this.windowLabel,
    this.onOpenFilterMenu,
  });

  final String timeRange;
  final ValueChanged<String> onTimeRangeChanged;
  final bool compact;
  final TextEditingController? searchController;
  final bool showSearch;
  final String? windowLabel;
  final VoidCallback? onOpenFilterMenu;

  InputDecoration _decoration(
    BuildContext context, {
    required String label,
    required Color iconColor,
    IconData? icon,
    String? hint,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      prefixIcon: icon == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(6),
              child: HeltySolidIcon(
                icon: icon,
                color: iconColor,
                size: 22,
                iconSize: 13,
                radius: 6,
              ),
            ),
      prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      labelStyle: const TextStyle(fontSize: 11),
    );
  }

  Widget _searchField(BuildContext context) {
    return TextField(
      controller: searchController,
      decoration: _decoration(
        context,
        label: 'Search',
        hint: 'Patient, unit, or ward…',
        icon: Icons.search,
        iconColor: NurseDashboardMetrics.iconIndigo,
      ),
      style: const TextStyle(fontSize: 12),
    );
  }

  Widget _timeRangeDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('range-$timeRange'),
      initialValue: timeRange,
      isExpanded: true,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _decoration(
        context,
        label: 'Period',
        icon: Icons.calendar_today_outlined,
        iconColor: NurseDashboardMetrics.iconBlue,
      ),
      items: [
        for (final range in NurseDashboardMetrics.timeRanges)
          DropdownMenuItem(value: range, child: Text(range)),
      ],
      onChanged: (v) {
        if (v != null) onTimeRangeChanged(v);
      },
    );
  }

  Widget filterMenuBody(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact) ...[
          _timeRangeDropdown(context),
          const SizedBox(height: 12),
        ],
        if (compact && showSearch) ...[
          _searchField(context),
          const SizedBox(height: 12),
        ],
        Text(
          'Reporting window',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          windowLabel?.trim().isNotEmpty == true
              ? windowLabel!
              : 'Metrics follow the selected period.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _filterIconButton({VoidCallback? onPressed}) {
    return IconButton(
      tooltip: 'Filters',
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: const HeltySolidIcon(
        icon: Icons.tune,
        color: NurseDashboardMetrics.iconPurple,
        size: 32,
        iconSize: 16,
        radius: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterButton = _filterIconButton(
      onPressed:
          onOpenFilterMenu ?? () => showNurseDashboardFilterMenu(context, this),
    );

    if (compact) {
      return Row(
        children: [
          Expanded(
            child: showSearch
                ? _searchField(context)
                : _timeRangeDropdown(context),
          ),
          const SizedBox(width: 8),
          filterButton,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showSearch) ...[
          Expanded(flex: 3, child: _searchField(context)),
          const SizedBox(width: 8),
        ],
        Expanded(flex: 2, child: _timeRangeDropdown(context)),
        const SizedBox(width: 8),
        filterButton,
      ],
    );
  }
}

Future<void> showNurseDashboardFilterMenu(
  BuildContext context,
  NurseDashboardFilterBar filterBar,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      final width = MediaQuery.sizeOf(ctx).width;
      return Dialog(
        alignment: Alignment.topRight,
        insetPadding: const EdgeInsets.fromLTRB(16, 88, 16, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: width < 392 ? width - 32 : 360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const HeltySolidIcon(
                      icon: Icons.tune,
                      color: NurseDashboardMetrics.iconPurple,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filters',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(ctx).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: filterBar.filterMenuBody(ctx),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
