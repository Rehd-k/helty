import 'package:auto_route/auto_route.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/providers/accounts_providers.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/accounts/widgets/accounts_async_scaffold.dart';
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';
import 'package:helty/src/accounts/widgets/accounts_period_selector.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsPaymentMixScreen extends ConsumerWidget {
  const AccountsPaymentMixScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canViewProfitLoss(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(title: 'Payment method mix');
    }
    final async = ref.watch(accountsDashboardProvider);
    final fmt = accountsNairaFormat();

    return AccountsAsyncScaffold(
      title: 'Payment method mix',
      subtitle: 'Collections split by payment type',
      colors: AccountsPalette.reports,
      asyncValue: async,
      header: const AccountsPeriodSelector(),
      onRetry: () => ref.invalidate(accountsDashboardProvider),
      builder: (context, data) {
        final mix = data.paymentMixSnapshot;
        if (mix.isEmpty) {
          return const AccountsEmptyState(
            title: 'No payment mix data',
            subtitle: 'No collections recorded for the selected period.',
            icon: Icons.pie_chart_outline_rounded,
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 720;
            final chart = SizedBox(
              height: narrow ? 220 : 260,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  sections: [
                    for (var i = 0; i < mix.length; i++)
                      PieChartSectionData(
                        value: mix[i].amount > 0 ? mix[i].amount : 0.01,
                        title: '${mix[i].percent.toStringAsFixed(0)}%',
                        color: _color(i),
                        radius: narrow ? 70 : 90,
                        titleStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            );
            final legend = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < mix.length; i++)
                  ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      backgroundColor: _color(i),
                      radius: 8,
                    ),
                    title: Text(mix[i].method),
                    trailing: Text(
                      fmt.format(mix[i].amount),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            );
            if (narrow) {
              return Column(children: [chart, const SizedBox(height: 16), legend]);
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: chart),
                Expanded(child: legend),
              ],
            );
          },
        );
      },
    );
  }

  Color _color(int i) {
    const colors = [
      AccountsPalette.primary,
      AccountsPalette.secondary,
      AccountsPalette.accent,
      Color(0xFF2DD4BF),
      Color(0xFF34D399),
    ];
    return colors[i % colors.length];
  }
}
