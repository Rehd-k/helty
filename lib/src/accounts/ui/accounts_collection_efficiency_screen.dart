import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/models/accounts_models.dart';
import 'package:helty/src/accounts/providers/accounts_providers.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/accounts/widgets/accounts_async_scaffold.dart';
import 'package:helty/src/accounts/widgets/accounts_kpi_grid.dart';
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';
import 'package:helty/src/accounts/widgets/accounts_period_selector.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsCollectionEfficiencyScreen extends ConsumerWidget {
  const AccountsCollectionEfficiencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canAccessAccountsModule(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(title: 'Collection efficiency');
    }
    final async = ref.watch(accountsCollectionEfficiencyProvider);
    final fmt = accountsNairaFormat();

    return AccountsAsyncScaffold<AccountsCollectionEfficiencyReport>(
      title: 'Collection efficiency',
      colors: AccountsPalette.reports,
      asyncValue: async,
      header: const AccountsPeriodSelector(),
      onRetry: () => ref.invalidate(accountsCollectionEfficiencyProvider),
      builder: (context, data) {
        if (data.period.isEmpty && data.billedAmount == 0) {
          return const AccountsEmptyState(title: 'No Collection efficiency', subtitle: 'No records for the selected filters.');
        }
        return AccountsKpiGrid(
          tiles: [
            AccountsKpiTile(
              label: 'Billed',
              value: fmt.format(data.billedAmount),
              icon: Icons.receipt_long_outlined,
            ),
            AccountsKpiTile(
              label: 'Collected',
              value: fmt.format(data.collectedAmount),
              icon: Icons.payments_rounded,
            ),
            AccountsKpiTile(
              label: 'Collection rate',
              value: '${data.collectionRatePercent.toStringAsFixed(1)}%',
              icon: Icons.speed_rounded,
            ),
            AccountsKpiTile(
              label: 'Avg days to collect',
              value: data.avgDaysToCollect.toStringAsFixed(0),
              icon: Icons.schedule_rounded,
            ),
            AccountsKpiTile(
              label: 'Write-offs',
              value: fmt.format(data.writeOffAmount),
              icon: Icons.money_off_rounded,
            ),
          ],
        );
      },
    );
  }
}
