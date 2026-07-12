import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/helper/date.formatter.dart';

import '../models/accounts_models.dart';
import '../providers/accounts_providers.dart';

class AccountsRevenueFilterBar extends ConsumerWidget {
  const AccountsRevenueFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(accountsRevenueFilterProvider);
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final p in AccountsRevenueFilter.presetPeriods)
          FilterChip(
            label: Text(AccountsPeriodFilter.labelFor(p)),
            selected: current.period == p,
            onSelected: (_) {
              ref.read(accountsRevenueFilterProvider.notifier).state =
                  AccountsRevenueFilter(period: p);
            },
            selectedColor: theme.colorScheme.primaryContainer,
            checkmarkColor: theme.colorScheme.primary,
          ),
        FilterChip(
          label: Text(_customLabel(current)),
          selected: current.period == 'custom',
          avatar: const Icon(Icons.date_range, size: 18),
          onSelected: (_) => _pickCustomRange(context, ref, current),
          selectedColor: theme.colorScheme.primaryContainer,
          checkmarkColor: theme.colorScheme.primary,
        ),
      ],
    );
  }

  String _customLabel(AccountsRevenueFilter filter) {
    if (filter.usesCustomRange) {
      return '${DateFormatter.shortDate(filter.from!)} – ${DateFormatter.shortDate(filter.to!)}';
    }
    return AccountsPeriodFilter.labelFor('custom');
  }

  Future<void> _pickCustomRange(
    BuildContext context,
    WidgetRef ref,
    AccountsRevenueFilter current,
  ) async {
    final now = DateTime.now();
    final initialRange = current.usesCustomRange
        ? DateTimeRange(start: current.from!, end: current.to!)
        : DateTimeRange(
            start: now.subtract(const Duration(days: 30)),
            end: now,
          );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: initialRange,
    );
    if (picked == null || !context.mounted) return;

    ref.read(accountsRevenueFilterProvider.notifier).state = AccountsRevenueFilter(
      period: 'custom',
      from: DateTime(picked.start.year, picked.start.month, picked.start.day),
      to: DateTime(
        picked.end.year,
        picked.end.month,
        picked.end.day,
        23,
        59,
        59,
        999,
      ),
    );
  }
}
