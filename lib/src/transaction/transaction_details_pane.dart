import 'package:flutter/material.dart';
import 'package:helty/src/core/extensions/number.extention.dart';

/// Displays detailed information about a single selected transaction.
///
/// The entire content is wrapped in a [SingleChildScrollView] so longservice
/// lists and the financial breakdown are always reachable.
///
/// Shows an empty placeholder state when [transaction] is `null`.
class TransactionDetailsPane extends StatelessWidget {
  const TransactionDetailsPane({
    super.key,
    required this.transaction,
    required this.onReprint,
    required this.onChangeMethod,
    required this.onRefund,
  });

  /// The transaction to display. Pass `null` to show the empty state.
  final Map<String, dynamic>? transaction;

  final VoidCallback onReprint;
  final VoidCallback onChangeMethod;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (transaction == null) {
      return _EmptyState(colorScheme: colorScheme);
    }

    return _DetailContent(
      txn: transaction!,
      colorScheme: colorScheme,
      onReprint: onReprint,
      onChangeMethod: onChangeMethod,
      onRefund: onRefund,
    );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.colorScheme});
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 48,
              color: colorScheme.onSurface.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 16),
            Text(
              'Select a transaction\nto view details.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Content ───────────────────────────────────────────────────────────

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.txn,
    required this.colorScheme,
    required this.onReprint,
    required this.onChangeMethod,
    required this.onRefund,
  });

  final Map<String, dynamic> txn;
  final ColorScheme colorScheme;
  final VoidCallback onReprint;
  final VoidCallback onChangeMethod;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    final List services = txn['services'] as List;
    final double totalServiceCost = services.fold<double>(
      0,
      (sum, item) => sum + (item['cost'] as num).toDouble(),
    );
    final double discount = (txn['discount'] as num).toDouble();
    final double profit = totalServiceCost - discount;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      // ── Entire detail pane scrolls vertically
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DetailHeader(txn: txn, colorScheme: colorScheme),

          // Scrollable body: services + breakdown
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ServicesSection(
                    services: services,
                    colorScheme: colorScheme,
                  ),
                  _FinancialBreakdown(
                    txn: txn,
                    totalServiceCost: totalServiceCost,
                    profit: profit,
                    colorScheme: colorScheme,
                  ),
                ],
              ),
            ),
          ),

          // Action buttons pinned at bottom
          _ActionButtons(
            colorScheme: colorScheme,
            onReprint: onReprint,
            onChangeMethod: onChangeMethod,
            onRefund: onRefund,
          ),
        ],
      ),
    );
  }
}

// ─── Header ───────────────────────────────────────────────────────────────────

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.txn, required this.colorScheme});
  final Map<String, dynamic> txn;
  final ColorScheme colorScheme;

  Color _statusColor(String? status) => switch (status) {
    'PAID' => Colors.green,
    'PARTIALLY_PAID' => Colors.orange,
    'CANCELLED' => Colors.red,
    'REFUNDED' => Colors.purple,
    'ACTIVE' => colorScheme.primary,
    _ => colorScheme.onSurface.withValues(alpha: 0.5),
  };

  @override
  Widget build(BuildContext context) {
    final status = txn['status'] as String? ?? '';
    final statusColor = _statusColor(status);
    final hasBank = txn['bankName'] != null;
    final hasRef = txn['reference'] != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transaction Details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            txn['tranId'] as String,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          Text(
            'Patient: ${txn['patientName']} (${txn['patientId']})',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          Text(
            'Date: ${txn['date']}',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          // Payment method chip + optional bank
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _InfoChip(
                label: txn['paymentMethod'] as String,
                icon: Icons.payment,
                colorScheme: colorScheme,
              ),
              if (hasBank)
                _InfoChip(
                  label: txn['bankName'] as String,
                  icon: Icons.account_balance,
                  colorScheme: colorScheme,
                ),
              if (hasRef)
                _InfoChip(
                  label: 'Ref: ${txn['reference']}',
                  icon: Icons.tag,
                  colorScheme: colorScheme,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.icon,
    required this.colorScheme,
  });
  final String label;
  final IconData icon;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: colorScheme.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Services Section ─────────────────────────────────────────────────────────

class _ServicesSection extends StatelessWidget {
  const _ServicesSection({required this.services, required this.colorScheme});
  final List services;
  final ColorScheme colorScheme;

  Color _sourceColor(String source) => switch (source.toUpperCase()) {
    'LAB' => Colors.blue,
    'RADIOLOGY' => Colors.indigo,
    'PHARMACY' => Colors.teal,
    'CONSULTATION' => colorScheme.primary,
    'ADMISSION' => Colors.purple,
    _ => colorScheme.onSurface.withValues(alpha: 0.5),
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Services Rendered  (${services.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Cost / Paid',
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
        ...List.generate(services.length, (i) {
          final svc = services[i] as Map;
          final source = (svc['source'] as String? ?? 'OTHER').toUpperCase();
          final sourceColor = _sourceColor(source);
          return Column(
            children: [
              if (i > 0)
                Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: colorScheme.outline.withValues(alpha: 0.06),
                ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Source badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      margin: const EdgeInsets.only(top: 1, right: 8),
                      decoration: BoxDecoration(
                        color: sourceColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        source.length > 5
                            ? '${source.substring(0, 4)}.'
                            : source,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: sourceColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            svc['name'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.85,
                              ),
                            ),
                          ),
                          if ((svc['quantity'] as int? ?? 1) > 1)
                            Text(
                              'qty: ${svc['quantity']}',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          (svc['cost'] as num).toFinancial(isMoney: true),
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.45,
                            ),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        Text(
                          (svc['paid'] as num).toFinancial(isMoney: true),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        }),
      ],
    );
  }
}

// ─── Financial Breakdown ──────────────────────────────────────────────────────

class _FinancialBreakdown extends StatelessWidget {
  const _FinancialBreakdown({
    required this.txn,
    required this.totalServiceCost,
    required this.profit,
    required this.colorScheme,
  });

  final Map<String, dynamic> txn;
  final double totalServiceCost;
  final double profit;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final debt = (txn['debt'] as num).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: 0.02),
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
      ),
      child: Column(
        children: [
          _BreakdownRow(
            label: 'Total Service Cost',
            amount: totalServiceCost,
            colorScheme: colorScheme,
          ),
          _BreakdownRow(
            label: 'Discount Applied',
            amount: (txn['discount'] as num).toDouble(),
            colorScheme: colorScheme,
            isDiscount: true,
          ),
          _BreakdownRow(
            label: 'Total Amount Due',
            amount: (txn['amountDue'] as num).toDouble(),
            colorScheme: colorScheme,
            isBold: true,
          ),
          const SizedBox(height: 8),
          _BreakdownRow(
            label: 'Total Amount Paid',
            amount: (txn['amountPaid'] as num).toDouble(),
            colorScheme: colorScheme,
            isBold: true,
            valueColor: Colors.green,
          ),
          _BreakdownRow(
            label: 'Unpaid Balance (Debt)',
            amount: debt,
            colorScheme: colorScheme,
            isBold: true,
            valueColor: debt > 0 ? Colors.red : null,
          ),
          const SizedBox(height: 8),
          _BreakdownRow(
            label: 'Net Profit Estimate',
            amount: profit,
            colorScheme: colorScheme,
          ),
        ],
      ),
    );
  }
}

/// A single labeled row in the financial breakdown.
class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.amount,
    required this.colorScheme,
    this.isBold = false,
    this.isDiscount = false,
    this.valueColor,
  });

  final String label;
  final double amount;
  final ColorScheme colorScheme;
  final bool isBold;
  final bool isDiscount;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: colorScheme.onSurface.withValues(
                alpha: isBold ? 0.8 : 0.6,
              ),
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}${amount.toFinancial(isMoney: true)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color:
                  valueColor ??
                  (isDiscount ? Colors.orange : colorScheme.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.colorScheme,
    required this.onReprint,
    required this.onChangeMethod,
    required this.onRefund,
  });

  final ColorScheme colorScheme;
  final VoidCallback onReprint;
  final VoidCallback onChangeMethod;
  final VoidCallback onRefund;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.1)),
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          OutlinedButton.icon(
            onPressed: onReprint,
            icon: const Icon(Icons.print, size: 14),
            label: const Text('Reprint', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          OutlinedButton.icon(
            onPressed: onChangeMethod,
            icon: const Icon(Icons.edit_note, size: 14),
            label: const Text('Payment', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          OutlinedButton.icon(
            onPressed: onRefund,
            icon: const Icon(Icons.undo, size: 14, color: Colors.red),
            label: const Text(
              'Refund',
              style: TextStyle(fontSize: 12, color: Colors.red),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: BorderSide(color: Colors.red.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
    );
  }
}
