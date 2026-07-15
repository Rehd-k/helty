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
class AccountsJournalEntriesScreen extends ConsumerStatefulWidget {
  const AccountsJournalEntriesScreen({super.key});

  @override
  ConsumerState<AccountsJournalEntriesScreen> createState() =>
      _AccountsJournalEntriesScreenState();
}

class _AccountsJournalEntriesScreenState
    extends ConsumerState<AccountsJournalEntriesScreen> {
  final _refCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _debitCtrl = TextEditingController();
  final _creditCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  @override
  void dispose() {
    _refCtrl.dispose();
    _descCtrl.dispose();
    _debitCtrl.dispose();
    _creditCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _post() async {
    if (!canPostJournalEntries(ref.read(authProvider).staff)) return;
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null) return;
    try {
      await AccountsReportsService().postJournalEntry(
        entryDate: DateTime.now(),
        reference: _refCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        debitAccount: _debitCtrl.text.trim(),
        creditAccount: _creditCtrl.text.trim(),
        amount: amount,
      );
      ref.invalidate(accountsJournalEntriesProvider);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Journal entry posted')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(authProvider).staff;
    if (!canViewJournalEntries(staff)) {
      return const AccountsAccessDenied(title: 'Journal entries');
    }
    final canPost = canPostJournalEntries(staff);
    final async = ref.watch(accountsJournalEntriesProvider);
    final fmt = accountsNairaFormat();

    return AccountsAsyncScaffold(
      title: 'Journal entries',
      subtitle: canPost
          ? 'General ledger postings'
          : 'View-only · General ledger postings',
      colors: AccountsPalette.reports,
      asyncValue: async,
      onRetry: () => ref.invalidate(accountsJournalEntriesProvider),
      builder: (context, entries) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (canPost)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'New journal entry',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _refCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Reference',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _debitCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Debit account',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _creditCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Credit account',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Amount (₦)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: _post,
                        child: const Text('Post entry'),
                      ),
                    ],
                  ),
                ),
              ),
            if (canPost) const SizedBox(height: 24),
            if (entries.isEmpty)
              const Expanded(
                child: AccountsEmptyState(
                  title: 'No Journal entries',
                  subtitle: 'No records for the selected filters.',
                ),
              )
            else
              Expanded(
                child: AccountsDataTableBox(
                  child: DataTable2(
                    minWidth: 1000,
                    columns: const [
                      DataColumn2(label: Text('Date'), size: ColumnSize.S),
                      DataColumn2(label: Text('Ref'), size: ColumnSize.S),
                      DataColumn2(label: Text('Debit'), size: ColumnSize.S),
                      DataColumn2(label: Text('Credit'), size: ColumnSize.S),
                      DataColumn2(label: Text('Amount'), size: ColumnSize.S),
                      DataColumn2(label: Text('Status'), size: ColumnSize.S),
                    ],
                    rows: [
                      for (final e in entries)
                        DataRow2(
                          cells: [
                            DataCell(
                              Text(DateFormatter.shortDate(e.entryDate)),
                            ),
                            DataCell(Text(e.reference)),
                            DataCell(Text(e.debitAccount)),
                            DataCell(Text(e.creditAccount)),
                            DataCell(Text(fmt.format(e.amount))),
                            DataCell(Text(e.status)),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
