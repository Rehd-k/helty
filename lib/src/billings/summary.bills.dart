import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/extensions/number.extention.dart';

// Assuming these exist based on your snippet
import 'package:helty/src/shared/finance_status_colors.dart';

import '../models/invoice.dart';
import '../printing/escpos/unpaid_invoice_print.dart';
import '../providers/auth_provider.dart';
import '../widgets/grid.widgets.dart';
import 'pending.bills.dart';

class SummaryBills extends ConsumerWidget {
  final Invoice invoice;

  const SummaryBills({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Text(
              "Bill Summary",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // The Grid Widget (Preserving your external widget)
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: buildModernGrid(invoice, (int _) {}, context),
              ),
            ),

            const SizedBox(height: 16),

            // Financial Breakdown
            // _buildRow('Subtotal', patient.amountDue.toFinancial(isMoney: true)),
            _buildRow(context, 'Tax', '0', isDiscount: false),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Divider(height: 1),
            ),

            // Total Row
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Total Amount',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    invoice.total.toFinancial(isMoney: true),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            LayoutBuilder(
              builder: (context, constraints) {
                final printButton = OutlinedButton.icon(
                  onPressed: () => printUnpaidInvoice(context, invoice),
                  icon: const Icon(Icons.print_outlined, size: 18),
                  label: const Text(
                    'Print invoice',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
                final payButton = FilledButton.icon(
                  onPressed: () =>
                      openCustomModal(context, invoice, auth.staff?.id ?? ''),
                  icon: const Icon(Icons.payment, size: 18),
                  label: const Text(
                    'Proceed to Payment',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
                if (constraints.maxWidth < 420) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(height: 50, child: printButton),
                      const SizedBox(height: 12),
                      SizedBox(height: 50, child: payButton),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(child: SizedBox(height: 50, child: printButton)),
                    const SizedBox(width: 12),
                    Expanded(child: SizedBox(height: 50, child: payButton)),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String value, {
    bool isDiscount = false,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final discountColor = FinanceStatusColors.discount(scheme);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDiscount ? discountColor : scheme.onSurfaceVariant,
                fontWeight: isDiscount ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDiscount ? discountColor : scheme.onSurface,
                fontWeight: isDiscount ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
