import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/auth/billing_permissions.dart';
import 'package:helty/src/models/bank_model.dart';
import 'package:helty/src/models/discount_policy_models.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/models/service_model.dart';

import '../../app_router.gr.dart';
import '../paitients/patient_providers.dart';
import '../providers/auth_provider.dart';
import '../services/bank_service.dart';
import '../services/invoice_service.dart';
import '../services/transaction_service.dart';
import '../widgets/patient_consultation_credits_panel.dart';
import 'package:helty/src/printing/escpos/receipt_escpos_service.dart';
import 'package:helty/src/printing/escpos/receipt_printer_picker_sheet.dart';

// ─────────────────────────────────────────────────────────────────────────────
// These payment methods require a bank to be selected before paying.
// ─────────────────────────────────────────────────────────────────────────────
const _bankRequiredMethods = {'card', 'transfer', 'cheque'};

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

  final List<BankModel> banks;

  /// Selected bank id (matches [BankModel.id]).
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
              value: b.id,
              child: Text(b.name, style: const TextStyle(fontSize: 13)),
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
    required this.firstName,
    required this.lastName,
    required this.patientId,
    required this.isInvoice,
    required this.selectedItems,
    required this.total,
    required this.staffId,
    this.invoiceId,

    /// Human-facing bill code (`invoiceID` from API) for receipt transaction ID.
    this.invoiceDisplayId,

    /// When non-empty with [invoiceId], uses `POST /invoices/:id/allocate-item-payments`.
    /// When null/empty with [invoiceId], uses `POST /invoices/:id/payments` (header payment).
    this.invoiceItemAllocations,
    this.invoiceMaxPayable,
    this.onPaymentComplete,
    this.preserveInvoiceOnDismiss = false,
  });
  final String firstName;
  final String lastName;
  final String patientId;
  final List<ServiceModel> selectedItems;
  final double total;
  final String staffId;
  final bool isInvoice;
  final String? invoiceId;
  final String? invoiceDisplayId;

  /// Per-line amounts for allocated invoice pay; sum should match [total] before discounts.
  final List<InvoiceItemAllocationInput>? invoiceItemAllocations;
  final double? invoiceMaxPayable;

  /// Called after the payment API call succeeds so the caller can clear its cart.
  final VoidCallback? onPaymentComplete;

  /// When false (default), closing without paying deletes [invoiceId] (draft checkout).
  /// When true, the invoice is left intact (e.g. existing inpatient / pending invoice).
  final bool preserveInvoiceOnDismiss;

  @override
  PayBillState createState() => PayBillState();
}

class PayBillState extends ConsumerState<PayBill> {
  // Data State
  late String _patientName;
  late String _patientId;
  late String _staffId;
  late double _originalAmount;
  double _amountToPay = 0;
  String? _insurance;
  List<String> charges = [];
  List<ServiceModel> _items = [];
  List<ServiceModel> _itemsForPrint = [];
  List<String> _discounts = [];
  String? _selectedDiscount;
  final transactionService = TransactionService();
  final bankService = BankService();
  final _invoiceService = InvoiceService();

  // Payment State
  String? _paymentMethod;
  bool _isSubmitting = false;
  final List<String> _methods = [
    'transfer',
    'card',
    'cash',
    'wallet',
    'cheque',
    'mixed',
  ];
  final Map<String, IconData> _methodIcons = {
    'transfer': Icons.account_balance,
    'card': Icons.credit_card,
    'cash': Icons.payments,
    'wallet': Icons.account_balance_wallet_outlined,
    'cheque': Icons.history_edu,
    'mixed': Icons.pie_chart,
  };

  // Bank State
  List<BankModel> _banks = [];
  bool _banksLoading = true;

  /// Bank id selected for Card / Transfer / Cheque (single-method flow).
  String? _selectedBankId;

  /// Per-method bank ids used inside the Mixed sheet.
  final Map<String, String?> _mixedBankIds = {};

  // Mixed Payment State
  final Map<String, double> _mixedAmounts = {};

  bool _confirmed = false;
  bool _paidIncludesConsultation = false;
  bool _isLoading = true;
  List<DiscountPolicy> _discountPolicies = const [];
  bool _discountPoliciesLoading = false;
  bool _applyingInvoiceDiscount = false;
  String? _selectedInvoicePolicyId;

  /// Set from last loaded invoice; used to gate HMO-desk Pay when patient has no HMO.
  String? _invoicePatientHmoId;
  bool _hasActiveInvoiceHmoCoverage = false;
  double? _invoiceHmoCoveragePercent;
  double _invoiceCoveredAmount = 0;
  bool _isApplyingHmoCover = false;
  String? _invoiceDisplayId;

  static String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  @override
  void initState() {
    super.initState();
    _patientName =
        '${_capitalize(widget.lastName)} ${_capitalize(widget.firstName)}';
    _patientId = widget.patientId;
    _staffId = widget.staffId;
    _originalAmount = widget.total;
    final maxPayable = widget.invoiceMaxPayable;
    if (maxPayable != null && maxPayable >= 0) {
      final cap = _moneyRound(maxPayable);
      _originalAmount = _moneyRound(
        _originalAmount > cap ? cap : _originalAmount,
      );
    }
    _amountToPay = _originalAmount;
    _items = List.of(widget.selectedItems);
    _itemsForPrint = List.of(widget.selectedItems);
    final displayId = widget.invoiceDisplayId?.trim();
    _invoiceDisplayId =
        displayId != null && displayId.isNotEmpty ? displayId : null;

    _fetchDetails();
    _loadBanks();
  }

  Future<void> _loadBanks() async {
    try {
      final banks = await bankService.fetchBanks();
      if (mounted) {
        setState(() {
          _banks = banks.data;
          _banksLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _banksLoading = false);
    }
  }

  /// Maps UI payment method to invoice payment `source` (backend enum).
  static String _invoicePaymentSource(String? method) {
    switch (method) {
      case 'cash':
        return 'CASH';
      case 'card':
        return 'CARD';
      case 'transfer':
      case 'cheque':
        return 'TRANSFER';
      case 'wallet':
        return 'WALLET';
      case 'mixed':
        return 'CASH';
      default:
        return 'CASH';
    }
  }

  /// `TransactionPaymentMethod` for allocate-item-payments.
  static String _allocateItemPaymentMethod(String? method) {
    switch (method) {
      case 'cash':
        return 'CASH';
      case 'card':
        return 'CARD';
      case 'transfer':
        return 'TRANSFER';
      case 'cheque':
        return 'TRANSFER';
      case 'wallet':
        return 'WALLET';
      case 'mixed':
        return 'CASH';
      default:
        return 'CASH';
    }
  }

  static double _moneyRound(double x) => (x * 100).round() / 100.0;

  static bool _coverageStatusBlocksDiscountReversal(String status) {
    final s = status.trim().toUpperCase();
    return s == 'SETTLED' || s == 'REVERSED';
  }

  bool _isReversibleDiscountInvoiceCoverage(InvoiceCoverage c) {
    if (c.kind.trim().toUpperCase() != 'DISCOUNT') return false;
    if (c.scope.trim().toUpperCase() != 'INVOICE') return false;
    return !_coverageStatusBlocksDiscountReversal(c.status);
  }

  bool _hasActiveHmoInvoiceCoverage(BillingInvoiceDetail detail) {
    for (final c in detail.coverages) {
      if (c.kind.trim().toUpperCase() != 'HMO') continue;
      if (c.scope.trim().toUpperCase() != 'INVOICE') continue;
      final s = c.status.trim().toUpperCase();
      if (s == 'REVERSED' || s == 'CANCELLED' || s == 'VOIDED') continue;
      return true;
    }
    // Fallback for payloads where coverage rows lag but amounts are already split.
    if (detail.coveredAmount > 0.005) return true;
    return false;
  }

  InvoiceCoverage? _activeHmoInvoiceCoverage(BillingInvoiceDetail detail) {
    for (final c in detail.coverages) {
      if (c.kind.trim().toUpperCase() != 'HMO') continue;
      if (c.scope.trim().toUpperCase() != 'INVOICE') continue;
      final s = c.status.trim().toUpperCase();
      if (s == 'REVERSED' || s == 'CANCELLED' || s == 'VOIDED') continue;
      return c;
    }
    return null;
  }

  /// Re-fetch after each reversal so remaining DISCOUNT rows are current.
  Future<void> _reverseAllReversibleDiscountInvoiceCoverages(String invoiceId) async {
    final staff = ref.read(authProvider).staff;
    if (!canReverseCoverage(staff)) return;
    while (mounted) {
      final detail = await _invoiceService.getBillingInvoice(invoiceId);
      final next = detail.coverages.where(_isReversibleDiscountInvoiceCoverage).toList();
      if (next.isEmpty) return;
      await _invoiceService.reverseCoverage(
        invoiceId: invoiceId,
        coverageId: next.first.id,
        reason: 'Change discount selection',
      );
    }
  }

  void _syncFromInvoiceDetail(BillingInvoiceDetail detail) {
    final displayId = detail.invoiceDisplayId?.trim();
    _invoiceDisplayId =
        displayId != null && displayId.isNotEmpty ? displayId : _invoiceDisplayId;
    final id = detail.patientHmoId?.trim();
    _invoicePatientHmoId = (id == null || id.isEmpty) ? null : id;
    final name = detail.patientHmoName?.trim();
    if (name != null && name.isNotEmpty) {
      _insurance = name;
    } else if (id != null && id.isNotEmpty) {
      final short = id.length > 10 ? '${id.substring(0, 10)}…' : id;
      _insurance = 'Plan ID $short';
    } else {
      _insurance = 'None';
    }
    final activeHmo = _activeHmoInvoiceCoverage(detail);
    _hasActiveInvoiceHmoCoverage =
        activeHmo != null || detail.coveredAmount > 0.005;
    _invoiceHmoCoveragePercent =
        activeHmo?.percent ?? detail.patientHmoDefaultCoveragePercent;
    _invoiceCoveredAmount = _moneyRound(detail.coveredAmount);
  }

  bool get _hasInvoiceId {
    final invId = widget.invoiceId?.trim();
    return invId != null && invId.isNotEmpty;
  }

  bool get _isHmoStaff {
    final staff = ref.read(authProvider).staff;
    return canSplitWithHmo(staff);
  }

  bool get _isHmoInvoiceFlow => widget.isInvoice && _hasInvoiceId && _isHmoStaff;

  bool get _hasPatientHmoOnInvoice {
    final hmoId = _invoicePatientHmoId?.trim();
    return hmoId != null && hmoId.isNotEmpty;
  }

  bool get _canShowCoverButton =>
      _isHmoInvoiceFlow && _hasPatientHmoOnInvoice && !_hasActiveInvoiceHmoCoverage;

  bool get _canShowPaymentMethods => !_isHmoStaff;

  bool get _canShowPayButton => !_isHmoStaff;

  bool get _isHmoDeskInvoicePayBlocked {
    if (!widget.isInvoice) return false;
    if (!_hasInvoiceId) return false;
    if (!_isHmoStaff) return false;
    return !_hasPatientHmoOnInvoice;
  }

  /// Scales line allocations when discounts change [_amountToPay] vs original sum.
  List<InvoiceItemAllocationDto> _buildScaledAllocations() {
    final inputs = widget.invoiceItemAllocations;
    if (inputs == null || inputs.isEmpty) return [];
    final sum0 = inputs.fold(0.0, (s, e) => s + e.amount);
    if (sum0 <= 0) return [];
    final target = _moneyRound(_amountToPay);
    if (inputs.length == 1) {
      return [
        InvoiceItemAllocationDto(
          invoiceItemId: inputs.first.invoiceItemId,
          amount: target,
        ),
      ];
    }
    final scaled = inputs
        .map((e) => _moneyRound(target * e.amount / sum0))
        .toList();
    final acc = scaled.fold(0.0, (a, b) => a + b);
    var diff = _moneyRound(target - acc);
    if (scaled.isNotEmpty && diff != 0) {
      scaled[scaled.length - 1] = _moneyRound(scaled.last + diff);
    }
    return List.generate(
      inputs.length,
      (i) => InvoiceItemAllocationDto(
        invoiceItemId: inputs[i].invoiceItemId,
        amount: scaled[i],
      ),
    );
  }

  /// Best-effort balance from `GET /invoices/:id` when `amountDue` / `netAmountDue` are missing or still zero.
  double _outstandingFromDetail(BillingInvoiceDetail d, double cartFallback) {
    double tryVal(double x) => _moneyRound(x);

    final fromEffective = d.effectivePayable - d.amountPaid;
    if (fromEffective > 0.005) return tryVal(fromEffective);
    if (d.netAmountDue > 0.005) return tryVal(d.netAmountDue);
    if (d.amountDue > 0.005) return tryVal(d.amountDue);
    final fromTotals = d.totalAmount - d.amountPaid;
    if (fromTotals > 0.005) return tryVal(fromTotals);
    final fromLines = d.invoiceItems.fold<double>(
      0,
      (s, i) => s + i.lineAmountDue,
    );
    if (fromLines > 0.005) return tryVal(fromLines);
    if (cartFallback > 0.005) return tryVal(cartFallback);
    return 0;
  }

  /// Computes payable amount from a fresh [BillingInvoiceDetail] (after discount/coverage refresh).
  double _payAmountFromDetail(BillingInvoiceDetail detail) {
    final outstanding = _outstandingFromDetail(detail, widget.total);
    final hasAlloc =
        widget.invoiceItemAllocations != null &&
        widget.invoiceItemAllocations!.isNotEmpty;

    if (hasAlloc) {
      final t = _moneyRound(widget.total);
      final cap = outstanding > 0.005 ? outstanding : t;
      final widgetCap = widget.invoiceMaxPayable;
      final hardCap = widgetCap != null && widgetCap > 0
          ? _moneyRound(widgetCap)
          : cap;
      var use = t > hardCap + 0.02 ? hardCap : t;
      if (use > cap + 0.02) use = cap;
      return use;
    }
    var use = outstanding > 0.005 ? outstanding : _moneyRound(widget.total);
    final widgetCap = widget.invoiceMaxPayable;
    if (widgetCap != null && widgetCap >= 0 && use > widgetCap) {
      use = _moneyRound(widgetCap);
    }
    return use;
  }

  Future<void> _fetchDetails() async {
    final invId = widget.invoiceId?.trim();
    if (invId == null || invId.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _insurance = '-';
          _invoicePatientHmoId = null;
          _hasActiveInvoiceHmoCoverage = false;
          _invoiceHmoCoveragePercent = null;
          _invoiceCoveredAmount = 0;
          _discounts = ['None'];
          _isLoading = false;
        });
      }
      return;
    }

    final staff = ref.read(authProvider).staff;
    final loadPolicies = widget.isInvoice && canApplyDiscount(staff);

    setState(() {
      _discountPoliciesLoading = loadPolicies;
    });

    try {
      final detail = await _invoiceService.getBillingInvoice(invId);
      List<DiscountPolicy> policies = const [];
      if (loadPolicies) {
        try {
          policies = await _invoiceService.getActiveDiscountPolicies();
        } catch (_) {
          policies = const [];
        }
      }
      if (!mounted) return;
      final use = _payAmountFromDetail(detail);

      setState(() {
        _originalAmount = use;
        _amountToPay = use;
        _syncFromInvoiceDetail(detail);
        _discounts = ['None'];
        _discountPolicies = policies;
        _discountPoliciesLoading = false;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _insurance = '-';
        _invoicePatientHmoId = null;
        _hasActiveInvoiceHmoCoverage = false;
        _invoiceHmoCoveragePercent = null;
        _invoiceCoveredAmount = 0;
        _discounts = ['None'];
        _discountPoliciesLoading = false;
        _isLoading = false;
      });
    }
  }

  Future<void> _applyHmoCover() async {
    final invId = widget.invoiceId?.trim();
    if (invId == null || invId.isEmpty) return;
    if (_isApplyingHmoCover || _isSubmitting) return;
    if (!_hasPatientHmoOnInvoice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient has no HMO on file.')),
      );
      return;
    }

    setState(() => _isApplyingHmoCover = true);
    try {
      var detail = await _invoiceService.getBillingInvoice(invId);
      if (!_hasActiveHmoInvoiceCoverage(detail)) {
        final percentOverride = detail.patientHmoDefaultCoveragePercent;
        await _invoiceService.applyHmoCoverage(
          invoiceId: invId,
          scope: 'INVOICE',
          percentOverride: percentOverride,
        );
        // Always re-fetch after apply so UI uses authoritative invoice state.
        detail = await _invoiceService.getBillingInvoice(invId);
      }
      if (!mounted) return;
      final use = _payAmountFromDetail(detail);
      setState(() {
        _originalAmount = use;
        _amountToPay = use;
        _syncFromInvoiceDetail(detail);
        _mixedAmounts.clear();
        _paymentMethod = null;
        _selectedBankId = null;
        _isApplyingHmoCover = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('HMO coverage applied.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isApplyingHmoCover = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply HMO coverage: $e')),
      );
    }
  }

  Future<void> _onInvoiceDiscountPolicySelected(String? value) async {
    final invId = widget.invoiceId?.trim();
    if (invId == null || invId.isEmpty) return;
    final staff = ref.read(authProvider).staff;
    if (!canApplyDiscount(staff)) return;

    if (value == null || value == '__none__') {
      setState(() => _applyingInvoiceDiscount = true);
      try {
        await _reverseAllReversibleDiscountInvoiceCoverages(invId);
        final detail = await _invoiceService.getBillingInvoice(invId);
        if (!mounted) return;
        final use = _payAmountFromDetail(detail);
        setState(() {
          _selectedInvoicePolicyId = null;
          _selectedDiscount = null;
          _originalAmount = use;
          _amountToPay = use;
          _syncFromInvoiceDetail(detail);
          _mixedAmounts.clear();
          _applyingInvoiceDiscount = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _applyingInvoiceDiscount = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
      return;
    }

    setState(() => _applyingInvoiceDiscount = true);
    try {
      await _reverseAllReversibleDiscountInvoiceCoverages(invId);
      await _invoiceService.applyDiscountCoverage(
        invoiceId: invId,
        policyId: value,
        scope: 'INVOICE',
      );
      final detail = await _invoiceService.getBillingInvoice(invId);
      if (!mounted) return;
      final use = _payAmountFromDetail(detail);
      DiscountPolicy? policy;
      for (final p in _discountPolicies) {
        if (p.id == value) {
          policy = p;
          break;
        }
      }
      setState(() {
        _originalAmount = use;
        _amountToPay = use;
        _syncFromInvoiceDetail(detail);
        _selectedInvoicePolicyId = value;
        _selectedDiscount = policy?.name;
        _applyingInvoiceDiscount = false;
        _mixedAmounts.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              policy != null
                  ? 'Discount "${policy.name}" applied'
                  : 'Discount applied',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _applyingInvoiceDiscount = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  BankModel? _bankById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final b in _banks) {
      if (b.id == id) return b;
    }
    return null;
  }

  /// Bank id used for the current payment (single method or first chosen in mixed).
  String? _selectedBankIdForPayment() {
    if (_paymentMethod == 'mixed') {
      return _mixedBankIds.entries
          .firstWhere(
            (e) => e.value != null && e.value!.isNotEmpty,
            orElse: () => const MapEntry('', null),
          )
          .value;
    }
    if (_bankRequiredMethods.contains(_paymentMethod)) {
      return _selectedBankId;
    }
    return null;
  }

  BankModel? _selectedBankForPayment() =>
      _bankById(_selectedBankIdForPayment());

  void _applyDiscount(String? discount) {
    if (widget.isInvoice) return;
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
    if (!_canShowPayButton) return false;
    if (_paymentMethod == null) return false;

    if (_isHmoDeskInvoicePayBlocked) return false;

    if (_paymentMethod == 'mixed') {
      final total = _mixedAmounts.values.fold(0.0, (a, b) => a + b);
      if ((total - _amountToPay).abs() >= 0.001) return false;
      // All bank-required methods used in mixed must have a bank selected.
      for (final m in _bankRequiredMethods) {
        final amount = _mixedAmounts[m] ?? 0;
        if (amount > 0 &&
            (_mixedBankIds[m] == null || _mixedBankIds[m]!.isEmpty)) {
          return false;
        }
      }
      return true;
    }

    // For bank-required single methods, a bank must be chosen.
    if (_bankRequiredMethods.contains(_paymentMethod)) {
      return _selectedBankId != null && _selectedBankId!.isNotEmpty;
    }

    return true;
  }

  List<Map<String, dynamic>> _receiptItemSnapshots() {
    return _itemsForPrint.map((s) {
      final qty = s.qty ?? 1;
      final lineTotal = s.displayLineTotal;
      return {
        'description': s.name,
        'quantity': qty,
        'total': lineTotal.toString(),
      };
    }).toList();
  }

  Map<String, dynamic> _receiptDataForPrinter() {
    final discount = _originalAmount > _amountToPay
        ? _originalAmount - _amountToPay
        : 0.0;
    final staff = ref.read(authProvider).staff;
    return ReceiptEscposService.fromPayBillSnapshot(
      patientName: _patientName,
      patientId: _patientId,
      cashierFirst: staff?.firstName ?? '',
      cashierLast: staff?.lastName ?? '',
      itemSnapshots: _receiptItemSnapshots(),
      totalAmount: _amountToPay,
      discountAmount: discount,
      amountPaid: _amountToPay,
      transactionId: _invoiceDisplayId ?? widget.invoiceDisplayId,
    );
  }

  void _openReceiptPrinterPicker() {
    showReceiptPrinterPickerSheet(context, data: _receiptDataForPrinter());
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

            void updateMixedBank(String method, String? bankId) {
              setModalState(() {
                _mixedBankIds[method] = bankId;
              });
              setState(() {});
            }

            final total = _mixedAmounts.values.fold(0.0, (a, b) => a + b);
            final remaining = _amountToPay - total;
            final isComplete = (total - _amountToPay).abs() < 0.001 && _canPay;

            return Container(
              decoration: const BoxDecoration(
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
                          (_mixedBankIds[m] != null &&
                              _mixedBankIds[m]!.isNotEmpty);

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
                                value: _mixedBankIds[m],
                                isLoading: _banksLoading,
                                onChanged: (bankId) =>
                                    updateMixedBank(m, bankId),
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

  bool _selectedItemsIncludeConsultation() {
    for (final item in widget.selectedItems) {
      final cat = (item.categoryName ?? '').toLowerCase();
      final name = item.name.toLowerCase();
      if (cat.contains('consultation') || name.contains('consultation')) {
        return true;
      }
    }
    return false;
  }

  Future<void> _makePayment() async {
    final bank = _selectedBankForPayment();
    final bankName = bank?.name;
    final accountNumber = bank?.accountNumber.trim();
    final bankAccountNumber = accountNumber != null && accountNumber.isNotEmpty
        ? accountNumber
        : null;

    // Build mixedBreakdown with bank info embedded if needed
    Map<String, dynamic>? mixedBreakdownWithBanks;
    if (_paymentMethod == 'mixed') {
      mixedBreakdownWithBanks = {};
      for (final m in _methods.where((m) => m != 'mixed')) {
        final amount = _mixedAmounts[m] ?? 0;
        if (amount > 0) {
          final b = _bankById(_mixedBankIds[m]);
          mixedBreakdownWithBanks[m] = {
            'amount': amount,
            if (b != null) 'bankName': b.name,
            if (b != null && b.accountNumber.trim().isNotEmpty)
              'bankAccountNumber': b.accountNumber.trim(),
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
      final invId = widget.invoiceId?.trim();
      if (_isHmoInvoiceFlow && !_hasActiveInvoiceHmoCoverage) {
        throw Exception('Apply HMO cover before taking payment');
      }

      final useAllocate =
          invId != null &&
          invId.isNotEmpty &&
          widget.invoiceItemAllocations != null &&
          widget.invoiceItemAllocations!.isNotEmpty;

      if (useAllocate) {
        final allocations = _buildScaledAllocations();
        if (allocations.isEmpty) {
          throw Exception('No line allocations to submit');
        }
        final allocSum = allocations.fold(0.0, (s, e) => s + e.amount);
        if ((allocSum - _amountToPay).abs() > 0.02) {
          throw Exception('Allocation total does not match amount to pay');
        }
        await _invoiceService.allocateInvoiceItemPayments(
          invoiceId: invId,
          payload: AllocateInvoiceItemPaymentsPayload(
            staffId: _staffId,
            amount: _moneyRound(_amountToPay),
            method: _allocateItemPaymentMethod(_paymentMethod),
            reference: _paymentMethod == 'mixed'
                ? 'paybill_mixed'
                : (_selectedDiscount ?? 'paybill'),
            bankAccountNumber: bankAccountNumber,
            allocations: allocations,
          ),
        );
      } else if (invId != null && invId.isNotEmpty) {
        await _invoiceService.recordInvoicePayment(
          invoiceId: invId,
          payload: RecordPaymentPayload(
            amount: _amountToPay,
            source: _invoicePaymentSource(_paymentMethod),
            method: _allocateItemPaymentMethod(_paymentMethod),
            reference: _paymentMethod == 'mixed'
                ? 'paybill_mixed'
                : (_selectedDiscount ?? 'paybill'),
            bankAccountNumber: bankAccountNumber,
          ),
        );
      } else {
        await transactionService.createQuickTransaction(dto);
      }
      if (mounted) {
        setState(() {
          _confirmed = true;
          _isSubmitting = false;
          _paidIncludesConsultation = _selectedItemsIncludeConsultation();
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

  Future<void> _handleCloseModal() async {
    if (_isSubmitting) return;

    final invId = widget.invoiceId?.trim();
    final shouldKeepInvoice =
        widget.preserveInvoiceOnDismiss || _hasActiveInvoiceHmoCoverage;
    if (!_confirmed &&
        !shouldKeepInvoice &&
        invId != null &&
        invId.isNotEmpty) {
      try {
        await _invoiceService.deleteInvoice(invId);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red.shade600,
            content: Text('Failed to discard invoice: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_confirmed) {
      return _buildSuccessView();
    }

    return GestureDetector(
      onTap: _handleCloseModal,
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
                                if (_canShowPaymentMethods) ...[
                                  const SizedBox(height: 20),
                                  _buildPaymentSection(
                                    Theme.of(context).primaryColor,
                                  ),
                                ] else ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _isHmoStaff
                                        ? 'HMO desk cannot take direct payment here.'
                                        : (_isHmoDeskInvoicePayBlocked
                                              ? 'Patient has no HMO on file.'
                                              : 'Apply HMO cover to continue.'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 24),
                                if (_canShowCoverButton)
                                  _buildCoverButton(
                                    Theme.of(context).colorScheme.secondary,
                                  ),
                                if (_canShowCoverButton) const SizedBox(height: 12),
                                if (_canShowPayButton)
                                  _buildPayButton(Theme.of(context).primaryColor),
                                if (_isHmoDeskInvoicePayBlocked) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Patient has no HMO on file.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.orange.shade800,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ],
                            ),
                          ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: _handleCloseModal,
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
          child: Text(
            _isHmoStaff ? 'HMO' : 'BILLING',
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

  Widget _buildInvoiceDiscountRow() {
    final staff = ref.watch(authProvider).staff;
    final allowed = canApplyDiscount(staff);
    if (!allowed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'Discount policies can be applied by billing, CMD, CMAC, or admin.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
      );
    }
    if (_discountPoliciesLoading || _isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    if (_discountPolicies.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'No active discount policies. Create one under Discount Policies.',
          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
        ),
      );
    }
    final sorted = List<DiscountPolicy>.from(_discountPolicies)
      ..sort((a, b) {
        final c = a.reason.compareTo(b.reason);
        if (c != 0) return c;
        return a.name.compareTo(b.name);
      });
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem<String>(
        value: '__none__',
        child: Text('No discount (remove policy coverage)'),
      ),
      ...sorted.map(
        (p) => DropdownMenuItem<String>(
          value: p.id,
          child: Text(
            '${p.reason} — ${p.name} (${p.mode} ${p.value})',
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];
    return Row(
      children: [
        const Icon(Icons.discount_outlined, size: 18, color: Colors.orange),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isDense: true,
              isExpanded: true,
              hint: const Text('Apply discount policy'),
              value: _selectedInvoicePolicyId ?? '__none__',
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              items: items,
              onChanged: _applyingInvoiceDiscount
                  ? null
                  : (v) => _onInvoiceDiscountPolicySelected(v),
            ),
          ),
        ),
        if (_applyingInvoiceDiscount)
          const Padding(
            padding: EdgeInsets.only(left: 8),
            child: SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  Widget _buildInvoiceSection() {
    final hasInsurance = _insurance != null && _insurance != 'None';
    final hmoPercent = _invoiceHmoCoveragePercent;
    final patientShare = _moneyRound(_amountToPay);
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
            if (hasInsurance) ...[
              _invoiceRow(
                'Coverage',
                hmoPercent != null
                    ? '${hmoPercent.toStringAsFixed(0)}%'
                    : (_hasActiveInvoiceHmoCoverage ? 'Applied' : 'Pending'),
              ),
              _invoiceRow(
                'Covered Amount',
                _invoiceCoveredAmount.toFinancial(isMoney: true),
              ),
              _invoiceRow(
                'Patient Payable',
                patientShare.toFinancial(isMoney: true),
                isBold: true,
              ),
            ],
            const Divider(),
          ],
          ..._items.map((c) {
            final qty = c.qty ?? 1;
            final lineTotal = c.displayLineTotal;
            final label = qty > 1 ? '${c.name}  x$qty' : c.name;
            return _invoiceRow(label, lineTotal.toFinancial(isMoney: true));
          }),
          const Divider(),
          if (widget.isInvoice &&
              widget.invoiceId != null &&
              widget.invoiceId!.trim().isNotEmpty)
            _buildInvoiceDiscountRow()
          else
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
                      hint: const Text('Select Discount'),
                      value: _selectedDiscount ?? 'None',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                      items: _discounts
                          .map(
                            (d) => DropdownMenuItem(value: d, child: Text(d)),
                          )
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
                  _selectedBankId = null; // reset bank when method changes
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

        // ── Bank dropdown (shown for Card / Transfer / Cheque) ──────────────
        if (needsBank) ...[
          const SizedBox(height: 16),
          BankDropdown(
            banks: _banks,
            value: _selectedBankId,
            isLoading: _banksLoading,
            onChanged: (bankId) => setState(() => _selectedBankId = bankId),
          ),
          if (_selectedBankId == null)
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

  Widget _buildCoverButton(Color buttonColor) {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: buttonColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: _isApplyingHmoCover || _isSubmitting ? null : _applyHmoCover,
        child: _isApplyingHmoCover
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Cover',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Card(
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
                if (_paidIncludesConsultation) ...[
                  const SizedBox(height: 16),
                  Text(
                    'This payment includes OPD consultation credit: up to 2 '
                    'completed visits within 14 days of payment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      height: 1.35,
                    ),
                  ),
                  if (_patientId.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    PatientConsultationCreditsPanel(patientId: _patientId),
                  ],
                ],
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _openReceiptPrinterPicker,
                      icon: const Icon(Icons.print),
                      label: const Text('Print receipt'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        ref.read(patientProvider.notifier).clearPatient();
                        Navigator.pop(context);
                        context.router.replaceAll([
                          EnlistPaitientRoute(serviceName: ''),
                        ]);
                        setState(() {
                          _confirmed = false;
                          _paymentMethod = null;
                          _selectedBankId = null;
                          _mixedAmounts.clear();
                          _mixedBankIds.clear();
                        });
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Done'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
