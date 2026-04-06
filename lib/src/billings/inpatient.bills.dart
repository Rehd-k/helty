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

  /// Server `lineTotal` (can exceed unit × qty, e.g. recurring daily roll-up).
  final double lineTotal;

  /// Server `amountPaid` on this invoice line.
  final double amountPaid;

  /// Remaining due on this line (`lineAmountDue`).
  final double lineAmountDue;

  ChargeItem({
    required this.id,
    required this.invoiceLineItemId,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.quantity = 1,
    this.lineTotal = 0,
    this.amountPaid = 0,
    this.lineAmountDue = 0,
  });

  double get total => amount * quantity;

  /// Denominator for payment progress (prefer API line total).
  double get displayLineTotal {
    if (lineTotal > 0) return lineTotal;
    final t = total;
    return t > 0 ? t : 1;
  }

  /// 0..1 for green fill (`amountPaid` vs line total).
  double get paymentProgress => (amountPaid / displayLineTotal).clamp(0.0, 1.0);

  bool get isLineFullyPaid =>
      lineAmountDue <= 0.001 || paymentProgress >= 0.999;
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
        lineTotal: item.lineTotal,
        amountPaid: item.lineItemAmountPaid,
        lineAmountDue: item.lineAmountDue,
      ),
  ];
}

/// Prefer `GET /invoices/:id/payments`; fill gaps from embedded `detail.payments` by id.
List<BillingInvoicePayment> _mergeInvoicePayments(
  BillingInvoiceDetail detail,
  List<BillingInvoicePayment> fromPaymentsEndpoint,
) {
  final byId = <String, BillingInvoicePayment>{};
  for (final p in fromPaymentsEndpoint) {
    byId[p.id] = p;
  }
  for (final p in detail.payments) {
    byId.putIfAbsent(p.id, () => p);
  }
  final list = byId.values.toList();
  list.sort((a, b) {
    final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
    return tb.compareTo(ta);
  });
  return list;
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

  /// From `GET /invoices/:id/payments`, merged with invoice detail (deduped by id).
  List<BillingInvoicePayment> _mergedInvoicePayments = [];
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
        _mergedInvoicePayments = [];
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
      List<BillingInvoicePayment> merged;
      try {
        final fromApi = await _invoiceService.getInvoicePayments(id);
        merged = _mergeInvoicePayments(detail, fromApi);
      } catch (_) {
        merged = List<BillingInvoicePayment>.from(detail.payments);
      }
      if (!mounted) return;
      setState(() {
        _billingDetail = detail;
        _mergedInvoicePayments = merged;
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
        _mergedInvoicePayments = [];
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Calendar date in local time (strip time component).
  DateTime _dateOnlyLocal(DateTime dt) {
    final l = dt.toLocal();
    return DateTime(l.year, l.month, l.day);
  }

  /// Inclusive calendar days from [start] through [end] (same day → 1).
  int _inclusiveCalendarDays(DateTime start, DateTime end) {
    final a = _dateOnlyLocal(start);
    final b = _dateOnlyLocal(end);
    return b.difference(a).inDays + 1;
  }

  /// Active usage segment for recurring lines (`endAt == null`); earliest [startAt] if several.
  BillingUsageSegment? _activeUsageSegment(BillingInvoiceItem item) {
    final withStart = item.usageSegments
        .where((s) => s.isActive && s.startAt != null)
        .toList();
    if (withStart.isEmpty) return null;
    withStart.sort((a, b) => a.startAt!.compareTo(b.startAt!));
    return withStart.first;
  }

  Widget _recurringDailySubtitle(BillingInvoiceItem line, ThemeData theme) {
    final dailyRate = line.unitPrice;
    final active = _activeUsageSegment(line);
    final startAt = active?.startAt;

    if (startAt == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            line.usageSegments.isEmpty
                ? 'Recurring daily (no usage window yet)'
                : 'Paused · no active usage segment',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            'Daily charge ${dailyRate.toFinancial(isMoney: true)}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      );
    }

    final now = DateTime.now();
    final days = _inclusiveCalendarDays(startAt, now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Started ${_formatDate(startAt.toLocal())} · '
          'Today ${_formatDate(now)} · '
          '$days ${days == 1 ? 'day' : 'days'}',
          style: const TextStyle(fontSize: 12),
        ),
        Text(
          'Daily charge ${dailyRate.toFinancial(isMoney: true)}',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
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

  /// Opens [PayBill] with line allocations. Use [paymentByLineId] to pay less than
  /// full [BillingInvoiceItem.lineAmountDue] on specific lines (partial pay).
  void _openPayBillForItems(
    List<BillingInvoiceItem> lines, {
    Map<String, double>? paymentByLineId,
  }) {
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
      double payAmount;
      if (paymentByLineId != null && paymentByLineId.containsKey(line.id)) {
        payAmount = paymentByLineId[line.id]!;
        if (payAmount <= 0) continue;
        payAmount = payAmount.clamp(0.01, due);
      } else {
        payAmount = (due * 100).round() / 100.0;
      }
      allocations.add(
        InvoiceItemAllocationInput(
          invoiceItemId: line.id,
          amount: (payAmount * 100).round() / 100.0,
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
        patientId: detail.patientId,
        firstName: name,
        lastName: '',
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

  Widget _chargeRowPaymentBackdrop(ChargeItem item) {
    final progress = item.paymentProgress;
    final due = item.lineAmountDue;
    final nothingPaid = progress < 0.001 && due > 0.001;
    final full = item.isLineFullyPaid;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (nothingPaid) ColoredBox(color: Colors.red.withValues(alpha: 0.10)),
        Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: full ? 1.0 : progress,
            heightFactor: 1,
            child: ColoredBox(
              color: Colors.green.withValues(alpha: full ? 0.26 : 0.22),
            ),
          ),
        ),
      ],
    );
  }

  bool _isRecurringUsageActive(BillingInvoiceItem item) =>
      item.usageSegments.any((s) => s.isActive);

  Future<void> _onLinePayMenuChoice(
    String? choice,
    BillingInvoiceItem line,
    ChargeItem charge,
  ) async {
    if (choice == null || !mounted) return;
    if (choice == 'full') {
      _openPayBillForItems([line]);
    } else if (choice == 'partial') {
      await _showPartialPaymentModal(line, charge);
    } else if (choice == 'pause_recurring') {
      await _toggleSingleRecurringLine(line: line, pause: true);
    } else if (choice == 'resume_recurring') {
      await _toggleSingleRecurringLine(line: line, pause: false);
    }
  }

  Future<void> _toggleSingleRecurringLine({
    required BillingInvoiceItem line,
    required bool pause,
  }) async {
    final invoice = _billingDetail;
    if (invoice == null || !line.isRecurringDaily || !mounted) return;
    try {
      if (pause) {
        await _invoiceService.pauseRecurringItem(
          invoiceId: invoice.id,
          itemId: line.id,
        );
      } else {
        await _invoiceService.resumeRecurringItem(
          invoiceId: invoice.id,
          itemId: line.id,
        );
      }
      if (!mounted) return;
      await _loadBillingData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pause
                ? 'Paused recurring billing for this line'
                : 'Resumed recurring billing for this line',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update recurring line: $e')),
      );
    }
  }

  List<PopupMenuEntry<String>> _lineContextMenuEntries(
    BillingInvoiceItem line,
    ChargeItem charge,
  ) {
    final entries = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: 'full',
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.payments_outlined, size: 22),
          title: const Text('Pay full balance'),
          subtitle: Text(
            charge.lineAmountDue.toFinancial(isMoney: true),
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ),
      const PopupMenuItem<String>(
        value: 'partial',
        child: ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.pie_chart_outline, size: 22),
          title: Text('Partial payment'),
          subtitle: Text(
            'Pay less than the full balance',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ),
    ];
    if (line.isRecurringDaily) {
      entries.add(const PopupMenuDivider());
      if (_isRecurringUsageActive(line)) {
        entries.add(
          const PopupMenuItem<String>(
            value: 'pause_recurring',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.pause_circle_outline, size: 22),
              title: Text('Pause recurring (this line only)'),
              subtitle: Text(
                'Stops daily accrual for this service',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        );
      } else {
        entries.add(
          const PopupMenuItem<String>(
            value: 'resume_recurring',
            child: ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.play_circle_outline, size: 22),
              title: Text('Resume recurring (this line only)'),
              subtitle: Text(
                'Restarts daily accrual for this service',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        );
      }
    }
    return entries;
  }

  void _showLinePaymentMenuAt(
    Offset globalPosition,
    BillingInvoiceItem line,
    ChargeItem charge,
  ) {
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx + 1,
        globalPosition.dy + 1,
      ),
      items: _lineContextMenuEntries(line, charge),
    ).then((choice) {
      if (mounted) _onLinePayMenuChoice(choice, line, charge);
    });
  }

  Future<void> _showLinePaymentBottomSheet(
    BillingInvoiceItem line,
    ChargeItem charge,
  ) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                charge.description,
                style: Theme.of(
                  ctx,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Pay full balance'),
              subtitle: Text(
                'Due ${charge.lineAmountDue.toFinancial(isMoney: true)}',
              ),
              onTap: () => Navigator.pop(ctx, 'full'),
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart_outline),
              title: const Text('Partial payment'),
              subtitle: const Text(
                'Choose an amount, then complete in Pay Bill',
              ),
              onTap: () => Navigator.pop(ctx, 'partial'),
            ),
            if (line.isRecurringDaily) ...[
              const Divider(height: 1),
              if (_isRecurringUsageActive(line))
                ListTile(
                  leading: const Icon(Icons.pause_circle_outline),
                  title: const Text('Pause recurring (this line only)'),
                  subtitle: const Text('Stops daily accrual for this service'),
                  onTap: () => Navigator.pop(ctx, 'pause_recurring'),
                )
              else
                ListTile(
                  leading: const Icon(Icons.play_circle_outline),
                  title: const Text('Resume recurring (this line only)'),
                  subtitle: const Text(
                    'Restarts daily accrual for this service',
                  ),
                  onTap: () => Navigator.pop(ctx, 'resume_recurring'),
                ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!mounted) return;
    await _onLinePayMenuChoice(choice, line, charge);
  }

  Future<void> _showPartialPaymentModal(
    BillingInvoiceItem line,
    ChargeItem charge,
  ) async {
    final due = line.lineAmountDue;
    if (due <= 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nothing due on this line')));
      return;
    }
    final ctrl = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Partial payment'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(charge.description),
              const SizedBox(height: 8),
              Text(
                'Balance due: ${due.toFinancial(isMoney: true)}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Amount to pay',
                  hintText: 'Max ${due.toFinancial(isMoney: true)}',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue to Pay Bill'),
          ),
        ],
      ),
    );
    if (submitted != true || !mounted) return;
    final raw = ctrl.text.trim().replaceAll(',', '');
    final amount = double.tryParse(raw) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a positive amount')));
      return;
    }
    if (amount > due + 0.02) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount cannot exceed ${due.toFinancial(isMoney: true)}',
          ),
        ),
      );
      return;
    }
    _openPayBillForItems([line], paymentByLineId: {line.id: amount});
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
    final balanceDue = inv.netAmountDue;

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
                _buildPaymentsTab(colorScheme),
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
          final theme = Theme.of(context);
          final trailingAmount = item.lineAmountDue > 0.001
              ? item.lineAmountDue
              : item.displayLineTotal;
          return Material(
            color: Colors.transparent,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Checkbox(
                      value: selected,
                      onChanged: detail == null
                          ? null
                          : (v) {
                              setState(() {
                                if (v == true) {
                                  _selectedLineIdsForPay.add(
                                    item.invoiceLineItemId,
                                  );
                                } else {
                                  _selectedLineIdsForPay.remove(
                                    item.invoiceLineItemId,
                                  );
                                }
                              });
                            },
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onSecondaryTapDown: line == null || item.isLineFullyPaid
                          ? null
                          : (d) => _showLinePaymentMenuAt(
                              d.globalPosition,
                              line,
                              item,
                            ),
                      onLongPress: line == null || item.isLineFullyPaid
                          ? null
                          : () => _showLinePaymentBottomSheet(line, item),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Positioned.fill(
                              child: _chargeRowPaymentBackdrop(item),
                            ),
                            ListTile(
                              tileColor: Colors.transparent,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              title: Text(
                                item.description,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (line != null && line.isRecurringDaily)
                                    _recurringDailySubtitle(line, theme)
                                  else
                                    Row(
                                      children: [
                                        Text(
                                          _formatDate(item.date),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        if (item.quantity > 1) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            'Qty: ${item.quantity}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Paid ${item.amountPaid.toFinancial(isMoney: true)} / ${item.displayLineTotal.toFinancial(isMoney: true)}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
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
                                        trailingAmount.toFinancial(
                                          isMoney: true,
                                        ),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: item.isLineFullyPaid
                                              ? Colors.green.shade800
                                              : null,
                                        ),
                                      ),
                                      if (item.lineAmountDue > 0.001 &&
                                          item.amountPaid > 0.001)
                                        Text(
                                          'due',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                        ),
                                      if (item.quantity > 1)
                                        Text(
                                          '${item.amount.toFinancial(isMoney: true)} / unit',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                  Builder(
                                    builder: (btnCtx) {
                                      return IconButton(
                                        tooltip: 'Payment options',
                                        icon: const Icon(
                                          Icons.payment_outlined,
                                          size: 22,
                                        ),
                                        onPressed:
                                            line == null || item.isLineFullyPaid
                                            ? null
                                            : () {
                                                final box =
                                                    btnCtx.findRenderObject()
                                                        as RenderBox?;
                                                if (box == null) return;
                                                final o = box.localToGlobal(
                                                  Offset.zero,
                                                );
                                                _showLinePaymentMenuAt(
                                                  o +
                                                      Offset(
                                                        0,
                                                        box.size.height,
                                                      ),
                                                  line,
                                                  item,
                                                );
                                              },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPaymentsTab(ColorScheme colorScheme) {
    final payments = _mergedInvoicePayments;
    if (payments.isEmpty) {
      return const Center(child: Text('No payments recorded yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: payments.length,
      itemBuilder: (context, index) {
        final row = payments[index];
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
            title: const Text(
              'Invoice payment',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${_formatDate(row.createdAt ?? DateTime.now())} • ${row.source}'
              '${row.reference != null && row.reference!.trim().isNotEmpty ? ' • ${row.reference}' : ''}',
            ),
            trailing: Text(
              row.amount.toFinancial(isMoney: true),
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
        payload: WalletDepositPayload(
          amount: amount,
          reference: 'deposit',
          staffId: ref.read(authProvider).staff?.id,
        ),
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
    final recurring = invoice.invoiceItems
        .where((e) => e.isRecurringDaily)
        .toList();
    if (recurring.isEmpty) return;

    final active = recurring.where((e) => _isRecurringUsageActive(e)).toList();
    final idle = recurring.where((e) => !_isRecurringUsageActive(e)).toList();

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recurring daily charges'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${recurring.length} recurring line(s): '
                '${active.length} running, ${idle.length} paused.',
              ),
              const SizedBox(height: 16),
              if (active.isNotEmpty) ...[
                FilledButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'pause_all'),
                  icon: const Icon(Icons.pause_circle_outline, size: 20),
                  label: Text('Pause all running (${active.length})'),
                ),
                const SizedBox(height: 8),
              ],
              if (idle.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: () => Navigator.pop(ctx, 'resume_all'),
                  icon: const Icon(Icons.play_circle_outline, size: 20),
                  label: Text('Resume all paused (${idle.length})'),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (action == null || !mounted) return;

    try {
      if (action == 'pause_all') {
        for (final item in active) {
          await _invoiceService.pauseRecurringItem(
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
              active.length == 1
                  ? 'Recurring line paused'
                  : 'Paused ${active.length} recurring lines',
            ),
          ),
        );
      } else if (action == 'resume_all') {
        for (final item in idle) {
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
              idle.length == 1
                  ? 'Recurring line resumed'
                  : 'Resumed ${idle.length} recurring lines',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(this.context).showSnackBar(
        SnackBar(content: Text('Unable to update recurring items: $e')),
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
