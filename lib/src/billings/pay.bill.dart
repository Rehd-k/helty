import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/models/service_model.dart';

import '../../app_router.gr.dart';
import '../paitients/patient_providers.dart';
import '../services/transaction_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// These payment methods require a bank to be selected before paying.
// ─────────────────────────────────────────────────────────────────────────────
const _bankRequiredMethods = {'pos', 'transfer', 'cheque'};

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Bank Dropdown Widget
// ─────────────────────────────────────────────────────────────────────────────

class BankDropdown extends StatelessWidget {
  const BankDropdown({
    super.key,
    required this.banks,
    required this.value,
    required this.onChanged,
    this.isLoading = false,
  });

  final List<String> banks;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Center(
          child: SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Select Bank',
        prefixIcon: const Icon(Icons.account_balance_outlined, size: 18),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        isDense: true,
      ),
      hint: const Text('Select Bank', style: TextStyle(fontSize: 13)),
      items: banks
          .map(
            (b) => DropdownMenuItem(
              value: b,
              child: Text(b, style: const TextStyle(fontSize: 13)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      style: theme.textTheme.bodyMedium,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PayBill
// ─────────────────────────────────────────────────────────────────────────────

class PayBill extends ConsumerStatefulWidget {
  const PayBill({
    super.key,
    required this.hasId,
    required this.firstName,
    required this.patientId,
    required this.selectedItems,
    required this.total,
    required this.staffId,
    this.onPaymentComplete,
  });
  final bool hasId;
  final String firstName;
  final String patientId;
  final List<ServiceModel> selectedItems;
  final double total;
  final String staffId;

  /// Called after the payment API call succeeds so the caller can clear its cart.
  final VoidCallback? onPaymentComplete;

  @override
  PayBillState createState() => PayBillState();
}

class PayBillState extends ConsumerState<PayBill> {
  // Data State
  late String _patientName;
  late String _patientId;
  late String _staffId;
  late double _originalAmount;
  late bool hasId;
  double _amountToPay = 0;
  String? _insurance;
  List<String> charges = [];
  List<ServiceModel> _items = [];
  List<String> _discounts = [];
  String? _selectedDiscount;
  final transactionService = TransactionService();

  // Payment State
  String? _paymentMethod;
  bool _isSubmitting = false;
  final List<String> _methods = ['transfer', 'pos', 'cash', 'cheque', 'mixed'];
  final Map<String, IconData> _methodIcons = {
    'transfer': Icons.account_balance,
    'pos': Icons.credit_card,
    'cash': Icons.payments,
    'cheque': Icons.history_edu,
    'mixed': Icons.pie_chart,
  };

  // Bank State
  List<String> _banks = [];
  bool _banksLoading = true;

  /// Bank selected for POS / Transfer / Cheque (single-method flow).
  String? _selectedBank;

  /// Per-method bank selections used inside the Mixed sheet.
  final Map<String, String?> _mixedBanks = {};

  // Mixed Payment State
  final Map<String, double> _mixedAmounts = {};

  bool _confirmed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _patientName = widget.firstName;
    _patientId = widget.patientId;
    _staffId = widget.staffId;
    _originalAmount = widget.total;
    _amountToPay = _originalAmount;
    _items = widget.selectedItems;
    hasId = widget.hasId;
    _fetchDetails();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    try {
      final banks = await transactionService.fetchBanks();
      if (mounted) {
        setState(() {
          _banks = banks;
          _banksLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _banksLoading = false);
    }
  }

  Future<void> _fetchDetails() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        _insurance = 'Acme Health Plan';
        _discounts = ['None', 'Senior 10%', 'Member 5%', 'Promo 100'];
        _isLoading = false;
      });
    }
  }

  void _applyDiscount(String? discount) {
    if (discount == null || discount == 'None') {
      _amountToPay = _originalAmount;
      _selectedDiscount = null;
    } else {
      if (discount.contains('10%')) {
        _amountToPay = _originalAmount * 0.9;
      } else if (discount.contains('5%')) {
        _amountToPay = _originalAmount * 0.95;
      } else if (discount.contains('100')) {
        _amountToPay = _originalAmount - 100;
      }
      _selectedDiscount = discount;
    }
    _mixedAmounts.clear();
    setState(() {});
  }

  /// Whether the current selection is valid to trigger payment.
  bool get _canPay {
    if (_paymentMethod == null) return false;

    if (_paymentMethod == 'mixed') {
      final total = _mixedAmounts.values.fold(0.0, (a, b) => a + b);
      if ((total - _amountToPay).abs() >= 0.001) return false;
      // All bank-required methods used in mixed must have a bank selected.
      for (final m in _bankRequiredMethods) {
        final amount = _mixedAmounts[m] ?? 0;
        if (amount > 0 && (_mixedBanks[m] == null || _mixedBanks[m]!.isEmpty)) {
          return false;
        }
      }
      return true;
    }

    // For bank-required single methods, a bank must be chosen.
    if (_bankRequiredMethods.contains(_paymentMethod)) {
      return _selectedBank != null && _selectedBank!.isNotEmpty;
    }

    return true;
  }

  // --- UI Builders ---

  void _openMixedSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            void updateAmount(String method, String text) {
              final value = double.tryParse(text) ?? 0;
              setModalState(() {
                _mixedAmounts[method] = value;
              });
              setState(() {});
            }

            void updateMixedBank(String method, String? bank) {
              setModalState(() {
                _mixedBanks[method] = bank;
              });
              setState(() {});
            }

            final total = _mixedAmounts.values.fold(0.0, (a, b) => a + b);
            final remaining = _amountToPay - total;
            final isComplete = (total - _amountToPay).abs() < 0.001 && _canPay;

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Split Payment',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    // Per-method rows
                    ..._methods.where((m) => m != 'mixed').map((m) {
                      final needsBank = _bankRequiredMethods.contains(m);
                      final bankChosen =
                          !needsBank ||
                          (_mixedBanks[m] != null &&
                              _mixedBanks[m]!.isNotEmpty);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Amount input
                            TextField(
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              enabled: bankChosen || !needsBank,
                              decoration: InputDecoration(
                                labelText: m.toUpperCase(),
                                prefixIcon: Icon(_methodIcons[m], size: 18),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 14,
                                ),
                                disabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
                                ),
                              ),
                              onChanged: (t) => updateAmount(m, t),
                            ),

                            // Bank dropdown for bank-required methods
                            if (needsBank) ...[
                              const SizedBox(height: 8),
                              BankDropdown(
                                banks: _banks,
                                value: _mixedBanks[m],
                                isLoading: _banksLoading,
                                onChanged: (bank) => updateMixedBank(m, bank),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total entered: ${total.toFinancial(isMoney: true)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Remaining: ${remaining > 0 ? remaining.toFinancial(isMoney: true) : "0.00"}',
                          style: TextStyle(
                            color: remaining > 0.001
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: isComplete
                              ? Colors.green
                              : Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: isComplete
                            ? () => Navigator.pop(context)
                            : null,
                        child: const Text('Confirm Split'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {});
    });
  }

  Future<void> _makePayment() async {
    // Determine bankName for the DTO
    String? bankName;
    if (_paymentMethod == 'mixed') {
      // For mixed, include first non-null bank (backend handles per-method breakdown)
      bankName = _mixedBanks.entries
          .firstWhere(
            (e) => e.value != null && e.value!.isNotEmpty,
            orElse: () => const MapEntry('', null),
          )
          .value;
    } else if (_bankRequiredMethods.contains(_paymentMethod)) {
      bankName = _selectedBank;
    }

    // Build mixedBreakdown with bank info embedded if needed
    Map<String, dynamic>? mixedBreakdownWithBanks;
    if (_paymentMethod == 'mixed') {
      mixedBreakdownWithBanks = {};
      for (final m in _methods.where((m) => m != 'mixed')) {
        final amount = _mixedAmounts[m] ?? 0;
        if (amount > 0) {
          mixedBreakdownWithBanks[m] = {
            'amount': amount,
            if (_mixedBanks[m] != null) 'bankName': _mixedBanks[m],
          };
        }
      }
    }

    final dto = QuickTransactionDto(
      patientId: _patientId,
      staffId: _staffId,
      amountPaid: _amountToPay,
      paymentMethod: _paymentMethod ?? 'cash',
      discount: _amountToPay < _originalAmount
          ? _originalAmount - _amountToPay
          : 0,
      notes: _selectedDiscount,
      bankName: bankName,
      mixedBreakdown: _paymentMethod == 'mixed'
          ? Map<String, double>.from(
              _mixedAmounts.map((k, v) => MapEntry(k, v)),
            )
          : null,
      items: _items
          .map(
            (s) => CreateTransactionItemDto(
              serviceId: s.serviceId,
              name: s.name,
              unitPrice: s.cost,
              quantity: s.qty ?? 1,
              source: s.categoryName ?? 'OTHER',
            ),
          )
          .toList(),
    );

    setState(() => _isSubmitting = true);

    try {
      await transactionService.createQuickTransaction(dto);
      if (mounted) {
        setState(() {
          _confirmed = true;
          _isSubmitting = false;
        });
        widget.onPaymentComplete?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            elevation: 8,
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Payment Processed Successfully!',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade600,
            content: Text('Payment failed: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_confirmed) {
      return _buildSuccessView();
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.black45,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: GestureDetector(
              onTap: () {}, // Swallow the click
              child: Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    _isLoading
                        ? const SizedBox(
                            height: 300,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildHeader(),
                                const SizedBox(height: 20),
                                _buildInvoiceSection(),
                                const SizedBox(height: 20),
                                _buildPaymentSection(
                                  Theme.of(context).primaryColor,
                                ),
                                const SizedBox(height: 24),
                                _buildPayButton(Theme.of(context).primaryColor),
                              ],
                            ),
                          ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: Colors.blue.shade100,
          child: Text(
            _patientName.substring(0, 1),
            style: TextStyle(color: Colors.blue.shade800, fontSize: 20),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _patientName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (hasId)
                Text(
                  'ID: $_patientId',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              if (!hasId)
                Text(
                  "ID: No ID",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'BILLING',
            style: TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (_insurance != null) ...[
            _invoiceRow('Insurance', _insurance!, isBold: true),
            const Divider(),
          ],
          ..._items.map((c) {
            final qty = c.qty ?? 1;
            final lineTotal = c.cost * qty;
            final label = qty > 1 ? '${c.name}  ×$qty' : c.name;
            return _invoiceRow(label, lineTotal.toFinancial(isMoney: true));
          }),
          const Divider(),
          Row(
            children: [
              const Icon(
                Icons.discount_outlined,
                size: 18,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isDense: true,
                    isExpanded: true,
                    hint: const Text("Select Discount"),
                    value: _selectedDiscount ?? 'None',
                    style: const TextStyle(color: Colors.black87, fontSize: 14),
                    items: _discounts
                        .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                        .toList(),
                    onChanged: (v) => _applyDiscount(v),
                  ),
                ),
              ),
            ],
          ),
          const Divider(thickness: 1.5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'TOTAL DUE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                ),
              ),
              Text(
                _amountToPay.toFinancial(isMoney: true),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _invoiceRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Tooltip(
              message: label,
              waitDuration: const Duration(milliseconds: 500),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSection(Color primaryColor) {
    final needsBank =
        _paymentMethod != null && _bankRequiredMethods.contains(_paymentMethod);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Payment Method",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _methods.map((m) {
            final isSelected = m == _paymentMethod;
            return InkWell(
              onTap: () {
                setState(() {
                  _paymentMethod = m;
                  _selectedBank = null; // reset bank when method changes
                  if (m == 'mixed') _openMixedSheet();
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? primaryColor.withValues(alpha: 0.1)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey.shade300,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _methodIcons[m],
                      color: isSelected ? primaryColor : Colors.grey,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? primaryColor : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        // ── Bank dropdown (shown for POS / Transfer / Cheque) ──────────────
        if (needsBank) ...[
          const SizedBox(height: 16),
          BankDropdown(
            banks: _banks,
            value: _selectedBank,
            isLoading: _banksLoading,
            onChanged: (bank) => setState(() => _selectedBank = bank),
          ),
          if (_selectedBank == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Please select a bank to continue',
                style: TextStyle(fontSize: 11, color: Colors.orange.shade700),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildPayButton(Color primaryColor) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: _canPay && !_confirmed && !_isSubmitting
            ? _makePayment
            : null,
        child: Text(
          'Pay ${_amountToPay.toFinancial(isMoney: true)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 64),
              const SizedBox(height: 20),
              const Text(
                'Payment Confirmed',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Receipt sent to $_patientName',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 30),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(patientProvider.notifier).clearPatient();
                  context.router.replaceAll([
                    EnlistPaitientRoute(serviceName: ''),
                  ]);
                  setState(() {
                    _confirmed = false;
                    _paymentMethod = null;
                    _selectedBank = null;
                    _mixedAmounts.clear();
                    _mixedBanks.clear();
                  });
                },
                icon: const Icon(Icons.print),
                label: const Text("Print Receipt"),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () {
                  ref.read(patientProvider.notifier).clearPatient();
                  context.router.replaceAll([
                    EnlistPaitientRoute(serviceName: 'inpatient'),
                  ]);
                  setState(() {
                    _confirmed = false;
                    _paymentMethod = null;
                    _selectedBank = null;
                    _mixedAmounts.clear();
                    _mixedBanks.clear();
                  });
                },
                icon: const Icon(Icons.bed),
                label: const Text("Process ward payment"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
