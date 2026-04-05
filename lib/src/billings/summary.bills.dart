import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/extensions/number.extention.dart';

// Assuming these exist based on your snippet
import '../models/invoice.dart';
import '../providers/auth_provider.dart';
import '../widgets/grid.widgets.dart';
import 'pending.bills.dart';

class SummaryBills extends ConsumerWidget {
  final Invoice invoice;

  const SummaryBills({super.key, required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    log('Building SummaryBills with invoice total: ${invoice.toString()}');
    final auth = ref.watch(authProvider);
    return Card(
      elevation: 0, // Flat design with border is trendy
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Text(
              "Bill Summary",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // The Grid Widget (Preserving your external widget)
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                height: 255,
                child: buildModernGrid(invoice, (int _) {}, context),
              ),
            ),

            const SizedBox(height: 20),

            // Financial Breakdown
            // _buildRow('Subtotal', patient.amountDue.toFinancial(isMoney: true)),
            _buildRow('Tax', '0', isDiscount: false),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 20,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () =>
                    openCustomModal(context, invoice, auth.staff?.id ?? ''),
                style: ElevatedButton.styleFrom(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.black87, // Modern dark button
                  foregroundColor: Colors.white,
                ),
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

  Widget _buildRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDiscount ? Colors.green : Colors.grey[600],
              fontWeight: isDiscount ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isDiscount ? Colors.green : Colors.black87,
              fontWeight: isDiscount ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
