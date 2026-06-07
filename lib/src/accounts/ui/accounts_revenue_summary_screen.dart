import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/accounts/widgets/accounts_kpi_grid.dart';
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';
import 'package:helty/src/models/billing_analytics_models.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/billing_analytics_service.dart';

@RoutePage()
class AccountsRevenueSummaryScreen extends ConsumerStatefulWidget {
  const AccountsRevenueSummaryScreen({super.key});

  @override
  ConsumerState<AccountsRevenueSummaryScreen> createState() =>
      _AccountsRevenueSummaryScreenState();
}

class _AccountsRevenueSummaryScreenState
    extends ConsumerState<AccountsRevenueSummaryScreen> {
  final _analytics = BillingAnalyticsService();
  String _period = 'today';
  bool _loading = true;
  String? _error;
  RevenueSummary? _revenue;
  UnpaidSummary? _unpaid;
  OverdueSummary? _overdue;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final asOf = DateTime.now();
      final results = await Future.wait([
        _analytics.getRevenueSummary(period: _period, asOf: asOf),
        _analytics.getUnpaidSummary(period: _period, asOf: asOf),
        _analytics.getOverdueSummary(period: _period, asOf: asOf),
      ]);
      if (!mounted) return;
      setState(() {
        _revenue = results[0] as RevenueSummary;
        _unpaid = results[1] as UnpaidSummary;
        _overdue = results[2] as OverdueSummary;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(authProvider).staff;
    if (!canAccessAccountsModule(staff)) {
      return const AccountsAccessDenied(title: 'Revenue summary');
    }
    if (canViewFullRevenueAnalytics(staff)) {
      return const AccountsAccessDenied(
        title: 'Revenue summary',
        message: 'Use Revenue Analytics for the full dashboard.',
      );
    }

    final fmt = accountsNairaFormat();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Revenue summary'),
        backgroundColor: AccountsPalette.primary.withValues(alpha: 0.08),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                        spacing: 8,
                        children: [
                          for (final p in ['today', 'week', 'month'])
                            FilterChip(
                              label: Text(p),
                              selected: _period == p,
                              onSelected: (_) {
                                setState(() => _period = p);
                                _load();
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      AccountsKpiGrid(
                        tiles: [
                          AccountsKpiTile(
                            label: 'Revenue',
                            value: fmt.format(_revenue?.current ?? 0),
                            icon: Icons.trending_up_rounded,
                          ),
                          AccountsKpiTile(
                            label: 'Unpaid',
                            value: fmt.format(
                              _unpaid?.outstandingAmount.current ?? 0,
                            ),
                            icon: Icons.pending_actions_rounded,
                          ),
                          AccountsKpiTile(
                            label: 'Overdue',
                            value: fmt.format(
                              _overdue?.overdueStock.outstandingTotal ?? 0,
                            ),
                            icon: Icons.warning_amber_rounded,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
    );
  }
}
