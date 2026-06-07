import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/models/accounts_models.dart';
import 'package:helty/src/accounts/providers/accounts_providers.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/accounts/widgets/accounts_async_scaffold.dart';
import 'package:helty/src/accounts/widgets/accounts_data_table_box.dart';
import 'package:helty/src/accounts/widgets/accounts_kpi_grid.dart';
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsAgingReportScreen extends ConsumerWidget {
  const AccountsAgingReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canAccessAccountsModule(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(title: 'AR aging report');
    }
    final async = ref.watch(accountsAgingReportProvider);
    final fmt = accountsNairaFormat();

    return AccountsAsyncScaffold<AccountsAgingReport>(
      title: 'AR aging report',
      subtitle: 'Outstanding receivables by age bucket',
      colors: AccountsPalette.reports,
      asyncValue: async,
      onRetry: () => ref.invalidate(accountsAgingReportProvider),
      builder: (context, data) {
        if (data.rows.isEmpty && data.buckets.isEmpty) {
          return const AccountsEmptyState(title: 'No AR aging report', subtitle: 'No records for the selected filters.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AccountsKpiGrid(
              tiles: [
                AccountsKpiTile(
                  label: 'Total outstanding',
                  value: fmt.format(data.totalOutstanding),
                  icon: Icons.account_balance_wallet_outlined,
                ),
                for (final b in data.buckets)
                  AccountsKpiTile(
                    label: b.bucket,
                    value: fmt.format(b.amount),
                    subtitle: '${b.count} items',
                  ),
              ],
            ),
            const SizedBox(height: 24),
            AccountsDataTableBox(
              child: DataTable2(
                columnSpacing: 10,
                horizontalMargin: 10,
                minWidth: 1000,
                columns: const [
                  DataColumn2(label: Text('Party'), size: ColumnSize.M),
                  DataColumn2(label: Text('Type'), size: ColumnSize.S),
                  DataColumn2(label: Text('Total'), size: ColumnSize.S),
                  DataColumn2(label: Text('Current'), size: ColumnSize.S),
                  DataColumn2(label: Text('30d'), size: ColumnSize.S),
                  DataColumn2(label: Text('60d'), size: ColumnSize.S),
                  DataColumn2(label: Text('90d'), size: ColumnSize.S),
                  DataColumn2(label: Text('90d+'), size: ColumnSize.S),
                ],
                rows: [
                  for (final r in data.rows)
                    DataRow2(
                      cells: [
                        DataCell(Text(r.partyName)),
                        DataCell(Text(r.type)),
                        DataCell(Text(fmt.format(r.totalDue))),
                        DataCell(Text(fmt.format(r.current))),
                        DataCell(Text(fmt.format(r.days30))),
                        DataCell(Text(fmt.format(r.days60))),
                        DataCell(Text(fmt.format(r.days90))),
                        DataCell(Text(fmt.format(r.over90))),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
