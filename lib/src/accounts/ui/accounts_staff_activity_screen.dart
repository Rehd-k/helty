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
import 'package:helty/src/accounts/widgets/accounts_period_selector.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsStaffActivityScreen extends ConsumerWidget {
  const AccountsStaffActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canViewStaffFinancialActivity(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(title: 'Staff financial activity');
    }
    final async = ref.watch(accountsStaffActivityProvider);
    final fmt = accountsNairaFormat();

    return AccountsAsyncScaffold(
      title: 'Staff financial activity',
      colors: AccountsPalette.audit,
      asyncValue: async,
      header: const AccountsPeriodSelector(),
      onRetry: () => ref.invalidate(accountsStaffActivityProvider),
      builder: (context, rows) {
        if (rows.isEmpty) {
          return const AccountsEmptyState(title: 'No Staff financial activity', subtitle: 'No records for the selected filters.');
        }
        return AccountsDataTableBox(
          child: DataTable2(
            minWidth: 900,
            columns: const [
              DataColumn2(label: Text('Staff'), size: ColumnSize.M),
              DataColumn2(label: Text('Role'), size: ColumnSize.S),
              DataColumn2(label: Text('Payments'), size: ColumnSize.S),
              DataColumn2(label: Text('Collected'), size: ColumnSize.S),
              DataColumn2(label: Text('Refunds'), size: ColumnSize.S),
              DataColumn2(label: Text('Remittances'), size: ColumnSize.S),
            ],
            rows: [
              for (final r in rows)
                DataRow2(
                  cells: [
                    DataCell(Text(r.staffName)),
                    DataCell(Text(r.role)),
                    DataCell(Text('${r.paymentsRecorded}')),
                    DataCell(Text(fmt.format(r.totalCollected))),
                    DataCell(Text('${r.refundsInitiated}')),
                    DataCell(Text('${r.remittancesRecorded}')),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
