import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/billings/pay.bill.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:helty/src/services/admission_service.dart';
import 'package:helty/src/services/invoice_service.dart';

/// Backend expects catalog UUID on `serviceId` (not human-readable codes).
String catalogServiceUuid(ServiceModel s) {
  final id = s.id.trim();
  if (id.isNotEmpty) return id;
  return s.serviceId.trim();
}

// ==========================================
// 1. MODELS (Mock Data Structures)
// ==========================================

enum ChargeCategory { daily, pharmacy, lab, radiology, surgery, other }

class ChargeItem {
  final String id;

  /// Invoice line id from API (`invoiceItems[].id`).
  final String invoiceLineItemId;
  final String description;
  final double amount;
  final DateTime date;
  final ChargeCategory category;
  final int quantity;

  ChargeItem({
    required this.id,
    required this.invoiceLineItemId,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.quantity = 1,
  });

  double get total => amount * quantity;
}

/// Maps API invoice line items to UI charge buckets: recurring daily first, then lab by category name.
ChargeCategory _chargeCategoryForBillingItem(BillingInvoiceItem item) {
  if (item.isRecurringDaily) return ChargeCategory.daily;
  final name = (item.serviceCategoryName ?? '').trim().toLowerCase();
  if (name == 'laboratory tests' ||
      name == 'laboratory' ||
      name == 'radiology & imaging') {
    return ChargeCategory.lab;
  }
  return ChargeCategory.other;
}

List<ChargeItem> _chargesFromBillingDetail(BillingInvoiceDetail? inv) {
  if (inv == null) return [];
  final created = inv.createdAt ?? DateTime.now();
  return [
    for (final item in inv.invoiceItems)
      ChargeItem(
        id: '${inv.id}-${item.id}',
        invoiceLineItemId: item.id,
        description: item.serviceName ?? item.serviceId,
        amount: item.unitPrice,
        quantity: item.quantity,
        date: created,
        category: _chargeCategoryForBillingItem(item),
      ),
  ];
}

class PaymentItem {
  final String id;
  final double amount;
  final DateTime date;
  final String method;
  final String receiptNumber;

  PaymentItem({
    required this.id,
    required this.amount,
    required this.date,
    required this.method,
    required this.receiptNumber,
  });
}

// ==========================================
// 2. MAIN BILLING SCREEN
// ==========================================

@RoutePage()
class PatientBillingScreen extends ConsumerStatefulWidget {
  /// Server invoice id; used to load `/invoices/:id` on each visit.
  final String invoiceId;
  final String patientName;

  const PatientBillingScreen({
    super.key,
    required this.invoiceId,
    this.patientName = '',
  });

  @override
  ConsumerState<PatientBillingScreen> createState() =>
      _PatientBillingScreenState();
}

class _PatientBillingScreenState extends ConsumerState<PatientBillingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdmissionService _admissionService = AdmissionService();
  final InvoiceService _invoiceService = InvoiceService();

  final List<PaymentItem> _payments = [];
  BillingInvoiceDetail? _billingDetail;
  BillingWallet? _wallet;
  bool _loading = true;
  String? _loadError;
  final Set<String> _selectedLineIdsForPay = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBillingData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBillingData() async {
    final id = widget.invoiceId.trim();
    if (id.isEmpty) {
      setState(() {
        _loading = false;
        _loadError = 'Missing invoice id';
        _billingDetail = null;
        _wallet = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _loadError = null;
    });

    try {
      final detail = await _invoiceService.getBillingInvoice(id);
      BillingWallet? wallet;
      try {
        wallet = await _invoiceService.getWallet(detail.patientId);
      } catch (_) {
        wallet = null;
      }
      if (!mounted) return;
      setState(() {
        _billingDetail = detail;
        _wallet = wallet;
        _loading = false;
        _loadError = null;
        _selectedLineIdsForPay.clear();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _billingDetail = null;
        _wallet = null;
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  ServiceModel _billingItemToServiceModel(BillingInvoiceItem item) {
    return ServiceModel(
      id: item.id,
      serviceId: item.serviceId,
      name: item.serviceName ?? item.serviceId,
      cost: item.unitPrice,
      qty: item.quantity,
      categoryName: item.serviceCategoryName,
    );
  }

  void _openPayBillForItems(List<BillingInvoiceItem> lines) {
    final detail = _billingDetail;
    if (detail == null || lines.isEmpty) return;
    final staff = ref.read(authProvider).staff;
    if (staff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in required to take payment')),
      );
      return;
    }
    final allocations = <InvoiceItemAllocationInput>[];
    for (final line in lines) {
      final due = line.lineAmountDue;
      if (due <= 0) continue;
      allocations.add(
        InvoiceItemAllocationInput(
          invoiceItemId: line.id,
          amount: (due * 100).round() / 100.0,
        ),
      );
    }
    if (allocations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing due on selected lines')),
      );
      return;
    }
    final total = allocations.fold(0.0, (s, e) => s + e.amount);
    final name = widget.patientName.trim().isNotEmpty
        ? widget.patientName
        : 'Patient';
    final models = lines.map(_billingItemToServiceModel).toList();
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => PayBill(
        hasId: true,
        patientId: detail.patientId,
        firstName: name,
        selectedItems: models,
        total: total,
        staffId: staff.id,
        isInvoice: true,
        invoiceId: detail.id,
        invoiceItemAllocations: allocations,
        onPaymentComplete: _loadBillingData,
      ),
    );
  }

  BillingInvoiceItem? _billingLineForCharge(
    ChargeItem charge,
    BillingInvoiceDetail? detail,
  ) {
    if (detail == null) return null;
    for (final i in detail.invoiceItems) {
      if (i.id == charge.invoiceLineItemId) return i;
    }
    return null;
  }

  // --- Actions ---
  void _showAddActionSheet(
    BuildContext context,
    String effectivePatientId,
    String effectivePatientName,
  ) {
    final selectedPatient = ref.read(patientProvider).selectedPatient;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Text(
                    'Add to bill',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.medication_outlined,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                  title: const Text('Add drugs'),
                  subtitle: const Text(
                    'Medicine sales — saved as invoice for patient',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    context.router.push(
                      DispenseRoute(
                        patientId: effectivePatientId,
                        patientName: effectivePatientName,
                        id: selectedPatient?.id ?? '',
                        invoiceId: widget.invoiceId.trim().isEmpty
                            ? null
                            : widget.invoiceId.trim(),
                        staffId: ref.read(authProvider).staff?.id,
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.radar, color: Colors.blue.shade800),
                  ),
                  title: const Text('Radiology'),
                  subtitle: const Text('Add radiology services'),
                  onTap: () {
                    Navigator.pop(context);
                    context.router.push(
                      EnlistPaitientRoute(serviceName: 'Investigation'),
                    );
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.teal.shade100,
                    child: Icon(
                      Icons.science_outlined,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  title: const Text('Labs'),
                  subtitle: const Text('Add laboratory services'),
                  onTap: () {
                    Navigator.pop(context);
                    context.router.push(
                      EnlistPaitientRoute(serviceName: 'Investigation'),
                    );
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(
                      Icons.receipt_long,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  title: const Text('Add other bills'),
                  subtitle: const Text(
                    'Room charges, daily charges, and other services',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddOtherBillsModal(context);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedPatient = ref.watch(patientProvider).selectedPatient;
    final detail = _billingDetail;
    final effectivePatientId =
        detail?.patientId ??
        (selectedPatient?.id ?? selectedPatient?.patientId ?? '');
    final effectivePatientName = widget.patientName.trim().isNotEmpty
        ? widget.patientName.trim()
        : (selectedPatient != null
              ? '${selectedPatient.firstName} ${selectedPatient.surname}'
              : '');

    if (_loading) {
      return Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text(
            'Billing Dashboard',
            style: TextStyle(fontSize: 18),
          ),
          elevation: 0,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('Billing Dashboard'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadBillingData,
              tooltip: 'Retry',
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                const SizedBox(height: 16),
                Text(_loadError!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _loadBillingData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final inv = detail;
    if (inv == null) {
      return Scaffold(
        backgroundColor: colorScheme.surfaceContainerLowest,
        appBar: AppBar(title: const Text('Billing Dashboard')),
        body: const Center(child: Text('Invoice data unavailable.')),
      );
    }

    final charges = _chargesFromBillingDetail(inv);
    final totalCharges = inv.totalAmount;
    final totalPayments = inv.amountPaid;
    final balanceDue = inv.amountDue;

    return _buildContent(
      context,
      colorScheme,
      effectivePatientId: effectivePatientId,
      effectivePatientName: effectivePatientName,
      charges: charges,
      totalCharges: totalCharges,
      totalPayments: totalPayments,
      balanceDue: balanceDue,
      walletBalance: _wallet?.balance ?? 0,
      invoiceDetail: inv,
    );
  }

  Widget _buildContent(
    BuildContext context,
    ColorScheme colorScheme, {
    required String effectivePatientId,
    required String effectivePatientName,
    required List<ChargeItem> charges,
    required double totalCharges,
    required double totalPayments,
    required double balanceDue,
    required double walletBalance,
    required BillingInvoiceDetail? invoiceDetail,
  }) {
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Billing Dashboard', style: TextStyle(fontSize: 18)),
            Text(
              'Patient ID: $effectivePatientId',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              'Patient: $effectivePatientName',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reload invoice',
            onPressed: _loadBillingData,
          ),
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Print Invoice',
            onPressed: () {},
          ),
        ],
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Itemized Charges'),
            Tab(text: 'Payment History'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildFinancialSummary(
            colorScheme,
            balanceDue: balanceDue,
            totalCharges: totalCharges,
            totalPayments: totalPayments,
            walletBalance: walletBalance,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildChargesTab(colorScheme, charges, invoiceDetail),
                _buildPaymentsTab(colorScheme, invoiceDetail),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => _showAddActionSheet(
                  context,
                  effectivePatientId,
                  effectivePatientName,
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Service'),
              ),
              FilledButton.tonalIcon(
                onPressed: invoiceDetail == null
                    ? null
                    : () {
                        final lines = _selectedLineIdsForPay.isEmpty
                            ? invoiceDetail.invoiceItems.toList()
                            : invoiceDetail.invoiceItems
                                  .where(
                                    (e) =>
                                        _selectedLineIdsForPay.contains(e.id),
                                  )
                                  .toList();
                        if (lines.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No bill lines to pay'),
                            ),
                          );
                          return;
                        }
                        _openPayBillForItems(lines);
                      },
                icon: const Icon(Icons.payments_outlined, size: 18),
                label: Text(
                  _selectedLineIdsForPay.isEmpty
                      ? 'Pay bill (all)'
                      : 'Pay selected (${_selectedLineIdsForPay.length})',
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: effectivePatientId.isEmpty
                    ? null
                    : () =>
                          _showWalletDepositDialog(context, effectivePatientId),
                icon: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 18,
                ),
                label: const Text('Deposit Wallet'),
              ),
              FilledButton.tonalIcon(
                onPressed:
                    invoiceDetail == null ||
                        invoiceDetail.invoiceItems
                            .where((e) => e.isRecurringDaily)
                            .isEmpty
                    ? null
                    : () => _showRecurringControlDialog(context, invoiceDetail),
                icon: const Icon(Icons.pause_circle_outline, size: 18),
                label: const Text('Pause/Resume'),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showDischargeDialog(
                  context,
                  effectivePatientId,
                  effectivePatientName,
                ),
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Discharge'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddOtherBillsModal(BuildContext context) {
    final invoiceId = widget.invoiceId.trim();
    if (invoiceId.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddOtherBillsSheet(
        invoiceId: invoiceId,
        invoiceService: _invoiceService,
        onClose: () => Navigator.pop(ctx),
        onAdded: () {
          Navigator.pop(ctx);
          _loadBillingData();
        },
      ),
    );
  }

  // ==========================================
  // WIDGET BUILDERS
  // ==========================================

  Widget _buildFinancialSummary(
    ColorScheme colorScheme, {
    required double balanceDue,
    required double totalCharges,
    required double totalPayments,
    required double walletBalance,
  }) {
    final bool isPaidOff = balanceDue <= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Balance Due',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  balanceDue.toFinancial(isMoney: true),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isPaidOff ? Colors.green : colorScheme.error,
                  ),
                ),
                if (isPaidOff)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'CLEARED',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: colorScheme.outlineVariant),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Charges:',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        totalCharges.toFinancial(isMoney: true),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Paid:',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        totalPayments.toFinancial(isMoney: true),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Wallet Balance:',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        walletBalance.toFinancial(isMoney: true),
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChargesTab(
    ColorScheme colorScheme,
    List<ChargeItem> charges,
    BillingInvoiceDetail? detail,
  ) {
    // Group charges by Category
    final groupedCharges = <ChargeCategory, List<ChargeItem>>{};
    for (var charge in charges) {
      groupedCharges.putIfAbsent(charge.category, () => []).add(charge);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('Compulsory & Daily Charges'),
        _buildChargeGroup(
          colorScheme,
          groupedCharges[ChargeCategory.daily] ?? [],
          detail,
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Pharmacy & Medications'),
        _buildChargeGroup(
          colorScheme,
          groupedCharges[ChargeCategory.pharmacy] ?? [],
          detail,
        ),
        const SizedBox(height: 24),

        _buildSectionHeader('Laboratory & Diagnostics'),
        _buildChargeGroup(colorScheme, [
          ...?groupedCharges[ChargeCategory.lab],
          ...?groupedCharges[ChargeCategory.radiology],
        ], detail),
        _buildSectionHeader('Other'),
        _buildChargeGroup(
          colorScheme,
          groupedCharges[ChargeCategory.other] ?? [],
          detail,
        ),
      ],
    );
  }

  Widget _buildChargeGroup(
    ColorScheme colorScheme,
    List<ChargeItem> items,
    BillingInvoiceDetail? detail,
  ) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text(
          'No charges in this category yet.',
          style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = items[index];
          final line = _billingLineForCharge(item, detail);
          final selected = _selectedLineIdsForPay.contains(
            item.invoiceLineItemId,
          );
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            leading: Checkbox(
              value: selected,
              onChanged: detail == null
                  ? null
                  : (v) {
                      setState(() {
                        if (v == true) {
                          _selectedLineIdsForPay.add(item.invoiceLineItemId);
                        } else {
                          _selectedLineIdsForPay.remove(item.invoiceLineItemId);
                        }
                      });
                    },
            ),
            title: Text(
              item.description,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            subtitle: Row(
              children: [
                Text(
                  _formatDate(item.date),
                  style: const TextStyle(fontSize: 12),
                ),
                if (item.quantity > 1) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Qty: ${item.quantity}',
                    style: const TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.total.toFinancial(isMoney: true),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    if (item.quantity > 1)
                      Text(
                        '${item.amount.toFinancial(isMoney: true)} each',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                IconButton(
                  tooltip: 'Pay this line',
                  icon: const Icon(Icons.payment_outlined, size: 22),
                  onPressed: line == null
                      ? null
                      : () => _openPayBillForItems([line]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentsTab(
    ColorScheme colorScheme,
    BillingInvoiceDetail? invoiceDetail,
  ) {
    final detailPayments =
        invoiceDetail?.payments ?? const <BillingInvoicePayment>[];
    if (_payments.isEmpty && detailPayments.isEmpty) {
      return const Center(child: Text('No payments recorded yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _payments.length + detailPayments.length,
      itemBuilder: (context, index) {
        final hasLegacy = index < _payments.length;
        final payment = hasLegacy ? _payments[index] : null;
        final detail = hasLegacy
            ? null
            : detailPayments[index - _payments.length];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.green.withValues(alpha: 0.5)),
          ),
          color: Colors.green.withValues(alpha: 0.05),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.check_circle, color: Colors.green),
            ),
            title: Text(
              hasLegacy
                  ? 'Receipt: ${payment!.receiptNumber}'
                  : 'Invoice payment',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              hasLegacy
                  ? '${_formatDate(payment!.date)} • ${payment.method}'
                  : '${_formatDate(detail!.createdAt ?? DateTime.now())} • ${detail.source}',
            ),
            trailing: Text(
              (hasLegacy ? payment!.amount : detail!.amount).toFinancial(
                isMoney: true,
              ),
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showWalletDepositDialog(
    BuildContext context,
    String patientId,
  ) async {
    final amountCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deposit wallet'),
        content: TextField(
          controller: amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deposit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final amount = double.tryParse(amountCtrl.text) ?? 0;
    if (amount <= 0) return;
    try {
      await _invoiceService.depositToWallet(
        patientId: patientId,
        payload: WalletDepositPayload(amount: amount, reference: 'deposit'),
      );
      if (!mounted) return;
      await _loadBillingData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(const SnackBar(content: Text('Wallet funded')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text('Deposit failed: $e')));
    }
  }

  Future<void> _showRecurringControlDialog(
    BuildContext context,
    BillingInvoiceDetail invoice,
  ) async {
    final recurringItems = invoice.invoiceItems.where(
      (e) => e.isRecurringDaily,
    );
    final item = recurringItems.first;
    final isActive = item.usageSegments.any((e) => e.isActive);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isActive ? 'Pause recurring item' : 'Resume recurring item',
        ),
        content: Text(
          '${item.serviceName ?? item.serviceId} will be ${isActive ? 'paused' : 'resumed'}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isActive ? 'Pause' : 'Resume'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      if (isActive) {
        await _invoiceService.pauseRecurringItem(
          invoiceId: invoice.id,
          itemId: item.id,
        );
      } else {
        await _invoiceService.resumeRecurringItem(
          invoiceId: invoice.id,
          itemId: item.id,
        );
      }
      if (!mounted) return;
      await _loadBillingData();
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(
          content: Text(
            isActive ? 'Recurring item paused' : 'Recurring item resumed',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Unable to update recurring item: $e')),
      );
    }
  }

  Future<void> _showDischargeDialog(
    BuildContext context,
    String patientId,
    String patientName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discharge patient'),
        content: const Text(
          'This will attempt discharge now. If invoice is unpaid, discharge is blocked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Discharge'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final admissionId = _billingDetail?.encounterId;
    if (admissionId == null || admissionId.isEmpty) {
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(
          content: Text(
            'Admission ID unavailable here. Open from inpatient view.',
          ),
        ),
      );
      return;
    }
    try {
      await _admissionService.dischargeAdmission(admissionId);
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        const SnackBar(content: Text('Patient discharged successfully')),
      );
    } on AdmissionDischargeBlockedException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      final invId = _billingDetail?.id ?? widget.invoiceId;
      if (invId.isNotEmpty) {
        this.context.router.push(
          PatientBillingRoute(invoiceId: invId, patientName: patientName),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text('Discharge failed: $e')));
    }
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ==========================================
// Add Other Bills modal (services from backend)
// ==========================================

class _AddOtherBillsSheet extends ConsumerStatefulWidget {
  const _AddOtherBillsSheet({
    required this.invoiceId,
    required this.invoiceService,
    required this.onClose,
    required this.onAdded,
  });

  final String invoiceId;
  final InvoiceService invoiceService;
  final VoidCallback onClose;
  final VoidCallback onAdded;

  @override
  ConsumerState<_AddOtherBillsSheet> createState() =>
      _AddOtherBillsSheetState();
}

class _AddOtherBillsSheetState extends ConsumerState<_AddOtherBillsSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final servicesAsync = ref.watch(
      serviceListProvider(_query.isEmpty ? null : _query),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Add other bills',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search services (room, daily, etc.)',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: servicesAsync.when(
                data: (services) {
                  if (services.isEmpty) {
                    return Center(
                      child: Text(
                        _query.isEmpty
                            ? 'Enter a search term to find services'
                            : 'No services found',
                        style: TextStyle(
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: services.length,
                    itemBuilder: (context, index) {
                      final service = services[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(service.name),
                          subtitle: Text(
                            service.categoryName ??
                                service.departmentName ??
                                'Service',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            ),
                          ),
                          trailing: Text(
                            service.cost.toFinancial(isMoney: true),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () => _addServiceToInvoice(context, service),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      e.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addServiceToInvoice(
    BuildContext context,
    ServiceModel service,
  ) async {
    String fmtDay(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final qtyCtrl = TextEditingController(text: '1');
    var recurring = false;
    var startDay = DateUtils.dateOnly(DateTime.now());
    final result =
        await showDialog<({int qty, bool recurring, DateTime? start})>(
          context: context,
          builder: (ctx) => StatefulBuilder(
            builder: (context, setLocal) {
              return AlertDialog(
                title: Text(service.name),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Price: ${service.cost.toFinancial(isMoney: true)}'),
                      const SizedBox(height: 12),
                      TextField(
                        controller: qtyCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Recurring daily'),
                        value: recurring,
                        onChanged: (v) => setLocal(() => recurring = v),
                      ),
                      if (recurring)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Start date'),
                          subtitle: Text(fmtDay(startDay)),
                          trailing: const Icon(Icons.calendar_today_outlined),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDay,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (picked != null) {
                              setLocal(
                                () => startDay = DateUtils.dateOnly(picked),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      final n = int.tryParse(qtyCtrl.text);
                      final q = n != null && n > 0 ? n : 1;
                      Navigator.pop(ctx, (
                        qty: q,
                        recurring: recurring,
                        start: recurring ? startDay : null,
                      ));
                    },
                    child: const Text('Add to bill'),
                  ),
                ],
              );
            },
          ),
        );
    qtyCtrl.dispose();
    if (result == null || !mounted) return;
    final serviceUuid = catalogServiceUuid(service);
    if (serviceUuid.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service has no valid id — cannot add to invoice'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      await widget.invoiceService.addBillingItem(
        invoiceId: widget.invoiceId,
        payload: AddInvoiceItemPayload(
          serviceId: serviceUuid,
          unitPrice: service.cost,
          quantity: result.qty,
          isRecurringDaily: result.recurring,
          startedAt: result.start,
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${service.name} x${result.qty} to bill'),
          ),
        );
        widget.onAdded();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
