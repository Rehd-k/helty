import 'package:flutter/material.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:intl/intl.dart';

/// A scrollable row of summary cards showing transaction financial totals.
///
/// Usage:
/// ```dart
/// TransactionSummarySection(totals: {
///   'totalSales': 1000.0,
///   'totalPaid': 900.0,
///   ...
/// })
/// ```
class TransactionSummarySection extends StatelessWidget {
  const TransactionSummarySection({super.key, required this.totals});

  /// Map of financial totals. Expected keys:
  /// `totalSales`, `totalPaid`, `transfer`, `pos`, `cheque`, `cash`, `grandTotal`
  final Map<String, double> totals;

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          TransactionSummaryCard(
            title: "Total Sales (Due)",
            amount: totals['totalSales']!.toFinancial(isMoney: true),
            isPrimary: true,
          ),
          const SizedBox(width: 12),
          TransactionSummaryCard(
            title: "Total Paid",
            amount: totals['totalPaid']!.toFinancial(isMoney: true),
            isSuccess: true,
          ),
          const SizedBox(width: 12),
          TransactionSummaryCard(
            title: "Transfers",
            amount: totals['transfer']!.toFinancial(isMoney: true),
          ),
          const SizedBox(width: 12),
          TransactionSummaryCard(
            title: "POS",
            amount: format.format(totals['pos'] ?? 0),
          ),
          const SizedBox(width: 12),
          TransactionSummaryCard(
            title: "Cheque",
            amount: totals['cheque']!.toFinancial(isMoney: true),
          ),
          const SizedBox(width: 12),
          TransactionSummaryCard(
            title: "Cash",
            amount: totals['cash']!.toFinancial(isMoney: true),
          ),
          const SizedBox(width: 12),
          TransactionSummaryCard(
            title: "Grand Total",
            amount: totals['grandTotal']!.toFinancial(isMoney: true),
            isPrimary: true,
          ),
          const SizedBox(width: 12),
          TransactionSummaryCard(
            title: "No. of Transactions",
            amount: 0.toFinancial(isMoney: false),
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}

/// A single financial summary card.
class TransactionSummaryCard extends StatelessWidget {
  const TransactionSummaryCard({
    super.key,
    required this.title,
    required this.amount,
    this.isPrimary = false,
    this.isSuccess = false,
  });

  final String title;
  final String amount;
  final bool isPrimary;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color bgColor = colorScheme.surface;
    Color textColor = colorScheme.onSurface;
    Border border = Border.all(
      color: colorScheme.outline.withValues(alpha: 0.2),
    );

    if (isPrimary) {
      bgColor = colorScheme.primary.withValues(alpha: 0.05);
      textColor = colorScheme.primary;
      border = Border.all(color: colorScheme.primary.withValues(alpha: 0.3));
    } else if (isSuccess) {
      bgColor = Colors.green.withValues(alpha: 0.05);
      textColor = Colors.green[700]!;
      border = Border.all(color: Colors.green.withValues(alpha: 0.3));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: border,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            amount,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
