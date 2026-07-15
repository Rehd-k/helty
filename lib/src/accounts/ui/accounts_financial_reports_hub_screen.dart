import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsFinancialReportsHubScreen extends ConsumerWidget {
  const AccountsFinancialReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(authProvider).staff;
    if (!canAccessAccountsModule(staff)) {
      return const AccountsAccessDenied(title: 'Financial reports');
    }
    final isHead = canViewAccountsHeadData(staff);
    final theme = Theme.of(context);

    final reports = <_ReportTile>[
      _ReportTile(
        'Daily collections',
        Icons.calendar_today_rounded,
        const AccountsDailyCollectionsRoute(),
        true,
      ),
      _ReportTile(
        'AR aging',
        Icons.hourglass_bottom_rounded,
        const AccountsAgingReportRoute(),
        true,
      ),
      _ReportTile(
        'Collection efficiency',
        Icons.speed_rounded,
        const AccountsCollectionEfficiencyRoute(),
        true,
      ),
      _ReportTile(
        'Revenue by department',
        Icons.pie_chart_outline_rounded,
        const BillingDashboardRoute(),
        true,
      ),
      if (isHead) ...[
        _ReportTile(
          'Profit & loss',
          Icons.assessment_rounded,
          const AccountsProfitLossRoute(),
          true,
        ),
        _ReportTile(
          'Cash flow',
          Icons.waterfall_chart_rounded,
          const AccountsCashFlowRoute(),
          true,
        ),
        _ReportTile(
          'Revenue by service',
          Icons.category_rounded,
          const AccountsRevenueByServiceRoute(),
          true,
        ),
        _ReportTile(
          'Expense vs budget',
          Icons.compare_arrows_rounded,
          const AccountsExpenseVsBudgetRoute(),
          true,
        ),
        _ReportTile(
          'Period comparison',
          Icons.show_chart_rounded,
          const AccountsPeriodComparisonRoute(),
          true,
        ),
        _ReportTile(
          'Payment method mix',
          Icons.account_balance_wallet_outlined,
          const AccountsPaymentMixRoute(),
          true,
        ),
      ],
      _ReportTile(
        'Consultation payments',
        Icons.receipt_long_outlined,
        const ConsultationPaymentReportRoute(),
        true,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Financial reports'),
        backgroundColor: AccountsPalette.primary.withValues(alpha: 0.08),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Select a report to view and export.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: reports.length,
            itemBuilder: (context, i) {
              final r = reports[i];
              return Card(
                elevation: 0,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: InkWell(
                  onTap: () => context.router.push(r.route),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(r.icon, color: AccountsPalette.primary, size: 32),
                        const Spacer(),
                        Text(
                          r.title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ReportTile {
  const _ReportTile(this.title, this.icon, this.route, this.available);
  final String title;
  final IconData icon;
  final PageRouteInfo route;
  final bool available;
}
