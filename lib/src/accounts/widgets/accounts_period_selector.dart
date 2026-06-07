import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/accounts_models.dart';
import '../providers/accounts_providers.dart';

class AccountsPeriodSelector extends ConsumerWidget {
  const AccountsPeriodSelector({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(accountsPeriodProvider);
    final theme = Theme.of(context);

    if (compact) {
      return DropdownButton<String>(
        value: current.period,
        underline: const SizedBox.shrink(),
        items: [
          for (final p in AccountsPeriodFilter.periods)
            DropdownMenuItem(
              value: p,
              child: Text(AccountsPeriodFilter.labelFor(p)),
            ),
        ],
        onChanged: (v) {
          if (v != null) {
            ref.read(accountsPeriodProvider.notifier).state =
                AccountsPeriodFilter(period: v);
          }
        },
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in AccountsPeriodFilter.periods)
          FilterChip(
            label: Text(AccountsPeriodFilter.labelFor(p)),
            selected: current.period == p,
            onSelected: (_) {
              ref.read(accountsPeriodProvider.notifier).state =
                  AccountsPeriodFilter(period: p);
            },
            selectedColor: theme.colorScheme.primaryContainer,
            checkmarkColor: theme.colorScheme.primary,
          ),
      ],
    );
  }
}
