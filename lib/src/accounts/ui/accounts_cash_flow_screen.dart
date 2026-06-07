import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/models/accounts_models.dart';
import 'package:helty/src/accounts/providers/accounts_providers.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/accounts/widgets/accounts_async_scaffold.dart';
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';
import 'package:helty/src/accounts/widgets/accounts_period_selector.dart';
import 'package:helty/src/accounts/widgets/accounts_section_header.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsCashFlowScreen extends ConsumerWidget {
  const AccountsCashFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(authProvider).staff;
    if (!canViewProfitLoss(staff)) {
      return const AccountsAccessDenied(title: 'Cash flow statement');
    }
    final async = ref.watch(accountsCashFlowProvider);
    final fmt = accountsNairaFormat();

    return AccountsAsyncScaffold<AccountsCashFlowReport>(
      title: 'Cash flow statement',
      subtitle: 'Operating, investing, and financing activities',
      colors: AccountsPalette.reports,
      asyncValue: async,
      header: const AccountsPeriodSelector(),
      onRetry: () => ref.invalidate(accountsCashFlowProvider),
      builder: (context, data) {
        if (data.operating.isEmpty) {
          return const AccountsEmptyState(title: 'No Cash flow statement', subtitle: 'No records for the selected filters.');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _summaryRow('Opening balance', data.openingBalance, fmt),
            _summaryRow('Net change', data.netChange, fmt),
            _summaryRow('Closing balance', data.closingBalance, fmt),
            const SizedBox(height: 20),
            const AccountsSectionHeader(
              icon: Icons.sync_alt_rounded,
              title: 'Operating activities',
            ),
            ..._lines(data.operating, fmt),
            const AccountsSectionHeader(
              icon: Icons.business_center_outlined,
              title: 'Investing activities',
            ),
            ..._lines(data.investing, fmt),
            const AccountsSectionHeader(
              icon: Icons.account_balance_rounded,
              title: 'Financing activities',
            ),
            ..._lines(data.financing, fmt),
          ],
        );
      },
    );
  }

  Widget _summaryRow(String label, double amount, NumberFormat fmt) {
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text(fmt.format(amount)),
      ),
    );
  }

  List<Widget> _lines(List<AccountsReportLine> lines, NumberFormat fmt) {
    return lines
        .map((l) => ListTile(
              title: Text(l.label),
              trailing: Text(fmt.format(l.amount)),
            ))
        .toList();
  }
}
