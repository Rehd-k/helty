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
import 'package:helty/src/shared/finance_status_colors.dart';

@RoutePage()
class AccountsExpenseVsBudgetScreen extends ConsumerWidget {
  const AccountsExpenseVsBudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canViewProfitLoss(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(title: 'Expense vs budget');
    }
    final async = ref.watch(accountsExpenseVsBudgetProvider);
    final fmt = accountsNairaFormat();

    return AccountsAsyncScaffold(
      title: 'Expense vs budget',
      subtitle: 'Variance highlights overspend',
      colors: AccountsPalette.reports,
      asyncValue: async,
      header: const AccountsPeriodSelector(),
      onRetry: () => ref.invalidate(accountsExpenseVsBudgetProvider),
      builder: (context, rows) {
        if (rows.isEmpty) {
          return const AccountsEmptyState(title: 'No Expense vs budget', subtitle: 'No records for the selected filters.');
        }
        final scheme = Theme.of(context).colorScheme;
        return AccountsDataTableBox(
          child: DataTable2(
            minWidth: 800,
            columns: const [
              DataColumn2(label: Text('Category'), size: ColumnSize.L),
              DataColumn2(label: Text('Budget'), size: ColumnSize.S),
              DataColumn2(label: Text('Actual'), size: ColumnSize.S),
              DataColumn2(label: Text('Variance'), size: ColumnSize.S),
              DataColumn2(label: Text('Var %'), size: ColumnSize.S),
            ],
            rows: [
              for (final r in rows)
                DataRow2(
                  color: r.variance > 0
                      ? WidgetStateProperty.all(
                          FinanceStatusColors.danger(scheme).withValues(
                            alpha: 0.06,
                          ),
                        )
                      : null,
                  cells: [
                    DataCell(Text(r.category)),
                    DataCell(Text(fmt.format(r.budget))),
                    DataCell(Text(fmt.format(r.actual))),
                    DataCell(Text(fmt.format(r.variance))),
                    DataCell(Text('${r.variancePercent.toStringAsFixed(1)}%')),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
