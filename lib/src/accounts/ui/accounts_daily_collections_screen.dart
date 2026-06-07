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
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsDailyCollectionsScreen extends ConsumerWidget {
  const AccountsDailyCollectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canAccessAccountsModule(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(title: 'Daily collections');
    }
    final async = ref.watch(accountsDailyCollectionsProvider);
    final fmt = accountsNairaFormat();

    return AccountsAsyncScaffold<List<AccountsDailyCollectionRow>>(
      title: 'Daily collections',
      subtitle: 'Payment method breakdown by day',
      colors: AccountsPalette.reports,
      asyncValue: async,
      onRetry: () => ref.invalidate(accountsDailyCollectionsProvider),
      builder: (context, rows) {
        if (rows.isEmpty) {
          return const AccountsEmptyState(title: 'No Daily collections report', subtitle: 'No records for the selected filters.',
          );
        }
        return AccountsDataTableBox(
          child: DataTable2(
            columnSpacing: 12,
            horizontalMargin: 12,
            minWidth: 900,
            columns: const [
              DataColumn2(label: Text('Date'), size: ColumnSize.S),
              DataColumn2(label: Text('Cash'), size: ColumnSize.S),
              DataColumn2(label: Text('Card'), size: ColumnSize.S),
              DataColumn2(label: Text('Transfer'), size: ColumnSize.S),
              DataColumn2(label: Text('Wallet'), size: ColumnSize.S),
              DataColumn2(label: Text('Total'), size: ColumnSize.S),
              DataColumn2(label: Text('Count'), size: ColumnSize.S),
            ],
            rows: [
              for (final r in rows)
                DataRow2(
                  cells: [
                    DataCell(Text(DateFormatter.shortDate(r.date))),
                    DataCell(Text(fmt.format(r.cash))),
                    DataCell(Text(fmt.format(r.card))),
                    DataCell(Text(fmt.format(r.transfer))),
                    DataCell(Text(fmt.format(r.wallet))),
                    DataCell(Text(fmt.format(r.total))),
                    DataCell(Text('${r.transactionCount}')),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
