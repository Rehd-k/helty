import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/providers/accounts_providers.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/accounts/widgets/accounts_async_scaffold.dart';
import 'package:helty/src/accounts/widgets/accounts_data_table_box.dart';
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsBankReconScreen extends ConsumerWidget {
  const AccountsBankReconScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canViewBankReconciliation(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(
        title: 'Bank reconciliation',
        message: 'You do not have access to bank reconciliation.',
      );
    }
    final async = ref.watch(accountsBankReconProvider);
    final fmt = accountsNairaFormat();

    return AccountsAsyncScaffold(
      title: 'Bank reconciliation',
      colors: AccountsPalette.dashboard,
      asyncValue: async,
      onRetry: () => ref.invalidate(accountsBankReconProvider),
      builder: (context, rows) {
        if (rows.isEmpty) {
          return const AccountsEmptyState(
            title: 'No Bank reconciliation',
            subtitle: 'No records for the selected filters.',
          );
        }
        return AccountsDataTableBox(
          child: DataTable2(
            minWidth: 900,
            columns: const [
              DataColumn2(label: Text('Bank'), size: ColumnSize.M),
              DataColumn2(label: Text('Statement date'), size: ColumnSize.S),
              DataColumn2(label: Text('Book'), size: ColumnSize.S),
              DataColumn2(label: Text('Statement'), size: ColumnSize.S),
              DataColumn2(label: Text('Variance'), size: ColumnSize.S),
              DataColumn2(label: Text('Status'), size: ColumnSize.S),
            ],
            rows: [
              for (final r in rows)
                DataRow2(
                  cells: [
                    DataCell(Text(r.bankName)),
                    DataCell(Text(DateFormatter.shortDate(r.statementDate))),
                    DataCell(Text(fmt.format(r.bookBalance))),
                    DataCell(Text(fmt.format(r.statementBalance))),
                    DataCell(Text(fmt.format(r.variance))),
                    DataCell(Text(r.status)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
