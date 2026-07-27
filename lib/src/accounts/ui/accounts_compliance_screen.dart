import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/shared/finance_status_colors.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/models/accounts_models.dart';
import 'package:helty/src/accounts/providers/accounts_providers.dart';
import 'package:helty/src/accounts/services/accounts_audit_service.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/accounts/widgets/accounts_async_scaffold.dart';
import 'package:helty/src/helper/date.formatter.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsComplianceScreen extends ConsumerWidget {
  const AccountsComplianceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(authProvider).staff;
    if (!canAccessAccountsModule(staff)) {
      return const AccountsAccessDenied(title: 'Compliance checklist');
    }
    final async = ref.watch(accountsComplianceProvider);
    final canAck = canAcknowledgeCompliance(staff);

    return AccountsAsyncScaffold<List<AccountsComplianceItem>>(
      title: 'Compliance checklist',
      subtitle: 'Financial controls and regulatory items',
      colors: AccountsPalette.audit,
      asyncValue: async,
      onRetry: () => ref.invalidate(accountsComplianceProvider),
      builder: (context, items) {
        if (items.isEmpty) {
          return const AccountsEmptyState(title: 'No Compliance checklist', subtitle: 'No records for the selected filters.');
        }
        return SingleChildScrollView(
          child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final c in items)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            c.status.toLowerCase().contains('compliant')
                                ? Icons.check_circle_rounded
                                : Icons.warning_amber_rounded,
                            color: c.status.toLowerCase().contains('compliant')
                                ? FinanceStatusColors.success(
                                    Theme.of(context).colorScheme,
                                  )
                                : FinanceStatusColors.warning(
                                    Theme.of(context).colorScheme,
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            c.code,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(c.description),
                      const SizedBox(height: 4),
                      Text('Status: ${c.status}'),
                      if (c.lastCheckedAt != null)
                        Text(
                          'Last checked: ${DateFormatter.dateTimeWithSeconds(c.lastCheckedAt!)}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      if (canAck && c.canAcknowledge) ...[
                        const SizedBox(height: 8),
                        FilledButton.tonal(
                          onPressed: () async {
                            await AccountsAuditService()
                                .acknowledgeCompliance(c.code);
                            ref.invalidate(accountsComplianceProvider);
                          },
                          child: const Text('Acknowledge'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
        );
      },
    );
  }
}
