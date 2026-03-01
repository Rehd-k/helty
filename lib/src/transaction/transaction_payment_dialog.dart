import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
/// Cash, POS, Transfer and Cheque.  For every non-cash method the user also
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
  late final double _totalDue;
  late final List<_MethodEntry> _entries;

  double get _totalEntered =>
      _entries.fold(0.0, (sum, e) => sum + e.enteredAmount);
  double get _remaining => (_totalDue - _totalEntered).clamp(0.0, _totalDue);
  bool get _isOverpaid => _totalEntered > _totalDue;
  bool get _isFullyPaid => _totalEntered >= _totalDue;

  @override
  void initState() {
    super.initState();
    _totalDue =
        (widget.transaction['amountDue'] as num).toDouble() -
        (widget.transaction['discount'] as num).toDouble();

    // Default: one entry per available method
    _entries = [
      _MethodEntry(method: PaymentMethod.cash),
      _MethodEntry(method: PaymentMethod.pos),
      _MethodEntry(method: PaymentMethod.transfer),
      _MethodEntry(method: PaymentMethod.cheque),
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

  void _submit() {
    // TODO: connect to TransactionService.recordPayment() for each entry with enteredAmount > 0
    Navigator.of(context).pop({
      'payments': _entries
          .where((e) => e.enteredAmount > 0)
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
                    onPressed: (_isFullyPaid && !_isOverpaid) ? _submit : null,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Confirm Payment'),
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
                '\$${totalDue.toStringAsFixed(2)}',
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
        ? Colors.red
        : (remaining == 0 ? Colors.green : colorScheme.primary);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Entered: \$${totalEntered.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: barColor,
                ),
              ),
              Text(
                isOverpaid
                    ? 'OVERPAID by \$${(totalEntered - totalDue).toStringAsFixed(2)}'
                    : 'Remaining: \$${remaining.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isOverpaid ? Colors.red : colorScheme.onSurface,
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

  bool get _isCash => entry.method == PaymentMethod.cash;

  IconData get _icon => switch (entry.method) {
    PaymentMethod.cash => Icons.payments_outlined,
    PaymentMethod.pos => Icons.credit_card_outlined,
    PaymentMethod.transfer => Icons.account_balance_outlined,
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
              labelText: 'Amount (\$)',
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

            // ── Reference (cheque number / transfer ref / POS approval code)
            TextField(
              controller: entry.referenceController,
              decoration: InputDecoration(
                labelText: switch (entry.method) {
                  PaymentMethod.cheque => 'Cheque Number',
                  PaymentMethod.transfer => 'Transfer Reference',
                  PaymentMethod.pos => 'POS Approval Code',
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
