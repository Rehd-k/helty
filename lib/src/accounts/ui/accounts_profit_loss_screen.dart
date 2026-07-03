import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
class AccountsProfitLossScreen extends ConsumerWidget {
  const AccountsProfitLossScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(authProvider).staff;
    if (!canAccessAccountsModule(staff)) {
      return const AccountsAccessDenied(title: 'Profit & loss');
    }
    if (!canViewProfitLoss(staff)) {
      return const AccountsAccessDenied(
        title: 'Profit & loss',
        message: 'Only the Account Head can view profit & loss statements.',
      );
    }

    final async = ref.watch(accountsProfitLossProvider);
    final fmt = accountsNairaFormat();

    return AccountsAsyncScaffold<AccountsProfitLossReport>(
      title: 'Profit & loss',
      subtitle: 'Revenue and expense summary',
      colors: AccountsPalette.reports,
      asyncValue: async,
      header: const AccountsPeriodSelector(),
      onRetry: () => ref.invalidate(accountsProfitLossProvider),
      builder: (context, data) {
        if (data.revenueLines.isEmpty && data.expenseLines.isEmpty) {
          return const AccountsEmptyState(title: 'No Profit & loss report', subtitle: 'No records for the selected filters.');
        }
        return SingleChildScrollView(
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: ListTile(
                title: const Text('Net profit'),
                trailing: Text(
                  fmt.format(data.netProfit),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AccountsPalette.primary,
                      ),
                ),
                subtitle: Text(
                  'Gross margin: ${data.grossMarginPercent.toStringAsFixed(1)}%',
                ),
              ),
            ),
            const SizedBox(height: 20),
            const AccountsSectionHeader(
              icon: Icons.trending_up_rounded,
              title: 'Revenue',
            ),
            const SizedBox(height: 8),
            ..._lines(data.revenueLines, fmt),
            const SizedBox(height: 20),
            const AccountsSectionHeader(
              icon: Icons.trending_down_rounded,
              title: 'Expenses',
            ),
            const SizedBox(height: 8),
            ..._lines(data.expenseLines, fmt),
          ],
        ),
        );
      },
    );
  }

  List<Widget> _lines(List<AccountsReportLine> lines, NumberFormat fmt) {
    return lines
        .map(
          (l) => ListTile(
            title: Text(
              l.label,
              style: TextStyle(
                fontWeight: l.isHeader == true || l.isTotal == true
                    ? FontWeight.w700
                    : FontWeight.normal,
              ),
            ),
            trailing: Text(fmt.format(l.amount)),
          ),
        )
        .toList();
  }
}
