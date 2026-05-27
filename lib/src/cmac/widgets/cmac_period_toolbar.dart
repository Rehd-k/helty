import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cmac_period.dart';
import '../providers/cmac_providers.dart';

class CmacPeriodToolbar extends ConsumerWidget {
  const CmacPeriodToolbar({
    super.key,
    this.onRefresh,
    this.accentColor,
  });

  final VoidCallback? onRefresh;
  final Color? accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accent = accentColor ?? cs.primary;
    final query = ref.watch(cmacAnalyticsQueryProvider);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.35)),
      ),
      color: cs.surface.withValues(alpha: 0.92),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(Icons.date_range_rounded, size: 20, color: accent),
            ...CmacPeriod.values.map((p) {
              final selected = query.period == p;
              return FilterChip(
                label: Text(p.label),
                selected: selected,
                onSelected: (_) {
                  ref.read(cmacAnalyticsQueryProvider.notifier).state =
                      query.copyWith(period: p);
                },
                selectedColor: accent.withValues(alpha: 0.25),
                checkmarkColor: accent,
              );
            }),
            IconButton.filledTonal(
              tooltip: 'Refresh',
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
            TextButton.icon(
              onPressed: () => _showAdvanced(context, ref, query),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Advanced'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAdvanced(
    BuildContext context,
    WidgetRef ref,
    CmacAnalyticsQuery query,
  ) async {
    var limit = query.limit;
    DateTime? asOf = query.asOf;
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: const Text('Report options'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    value: limit,
                    decoration: const InputDecoration(labelText: 'Top-N limit'),
                    items: const [5, 10, 20, 50]
                        .map(
                          (n) => DropdownMenuItem(value: n, child: Text('$n')),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => limit = v ?? 10),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      asOf == null
                          ? 'As-of: now'
                          : 'As-of: ${asOf!.toLocal()}',
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final d = await showDatePicker(
                          context: ctx,
                          initialDate: asOf ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (d != null) {
                          setState(() => asOf = d);
                        }
                      },
                      child: const Text('Pick date'),
                    ),
                  ),
                  if (asOf != null)
                    TextButton(
                      onPressed: () => setState(() => asOf = null),
                      child: const Text('Clear as-of date'),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    ref.read(cmacAnalyticsQueryProvider.notifier).state =
                        query.copyWith(
                          limit: limit,
                          asOf: asOf,
                          clearAsOf: asOf == null && query.asOf != null,
                        );
                    Navigator.pop(ctx);
                  },
                  child: const Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
