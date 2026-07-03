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
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsChartOfAccountsScreen extends ConsumerStatefulWidget {
  const AccountsChartOfAccountsScreen({super.key});

  @override
  ConsumerState<AccountsChartOfAccountsScreen> createState() =>
      _AccountsChartOfAccountsScreenState();
}

class _AccountsChartOfAccountsScreenState
    extends ConsumerState<AccountsChartOfAccountsScreen> {
  final _codeCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  String _type = 'asset';

  @override
  void dispose() {
    _codeCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!canManageChartOfAccounts(ref.read(authProvider).staff)) return;
    try {
      await AccountsReportsService().createChartAccount(
        code: _codeCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        type: _type,
      );
      ref.invalidate(accountsChartOfAccountsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created')),
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
    if (!canManageChartOfAccounts(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(title: 'Chart of accounts');
    }
    final async = ref.watch(accountsChartOfAccountsProvider);
    final fmt = accountsNairaFormat();

    return AccountsAsyncScaffold(
      title: 'Chart of accounts',
      colors: AccountsPalette.reports,
      asyncValue: async,
      onRetry: () => ref.invalidate(accountsChartOfAccountsProvider),
      builder: (context, accounts) {
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
                      'Add account',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _codeCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Code',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        DropdownButton<String>(
                          value: _type,
                          items: const [
                            DropdownMenuItem(
                              value: 'asset',
                              child: Text('Asset'),
                            ),
                            DropdownMenuItem(
                              value: 'liability',
                              child: Text('Liability'),
                            ),
                            DropdownMenuItem(
                              value: 'equity',
                              child: Text('Equity'),
                            ),
                            DropdownMenuItem(
                              value: 'revenue',
                              child: Text('Revenue'),
                            ),
                            DropdownMenuItem(
                              value: 'expense',
                              child: Text('Expense'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _type = v);
                          },
                        ),
                        const SizedBox(width: 12),
                        FilledButton(
                          onPressed: _create,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (accounts.isEmpty)
              const Expanded(
                child: AccountsEmptyState(
                  title: 'No Chart of accounts',
                  subtitle: 'No records for the selected filters.',
                ),
              )
            else
              Expanded(
                child: AccountsDataTableBox(
                  child: DataTable2(
                  columns: const [
                    DataColumn2(label: Text('Code'), size: ColumnSize.S),
                    DataColumn2(label: Text('Name'), size: ColumnSize.L),
                    DataColumn2(label: Text('Type'), size: ColumnSize.S),
                    DataColumn2(label: Text('Balance'), size: ColumnSize.S),
                    DataColumn2(label: Text('Active'), size: ColumnSize.S),
                  ],
                  rows: [
                    for (final a in accounts)
                      DataRow2(
                        cells: [
                          DataCell(Text(a.code)),
                          DataCell(Text(a.name)),
                          DataCell(Text(a.type)),
                          DataCell(Text(fmt.format(a.balance))),
                          DataCell(
                            Icon(
                              a.isActive
                                  ? Icons.check_circle_outline
                                  : Icons.cancel_outlined,
                              size: 18,
                            ),
                          ),
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
