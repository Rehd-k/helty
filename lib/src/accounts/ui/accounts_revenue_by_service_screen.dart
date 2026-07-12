import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/providers/accounts_providers.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/accounts/widgets/accounts_async_scaffold.dart';
import 'package:helty/src/accounts/widgets/accounts_data_table_box.dart';
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';
import 'package:helty/src/accounts/widgets/accounts_revenue_filter_bar.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsRevenueByServiceScreen extends ConsumerWidget {
  const AccountsRevenueByServiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canViewRevenueByService(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(title: 'Revenue by service');
    }
    final async = ref.watch(accountsRevenueByServiceProvider);
    final filter = ref.watch(accountsRevenueFilterProvider);
    final fmt = accountsNairaFormat();

    return AccountsAsyncScaffold(
      title: 'Revenue by service category',
      colors: AccountsPalette.reports,
      asyncValue: async,
      header: const AccountsRevenueFilterBar(),
      onRetry: () => ref.invalidate(accountsRevenueByServiceProvider),
      builder: (context, rows) {
        if (rows.isEmpty) {
          return const AccountsEmptyState(
            title: 'No Revenue by service',
            subtitle: 'No records for the selected filters.',
          );
        }
        return AccountsDataTableBox(
          child: DataTable2(
            columns: const [
              DataColumn2(label: Text('Category'), size: ColumnSize.L),
              DataColumn2(label: Text('Amount'), size: ColumnSize.S),
              DataColumn2(label: Text('Count'), size: ColumnSize.S),
              DataColumn2(label: Text('% of total'), size: ColumnSize.S),
              DataColumn2(label: Text(''), size: ColumnSize.S),
            ],
            rows: [
              for (final r in rows)
                DataRow2(
                  onTap: () => context.router.push(
                    AccountsRevenueByServiceDetailRoute(
                      serviceCategory: r.serviceCategory,
                      period: filter.period,
                      asOf: filter.asOf,
                      from: filter.from,
                      to: filter.to,
                    ),
                  ),
                  cells: [
                    DataCell(Text(r.serviceCategory)),
                    DataCell(Text(fmt.format(r.amount))),
                    DataCell(Text('${r.transactionCount}')),
                    DataCell(Text('${r.percentOfTotal.toStringAsFixed(1)}%')),
                    const DataCell(Icon(Icons.chevron_right)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
