import 'package:flutter/material.dart';

import '../../helper/theme.dart';
import '../patient_hub_metrics.dart';

class HubSectionScaffold extends StatelessWidget {
  const HubSectionScaffold({
    super.key,
    required this.child,
    this.filterRow,
    this.sortDropdown,
    this.loading = false,
    this.error,
    this.onRetry,
  });

  final Widget child;
  final Widget? filterRow;
  final Widget? sortDropdown;
  final bool loading;
  final String? error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(error!, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < PatientHubMetrics.cardBreakpoint;
        final hasFilters = filterRow != null || sortDropdown != null;

        Widget toolbar() {
          if (!hasFilters) return const SizedBox.shrink();
          if (compact && filterRow != null) {
            return Row(
              children: [
                if (sortDropdown != null) sortDropdown!,
                const Spacer(),
                IconButton(
                  tooltip: 'Filters',
                  onPressed: () => _showFilterMenu(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  icon: const HubSolidIcon(
                    icon: Icons.tune,
                    color: PatientHubMetrics.iconPurple,
                    size: 32,
                    iconSize: 16,
                    radius: 8,
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              if (filterRow != null) Expanded(child: filterRow!),
              if (sortDropdown != null) sortDropdown!,
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hasFilters)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: toolbar(),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }

  void _showFilterMenu(BuildContext context) {
    showDialog<void>(
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
                      const HubSolidIcon(
                        icon: Icons.tune,
                        color: PatientHubMetrics.iconPurple,
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
                  if (filterRow != null) filterRow!,
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

InputDecoration hubFilterDecoration(
  BuildContext context, {
  required String label,
  required Color iconColor,
  required IconData icon,
}) {
  final cs = Theme.of(context).colorScheme;
  return InputDecoration(
    labelText: label,
    isDense: true,
    prefixIcon: Padding(
      padding: const EdgeInsets.all(6),
      child: HubSolidIcon(
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
