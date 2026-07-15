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
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsApprovalsScreen extends ConsumerWidget {
  const AccountsApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(authProvider).staff;
    if (!canViewFinancialApprovals(staff)) {
      return const AccountsAccessDenied(
        title: 'Financial approvals',
        message: 'You do not have access to the financial approvals queue.',
      );
    }
    final canAct = canApproveFinancialActions(staff);
    final async = ref.watch(accountsPendingApprovalsProvider);
    final fmt = accountsNairaFormat();
    final svc = AccountsReportsService();

    return AccountsAsyncScaffold<List<AccountsApprovalRequest>>(
      title: 'Pending financial approvals',
      subtitle: canAct
          ? 'Write-offs and coverage reversals (not line-item refunds)'
          : 'View-only · Write-offs and coverage reversals awaiting Account Head action',
      colors: AccountsPalette.audit,
      asyncValue: async,
      onRetry: () => ref.invalidate(accountsPendingApprovalsProvider),
      builder: (context, items) {
        if (items.isEmpty) {
          return const AccountsEmptyState(
            title: 'No Financial approvals queue',
            subtitle: 'No records for the selected filters.',
          );
        }
        return AccountsDataTableBox(
          child: DataTable2(
            minWidth: 1000,
            columns: [
              const DataColumn2(label: Text('Type'), size: ColumnSize.S),
              const DataColumn2(label: Text('Amount'), size: ColumnSize.S),
              const DataColumn2(label: Text('Requester'), size: ColumnSize.S),
              const DataColumn2(label: Text('Submitted'), size: ColumnSize.S),
              const DataColumn2(label: Text('Detail'), size: ColumnSize.L),
              if (canAct)
                const DataColumn2(label: Text('Actions'), size: ColumnSize.S),
            ],
            rows: [
              for (final a in items)
                DataRow2(
                  cells: [
                    DataCell(Text(a.type)),
                    DataCell(Text(fmt.format(a.amount))),
                    DataCell(Text(a.requester)),
                    DataCell(
                      Text(DateFormatter.dateTimeWithSeconds(a.submittedAt)),
                    ),
                    DataCell(Text(a.detail)),
                    if (canAct)
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline),
                              tooltip: 'Approve',
                              onPressed: () async {
                                await svc.approveRequest(a.id);
                                ref.invalidate(
                                  accountsPendingApprovalsProvider,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined),
                              tooltip: 'Reject',
                              onPressed: () async {
                                await svc.rejectRequest(
                                  a.id,
                                  reason: 'Rejected by account head',
                                );
                                ref.invalidate(
                                  accountsPendingApprovalsProvider,
                                );
                              },
                            ),
                          ],
                        ),
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
