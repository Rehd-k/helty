import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/accounts/widgets/accounts_money_format.dart';

import '../models/invoice_billing_models.dart';
import '../providers/auth_provider.dart';
import '../providers/invoices_providers.dart';
import 'wallet_providers.dart';

class WalletAdjustDialog {
  static Future<WalletAdjustResponse?> show(
    BuildContext context, {
    required WidgetRef ref,
    required String patientUuid,
    required String patientName,
    required double currentBalance,
    VoidCallback? onSuccess,
  }) async {
    final amountCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    var type = 'CREDIT';
    var busy = false;
    final fmt = accountsNairaFormat();

    final result = await showDialog<WalletAdjustResponse?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Adjust wallet'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Current balance: ${fmt.format(currentBalance)}',
                  style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (patientName.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    patientName,
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                ],
                const SizedBox(height: 16),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'CREDIT',
                      label: Text('Credit'),
                      icon: Icon(Icons.add_circle_outline),
                    ),
                    ButtonSegment(
                      value: 'DEBIT',
                      label: Text('Debit'),
                      icon: Icon(Icons.remove_circle_outline),
                    ),
                  ],
                  selected: {type},
                  onSelectionChanged: busy
                      ? null
                      : (s) => setState(() => type = s.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₦ ',
                  ),
                  enabled: !busy,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reason (required)',
                    hintText: 'e.g. Correction: duplicate deposit',
                  ),
                  enabled: !busy,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: busy ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: busy
                  ? null
                  : () async {
                      final amount = double.tryParse(amountCtrl.text.trim());
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Enter a valid adjustment amount.'),
                          ),
                        );
                        return;
                      }
                      final reason = reasonCtrl.text.trim();
                      if (reason.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('A reason is required.'),
                          ),
                        );
                        return;
                      }
                      if (patientUuid.trim().isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('Patient UUID is required.'),
                          ),
                        );
                        return;
                      }
                      if (type == 'DEBIT' && amount > currentBalance + 0.001) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Debit exceeds balance (${fmt.format(currentBalance)}).',
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() => busy = true);
                      try {
                        final auth = ref.read(authProvider);
                        final response = await ref
                            .read(invoiceNotifierProvider.notifier)
                            .adjustWallet(
                              patientId: patientUuid,
                              payload: WalletAdjustPayload(
                                amount: amount,
                                type: type,
                                reference: reason,
                                staffId: auth.staff?.id,
                              ),
                            );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx, response);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Adjust failed: $e')),
                          );
                          setState(() => busy = false);
                        }
                      }
                    },
              child: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(type == 'DEBIT' ? 'Debit' : 'Credit'),
            ),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      invalidatePatientWalletHistory(ref, patientUuid);
      onSuccess?.call();
      final verb = result.transaction.isDebit ? 'debited' : 'credited';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Wallet $verb successfully.')),
      );
    }
    return result;
  }
}
