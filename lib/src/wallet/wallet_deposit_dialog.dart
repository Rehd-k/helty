import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/invoice_billing_models.dart';
import '../providers/auth_provider.dart';
import '../providers/invoices_providers.dart';
import 'wallet_providers.dart';
import 'wallet_receipt_helper.dart';

class WalletDepositDialog {
  static Future<WalletDepositResponse?> show(
    BuildContext context, {
    required WidgetRef ref,
    required String patientUuid,
    required String patientName,
    String? chartNumber,
    bool offerReceipt = true,
    VoidCallback? onSuccess,
  }) async {
    final amountCtrl = TextEditingController();
    final referenceCtrl = TextEditingController();
    var busy = false;

    final result = await showDialog<WalletDepositResponse?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Fund wallet'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                controller: referenceCtrl,
                decoration: const InputDecoration(
                  labelText: 'Reference (optional)',
                  hintText: 'Defaults to deposit',
                ),
                enabled: !busy,
              ),
            ],
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
                            content: Text('Enter a valid deposit amount.'),
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
                      setState(() => busy = true);
                      try {
                        final auth = ref.read(authProvider);
                        final reference = referenceCtrl.text.trim();
                        final response = await ref
                            .read(invoiceNotifierProvider.notifier)
                            .depositWallet(
                              patientId: patientUuid,
                              payload: WalletDepositPayload(
                                amount: amount,
                                reference: reference.isEmpty
                                    ? 'deposit'
                                    : reference,
                                staffId: auth.staff?.id,
                              ),
                            );
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx, response);
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(content: Text('Deposit failed: $e')),
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
                  : const Text('Deposit'),
            ),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      invalidatePatientWalletHistory(ref, patientUuid);
      onSuccess?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wallet funded successfully.')),
      );
      if (offerReceipt) {
        await WalletReceiptHelper.printFromAuth(
          context: context,
          ref: ref,
          transaction: result.transaction,
          patientName: patientName,
          chartNumber: chartNumber ?? '',
          balanceAfter: result.wallet.balance,
        );
      }
    }
    return result;
  }
}
