import 'package:flutter/material.dart';

import '../../../helper/theme.dart';
import '../../../widgets/date.filter.dart';
import '../../../widgets/helty_surface.dart';
import '../completed_encounters_metrics.dart';

/// Compact one-line search + scope and visit type.
/// Date range (and extra filters on small screens) live in the filter menu.
class CompletedEncountersFilterBar extends StatelessWidget {
  const CompletedEncountersFilterBar({
    super.key,
    required this.searchController,
    required this.showScopeToggle,
    required this.mineOnly,
    required this.onMineOnlyChanged,
    required this.visitTypes,
    required this.selectedVisitType,
    required this.onVisitTypeChanged,
    required this.onDateFilterChanged,
    required this.onDateRefresh,
    required this.compact,
    this.fromDate,
    this.toDate,
    this.onOpenFilterMenu,
  });

  final TextEditingController searchController;
  final bool showScopeToggle;
  final bool mineOnly;
  final ValueChanged<bool> onMineOnlyChanged;
  final List<String> visitTypes;
  final String? selectedVisitType;
  final ValueChanged<String?> onVisitTypeChanged;
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
        hint: 'Patient, doctor, ID, or complaint…',
        icon: Icons.search,
        iconColor: CompletedEncountersMetrics.iconIndigo,
      ),
      style: const TextStyle(fontSize: 12),
    );
  }

  Widget _scopeDropdown(BuildContext context) {
    return DropdownButtonFormField<bool>(
      key: ValueKey('scope-$mineOnly'),
      initialValue: mineOnly,
      isExpanded: true,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _decoration(
        context,
        label: 'Scope',
        icon: Icons.groups_outlined,
        iconColor: CompletedEncountersMetrics.iconPink,
      ),
      items: const [
        DropdownMenuItem<bool>(
          value: false,
          child: Text('All completed', overflow: TextOverflow.ellipsis),
        ),
        DropdownMenuItem<bool>(
          value: true,
          child: Text('Mine only', overflow: TextOverflow.ellipsis),
        ),
      ],
      onChanged: (v) {
        if (v != null) onMineOnlyChanged(v);
      },
    );
  }

  Widget _visitTypeDropdown(BuildContext context) {
    return DropdownButtonFormField<String?>(
      key: ValueKey('visit-${selectedVisitType ?? 'all'}'),
      initialValue: selectedVisitType,
      isExpanded: true,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _decoration(
        context,
        label: 'Visit type',
        icon: Icons.flag_outlined,
        iconColor: CompletedEncountersMetrics.waitAmber,
      ),
      items: [
        const DropdownMenuItem<String?>(
          value: null,
          child: Text('All visit types', overflow: TextOverflow.ellipsis),
        ),
        ...visitTypes.map(
          (t) => DropdownMenuItem<String?>(
            value: t,
            child: Text(t, overflow: TextOverflow.ellipsis),
          ),
        ),
      ],
      onChanged: onVisitTypeChanged,
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
          if (showScopeToggle) ...[
            _scopeDropdown(context),
            const SizedBox(height: 10),
          ],
          _visitTypeDropdown(context),
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
      icon: const HeltySolidIcon(
        icon: Icons.tune,
        color: CompletedEncountersMetrics.iconPurple,
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
          onOpenFilterMenu ??
          () => showCompletedEncountersFilterMenu(context, this),
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
        if (showScopeToggle) ...[
          const SizedBox(width: 8),
          Expanded(flex: 2, child: _scopeDropdown(context)),
        ],
        const SizedBox(width: 8),
        Expanded(flex: 2, child: _visitTypeDropdown(context)),
        const SizedBox(width: 8),
        filterButton,
      ],
    );
  }
}

Future<void> showCompletedEncountersFilterMenu(
  BuildContext context,
  CompletedEncountersFilterBar filterBar,
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
                    const HeltySolidIcon(
                      icon: Icons.tune,
                      color: CompletedEncountersMetrics.iconPurple,
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
