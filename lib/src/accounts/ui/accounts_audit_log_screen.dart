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
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsAuditLogScreen extends ConsumerWidget {
  const AccountsAuditLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canAccessAccountsModule(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(title: 'Financial audit log');
    }
    final async = ref.watch(accountsAuditLogsProvider);

    return AccountsAsyncScaffold<AccountsAuditComplianceBundle>(
      title: 'Financial audit log',
      subtitle: 'Activity trail for payments, invoices, and receivables',
      colors: AccountsPalette.audit,
      asyncValue: async,
      onRetry: () => ref.invalidate(accountsAuditLogsProvider),
      builder: (context, data) {
        if (data.logs.isEmpty) {
          return const AccountsEmptyState(
            title: 'No audit entries',
            subtitle: 'No financial activity for the selected filters.',
            icon: Icons.history_rounded,
          );
        }
        return AccountsDataTableBox(
          child: DataTable2(
            columnSpacing: 10,
            horizontalMargin: 10,
            minWidth: 1000,
            columns: const [
              DataColumn2(label: Text('Time'), size: ColumnSize.S),
              DataColumn2(label: Text('User'), size: ColumnSize.S),
              DataColumn2(label: Text('Action'), size: ColumnSize.S),
              DataColumn2(label: Text('Entity'), size: ColumnSize.M),
              DataColumn2(label: Text('Detail'), size: ColumnSize.L),
            ],
            rows: [
              for (final l in data.logs)
                DataRow2(
                  cells: [
                    DataCell(Text(DateFormatter.dateTimeWithSeconds(l.at))),
                    DataCell(Text(l.user)),
                    DataCell(Text(l.action)),
                    DataCell(Text(l.entity)),
                    DataCell(Text(l.metadata)),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
