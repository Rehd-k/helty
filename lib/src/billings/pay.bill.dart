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
import 'hmo_coverage_ui.dart';
import '../widgets/patient_consultation_credits_panel.dart';
import 'package:helty/src/printing/escpos/receipt_escpos_service.dart';
import 'package:helty/src/printing/escpos/receipt_printer_picker_sheet.dart';
import 'package:helty/src/wallet/wallet_deposit_dialog.dart';
import 'package:helty/src/wallet/wallet_providers.dart';
import 'package:helty/src/core/widgets/patient_avatar.dart';
import 'package:helty/src/shared/department_colors.dart';
import 'package:helty/src/core/layout/app_breakpoints.dart';

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
    this.patientDisplayName,
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

  /// Full formatted patient label for UI and receipts (title + all name parts).
  final String? patientDisplayName;
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

  /// Outstanding before any discount previewed in this dialog.
  double _basePayable = 0;
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
  String? _selectedInvoicePolicyId;

  /// Set from last loaded invoice; used to gate HMO-desk Pay when patient has no HMO.
  String? _invoicePatientHmoId;
  bool _hasActiveInvoiceHmoCoverage = false;
  InvoiceCoverage? _activeHmoCoverage;
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
    final formatted = widget.patientDisplayName?.trim();
    if (formatted != null && formatted.isNotEmpty) {
      _patientName = formatted;
    } else {
      _patientName =
          '${_capitalize(widget.lastName)} ${_capitalize(widget.firstName)}'
              .trim();
    }
    if (_patientName.isEmpty) {
      _patientName = 'Patient';
    }
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
    _basePayable = _originalAmount;
    _amountToPay = _originalAmount;
    _items = List.of(widget.selectedItems);
    _itemsForPrint = List.of(widget.selectedItems);
    final displayId = widget.invoiceDisplayId?.trim();
    _invoiceDisplayId = displayId != null && displayId.isNotEmpty
        ? displayId
        : null;

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

  bool get _isZeroPayable => _amountToPay <= 0.005;

  double _previewPayableAfterPolicy(double base, DiscountPolicy policy) {
    final mode = policy.mode.trim().toUpperCase();
    if (mode == 'PERCENT') {
      final pct = policy.value.clamp(0, 100);
      return _moneyRound(base * (100 - pct) / 100);
    }
    if (mode == 'FIXED') {
      return _moneyRound((base - policy.value).clamp(0, double.infinity));
    }
    return base;
  }

  DiscountPolicy? _discountPolicyById(String? id) {
    if (id == null || id.isEmpty || id == '__none__') return null;
    for (final p in _discountPolicies) {
      if (p.id == id) return p;
    }
    return null;
  }

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
    return activeHmoInvoiceCoverage(detail.coverages) != null;
  }

  InvoiceCoverage? _activeHmoInvoiceCoverage(BillingInvoiceDetail detail) {
    return activeHmoInvoiceCoverage(detail.coverages);
  }

  /// Re-fetch after each reversal so remaining DISCOUNT rows are current.
  Future<void> _reverseAllReversibleDiscountInvoiceCoverages(
    String invoiceId,
  ) async {
    final staff = ref.read(authProvider).staff;
    if (!canReverseCoverage(staff)) return;
    while (mounted) {
      final detail = await _invoiceService.getBillingInvoice(invoiceId);
      final next = detail.coverages
          .where(_isReversibleDiscountInvoiceCoverage)
          .toList();
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
    _invoiceDisplayId = displayId != null && displayId.isNotEmpty
        ? displayId
        : _invoiceDisplayId;
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
    _activeHmoCoverage = activeHmo;
    _hasActiveInvoiceHmoCoverage = activeHmo != null;
    _invoiceHmoCoveragePercent =
        activeHmo?.percent ??
        activeHmo?.value ??
        detail.patientHmoDefaultCoveragePercent;
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

  bool get _isHmoInvoiceFlow =>
      widget.isInvoice && _hasInvoiceId && _isHmoStaff;

  bool get _hasPatientHmoOnInvoice {
    final hmoId = _invoicePatientHmoId?.trim();
    return hmoId != null && hmoId.isNotEmpty;
  }

  bool get _canShowCoverButton =>
      _isHmoInvoiceFlow &&
      _hasPatientHmoOnInvoice &&
      !_hasActiveInvoiceHmoCoverage;

  bool get _canShowUncoverButton {
    if (!_isHmoInvoiceFlow || !_hasActiveInvoiceHmoCoverage) return false;
    final coverage = _activeHmoCoverage;
    if (coverage == null) return false;
    return isHmoCoverageReversibleWithin24h(coverage);
  }

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
          _activeHmoCoverage = null;
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
        _basePayable = use;
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
        _activeHmoCoverage = null;
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

    final percent = await showApplyHmoPercentDialog(
      context,
      defaultPercent: _invoiceHmoCoveragePercent,
    );
    if (percent == null || !mounted) return;

    setState(() => _isApplyingHmoCover = true);
    try {
      var detail = await _invoiceService.getBillingInvoice(invId);
      if (!_hasActiveHmoInvoiceCoverage(detail)) {
        await _invoiceService.applyHmoCoverage(
          invoiceId: invId,
          scope: 'INVOICE',
          percentOverride: percent,
        );
        // Always re-fetch after apply so UI uses authoritative invoice state.
        detail = await _invoiceService.getBillingInvoice(invId);
      }
      if (!mounted) return;
      final use = _payAmountFromDetail(detail);
      setState(() {
        _basePayable = use;
        _originalAmount = use;
        _amountToPay = use;
        _syncFromInvoiceDetail(detail);
        _mixedAmounts.clear();
        _paymentMethod = null;
        _selectedBankId = null;
        _isApplyingHmoCover = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('HMO coverage applied.')));
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isApplyingHmoCover = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to apply HMO coverage: $e')),
      );
    }
  }

  Future<void> _uncoverHmo() async {
    final invId = widget.invoiceId?.trim();
    final coverage = _activeHmoCoverage;
    if (invId == null || invId.isEmpty || coverage == null) return;
    if (_isApplyingHmoCover || _isSubmitting) return;
    if (!isHmoCoverageReversibleWithin24h(coverage)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'HMO coverage can only be reversed within 24 hours of apply.',
          ),
        ),
      );
      return;
    }

    final confirmed = await showUncoverHmoDialog(context);
    if (confirmed == null || !mounted) return;

    setState(() => _isApplyingHmoCover = true);
    try {
      final detail = await _invoiceService.reverseCoverage(
        invoiceId: invId,
        coverageId: coverage.id,
        reason: confirmed.reason,
      );
      if (!mounted) return;
      final use = _payAmountFromDetail(detail);
      setState(() {
        _basePayable = use;
        _originalAmount = use;
        _amountToPay = use;
        _syncFromInvoiceDetail(detail);
        _mixedAmounts.clear();
        _paymentMethod = null;
        _selectedBankId = null;
        _isApplyingHmoCover = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'HMO coverage removed. You can re-apply or leave it uncovered.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isApplyingHmoCover = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to uncover HMO: $e')));
    }
  }

  void _onInvoiceDiscountPolicySelected(String? value) {
    if (value == null || value == '__none__') {
      setState(() {
        _selectedInvoicePolicyId = null;
        _selectedDiscount = null;
        _amountToPay = _basePayable;
        _mixedAmounts.clear();
        _paymentMethod = null;
        _selectedBankId = null;
      });
      return;
    }

    final policy = _discountPolicyById(value);
    if (policy == null) return;

    setState(() {
      _selectedInvoicePolicyId = value;
      _selectedDiscount = policy.name;
      _amountToPay = _previewPayableAfterPolicy(_basePayable, policy);
      _mixedAmounts.clear();
      _paymentMethod = null;
      _selectedBankId = null;
    });
  }

  Future<void> _applyPendingDiscountOnServer() async {
    final invId = widget.invoiceId?.trim();
    final policyId = _selectedInvoicePolicyId;
    if (invId == null || invId.isEmpty) return;
    if (policyId == null || policyId == '__none__') return;

    await _reverseAllReversibleDiscountInvoiceCoverages(invId);
    await _invoiceService.applyDiscountCoverage(
      invoiceId: invId,
      policyId: policyId,
      scope: 'INVOICE',
    );
    final detail = await _invoiceService.getBillingInvoice(invId);
    if (!mounted) return;
    _syncFromInvoiceDetail(detail);
    // Only refresh payable when patient still owes — avoid overwriting a
    // zero preview with gross outstanding before coverage settles in totals.
    if (_amountToPay > 0.005) {
      _amountToPay = _payAmountFromDetail(detail);
    }
  }

  void _completeCheckoutSuccess() {
    if (!mounted) return;
    setState(() {
      _confirmed = true;
      _isSubmitting = false;
      _paidIncludesConsultation = _selectedItemsIncludeConsultation();
    });
    widget.onPaymentComplete?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    if (_isHmoDeskInvoicePayBlocked) return false;
    if (_isZeroPayable) return true;
    if (_paymentMethod == null) return false;

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
            final colorScheme = Theme.of(context).colorScheme;

            return Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
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
                                    color: colorScheme.outlineVariant,
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
                                ? colorScheme.error
                                : DepartmentColors.pharmacy,
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
                              ? DepartmentColors.pharmacy
                              : colorScheme.surfaceContainerHighest,
                          foregroundColor: isComplete
                              ? Colors.white
                              : colorScheme.onSurfaceVariant,
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
    if (_isSubmitting) return;
    // Capture before apply — server refresh can leave a non-zero outstanding
    // even when discount coverage fully waives patient share.
    final freeCheckout = _isZeroPayable;
    setState(() => _isSubmitting = true);
    try {
      await _applyPendingDiscountOnServer();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
          content: Text('Failed to apply discount: $e'),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }
    if (!mounted) return;
    if (freeCheckout) {
      _completeCheckoutSuccess();
      return;
    }
    await _submitPayment();
  }

  Future<void> _submitPayment() async {
    if (_isZeroPayable) {
      _completeCheckoutSuccess();
      return;
    }

    final paymentMethod = _paymentMethod ?? 'cash';
    final bank = _selectedBankForPayment();
    final bankName = bank?.name;
    final accountNumber = bank?.accountNumber.trim();
    final bankAccountNumber = accountNumber != null && accountNumber.isNotEmpty
        ? accountNumber
        : null;

    final dto = QuickTransactionDto(
      patientId: _patientId,
      staffId: _staffId,
      amountPaid: _amountToPay,
      paymentMethod: paymentMethod,
      discount: _amountToPay < _originalAmount
          ? _originalAmount - _amountToPay
          : 0,
      notes: _selectedDiscount,
      bankName: bankName,
      mixedBreakdown: paymentMethod == 'mixed'
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
            amount: _moneyRound(_amountToPay),
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
      _completeCheckoutSuccess();
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        final msg = e.toString();
        if (msg.toLowerCase().contains('insufficient wallet balance')) {
          await _showInsufficientWalletDialog(msg);
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
            content: Text('Payment failed: $e'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _showInsufficientWalletDialog(String message) async {
    final patient = ref.read(patientProvider).selectedPatient;
    final chartNumber = patient?.patientId ?? widget.patientId;
    final patientName =
        '${widget.firstName} ${widget.lastName}'.trim().isNotEmpty
        ? '${widget.firstName} ${widget.lastName}'.trim()
        : (patient != null ? patient.displayName.trim() : 'Patient');
    final patientUuid = patient?.id ?? widget.patientId;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        final width = AppBreakpoints.of(ctx).dialogWidth(ctx, max: 480);
        return SizedBox(
          width: width,
          child: AlertDialog(
            title: const Text('Insufficient wallet balance'),
            content: Text(message.replaceFirst('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  if (patientUuid.trim().isEmpty) return;
                  await WalletDepositDialog.show(
                    context,
                    ref: ref,
                    patientUuid: patientUuid,
                    patientName: patientName,
                    chartNumber: chartNumber,
                    onSuccess: () =>
                        invalidatePatientWalletHistory(ref, patientUuid),
                  );
                },
                child: const Text('Fund wallet'),
              ),
            ],
          ),
        );
      },
    );
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
            backgroundColor: Theme.of(context).colorScheme.error,
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
                                if (_canShowPaymentMethods &&
                                    !_isZeroPayable) ...[
                                  const SizedBox(height: 20),
                                  _buildPaymentSection(
                                    Theme.of(context).primaryColor,
                                  ),
                                ] else if (!_canShowPaymentMethods) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    _isHmoStaff
                                        ? 'HMO desk cannot take direct payment here.'
                                        : (_isHmoDeskInvoicePayBlocked
                                              ? 'Patient has no HMO on file.'
                                              : 'Apply HMO cover to continue.'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: DepartmentColors.billing,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                                const SizedBox(height: 24),
                                if (_canShowCoverButton)
                                  _buildCoverButton(
                                    Theme.of(context).colorScheme.secondary,
                                  ),
                                if (_canShowCoverButton)
                                  const SizedBox(height: 12),
                                if (_canShowUncoverButton)
                                  _buildUncoverButton(
                                    Theme.of(context).colorScheme.secondary,
                                  ),
                                if (_canShowUncoverButton) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    formatHmoReverseWindowLabel(
                                      _activeHmoCoverage!,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                if (_isHmoInvoiceFlow &&
                                    _hasActiveInvoiceHmoCoverage &&
                                    !_canShowUncoverButton) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    _activeHmoCoverage == null
                                        ? 'HMO coverage applied.'
                                        : formatHmoReverseWindowLabel(
                                            _activeHmoCoverage!,
                                          ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                if (_canShowPayButton)
                                  _buildPayButton(
                                    Theme.of(context).primaryColor,
                                  ),
                                if (_isHmoDeskInvoicePayBlocked) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Patient has no HMO on file.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: DepartmentColors.billing,
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
                        icon: Icon(
                          Icons.close,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
    final scheme = Theme.of(context).colorScheme;
    final selected = ref.watch(patientProvider).selectedPatient;
    return Row(
      children: [
        PatientAvatar(
          avatarUrl: selected?.avatarUrl,
          firstName: widget.firstName,
          surname: widget.lastName,
          displayName: selected?.displayName,
          size: 48,
          updatedAt: selected?.updatedAt,
          foregroundColor: DepartmentColors.outpatientClinic,
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
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),

              Text(
                "ID: No ID",
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: DepartmentColors.outpatientClinic.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _isHmoStaff ? 'HMO' : 'BILLING',
            style: TextStyle(
              color: DepartmentColors.outpatientClinic,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceDiscountRow() {
    final scheme = Theme.of(context).colorScheme;
    final staff = ref.watch(authProvider).staff;
    final allowed = canApplyDiscount(staff);
    if (!allowed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text(
          'Discount policies can be applied by billing, CMD, CMAC, or admin.',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
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
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
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
        Icon(
          Icons.discount_outlined,
          size: 18,
          color: DepartmentColors.billing,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isDense: true,
              isExpanded: true,
              hint: const Text('Apply discount policy'),
              value: _selectedInvoicePolicyId ?? '__none__',
              style: TextStyle(color: scheme.onSurface, fontSize: 13),
              items: items,
              onChanged: (v) => _onInvoiceDiscountPolicySelected(v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceSection() {
    final scheme = Theme.of(context).colorScheme;
    final hasInsurance = _insurance != null && _insurance != 'None';
    final hmoPercent = _invoiceHmoCoveragePercent;
    final patientShare = _moneyRound(_amountToPay);
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
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
                  color: DepartmentColors.billing,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isDense: true,
                      isExpanded: true,
                      hint: const Text('Select Discount'),
                      value: _selectedDiscount ?? 'None',
                      style: TextStyle(color: scheme.onSurface, fontSize: 14),
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
              Text(
                'TOTAL DUE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                _amountToPay.toFinancial(isMoney: true),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _invoiceRow(String label, String value, {bool isBold = false}) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
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
                  color: muted,
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
    final scheme = Theme.of(context).colorScheme;
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
                      : scheme.surface,
                  border: Border.all(
                    color: isSelected ? primaryColor : scheme.outlineVariant,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _methodIcons[m],
                      color: isSelected
                          ? primaryColor
                          : scheme.onSurfaceVariant,
                      size: 22,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? primaryColor
                            : scheme.onSurfaceVariant,
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
                style: TextStyle(fontSize: 11, color: DepartmentColors.billing),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildPayButton(Color primaryColor) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          disabledBackgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _canPay && !_confirmed && !_isSubmitting
            ? _makePayment
            : null,
        child: Text(
          _isZeroPayable
              ? 'Free'
              : 'Pay ${_amountToPay.toFinancial(isMoney: true)}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCoverButton(Color buttonColor) {
    return SizedBox(
      height: 50,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: buttonColor,
          disabledBackgroundColor: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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

  Widget _buildUncoverButton(Color buttonColor) {
    return SizedBox(
      height: 50,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: buttonColor,
          side: BorderSide(color: buttonColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _isApplyingHmoCover || _isSubmitting ? null : _uncoverHmo,
        child: _isApplyingHmoCover
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(buttonColor),
                ),
              )
            : const Text(
                'Uncover',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildSuccessView() {
    final scheme = Theme.of(context).colorScheme;
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
                Icon(
                  Icons.check_circle,
                  color: DepartmentColors.pharmacy,
                  size: 64,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Payment Confirmed',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  'Receipt sent to $_patientName',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                if (_paidIncludesConsultation) ...[
                  const SizedBox(height: 16),
                  Text(
                    'This payment includes OPD consultation credit: up to 2 '
                    'completed visits within 14 days of payment.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
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
