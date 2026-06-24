import 'package:flutter/material.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (filterRow != null || sortDropdown != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                if (filterRow != null) Expanded(child: filterRow!),
                if (sortDropdown != null) sortDropdown!,
              ],
            ),
          ),
        Expanded(child: child),
      ],
    );
  }
}
