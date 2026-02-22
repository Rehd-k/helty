import 'package:flutter/material.dart';

// Assuming these exist based on your snippet
import '../models/invoice.dart';
import '../widgets/grid.widgets.dart';

class SummaryBills extends StatelessWidget {
  final Invoice invoice;

  const SummaryBills({super.key, required this.invoice});

  double calculateTotalRevenue(List<Invoice> records) {
    return records.fold(0.0, (sum, record) => sum + record.total);
  }

  void _openPaymentModal(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent, // We handle the dimming inside PayBill
      builder: (context) {
        // PayBill(patient: patient)
        return Card();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  '0',
                  // invoice..toFinancial(isMoney: true),
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
                onPressed: () => _openPaymentModal(context),
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
