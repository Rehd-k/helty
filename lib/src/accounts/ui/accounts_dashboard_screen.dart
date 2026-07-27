import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/models/accounts_models.dart';
import 'package:helty/src/accounts/providers/accounts_providers.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/accounts/widgets/accounts_async_scaffold.dart';
import 'package:helty/src/accounts/widgets/accounts_kpi_grid.dart';
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';
import 'package:helty/src/accounts/widgets/accounts_period_selector.dart';
import 'package:helty/src/accounts/widgets/accounts_section_header.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/shared/department_colors.dart';

@RoutePage()
class AccountsDashboardScreen extends ConsumerWidget {
  const AccountsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(authProvider).staff;
    if (!canAccessAccountsModule(staff)) {
      return const AccountsAccessDenied(title: 'Accounts & Audit');
    }

    final isHead = canViewAccountsHeadData(staff);
    final async = ref.watch(accountsDashboardProvider);

    return AccountsAsyncScaffold<AccountsDashboardBundle>(
      title: 'Accounts & Audit',
      subtitle: isHead
          ? 'Financial command overview · All figures in Nigerian Naira (₦)'
          : 'Operational finance workspace',
      asyncValue: async,
      colors: AccountsPalette.dashboard,
      header: const AccountsPeriodSelector(),
      onRetry: () => ref.invalidate(accountsDashboardProvider),
      builder: (context, data) {
        final fmt = accountsNairaFormat();
        final tiles = isHead
            ? _headKpis(data, fmt, context)
            : _staffKpis(data, fmt, context);

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AccountsKpiGrid(tiles: tiles),
              const SizedBox(height: 28),
              AccountsSectionHeader(
                icon: Icons.bolt_rounded,
                title: 'Quick actions',
                subtitle:
                    'Jump to collections, receivables, reports, and audit',
              ),
              const SizedBox(height: 16),
              _QuickActionsGrid(isHead: isHead),
              const SizedBox(height: 28),
              AccountsSectionHeader(
                icon: Icons.history_rounded,
                title: 'Recent activity',
                subtitle: 'Latest financial events',
              ),
              const SizedBox(height: 12),
              _ActivityFeed(items: data.activityFeed, fmt: fmt),
            ],
          ),
        );
      },
    );
  }

  List<AccountsKpiTile> _headKpis(
    AccountsDashboardBundle data,
    NumberFormat fmt,
    BuildContext context,
  ) {
    return [
      AccountsKpiTile(
        label: 'Gross revenue',
        value: fmt.format(data.grossRevenue),
        icon: Icons.trending_up_rounded,
        onTap: () => context.router.push(const BillingDashboardRoute()),
      ),
      AccountsKpiTile(
        label: 'Net collections',
        value: fmt.format(data.netCollections),
        icon: Icons.payments_rounded,
        accent: AccountsPalette.secondary,
        onTap: () => context.router.push(const TransactionsRoute()),
      ),
      AccountsKpiTile(
        label: 'Outstanding AR',
        value: fmt.format(data.outstandingAr),
        icon: Icons.account_balance_wallet_outlined,
        onTap: () => context.router.push(const AccountsAgingReportRoute()),
      ),
      AccountsKpiTile(
        label: 'Overdue',
        value: fmt.format(data.overdueAmount),
        icon: Icons.warning_amber_rounded,
        accent: DepartmentColors.billing,
      ),
      AccountsKpiTile(
        label: 'HMO receivables',
        value: fmt.format(data.hmoReceivables),
        icon: Icons.health_and_safety_outlined,
        onTap: () => context.router.push(const ReceivablesHmoRoute()),
      ),
      AccountsKpiTile(
        label: 'Discount receivables',
        value: fmt.format(data.discountReceivables),
        icon: Icons.sell_outlined,
        onTap: () => context.router.push(const ReceivablesDiscountRoute()),
      ),
      AccountsKpiTile(
        label: 'Wallet float',
        value: fmt.format(data.walletFloat),
        icon: Icons.account_balance_rounded,
        onTap: () => context.router.push(const AccountsWalletsOverviewRoute()),
      ),
      AccountsKpiTile(
        label: 'Pending approvals',
        value: data.pendingApprovalsCount.toString(),
        icon: Icons.fact_check_outlined,
        onTap: () => context.router.push(const AccountsApprovalsRoute()),
      ),
      if (data.leakAlertsCount > 0)
        AccountsKpiTile(
          label: 'Leak alerts',
          value: data.leakAlertsCount.toString(),
          icon: Icons.shield_outlined,
          accent: DepartmentColors.billing,
          onTap: () => context.router.push(const AccountsLeakDetectionRoute()),
        ),
    ];
  }

  List<AccountsKpiTile> _staffKpis(
    AccountsDashboardBundle data,
    NumberFormat fmt,
    BuildContext context,
  ) {
    return [
      AccountsKpiTile(
        label: "Today's collections",
        value: fmt.format(data.netCollections),
        icon: Icons.payments_rounded,
        onTap: () => context.router.push(const TransactionsRoute()),
      ),
      AccountsKpiTile(
        label: 'Pending receivables',
        value: fmt.format(data.hmoReceivables + data.discountReceivables),
        icon: Icons.receipt_long_outlined,
        onTap: () => context.router.push(const ReceivablesHmoRoute()),
      ),
      AccountsKpiTile(
        label: 'Remittances due',
        value: fmt.format(data.remittancesDue),
        icon: Icons.send_rounded,
      ),
      AccountsKpiTile(
        label: 'Recent payments',
        value: data.recentPaymentsCount.toString(),
        icon: Icons.history_rounded,
        onTap: () => context.router.push(const TransactionsRoute()),
      ),
    ];
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({required this.isHead});

  final bool isHead;

  @override
  Widget build(BuildContext context) {
    final actions = <_Action>[
      _Action(
        'Collections ledger',
        Icons.list_alt_rounded,
        const TransactionsRoute(),
      ),
      _Action(
        'HMO receivables',
        Icons.health_and_safety_outlined,
        const ReceivablesHmoRoute(),
      ),
      _Action(
        'Discount receivables',
        Icons.sell_outlined,
        const ReceivablesDiscountRoute(),
      ),
      _Action(
        'Daily collections',
        Icons.calendar_today_rounded,
        const AccountsDailyCollectionsRoute(),
      ),
      _Action(
        'AR aging',
        Icons.hourglass_bottom_rounded,
        const AccountsAgingReportRoute(),
      ),
      _Action(
        'Financial reports',
        Icons.assessment_rounded,
        const AccountsFinancialReportsHubRoute(),
      ),
      _Action('Audit log', Icons.policy_rounded, const AccountsAuditLogRoute()),
      _Action(
        'Compliance',
        Icons.verified_user_outlined,
        const AccountsComplianceRoute(),
      ),
      _Action(
        'Consultation report',
        Icons.receipt_long_outlined,
        const ConsultationPaymentReportRoute(),
      ),
      _Action(
        'Bank accounts',
        Icons.account_balance_outlined,
        const AccountsBanksRoute(),
      ),
      _Action(
        'Patient wallets',
        Icons.wallet_rounded,
        const AccountsWalletsOverviewRoute(),
      ),
      _Action(
        'Cash reconciliation',
        Icons.calculate_rounded,
        const AccountsDailyCashReconRoute(),
      ),
      if (isHead) ...[
        _Action(
          'Revenue analytics',
          Icons.bar_chart_rounded,
          const BillingDashboardRoute(),
        ),
        _Action(
          'Approvals',
          Icons.fact_check_outlined,
          const AccountsApprovalsRoute(),
        ),
        _Action(
          'Period close',
          Icons.lock_clock_rounded,
          const AccountsPeriodCloseRoute(),
        ),
        _Action(
          'Journal entries',
          Icons.menu_book_rounded,
          const AccountsJournalEntriesRoute(),
        ),
        _Action(
          'Chart of accounts',
          Icons.account_tree_rounded,
          const AccountsChartOfAccountsRoute(),
        ),
        _Action(
          'Leak detection',
          Icons.shield_outlined,
          const AccountsLeakDetectionRoute(),
        ),
      ] else
        _Action(
          'Revenue summary',
          Icons.insights_outlined,
          const AccountsRevenueSummaryRoute(),
        ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final a in actions)
          ActionChip(
            avatar: Icon(a.icon, size: 18),
            label: Text(a.label),
            onPressed: () => context.router.push(a.route),
          ),
      ],
    );
  }
}

class _Action {
  const _Action(this.label, this.icon, this.route);
  final String label;
  final IconData icon;
  final PageRouteInfo route;
}

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.items, required this.fmt});

  final List<AccountsActivityItem> items;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No recent activity for this period.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final item = items[i];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AccountsPalette.primary.withValues(alpha: 0.12),
              child: Icon(
                _iconFor(item.category),
                color: AccountsPalette.primary,
                size: 20,
              ),
            ),
            title: Text(item.message),
            subtitle: Text(
              '${item.actorLabel} · ${DateFormatter.dateTimeWithSeconds(item.at)}',
            ),
            trailing: item.amount != null
                ? Text(
                    fmt.format(item.amount),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }

  IconData _iconFor(String category) {
    switch (category.toLowerCase()) {
      case 'payment':
        return Icons.payments_rounded;
      case 'remittance':
        return Icons.send_rounded;
      case 'refund':
        return Icons.undo_rounded;
      case 'revenue':
        return Icons.trending_up_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }
}
