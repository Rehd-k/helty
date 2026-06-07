import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/accounts/accounts_palette.dart';
import 'package:helty/src/accounts/auth/accounting_permissions.dart';
import 'package:helty/src/accounts/providers/accounts_providers.dart';
import 'package:helty/src/accounts/widgets/accounts_access_denied.dart';
import 'package:helty/src/accounts/widgets/accounts_async_scaffold.dart';
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';
import 'package:helty/src/providers/auth_provider.dart';

@RoutePage()
class AccountsLeakDetectionScreen extends ConsumerWidget {
  const AccountsLeakDetectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canViewLeakDetection(ref.watch(authProvider).staff)) {
      return const AccountsAccessDenied(
        title: 'Leak detection',
        message: 'Only the Account Head can view leak detection.',
      );
    }
    final async = ref.watch(accountsLeakDetectionProvider);
    final fmt = accountsNairaFormat();

    return AccountsAsyncScaffold(
      title: 'Leak detection',
      subtitle: 'Estimated revenue exposure — review with finance',
      colors: AccountsPalette.audit,
      asyncValue: async,
      onRetry: () => ref.invalidate(accountsLeakDetectionProvider),
      builder: (context, leaks) {
        if (leaks.isEmpty) {
          return const AccountsEmptyState(title: 'No Leak detection', subtitle: 'No records for the selected filters.');
        }
        return Column(
          children: [
            for (final l in leaks)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(
                    Icons.shield_outlined,
                    color: l.severity == 'high'
                        ? Colors.red
                        : l.severity == 'medium'
                            ? Colors.orange
                            : AccountsPalette.primary,
                  ),
                  title: Text(l.title),
                  subtitle: Text(l.description),
                  trailing: Text(
                    fmt.format(l.estimatedExposure),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
