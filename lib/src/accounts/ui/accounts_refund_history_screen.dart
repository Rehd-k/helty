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
class AccountsRefundHistoryScreen extends ConsumerWidget {
  const AccountsRefundHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canAccessAccountsModule(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(title: 'Refund history');
    }
    final async = ref.watch(accountsRefundHistoryProvider);

    return AccountsAsyncScaffold(
      title: 'Payment refund history',
      subtitle: 'Refunds from financial audit trail (last 90 days)',
      colors: AccountsPalette.audit,
      asyncValue: async,
      onRetry: () => ref.invalidate(accountsRefundHistoryProvider),
      builder: (context, rows) {
        if (rows.isEmpty) {
          return const AccountsEmptyState(
            title: 'No refunds recorded',
            subtitle: 'Refund events will appear here when processed.',
            icon: Icons.undo_rounded,
          );
        }
        return AccountsDataTableBox(
          child: DataTable2(
            minWidth: 900,
            columns: const [
              DataColumn2(label: Text('Time'), size: ColumnSize.S),
              DataColumn2(label: Text('User'), size: ColumnSize.S),
              DataColumn2(label: Text('Action'), size: ColumnSize.S),
              DataColumn2(label: Text('Entity'), size: ColumnSize.M),
              DataColumn2(label: Text('Detail'), size: ColumnSize.L),
            ],
            rows: [
              for (final r in rows)
                DataRow2(
                  cells: [
                    DataCell(Text(DateFormatter.dateTimeWithSeconds(r.at))),
                    DataCell(Text(r.user)),
                    DataCell(Text(r.action)),
                    DataCell(Text(r.entity)),
                    DataCell(Text(r.metadata)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
