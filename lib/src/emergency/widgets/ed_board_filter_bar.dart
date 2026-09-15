import 'package:flutter/material.dart';

import '../../helper/theme.dart';
import '../../widgets/date.filter.dart';
import '../ed_board_metrics.dart';
import '../models/ed_enums.dart';

/// One-row search + status + ESI. Dates (and extras on compact) live in the filter menu.
class EdBoardFilterBar extends StatelessWidget {
  const EdBoardFilterBar({
    super.key,
    required this.searchController,
    required this.statusValue,
    required this.onStatusChanged,
    required this.esiValue,
    required this.onEsiChanged,
    required this.onDateFilterChanged,
    required this.onDateRefresh,
    required this.compact,
    this.fromDate,
    this.toDate,
  });

  final TextEditingController searchController;
  final String statusValue;
  final ValueChanged<String> onStatusChanged;
  final String esiValue;
  final ValueChanged<String> onEsiChanged;
  final void Function(
    String query,
    String category,
    DateTime? from,
    DateTime? to,
  )
  onDateFilterChanged;
  final VoidCallback onDateRefresh;
  final bool compact;
  final DateTime? fromDate;
  final DateTime? toDate;

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
              child: EdBoardSolidIcon(
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
        hint: 'Name, ID, or complaint…',
        icon: Icons.search,
        iconColor: EdBoardMetrics.iconIndigo,
      ),
      style: const TextStyle(fontSize: 12),
    );
  }

  Widget _statusDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('ed-status-$statusValue'),
      initialValue: statusValue,
      isExpanded: true,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _decoration(
        context,
        label: 'Status',
        icon: Icons.flag_outlined,
        iconColor: EdBoardMetrics.waitAmber,
      ),
      items: [
        const DropdownMenuItem(value: 'all', child: Text('All statuses')),
        ...EdWorkflowStatus.values.map(
          (s) => DropdownMenuItem(value: s.apiValue, child: Text(s.label)),
        ),
      ],
      onChanged: (v) {
        if (v != null) onStatusChanged(v);
      },
    );
  }

  Widget _esiDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('ed-esi-$esiValue'),
      initialValue: esiValue,
      isExpanded: true,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _decoration(
        context,
        label: 'ESI',
        icon: Icons.priority_high_outlined,
        iconColor: EdBoardMetrics.waitRed,
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All ESI')),
        DropdownMenuItem(value: '1', child: Text('ESI 1')),
        DropdownMenuItem(value: '2', child: Text('ESI 2')),
        DropdownMenuItem(value: '3', child: Text('ESI 3')),
        DropdownMenuItem(value: '4', child: Text('ESI 4')),
        DropdownMenuItem(value: '5', child: Text('ESI 5')),
      ],
      onChanged: (v) {
        if (v != null) onEsiChanged(v);
      },
    );
  }

  Widget _dateFilter() {
    return FromToDateFilter(
      doRefresh: onDateRefresh,
      dateFilter: true,
      notifyOnInit: false,
      initialFrom: fromDate,
      initialTo: toDate,
      onFilterChanged: onDateFilterChanged,
    );
  }

  Widget filterMenuBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact) ...[
          _statusDropdown(context),
          const SizedBox(height: 10),
          _esiDropdown(context),
          const SizedBox(height: 12),
        ],
        Text(
          'Date range',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _dateFilter(),
      ],
    );
  }

  Widget _filterIconButton({VoidCallback? onPressed}) {
    return IconButton(
      tooltip: 'Filters',
      onPressed: onPressed,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: const EdBoardSolidIcon(
        icon: Icons.tune,
        color: EdBoardMetrics.iconPurple,
        size: 32,
        iconSize: 16,
        radius: 8,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterButton = _filterIconButton(
      onPressed: () => showEdBoardFilterMenu(context, this),
    );

    if (compact) {
      return Row(
        children: [
          Expanded(child: _searchField(context)),
          const SizedBox(width: 8),
          filterButton,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(flex: 3, child: _searchField(context)),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: _statusDropdown(context)),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: _esiDropdown(context)),
        const SizedBox(width: 8),
        filterButton,
      ],
    );
  }
}

Future<void> showEdBoardFilterMenu(
  BuildContext context,
  EdBoardFilterBar filterBar,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return Dialog(
        alignment: Alignment.topRight,
        insetPadding: const EdgeInsets.fromLTRB(16, 88, 16, 16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const EdBoardSolidIcon(
                      icon: Icons.tune,
                      color: EdBoardMetrics.iconPurple,
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
