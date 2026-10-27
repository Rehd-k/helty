import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/models/bank_model.dart';
import 'package:helty/src/services/bank_service.dart';
import 'package:helty/src/services/transaction_service.dart';

import 'transaction_models.dart';

enum _EditableMethod { cash, card, transfer }

/// Dialog for changing how an existing transaction payment was received.
///
/// Updates the payment's method in place. It does not record another payment
/// or change the amount.
class ChangePaymentDialog extends StatefulWidget {
  const ChangePaymentDialog({super.key, required this.transaction});

  final TransactionMap transaction;

  @override
  State<ChangePaymentDialog> createState() => _ChangePaymentDialogState();
}

class _ChangePaymentDialogState extends State<ChangePaymentDialog> {
  final BankService _bankService = BankService();
  final TransactionService _transactionService = TransactionService();
  final TextEditingController _referenceController = TextEditingController();

  _EditableMethod? _method;
  List<BankModel> _banks = const [];
  BankModel? _selectedBank;
  bool _loadingBanks = true;
  String? _banksError;
  bool _submitting = false;
  String? _error;

  String get _currentMethod =>
      (widget.transaction['paymentMethod'] as String?)?.trim() ?? '';

  bool get _locked {
    switch (_currentMethod.toLowerCase()) {
      case 'wallet':
      case 'insurance':
      case 'waiver':
        return true;
      default:
        return false;
    }
  }

  bool get _needsBank =>
      _method == _EditableMethod.card || _method == _EditableMethod.transfer;

  double get _amount {
    final paid = widget.transaction['amountPaid'];
    if (paid is num) return paid.toDouble();
    final due = widget.transaction['amountDue'];
    if (due is num) return due.toDouble();
    return 0;
  }

  @override
  void initState() {
    super.initState();
    _method = _methodFromLabel(_currentMethod);
    final reference = widget.transaction['reference']?.toString().trim() ?? '';
    if (reference.isNotEmpty) _referenceController.text = reference;
    _loadBanks();
  }

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  _EditableMethod? _methodFromLabel(String label) {
    switch (label.toLowerCase()) {
      case 'cash':
        return _EditableMethod.cash;
      case 'card':
        return _EditableMethod.card;
      case 'transfer':
        return _EditableMethod.transfer;
      default:
        return null;
    }
  }

  Future<void> _loadBanks() async {
    try {
      final all = <BankModel>[];
      var skip = 0;
      const take = 100;
      while (true) {
        final page = await _bankService.fetchBanks(skip: skip, take: take);
        all.addAll(page.data);
        if (!page.hasMore || page.data.isEmpty) break;
        skip += page.data.length;
      }
      if (!mounted) return;
      final currentName =
          widget.transaction['bankName']?.toString().trim() ?? '';
      BankModel? match;
      if (currentName.isNotEmpty) {
        for (final bank in all) {
          if (bank.name.trim().toLowerCase() == currentName.toLowerCase()) {
            match = bank;
            break;
          }
        }
      }
      setState(() {
        _banks = all;
        _selectedBank = match;
        _loadingBanks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingBanks = false;
        _banksError = _errorText(e);
      });
    }
  }

  Future<void> _submit() async {
    final paymentId = widget.transaction['id']?.toString().trim() ?? '';
    if (paymentId.isEmpty) {
      setState(() {
        _error = 'Cannot change method: missing payment id.';
      });
      return;
    }
    if (_locked || _method == null) return;
    if (_needsBank && _selectedBank == null) {
      setState(() => _error = 'Select the bank this payment was paid into.');
      return;
    }

    final source = switch (_method!) {
      _EditableMethod.cash => 'CASH',
      _EditableMethod.card => 'CARD',
      _EditableMethod.transfer => 'TRANSFER',
    };

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await _transactionService.updatePaymentMethod(
        paymentId: paymentId,
        source: source,
        method: source,
        reference: _needsBank ? _referenceController.text.trim() : null,
        bankAccountNumber: _needsBank ? _selectedBank!.accountNumber : null,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _errorText(e);
      });
    }
  }

  String _errorText(Object error) {
    if (error is DioException) {
      final inner = error.error;
      if (inner != null) return inner.toString();
      final message = error.message?.trim();
      if (message != null && message.isNotEmpty) return message;
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final txn = widget.transaction;
    final canConfirm =
        !_locked &&
        !_submitting &&
        _method != null &&
        (!_needsBank || (!_loadingBanks && _selectedBank != null));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.payment, color: colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Change payment method',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
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
                  const SizedBox(height: 8),
                  Text(
                    _amount.toFinancial(isMoney: true),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current method: ${_currentMethod.isEmpty ? '—' : _currentMethod}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                child: _locked
                    ? Text(
                        '$_currentMethod payments cannot be reclassified here. Void this payment and record a new one instead.',
                        style: TextStyle(
                          fontSize: 13,
                          color: colorScheme.onSurface.withValues(alpha: 0.8),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'New method',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SegmentedButton<_EditableMethod>(
                            showSelectedIcon: false,
                            emptySelectionAllowed: true,
                            selected: _method == null ? {} : {_method!},
                            onSelectionChanged: _submitting
                                ? null
                                : (selection) {
                                    setState(() {
                                      _method = selection.isEmpty
                                          ? null
                                          : selection.first;
                                      _error = null;
                                    });
                                  },
                            segments: const [
                              ButtonSegment(
                                value: _EditableMethod.cash,
                                label: Text('Cash'),
                                icon: Icon(Icons.payments_outlined, size: 16),
                              ),
                              ButtonSegment(
                                value: _EditableMethod.card,
                                label: Text('Card'),
                                icon: Icon(Icons.credit_card_outlined, size: 16),
                              ),
                              ButtonSegment(
                                value: _EditableMethod.transfer,
                                label: Text('Transfer'),
                                icon: Icon(
                                  Icons.account_balance_outlined,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                          if (_needsBank) ...[
                            const SizedBox(height: 16),
                            if (_loadingBanks)
                              const LinearProgressIndicator(minHeight: 2)
                            else if (_banksError != null)
                              Text(
                                'Could not load banks: $_banksError',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.error,
                                ),
                              )
                            else if (_banks.isEmpty)
                              Text(
                                'No hospital bank accounts are registered.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.error,
                                ),
                              )
                            else
                              DropdownButtonFormField<String>(
                                key: ValueKey(_selectedBank?.id ?? 'bank'),
                                initialValue: _selectedBank?.id,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Bank paid into',
                                  prefixIcon: const Icon(
                                    Icons.account_balance,
                                    size: 18,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  isDense: true,
                                ),
                                items: _banks
                                    .map(
                                      (bank) => DropdownMenuItem<String>(
                                        value: bank.id,
                                        child: Text(
                                          '${bank.name} · ${bank.accountNumber}',
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: _submitting
                                    ? null
                                    : (id) {
                                        BankModel? match;
                                        for (final bank in _banks) {
                                          if (bank.id == id) {
                                            match = bank;
                                            break;
                                          }
                                        }
                                        setState(() {
                                          _selectedBank = match;
                                          _error = null;
                                        });
                                      },
                              ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _referenceController,
                              enabled: !_submitting,
                              decoration: InputDecoration(
                                labelText: _method == _EditableMethod.card
                                    ? 'Card approval code'
                                    : 'Transfer reference',
                                prefixIcon: const Icon(Icons.tag, size: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                isDense: true,
                              ),
                              style: const TextStyle(fontSize: 13),
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.error,
                              ),
                            ),
                          ],
                        ],
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: canConfirm ? _submit : null,
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(_submitting ? 'Saving...' : 'Update method'),
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
