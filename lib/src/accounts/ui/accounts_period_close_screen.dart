import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/models/accounts_models.dart';
import 'package:helty/src/accounts/providers/accounts_providers.dart';
import 'package:helty/src/accounts/services/accounts_reports_service.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/accounts/widgets/accounts_async_scaffold.dart';
import 'package:helty/src/accounts/widgets/accounts_data_table_box.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsPeriodCloseScreen extends ConsumerWidget {
  const AccountsPeriodCloseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(authProvider).staff;
    if (!canViewPeriodClose(staff)) {
      return const AccountsAccessDenied(
        title: 'Fiscal period close',
        message: 'You do not have access to fiscal periods.',
      );
    }
    final canAct = canClosePeriod(staff);
    final async = ref.watch(accountsFiscalPeriodsProvider);
    final svc = AccountsReportsService();

    return AccountsAsyncScaffold<List<AccountsFiscalPeriod>>(
      title: 'Fiscal period close',
      subtitle: canAct
          ? 'Lock periods after month-end close'
          : 'View-only · Fiscal period status',
      colors: AccountsPalette.audit,
      asyncValue: async,
      onRetry: () => ref.invalidate(accountsFiscalPeriodsProvider),
      builder: (context, periods) {
        if (periods.isEmpty) {
          return const AccountsEmptyState(
            title: 'No Fiscal periods',
            subtitle: 'No records for the selected filters.',
          );
        }
        return AccountsDataTableBox(
          child: DataTable2(
            columns: [
              const DataColumn2(label: Text('Period'), size: ColumnSize.M),
              const DataColumn2(label: Text('Start'), size: ColumnSize.S),
              const DataColumn2(label: Text('End'), size: ColumnSize.S),
              const DataColumn2(label: Text('Status'), size: ColumnSize.S),
              DataColumn2(
                label: Text(canAct ? 'Action' : 'Closed by'),
                size: ColumnSize.S,
              ),
            ],
            rows: [
              for (final p in periods)
                DataRow2(
                  cells: [
                    DataCell(Text(p.label)),
                    DataCell(Text(DateFormatter.shortDate(p.startDate))),
                    DataCell(Text(DateFormatter.shortDate(p.endDate))),
                    DataCell(Text(p.status)),
                    DataCell(
                      canAct && p.status.toLowerCase() == 'open'
                          ? TextButton(
                              onPressed: () async {
                                final ok = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Close period?'),
                                    content: Text(
                                      'Close ${p.label}? This cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(ctx, true),
                                        child: const Text('Close period'),
                                      ),
                                    ],
                                  ),
                                );
                                if (ok == true) {
                                  await svc.closePeriod(p.id);
                                  ref.invalidate(accountsFiscalPeriodsProvider);
                                }
                              },
                              child: const Text('Close'),
                            )
                          : Text(p.closedBy ?? '—'),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
