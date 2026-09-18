import 'package:flutter/material.dart';

import '../../helper/theme.dart';
import '../../widgets/helty_surface.dart';
import '../cmd_oversight_metrics.dart';

/// Compact one-line search + staffing status. Sort lives in the filter menu.
class CmdOversightFilterBar extends StatelessWidget {
  const CmdOversightFilterBar({
    super.key,
    required this.searchController,
    required this.statusValue,
    required this.onStatusChanged,
    required this.largestGapFirst,
    required this.onLargestGapFirstChanged,
    required this.compact,
    this.onOpenFilterMenu,
  });

  final TextEditingController searchController;
  final String statusValue;
  final ValueChanged<String> onStatusChanged;
  final bool largestGapFirst;
  final ValueChanged<bool> onLargestGapFirstChanged;
  final bool compact;
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
        hint: 'Department name…',
        icon: Icons.search,
        iconColor: CmdOversightMetrics.iconIndigo,
      ),
      style: const TextStyle(fontSize: 12),
    );
  }

  Widget _statusDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey('status-$statusValue'),
      initialValue: statusValue,
      isExpanded: true,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _decoration(
        context,
        label: 'Coverage',
        icon: Icons.flag_outlined,
        iconColor: CmdOversightMetrics.waitAmber,
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All departments')),
        DropdownMenuItem(value: 'short', child: Text('Short staffed')),
        DropdownMenuItem(value: 'covered', child: Text('Covered')),
      ],
      onChanged: (v) {
        if (v != null) onStatusChanged(v);
      },
    );
  }

  Widget filterMenuBody(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (compact) ...[_statusDropdown(context), const SizedBox(height: 12)],
        Text(
          'Sort',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<bool>(
          initialValue: largestGapFirst,
          isExpanded: true,
          decoration: _decoration(
            context,
            label: 'Order',
            icon: Icons.sort,
            iconColor: CmdOversightMetrics.iconTeal,
          ),
          items: const [
            DropdownMenuItem(value: true, child: Text('Largest gap first')),
            DropdownMenuItem(value: false, child: Text('Department A–Z')),
          ],
          onChanged: (v) {
            if (v != null) onLargestGapFirstChanged(v);
          },
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
        color: CmdOversightMetrics.iconPurple,
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
          onOpenFilterMenu ?? () => showCmdOversightFilterMenu(context, this),
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
        filterButton,
      ],
    );
  }
}

Future<void> showCmdOversightFilterMenu(
  BuildContext context,
  CmdOversightFilterBar filterBar,
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
                      color: CmdOversightMetrics.iconPurple,
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
