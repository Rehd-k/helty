import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/models/accounts_models.dart';
import 'package:helty/src/accounts/providers/accounts_providers.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/accounts/widgets/accounts_async_scaffold.dart';
import 'package:helty/src/accounts/widgets/accounts_data_table_box.dart';
import 'package:helty/src/accounts/widgets/accounts_kpi_grid.dart';
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsWalletsOverviewScreen extends ConsumerWidget {
  const AccountsWalletsOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canAccessAccountsModule(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(title: 'Patient wallets');
    }
    final async = ref.watch(accountsWalletsSummaryProvider);
    final fmt = accountsNairaFormat();

    return AccountsAsyncScaffold<AccountsWalletsSummary>(
      title: 'Patient wallets overview',
      subtitle: 'Aggregate wallet float across patients',
      colors: AccountsPalette.dashboard,
      asyncValue: async,
      onRetry: () => ref.invalidate(accountsWalletsSummaryProvider),
      builder: (context, data) {
        if (data.rows.isEmpty && data.totalFloat == 0) {
          return const AccountsEmptyState(title: 'No Patient wallets summary', subtitle: 'No records for the selected filters.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AccountsKpiGrid(
              tiles: [
                AccountsKpiTile(
                  label: 'Total float',
                  value: fmt.format(data.totalFloat),
                  icon: Icons.account_balance_wallet_rounded,
                ),
                AccountsKpiTile(
                  label: 'Active wallets',
                  value: '${data.activeWallets}',
                  icon: Icons.people_outline_rounded,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Tap a row to view wallet history',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: AccountsDataTableBox(
                child: DataTable2(
                columns: const [
                  DataColumn2(label: Text('Patient'), size: ColumnSize.L),
                  DataColumn2(label: Text('Balance'), size: ColumnSize.S),
                  DataColumn2(label: Text('Transactions'), size: ColumnSize.S),
                  DataColumn2(label: Text('Last activity'), size: ColumnSize.S),
                  DataColumn2(label: Text(''), size: ColumnSize.S),
                ],
                rows: [
                  for (final r in data.rows)
                    DataRow2(
                      onTap: r.patientId.trim().isEmpty
                          ? null
                          : () => context.router.push(
                              PatientWalletHistoryRoute(
                                patientUuid: r.patientId,
                                patientName: r.patientName,
                              ),
                            ),
                      cells: [
                        DataCell(Text(r.patientName)),
                        DataCell(Text(fmt.format(r.balance))),
                        DataCell(Text('${r.transactionCount}')),
                        DataCell(Text(
                          r.lastTransactionAt != null
                              ? DateFormatter.dateTimeWithSeconds(
                                  r.lastTransactionAt!,
                                )
                              : '—',
                        )),
                        const DataCell(Icon(Icons.chevron_right)),
                      ],
                    ),
                ],
              ),
            ),
            ),
          ],
        );
      },
    );
  }
}
