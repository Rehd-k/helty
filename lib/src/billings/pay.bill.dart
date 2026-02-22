import 'package:flutter/material.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/models/service_model.dart';

import '../paitients/patient_model.dart';

class PayBill extends StatefulWidget {
  const PayBill({
    super.key,
    required this.patient,
    required this.selectedItems,
    required this.total,
  });
  final Patient patient;
  final List<ServiceModel> selectedItems;
  final double total;

  @override
  PayBillState createState() => PayBillState();
}

class PayBillState extends State<PayBill> {
  // Data State
  late String _patientName;
  late String _patientId;
  late double _originalAmount;
  double _amountToPay = 0;
  String? _insurance;
  List<String> charges = [];
  List<ServiceModel> _items = [];
  List<String> _discounts = [];
  String? _selectedDiscount;

  // Payment State
  String? _paymentMethod;
  final List<String> _methods = ['transfer', 'pos', 'cash', 'cheque', 'mixed'];
  final Map<String, IconData> _methodIcons = {
    'transfer': Icons.account_balance,
    'pos': Icons.credit_card,
    'cash': Icons.payments,
    'cheque': Icons.history_edu, // closest to check
    'mixed': Icons.pie_chart,
  };

  // Mixed Payment State
  final Map<String, double> _mixedAmounts = {};

  bool _confirmed = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _patientName = widget.patient.firstName;
    _patientId = widget.patient.patientId;
    _originalAmount = widget.total;
    _amountToPay = _originalAmount;
    _items = widget.selectedItems;
    _fetchDetails();
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

  bool get _canPay {
    if (_paymentMethod == null) return false;
    if (_paymentMethod == 'mixed') {
      final total = _mixedAmounts.values.fold(0.0, (a, b) => a + b);
      return (total - _amountToPay).abs() < 0.001;
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
              // Update parent state as well so the main UI knows
              setState(() {});
            }

            final total = _mixedAmounts.values.fold(0.0, (a, b) => a + b);
            final remaining = _amountToPay - total;
            final isComplete = (total - _amountToPay).abs() < 0.001;

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
                  ..._methods.where((m) => m != 'mixed').map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextField(
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                        ),
                        onChanged: (t) => updateAmount(m, t),
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
                          color: remaining > 0.001 ? Colors.red : Colors.green,
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
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() {});
    });
  }

  void _makePayment() {
    setState(() => _confirmed = true);
    // In a real app, you would await the API call here
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment Processed Successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    if (_confirmed) {
      return _buildSuccessView();
    }

    // 1. Wrap the entire view in a GestureDetector to handle background clicks
    return GestureDetector(
      onTap: () =>
          Navigator.of(context).pop(), // Close when clicking the background
      child: Scaffold(
        backgroundColor:
            Colors.black45, // Gives a dimmed modal background effect
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            // 2. Wrap the Card in a GestureDetector to STOP the click from bubbling up
            // Otherwise, clicking the card itself would close the modal!
            child: GestureDetector(
              onTap: () {}, // Swallow the click
              child: Card(
                margin: const EdgeInsets.all(16),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                // 3. Use a Stack to overlay the "X" button on top of the content
                child: Stack(
                  children: [
                    // The Content
                    _isLoading
                        ? const SizedBox(
                            height: 300,
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(
                              24,
                              40,
                              24,
                              24,
                            ), // Added top padding for the X
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildHeader(),
                                const SizedBox(height: 20),
                                _buildInvoiceSection(),
                                const SizedBox(height: 20),
                                _buildPaymentSection(primaryColor),
                                const SizedBox(height: 24),
                                _buildPayButton(primaryColor),
                              ],
                            ),
                          ),
                    // 4. The Close Button (The "X")
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
              Text(
                'ID: $_patientId',
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
            return _invoiceRow(c.name, c.cost.toFinancial(isMoney: true));
          }),
          const Divider(),
          Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
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
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
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
        onPressed: _canPay && !_confirmed ? _makePayment : null,
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
                  // Reset for demo purposes
                  setState(() {
                    _confirmed = false;
                    _paymentMethod = null;
                    _mixedAmounts.clear();
                  });
                },
                icon: const Icon(Icons.print),
                label: const Text("Print Receipt"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
