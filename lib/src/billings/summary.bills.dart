import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/extensions/number.extention.dart';

// Assuming these exist based on your snippet
import 'package:helty/src/shared/finance_status_colors.dart';

import '../models/invoice.dart';
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  invoice.total.toFinancial(isMoney: true),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: scheme.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: () =>
                    openCustomModal(context, invoice, auth.staff?.id ?? ''),
                icon: const Icon(Icons.payment, size: 18),
                label: const Text(
                  'Proceed to Payment',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
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
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDiscount ? discountColor : scheme.onSurfaceVariant,
              fontWeight: isDiscount ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isDiscount ? discountColor : scheme.onSurface,
              fontWeight: isDiscount ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
