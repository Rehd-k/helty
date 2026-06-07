import 'package:auto_route/auto_route.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/providers/accounts_providers.dart';
import 'package:helty/src/accounts/services/accounts_reports_service.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/accounts/widgets/accounts_async_scaffold.dart';
import 'package:helty/src/accounts/widgets/accounts_data_table_box.dart';
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsDailyCashReconScreen extends ConsumerStatefulWidget {
  const AccountsDailyCashReconScreen({super.key});

  @override
  ConsumerState<AccountsDailyCashReconScreen> createState() =>
      _AccountsDailyCashReconScreenState();
}

class _AccountsDailyCashReconScreenState
    extends ConsumerState<AccountsDailyCashReconScreen> {
  final _countedController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _countedController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final counted = double.tryParse(_countedController.text.trim());
    if (counted == null) return;
    try {
      await AccountsReportsService().submitDailyCashRecon(
        date: DateTime.now(),
        countedCash: counted,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );
      ref.invalidate(accountsDailyCashReconProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cash reconciliation submitted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!canAccessAccountsModule(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(title: 'Daily cash reconciliation');
    }
    final async = ref.watch(accountsDailyCashReconProvider);
    final fmt = accountsNairaFormat();

    return AccountsAsyncScaffold(
      title: 'Daily cash reconciliation',
      colors: AccountsPalette.dashboard,
      asyncValue: async,
      onRetry: () => ref.invalidate(accountsDailyCashReconProvider),
      builder: (context, rows) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Submit today\'s cash count',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _countedController,
                      decoration: const InputDecoration(
                        labelText: 'Counted cash (₦)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesController,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: _submit,
                      child: const Text('Submit reconciliation'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (rows.isEmpty)
              const AccountsEmptyState(title: 'No Daily cash reconciliation history', subtitle: 'No records for the selected filters.',
              )
            else
              AccountsDataTableBox(
                child: DataTable2(
                  columns: const [
                    DataColumn2(label: Text('Date'), size: ColumnSize.S),
                    DataColumn2(label: Text('Expected'), size: ColumnSize.S),
                    DataColumn2(label: Text('Counted'), size: ColumnSize.S),
                    DataColumn2(label: Text('Variance'), size: ColumnSize.S),
                    DataColumn2(label: Text('Status'), size: ColumnSize.S),
                  ],
                  rows: [
                    for (final r in rows)
                      DataRow2(
                        cells: [
                          DataCell(Text(DateFormatter.shortDate(r.date))),
                          DataCell(Text(fmt.format(r.expectedCash))),
                          DataCell(Text(fmt.format(r.countedCash))),
                          DataCell(Text(fmt.format(r.variance))),
                          DataCell(Text(r.status)),
                        ],
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
