import 'package:flutter/material.dart';
import 'package:helty/src/shared/finance_status_colors.dart';
import 'package:flutter/services.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/services/invoice_service.dart';

import 'transaction_models.dart';

// ─── Bank names used for non-cash payment methods ────────────────────────────
const List<String> _kBanks = [
  'Access Bank',
  'First Bank',
  'GTBank (Guaranty Trust)',
  'UBA (United Bank for Africa)',
  'Zenith Bank',
  'Fidelity Bank',
  'Polaris Bank',
  'Stanbic IBTC',
  'Sterling Bank',
  'Union Bank',
  'Wema Bank',
  'Ecobank',
  'FCMB',
  'Heritage Bank',
  'Keystone Bank',
  'Providus Bank',
  'Rand Merchant Bank',
  'SunTrust Bank',
  'Titan Bank',
  'Other',
];

// ─── Entry per payment method ─────────────────────────────────────────────────

class _MethodEntry {
  _MethodEntry({required this.method})
    : amountController = TextEditingController(),
      referenceController = TextEditingController(),
      selectedBank = null;

  final PaymentMethod method;
  final TextEditingController amountController;
  final TextEditingController referenceController;
  String? selectedBank;

  double get enteredAmount =>
      double.tryParse(amountController.text.trim()) ?? 0.0;

  void dispose() {
    amountController.dispose();
    referenceController.dispose();
  }
}

/// Dialog for recording / changing payment on a transaction.
///
/// Shows the outstanding total, lets the cashier split the payment across
/// Cash, Card, Transfer and Wallet. For Card/Transfer the user also
/// selects the bank.  A live "Remaining" counter counts down as amounts are
/// entered.
///
/// Usage:
/// ```dart
/// await showDialog(
///   context: context,
///   builder: (_) => ChangePaymentDialog(transaction: txn),
/// );
/// ```
class ChangePaymentDialog extends StatefulWidget {
  const ChangePaymentDialog({super.key, required this.transaction});

  final TransactionMap transaction;

  @override
  State<ChangePaymentDialog> createState() => _ChangePaymentDialogState();
}

class _ChangePaymentDialogState extends State<ChangePaymentDialog> {
  final InvoiceService _invoiceService = InvoiceService();
  late final double _totalDue;
  late final List<_MethodEntry> _entries;
  bool _isSubmitting = false;

  double get _totalEntered =>
      _entries.fold(0.0, (sum, e) => sum + e.enteredAmount);
  double get _remaining => (_totalDue - _totalEntered).clamp(0.0, _totalDue);
  bool get _isOverpaid => _totalEntered > _totalDue;
  bool get _isFullyPaid => _totalEntered >= _totalDue;

  @override
  void initState() {
    super.initState();
    final debt = (widget.transaction['debt'] as num?)?.toDouble() ?? 0;
    final amountDue =
        (widget.transaction['amountDue'] as num?)?.toDouble() ?? 0;
    final discount = (widget.transaction['discount'] as num?)?.toDouble() ?? 0;
    _totalDue = debt > 0 ? debt : (amountDue - discount);

    // Default: one entry per available method
    _entries = [
      _MethodEntry(method: PaymentMethod.cash),
      _MethodEntry(method: PaymentMethod.card),
      _MethodEntry(method: PaymentMethod.transfer),
      _MethodEntry(method: PaymentMethod.wallet),
    ];

    // Listen for input changes to rebuild the remaining counter
    for (final e in _entries) {
      e.amountController.addListener(() => setState(() {}));
    }
  }

  @override
  void dispose() {
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  static String _sourceFor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'CARD';
      case PaymentMethod.transfer:
      case PaymentMethod.cheque:
        return 'TRANSFER';
      case PaymentMethod.wallet:
        return 'WALLET';
      case PaymentMethod.cash:
      case PaymentMethod.insurance:
      case PaymentMethod.waiver:
        return 'CASH';
    }
  }

  static String? _methodFor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'CARD';
      case PaymentMethod.transfer:
      case PaymentMethod.cheque:
        return 'TRANSFER';
      case PaymentMethod.cash:
        return 'CASH';
      case PaymentMethod.wallet:
        return null;
      case PaymentMethod.insurance:
      case PaymentMethod.waiver:
        return 'CASH';
    }
  }

  Future<void> _submit() async {
    final invoiceId = (widget.transaction['invoiceId'] as String?)?.trim();
    if (invoiceId == null || invoiceId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing invoice link for this transaction'),
        ),
      );
      return;
    }

    final entries = _entries.where((e) => e.enteredAmount > 0).toList();
    for (final e in entries) {
      final bankRequired =
          e.method == PaymentMethod.transfer || e.method == PaymentMethod.card;
      if (bankRequired && (e.selectedBank == null || e.selectedBank!.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Select bank for ${e.method.label} payment')),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);
    try {
      for (final e in entries) {
        await _invoiceService.recordInvoicePayment(
          invoiceId: invoiceId,
          payload: RecordPaymentPayload(
            amount: e.enteredAmount,
            source: _sourceFor(e.method),
            method: _methodFor(e.method),
            reference: e.referenceController.text.trim().isEmpty
                ? null
                : e.referenceController.text.trim(),
            bankAccountNumber: e.selectedBank,
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop({
        'payments': entries
            .map(
              (e) => {
                'method': e.method.name,
                'amount': e.enteredAmount,
                if (e.method != PaymentMethod.cash) 'bankName': e.selectedBank,
                if (e.referenceController.text.isNotEmpty)
                  'reference': e.referenceController.text.trim(),
              },
            )
            .toList(),
        'totalPaid': _totalEntered,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Payment failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final txn = widget.transaction;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header
            _DialogHeader(
              txn: txn,
              totalDue: _totalDue,
              colorScheme: colorScheme,
            ),

            // ── Live balance bar
            _BalanceBar(
              totalDue: _totalDue,
              totalEntered: _totalEntered,
              remaining: _remaining,
              isOverpaid: _isOverpaid,
              colorScheme: colorScheme,
            ),

            // ── Payment method entries
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                child: Column(
                  children: _entries
                      .map(
                        (e) => _PaymentMethodRow(
                          entry: e,
                          colorScheme: colorScheme,
                          onBankChanged: (bank) =>
                              setState(() => e.selectedBank = bank),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),

            // ── Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: (_isFullyPaid && !_isOverpaid && !_isSubmitting)
                        ? _submit
                        : null,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(
                      _isSubmitting ? 'Processing...' : 'Confirm Payment',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Dialog header ────────────────────────────────────────────────────────────

class _DialogHeader extends StatelessWidget {
  const _DialogHeader({
    required this.txn,
    required this.totalDue,
    required this.colorScheme,
  });

  final TransactionMap txn;
  final double totalDue;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.payment, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Record / Change Payment',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 18),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${txn['tranId']}  •  ${txn['patientName']}',
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                'Total Amount Due:  ',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              Text(
                totalDue.toFinancial(isMoney: true),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Balance bar ──────────────────────────────────────────────────────────────

class _BalanceBar extends StatelessWidget {
  const _BalanceBar({
    required this.totalDue,
    required this.totalEntered,
    required this.remaining,
    required this.isOverpaid,
    required this.colorScheme,
  });

  final double totalDue;
  final double totalEntered;
  final double remaining;
  final bool isOverpaid;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final progress = (totalDue > 0
        ? (totalEntered / totalDue).clamp(0.0, 1.0)
        : 0.0);
    final barColor = isOverpaid
        ? FinanceStatusColors.danger(colorScheme)
        : (remaining == 0
            ? FinanceStatusColors.success(colorScheme)
            : colorScheme.primary);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Entered: ${totalEntered.toFinancial(isMoney: true)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
              Text(
                isOverpaid
                    ? 'OVERPAID by ${(totalEntered - totalDue).toFinancial(isMoney: true)}'
                    : 'Remaining: ${remaining.toFinancial(isMoney: true)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isOverpaid
                      ? FinanceStatusColors.danger(colorScheme)
                      : colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: colorScheme.outline.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Single method row ────────────────────────────────────────────────────────

class _PaymentMethodRow extends StatelessWidget {
  const _PaymentMethodRow({
    required this.entry,
    required this.colorScheme,
    required this.onBankChanged,
  });

  final _MethodEntry entry;
  final ColorScheme colorScheme;
  final ValueChanged<String?> onBankChanged;

  bool get _isCash =>
      entry.method == PaymentMethod.cash ||
      entry.method == PaymentMethod.wallet;

  IconData get _icon => switch (entry.method) {
    PaymentMethod.cash => Icons.payments_outlined,
    PaymentMethod.card => Icons.credit_card_outlined,
    PaymentMethod.transfer => Icons.account_balance_outlined,
    PaymentMethod.wallet => Icons.account_balance_wallet_outlined,
    PaymentMethod.cheque => Icons.receipt_outlined,
    _ => Icons.payment_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: entry.enteredAmount > 0
              ? colorScheme.primary.withValues(alpha: 0.4)
              : colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Method label
          Row(
            children: [
              Icon(_icon, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                entry.method.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Amount field
          TextField(
            controller: entry.amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixIcon: const Icon(Icons.attach_money, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            style: const TextStyle(fontSize: 13),
          ),

          // ── Bank selector (non-cash only)
          if (!_isCash) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: entry.selectedBank,
              decoration: InputDecoration(
                labelText: 'Bank Paid Into',
                prefixIcon: const Icon(Icons.account_balance, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              style: const TextStyle(fontSize: 13),
              items: _kBanks
                  .map(
                    (b) => DropdownMenuItem<String>(value: b, child: Text(b)),
                  )
                  .toList(),
              onChanged: onBankChanged,
            ),
            const SizedBox(height: 10),

            // ── Reference (cheque number / transfer ref / card approval code)
            TextField(
              controller: entry.referenceController,
              decoration: InputDecoration(
                labelText: switch (entry.method) {
                  PaymentMethod.transfer => 'Transfer Reference',
                  PaymentMethod.card => 'Card approval code',
                  _ => 'Reference',
                },
                prefixIcon: const Icon(Icons.tag, size: 18),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
