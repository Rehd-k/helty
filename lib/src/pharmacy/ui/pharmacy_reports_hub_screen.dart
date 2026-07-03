import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/app_router.gr.dart';

import '../../providers/auth_provider.dart';
import '../../providers/super_admin_preview_provider.dart';
import '../auth/pharmacy_permissions.dart';
import '../services/pharmacy_reports_service.dart';

@RoutePage()
class PharmacyReportsHubScreen extends ConsumerWidget {
  const PharmacyReportsHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(authProvider).staff;
    final preview = ref.watch(superAdminPreviewProvider);
    if (!canViewPharmacyFinancialReports(staff, preview)) {
      return _denied(context);
    }

    final theme = Theme.of(context);
    final reports = <_ReportTile>[
      _ReportTile(
        'Sales by drug',
        Icons.medication_outlined,
        PharmacySalesBreakdownRoute(
          initialGroupBy: PharmacySalesGroupBy.drug,
        ),
      ),
      _ReportTile(
        'Sales by therapeutic class',
        Icons.category_rounded,
        PharmacySalesBreakdownRoute(
          initialGroupBy: PharmacySalesGroupBy.therapeuticClass,
        ),
      ),
      _ReportTile(
        'Sales by payer',
        Icons.account_balance_wallet_outlined,
        PharmacySalesBreakdownRoute(
          initialGroupBy: PharmacySalesGroupBy.payer,
        ),
      ),
      _ReportTile(
        'Sales by dispensary',
        Icons.store_mall_directory_outlined,
        PharmacySalesBreakdownRoute(
          initialGroupBy: PharmacySalesGroupBy.dispensary,
        ),
      ),
      _ReportTile(
        'Inventory valuation',
        Icons.warehouse_rounded,
        PharmacyInventoryValuationRoute(),
      ),
      _ReportTile(
        'Dispense history',
        Icons.receipt_long_outlined,
        DispenseHistoryRoute(),
      ),
      const _ReportTile(
        'Supply history',
        Icons.list_alt_outlined,
        SupplyHistoryRoute(),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Pharmacy reports'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Sales, profit and inventory reports for the head of pharmacy.',
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
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: InkWell(
                  onTap: () => context.router.push(r.route),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(r.icon, color: theme.colorScheme.primary),
                        Text(
                          r.label,
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

  Widget _denied(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Pharmacy reports'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'These reports are available to the head of pharmacy only.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReportTile {
  const _ReportTile(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final PageRouteInfo route;
}
