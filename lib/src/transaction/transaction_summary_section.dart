import 'package:flutter/material.dart';
import 'package:helty/src/core/extensions/number.extention.dart';

/// A scrollable row of summary cards showing transaction financial totals.
/// Payment-method cards (Cash, Transfer, Card, Wallet) are tappable to filter by method.
///
/// Usage:
/// ```dart
/// TransactionSummarySection(totals: {
///   'totalSales': 1000.0,
///   'totalPaid': 900.0,
///   'transactionCount': 42,
///   ...
/// })
/// ```
class TransactionSummarySection extends StatelessWidget {
  const TransactionSummarySection({
    super.key,
    required this.totals,
    this.onPaymentCardTap,
    this.selectedPaymentMethod,
  });

  /// Map of financial totals. Expected keys:
  /// `totalSales`, `totalPaid`, `transfer`, `card`, `cash`, `wallet`, `grandTotal`, `transactionCount`
  final Map<String, dynamic> totals;
  /// Called when a payment-method card is tapped. Pass null to clear filter (show all).
  final ValueChanged<String?>? onPaymentCardTap;
  /// Currently selected payment method filter (e.g. 'Cash', 'Transfer').
  final String? selectedPaymentMethod;

  double _num(Object? v) => (v as num?)?.toDouble() ?? 0.0;
  int _int(Object? v) => (v is int?) ? (v ?? 0) : ((v as num?)?.toInt() ?? 0);

  @override
  Widget build(BuildContext context) {
    final transactionCount = _int(totals['transactionCount']);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          TransactionSummaryCard(
            title: "Total Sales (Due)",
            amount: _num(totals['totalSales']).toFinancial(isMoney: true),
            isPrimary: true,
            onTap: onPaymentCardTap != null ? () => onPaymentCardTap!(null) : null,
            isSelected: selectedPaymentMethod == null,
          ),
          const SizedBox(width: 12),
          TransactionSummaryCard(
            title: "Total Paid",
            amount: _num(totals['totalPaid']).toFinancial(isMoney: true),
            isSuccess: true,
            onTap: onPaymentCardTap != null ? () => onPaymentCardTap!(null) : null,
            isSelected: selectedPaymentMethod == null,
          ),
          const SizedBox(width: 12),
          TransactionSummaryCard(
            title: "Transfers",
            amount: _num(totals['transfer']).toFinancial(isMoney: true),
            onTap: onPaymentCardTap != null ? () => onPaymentCardTap!('Transfer') : null,
            isSelected: selectedPaymentMethod == 'Transfer',
          ),
          const SizedBox(width: 12),
          TransactionSummaryCard(
            title: "Card",
            amount: _num(totals['card'] ?? totals['pos'])
                .toFinancial(isMoney: true),
            onTap: onPaymentCardTap != null ? () => onPaymentCardTap!('Card') : null,
            isSelected: selectedPaymentMethod == 'Card',
          ),
          const SizedBox(width: 12),
          TransactionSummaryCard(
            title: "Wallet",
            amount: _num(totals['wallet']).toFinancial(isMoney: true),
            onTap: onPaymentCardTap != null ? () => onPaymentCardTap!('Wallet') : null,
            isSelected: selectedPaymentMethod == 'Wallet',
          ),
          const SizedBox(width: 12),
          TransactionSummaryCard(
            title: "Cash",
            amount: _num(totals['cash']).toFinancial(isMoney: true),
            onTap: onPaymentCardTap != null ? () => onPaymentCardTap!('Cash') : null,
            isSelected: selectedPaymentMethod == 'Cash',
          ),
          const SizedBox(width: 12),
          TransactionSummaryCard(
            title: "Grand Total",
            amount: _num(totals['grandTotal']).toFinancial(isMoney: true),
            isPrimary: true,
            onTap: onPaymentCardTap != null ? () => onPaymentCardTap!(null) : null,
            isSelected: selectedPaymentMethod == null,
          ),
          const SizedBox(width: 12),
          TransactionSummaryCard(
            title: "No. of Transactions",
            amount: transactionCount.toFinancial(isMoney: false),
            isPrimary: true,
          ),
        ],
      ),
    );
  }
}

/// A single financial summary card. Optionally tappable to filter by payment method.
class TransactionSummaryCard extends StatelessWidget {
  const TransactionSummaryCard({
    super.key,
    required this.title,
    required this.amount,
    this.isPrimary = false,
    this.isSuccess = false,
    this.onTap,
    this.isSelected = false,
  });

  final String title;
  final String amount;
  final bool isPrimary;
  final bool isSuccess;
  final VoidCallback? onTap;
  final bool isSelected;

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
    if (isSelected && onTap != null) {
      border = Border.all(color: colorScheme.primary, width: 2);
    }

    Widget card = Container(
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

    if (onTap != null) {
      card = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: card,
      );
    }
    return card;
  }
}
