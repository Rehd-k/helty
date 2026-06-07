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
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsInvoiceChangesScreen extends ConsumerWidget {
  const AccountsInvoiceChangesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canAccessAccountsModule(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(title: 'Invoice change history');
    }
    final async = ref.watch(accountsInvoiceChangesProvider);

    return AccountsAsyncScaffold(
      title: 'Invoice change history',
      colors: AccountsPalette.audit,
      asyncValue: async,
      onRetry: () => ref.invalidate(accountsInvoiceChangesProvider),
      builder: (context, rows) {
        if (rows.isEmpty) {
          return const AccountsEmptyState(title: 'No Invoice change history', subtitle: 'No records for the selected filters.');
        }
        return AccountsDataTableBox(
          child: DataTable2(
            minWidth: 900,
            columns: const [
              DataColumn2(label: Text('Invoice'), size: ColumnSize.S),
              DataColumn2(label: Text('Changed at'), size: ColumnSize.S),
              DataColumn2(label: Text('By'), size: ColumnSize.S),
              DataColumn2(label: Text('Type'), size: ColumnSize.S),
              DataColumn2(label: Text('Detail'), size: ColumnSize.L),
            ],
            rows: [
              for (final r in rows)
                DataRow2(
                  cells: [
                    DataCell(Text(r.invoiceNumber)),
                    DataCell(Text(DateFormatter.dateTimeWithSeconds(r.changedAt))),
                    DataCell(Text(r.changedBy)),
                    DataCell(Text(r.changeType)),
                    DataCell(Text(r.detail)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
