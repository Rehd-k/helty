import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/models/accounts_models.dart';
import 'package:helty/src/accounts/providers/accounts_providers.dart';
import 'package:helty/src/accounts/services/accounts_refund_requests_service.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/accounts/widgets/accounts_async_scaffold.dart';
import 'package:helty/src/accounts/widgets/accounts_data_table_box.dart';
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';
import 'package:helty/src/billings/widgets/invoice_item_refund_dialogs.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsRefundRequestsScreen extends ConsumerWidget {
  const AccountsRefundRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(authProvider).staff;
    if (!canViewItemRefundRequests(staff)) {
      return const AccountsAccessDenied(
        title: 'Item refund requests',
        message: 'You do not have access to the item refund requests queue.',
      );
    }
    final canAct = canApproveItemRefundRequests(staff);
    final async = ref.watch(accountsPendingRefundRequestsProvider);
    final fmt = accountsNairaFormat();
    final svc = AccountsRefundRequestsService();

    return AccountsAsyncScaffold<List<AccountsPendingRefundRequest>>(
      title: 'Item refund requests',
      subtitle: canAct
          ? 'Pending line-item refunds awaiting account or billing head approval'
          : 'View-only · Pending line-item refunds',
      colors: AccountsPalette.audit,
      asyncValue: async,
      onRetry: () => ref.invalidate(accountsPendingRefundRequestsProvider),
      builder: (context, items) {
        if (items.isEmpty) {
          return const AccountsEmptyState(
            title: 'No pending refund requests',
            subtitle: 'Billing staff requests will appear here for approval.',
            icon: Icons.receipt_long_outlined,
          );
        }
        return AccountsDataTableBox(
          child: DataTable2(
            minWidth: 1200,
            columns: [
              const DataColumn2(label: Text('Invoice'), size: ColumnSize.S),
              const DataColumn2(label: Text('Patient'), size: ColumnSize.S),
              const DataColumn2(label: Text('Line'), size: ColumnSize.L),
              const DataColumn2(label: Text('Line total'), size: ColumnSize.S),
              const DataColumn2(label: Text('Paid'), size: ColumnSize.S),
              const DataColumn2(label: Text('Reason'), size: ColumnSize.L),
              const DataColumn2(label: Text('Requester'), size: ColumnSize.S),
              const DataColumn2(label: Text('Submitted'), size: ColumnSize.S),
              DataColumn2(
                label: Text(canAct ? 'Actions' : 'Invoice'),
                size: ColumnSize.M,
              ),
            ],
            rows: [
              for (final r in items)
                DataRow2(
                  cells: [
                    DataCell(Text(r.invoiceDisplayId ?? r.invoiceId)),
                    DataCell(
                      Text(
                        r.patientName?.isNotEmpty == true
                            ? r.patientName!
                            : (r.patientDisplayId ?? '—'),
                      ),
                    ),
                    DataCell(Text(r.lineDescription)),
                    DataCell(Text(fmt.format(r.lineTotal))),
                    DataCell(Text(fmt.format(r.amountPaid))),
                    DataCell(Text(r.reason)),
                    DataCell(Text(r.requester)),
                    DataCell(
                      Text(DateFormatter.dateTimeWithSeconds(r.submittedAt)),
                    ),
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.open_in_new),
                            tooltip: 'Open invoice',
                            onPressed: r.invoiceId.isEmpty
                                ? null
                                : () {
                                    context.router.push(
                                      PatientBillingRoute(
                                        invoiceId: r.invoiceId,
                                        patientName: r.patientName ?? '',
                                      ),
                                    );
                                  },
                          ),
                          if (canAct) ...[
                            IconButton(
                              icon: const Icon(Icons.check_circle_outline),
                              tooltip: 'Approve',
                              onPressed: () async {
                                final note = await showRefundApproveNoteDialog(
                                  context,
                                );
                                if (!context.mounted) return;
                                if (note == null) return;
                                try {
                                  final result = await svc.approve(
                                    r.id,
                                    note: note.isEmpty ? null : note,
                                  );
                                  if (!context.mounted) return;
                                  ref.invalidate(
                                    accountsPendingRefundRequestsProvider,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Refund approved. ${result.refundedAmount.toFinancial(isMoney: true)} reversed.',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_outlined),
                              tooltip: 'Reject',
                              onPressed: () async {
                                final reason =
                                    await showRefundRejectReasonDialog(context);
                                if (reason == null || !context.mounted) return;
                                try {
                                  await svc.reject(r.id, reason: reason);
                                  if (!context.mounted) return;
                                  ref.invalidate(
                                    accountsPendingRefundRequestsProvider,
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Refund request rejected.'),
                                    ),
                                  );
                                } catch (e) {
                                  if (!context.mounted) return;
                                  ScaffoldMessenger.of(
                                    context,
                                  ).showSnackBar(SnackBar(content: Text('$e')));
                                }
                              },
                            ),
                          ],
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
