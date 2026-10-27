import 'dart:typed_data';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/billings/billing_leave_guard.dart';
import 'package:helty/src/billings/inpatient_charge_models.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/models/discount_policy_models.dart';
import 'package:helty/src/core/responsive.dart';
import 'package:helty/src/billings/pay.bill.dart';
import 'package:helty/src/billings/widgets/purchases_consumable_billing_panel.dart';
import 'package:helty/src/printing/core/display_id.dart';
import 'package:helty/src/printing/pdf/inpatient_invoice_pdf.dart';
import 'package:helty/src/auth/billing_permissions.dart';
import 'package:helty/src/billings/hmo_coverage_ui.dart';
import 'package:helty/src/billings/widgets/invoice_item_refund_dialogs.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/app_router.gr.dart';
import 'package:helty/src/models/service_model.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/providers/service_providers.dart';
import 'package:helty/src/paitients/patient_providers.dart';
import 'package:helty/src/admissions/admission_discharge_helpers.dart';
import 'package:helty/src/admissions/discharge_admission_dialog.dart';
import 'package:helty/src/purchases/models/purchases_model.dart';
import 'package:helty/src/services/admission_service.dart';
import 'package:helty/src/services/invoice_service.dart';
import 'package:helty/src/helper/theme.dart';
import 'package:helty/src/shared/department_colors.dart';
import 'package:helty/src/wallet/wallet_deposit_dialog.dart';
import 'package:helty/src/wallet/wallet_providers.dart';
import 'package:helty/src/widgets/helty_slide_panel.dart';
import 'package:helty/src/widgets/helty_surface.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

/// Backend expects catalog UUID on `serviceId` (not human-readable codes).
String catalogServiceUuid(ServiceModel s) {
  final id = s.id.trim();
  if (id.isNotEmpty) return id;
  return s.serviceId.trim();
}

const _billCardBreakpoint = 768.0;
const _billPageSize = 20;

const _accentBlue = Color(0xFF2563EB);
const _accentTeal = Color(0xFF0D9488);
const _accentPurple = Color(0xFF7C3AED);
const _accentPink = Color(0xFFDB2777);
const _accentIndigo = Color(0xFF4F46E5);
const _accentGreen = Color(0xFF16A34A);
const _accentAmber = Color(0xFFEA580C);
const _accentRed = Color(0xFFDC2626);

enum _InvoicePdfLayout { summary, itemized }

// ==========================================
// 1. MODELS (Mock Data Structures)
// ==========================================

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
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _fabController;
  final AdmissionService _admissionService = AdmissionService();
  final InvoiceService _invoiceService = InvoiceService();

  /// From `GET /invoices/:id/payments`, merged with invoice detail (deduped by id).
  List<BillingInvoicePayment> _mergedInvoicePayments = [];
  BillingInvoiceDetail? _billingDetail;
  BillingWallet? _wallet;
  bool _loading = true;
  String? _loadError;
  final Set<String> _selectedLineIdsForPay = {};
  List<DiscountPolicy> _discountPolicies = const [];
  bool _coverageBusy = false;
  List<BillingInvoiceRefundRequest> _refundRequests = const [];
  bool _refundRequestsLoading = false;
  String? _refundRequestsError;
  bool _deletingInvoice = false;
  bool _allowRouteLeave = false;
  bool _leaveCheckOpen = false;
  final Set<String> _deletingLineIds = {};
  final Set<String> _replacingRecurringLineIds = {};
  final TextEditingController _lineSearchCtrl = TextEditingController();
  String _lineQuery = '';
  String _categoryFilter = 'all';
  String _settlementFilter = 'all';
  int _listSkip = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _lineSearchCtrl.addListener(_onLineSearchChanged);
    BillingLeaveGate.instance.register(_confirmLeave);
    _loadBillingData();
  }

  void _onLineSearchChanged() {
    final q = _lineSearchCtrl.text.trim().toLowerCase();
    if (q == _lineQuery) return;
    setState(() {
      _lineQuery = q;
      _listSkip = 0;
    });
  }

  void _onTabChanged() {
    if (!mounted || _tabController.indexIsChanging) return;
    setState(() => _listSkip = 0);
    if (_tabController.index == 2) {
      _loadRefundRequests();
    }
  }

  @override
  void dispose() {
    BillingLeaveGate.instance.unregister(_confirmLeave);
    _lineSearchCtrl.removeListener(_onLineSearchChanged);
    _lineSearchCtrl.dispose();
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  Future<void> _loadRefundRequests() async {
    final id = _billingDetail?.id ?? widget.invoiceId.trim();
    if (id.isEmpty) return;
    setState(() {
      _refundRequestsLoading = true;
      _refundRequestsError = null;
    });
    try {
      final rows = await _invoiceService.getInvoiceRefundRequests(id);
      if (!mounted) return;
      setState(() {
        _refundRequests = rows;
        _refundRequestsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _refundRequestsLoading = false;
        _refundRequestsError = e.toString();
      });
    }
  }

  Future<void> _submitRefundRequest(BillingInvoiceItem line) async {
    final invoice = _billingDetail;
    if (invoice == null || !mounted) return;
    final reason = await showInvoiceItemRefundReasonDialog(context);
    if (reason == null || !mounted) return;
    try {
      await _invoiceService.submitItemRefundRequest(
        invoiceId: invoice.id,
        itemId: line.id,
        reason: reason,
      );
      if (!mounted) return;
      await _loadBillingData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund request submitted for approval.')),
      );
    } on InvoiceRefundRequestException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        await _loadBillingData();
      } else if (e.statusCode == 404) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
        if (mounted) _leaveBillingScreen();
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _cancelRefundRequest(BillingInvoiceItem line) async {
    final invoice = _billingDetail;
    final requestId = line.activeRefundRequest?.id;
    if (invoice == null || requestId == null || !mounted) return;
    final confirmed = await showCancelInvoiceItemRefundDialog(context);
    if (!confirmed || !mounted) return;
    try {
      await _invoiceService.cancelItemRefundRequest(
        invoiceId: invoice.id,
        itemId: line.id,
        requestId: requestId,
      );
      if (!mounted) return;
      await _loadBillingData();
      if (_tabController.index == 2) await _loadRefundRequests();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund request cancelled.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  String _invoiceDeleteErrorMessage(Object error) {
    final raw = error.toString().trim();
    if (raw.isEmpty) return 'Unable to delete invoice';
    if (raw.startsWith('Exception:')) {
      final cleaned = raw.replaceFirst('Exception:', '').trim();
      return cleaned.isEmpty ? 'Unable to delete invoice' : cleaned;
    }
    return raw;
  }

  Future<void> _deleteInvoiceAndAllItems({
    required String invoiceDisplayId,
    required BillingInvoiceDetail detail,
  }) async {
    if (_deletingInvoice) return;
    final staff = ref.read(authProvider).staff;
    if (!canDeleteInpatientInvoice(staff)) return;

    final itemCount = detail.invoiceItems.length;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete invoice'),
        content: Text(
          itemCount == 0
              ? 'Delete invoice $invoiceDisplayId? This action cannot be undone.'
              : 'Delete all $itemCount item${itemCount == 1 ? '' : 's'} and '
                    'invoice $invoiceDisplayId? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    setState(() => _deletingInvoice = true);
    try {
      final invoiceId = detail.id.trim().isNotEmpty
          ? detail.id
          : widget.invoiceId.trim();
      for (final item in detail.invoiceItems) {
        final itemId = item.id.trim();
        if (itemId.isEmpty) continue;
        await _invoiceService.deleteItem(invoiceId, itemId);
      }
      await _invoiceService.deleteInvoice(invoiceId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invoice deleted successfully')),
      );
      _leaveBillingScreen();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_invoiceDeleteErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() => _deletingInvoice = false);
      }
    }
  }

  Future<void> _deleteInvoiceLine({
    required BillingInvoiceItem line,
    required ChargeItem charge,
  }) async {
    if (_deletingLineIds.contains(line.id)) return;
    final staff = ref.read(authProvider).staff;
    if (!canDeleteInpatientInvoice(staff)) return;

    final invoice = _billingDetail;
    if (invoice == null) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete item'),
        content: Text(
          'Remove "${charge.description}" from this invoice? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !mounted) return;

    setState(() => _deletingLineIds.add(line.id));
    try {
      await _invoiceService.deleteItem(invoice.id, line.id);
      if (!mounted) return;
      setState(() {
        _selectedLineIdsForPay.remove(line.id);
        _selectedLineIdsForPay.remove(charge.invoiceLineItemId);
      });
      await _loadBillingData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invoice item deleted')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_invoiceDeleteErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() => _deletingLineIds.remove(line.id));
      }
    }
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
      List<DiscountPolicy> policies = const [];
      try {
        policies = await _invoiceService.getActiveDiscountPolicies();
      } catch (_) {
        policies = const [];
      }
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
        _discountPolicies = policies;
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

  Future<_InvoicePdfLayout?> _chooseInvoicePdfLayout({
    required String title,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width - 32 < 560 ? width - 32 : 560.0;
    return showDialog<_InvoicePdfLayout>(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return Dialog(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const HeltySolidIcon(
                        icon: Icons.picture_as_pdf_outlined,
                        color: _accentIndigo,
                        size: 32,
                        iconSize: 16,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      'Choose a category summary, or the full itemized bill.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    leading: const HeltySolidIcon(
                      icon: Icons.summarize_outlined,
                      color: _accentBlue,
                      size: 32,
                      iconSize: 16,
                    ),
                    title: const Text('Summary'),
                    subtitle: const Text(
                      'Category totals and total paid',
                    ),
                    onTap: () =>
                        Navigator.of(ctx).pop(_InvoicePdfLayout.summary),
                  ),
                  ListTile(
                    leading: const HeltySolidIcon(
                      icon: Icons.receipt_long_outlined,
                      color: _accentTeal,
                      size: 32,
                      iconSize: 16,
                    ),
                    title: const Text('Itemized'),
                    subtitle: const Text(
                      'Every charge line, as shown on this bill',
                    ),
                    onTap: () =>
                        Navigator.of(ctx).pop(_InvoicePdfLayout.itemized),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _printInvoice({
    required String patientDisplayId,
    required String invoiceDisplayId,
    required String effectivePatientName,
    required List<ChargeItem> charges,
    required double totalCharges,
    required double totalPayments,
    required double balanceDue,
    required double walletBalance,
    required bool itemized,
  }) async {
    await Printing.layoutPdf(
      onLayout: (format) async {
        final bytes = await buildInpatientInvoicePdf(
          format: format,
          patientDisplayId: patientDisplayId,
          invoiceDisplayId: invoiceDisplayId,
          patientName: effectivePatientName,
          charges: charges,
          totalCharges: totalCharges,
          totalPayments: totalPayments,
          balanceDue: balanceDue,
          walletBalance: walletBalance,
          itemized: itemized,
        );
        return Uint8List.fromList(bytes);
      },
    );
  }

  Future<void> _shareInvoice({
    required String patientDisplayId,
    required String invoiceDisplayId,
    required String effectivePatientName,
    required List<ChargeItem> charges,
    required double totalCharges,
    required double totalPayments,
    required double balanceDue,
    required double walletBalance,
    required bool itemized,
  }) async {
    final bytes = await buildInpatientInvoicePdf(
      format: PdfPageFormat.a4,
      patientDisplayId: patientDisplayId,
      invoiceDisplayId: invoiceDisplayId,
      patientName: effectivePatientName,
      charges: charges,
      totalCharges: totalCharges,
      totalPayments: totalPayments,
      balanceDue: balanceDue,
      walletBalance: walletBalance,
      itemized: itemized,
    );
    final kind = itemized ? 'itemized' : 'summary';
    await Printing.sharePdf(
      bytes: Uint8List.fromList(bytes),
      filename: 'inpatient_invoice_${invoiceDisplayId}_$kind.pdf',
    );
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

  /// Days actually consumed across usage segments, merging overlaps.
  int _usedDays(BillingInvoiceItem line) {
    final now = _dateOnlyLocal(DateTime.now());
    final ranges = <(DateTime, DateTime)>[];
    for (final segment in line.usageSegments) {
      final startAt = segment.startAt;
      if (startAt == null) continue;
      final start = _dateOnlyLocal(startAt);
      final end = segment.endAt == null ? now : _dateOnlyLocal(segment.endAt!);
      if (end.isBefore(start)) continue;
      ranges.add((start, end));
    }
    if (ranges.isEmpty) return 0;
    ranges.sort((a, b) => a.$1.compareTo(b.$1));
    var cursor = ranges.first.$1;
    var until = ranges.first.$2;
    var days = 0;
    for (final range in ranges.skip(1)) {
      final nextStart = range.$1;
      if (!nextStart.isAfter(until.add(const Duration(days: 1)))) {
        if (range.$2.isAfter(until)) until = range.$2;
      } else {
        days += until.difference(cursor).inDays + 1;
        cursor = nextStart;
        until = range.$2;
      }
    }
    days += until.difference(cursor).inDays + 1;
    return days;
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

  DateTime? _recurringLineStartDate(BillingInvoiceItem line) {
    final active = _activeUsageSegment(line);
    if (active?.startAt != null) {
      return _dateOnlyLocal(active!.startAt!);
    }
    final starts = line.usageSegments
        .where((s) => s.startAt != null)
        .map((s) => s.startAt!)
        .toList();
    if (starts.isEmpty) return null;
    starts.sort();
    return _dateOnlyLocal(starts.first);
  }

  String? _recurringEditBlockReason(BillingInvoiceItem line) {
    final staff = ref.read(authProvider).staff;
    if (!canEditRecurringInvoiceItemStartDateForStaff(staff)) {
      return 'Only billing staff or department heads can edit recurring start dates';
    }
    if (!line.isRecurringDaily) return null;
    if (line.serviceId.trim().isEmpty) {
      return 'Only service recurring lines can have their start date edited';
    }
    if (line.lineItemAmountPaid > 0.001) {
      return 'Cannot edit start date on a line with payments — request a refund first';
    }
    if (line.refundPending) {
      return 'Cannot edit start date while a refund request is pending';
    }
    return null;
  }

  Future<void> _editRecurringItemStartDate({
    required BillingInvoiceItem line,
    required ChargeItem charge,
  }) async {
    if (_replacingRecurringLineIds.contains(line.id)) return;

    final blockReason = _recurringEditBlockReason(line);
    if (blockReason != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(blockReason)));
      return;
    }

    final invoice = _billingDetail;
    if (invoice == null || !mounted) return;

    final currentStart =
        _recurringLineStartDate(line) ?? _dateOnlyLocal(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: currentStart,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Recurring start date',
    );
    if (picked == null || !mounted) return;

    final newStart = _dateOnlyLocal(picked);
    if (newStart == currentStart) return;

    final now = DateTime.now();
    final oldDays = _inclusiveCalendarDays(currentStart, now);
    final newDays = _inclusiveCalendarDays(newStart, now);
    final oldEstimate = line.unitPrice * line.quantity * oldDays;
    final newEstimate = line.unitPrice * line.quantity * newDays;
    final wasPaused = !_isRecurringUsageActive(line);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit recurring start date'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                charge.description,
                style: Theme.of(
                  ctx,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text('Current start: ${_formatDate(currentStart)}'),
              Text('New start: ${_formatDate(newStart)}'),
              const SizedBox(height: 8),
              Text(
                'Estimated total: '
                '${oldEstimate.toFinancial(isMoney: true)} → '
                '${newEstimate.toFinancial(isMoney: true)} '
                '($newDays ${newDays == 1 ? 'day' : 'days'} × '
                '${line.unitPrice.toFinancial(isMoney: true)})',
              ),
              const SizedBox(height: 12),
              Text(
                wasPaused
                    ? 'This replaces the line on the invoice. Pause history is reset; '
                          'the line will be re-paused after the date change.'
                    : 'This replaces the line on the invoice. The amount will be '
                          'recalculated from the new start date.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Text(
                'If re-adding fails after delete, you will need to add the service again manually.',
                style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                  color: Theme.of(ctx).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Update start date'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final existingIds = invoice.invoiceItems.map((i) => i.id).toSet();
    setState(() => _replacingRecurringLineIds.add(line.id));
    try {
      final updated = await _invoiceService.replaceRecurringBillingItem(
        invoiceId: invoice.id,
        itemId: line.id,
        existingItemIds: existingIds,
        pauseAfterReAdd: wasPaused,
        payload: AddInvoiceItemPayload(
          serviceId: line.serviceId,
          unitPrice: line.unitPrice,
          quantity: line.quantity,
          isRecurringDaily: true,
          startedAt: newStart,
        ),
      );
      if (!mounted) return;
      setState(() {
        _selectedLineIdsForPay.remove(line.id);
        _selectedLineIdsForPay.remove(charge.invoiceLineItemId);
      });
      await _loadBillingData();
      if (!mounted) return;

      final newLine = InvoiceService.findReplacedRecurringLine(
        detail: updated,
        existingItemIds: existingIds,
        serviceId: line.serviceId,
      );
      final totalLabel = newLine != null
          ? newLine.lineTotal.toFinancial(isMoney: true)
          : 'updated';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recurring start date updated to ${_formatDate(newStart)} · '
            'Line total $totalLabel',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_invoiceDeleteErrorMessage(e))));
    } finally {
      if (mounted) {
        setState(() => _replacingRecurringLineIds.remove(line.id));
      }
    }
  }

  ServiceModel _billingItemToServiceModel(BillingInvoiceItem item) {
    final label = item.displayLabel;
    String? categoryName;
    if (item.isDrugLine) {
      categoryName = 'Pharmacy';
    } else if (item.isPurchaseItemLine) {
      categoryName = 'Supplies';
    } else if (item.isConsumableLine) {
      categoryName = 'Consumables';
    } else {
      categoryName = item.serviceCategoryName;
    }
    return ServiceModel(
      id: item.id,
      serviceId: item.serviceId.isNotEmpty
          ? item.serviceId
          : (item.purchaseItemId ?? item.drugId ?? item.id),
      name: label,
      cost: item.unitPrice,
      qty: item.quantity,
      categoryName: categoryName,
      departmentName: item.serviceDepartmentName,
      drugId: item.drugId,
      purchaseItemId: item.purchaseItemId,
      purchasesLocationId: item.purchasesLocationId,
      lineTotal: item.lineTotal,
      lineCovered: item.lineCovered,
      lineEffectiveDue: item.lineEffectiveDue,
      lineAmountDue: item.lineAmountDue,
      createdByName: item.createdByName,
    );
  }

  /// Opens [PayBill] with line allocations. Use [paymentByLineId] to pay less than
  /// full [BillingInvoiceItem.lineAmountDue] on specific lines (partial pay).
  void _openPayBillForItems(
    List<BillingInvoiceItem> lines, {
    Map<String, double>? paymentByLineId,
    String? initialPaymentMethod,
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
        patientDisplayName: name,
        selectedItems: models,
        total: total,
        staffId: staff.id,
        isInvoice: true,
        invoiceId: detail.id,
        invoiceDisplayId: detail.invoiceDisplayId,
        invoiceItemAllocations: allocations,
        invoiceMaxPayable: (detail.effectivePayable - detail.amountPaid) > 0
            ? (detail.effectivePayable - detail.amountPaid)
            : 0,
        onPaymentComplete: () {
          invalidatePatientWalletHistory(ref, detail.patientId);
          _loadBillingData();
        },
        preserveInvoiceOnDismiss: true,
        initialPaymentMethod: initialPaymentMethod,
      ),
    );
  }

  void _leaveBillingScreen() {
    if (_allowRouteLeave) {
      context.router.maybePop();
      return;
    }
    setState(() => _allowRouteLeave = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.router.maybePop();
    });
  }

  Future<void> _onBackPressed() async {
    final leave = await _confirmLeave();
    if (leave && mounted) _leaveBillingScreen();
  }

  /// True when this screen may be covered or popped. False keeps the user here.
  Future<bool> _confirmLeave() async {
    if (_allowRouteLeave) return true;
    if (_leaveCheckOpen) return false;
    final detail = _billingDetail;
    final wallet = _wallet?.balance;
    if (detail == null || wallet == null) return true;
    final position = detail.effectivePayable - (wallet + detail.amountPaid);
    if (position > 0.001) return true;

    _leaveCheckOpen = true;
    final discharged = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final width = MediaQuery.sizeOf(ctx).width;
        final maxWidth = width - 32 < 560 ? width - 32 : 560.0;
        return AlertDialog(
          title: const Text('Final bill'),
          content: SizedBox(
            width: maxWidth,
            child: const Text(
              'Has this patient been discharged, and is this their final bill?',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('No'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
    if (!mounted) {
      _leaveCheckOpen = false;
      return false;
    }
    if (discharged != true) {
      _leaveCheckOpen = false;
      return discharged == false;
    }

    if (position < -0.001) {
      final excess = -position;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final width = MediaQuery.sizeOf(ctx).width;
          final maxWidth = width - 32 < 560 ? width - 32 : 560.0;
          return AlertDialog(
            title: const Text('Wallet is over'),
            content: SizedBox(
              width: maxWidth,
              child: Text(
                'After this bill is taken out, the wallet is still over by '
                '${excess.toFinancial(isMoney: true)}. Contact a superior '
                'officer to remove that excess. You can leave this screen '
                'by choosing No, or once the extra amount is gone and the '
                'bill matches the wallet and payments exactly.',
              ),
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Stay on this bill'),
              ),
            ],
          );
        },
      );
      _leaveCheckOpen = false;
      return false;
    }

    _leaveCheckOpen = false;
    _openPayBillForItems(
      detail.invoiceItems,
      initialPaymentMethod: 'wallet',
    );
    return false;
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
    } else if (choice == 'request_refund') {
      await _submitRefundRequest(line);
    } else if (choice == 'cancel_refund') {
      await _cancelRefundRequest(line);
    } else if (choice == 'edit_recurring_start') {
      await _editRecurringItemStartDate(line: line, charge: charge);
    } else if (choice == 'delete_line') {
      await _deleteInvoiceLine(line: line, charge: charge);
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

  Future<void> _applyHmoSplit() async {
    final detail = _billingDetail;
    final staff = ref.read(authProvider).staff;
    if (detail == null || !canSplitWithHmo(staff)) return;
    if ((detail.patientHmoId ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient has no registered HMO')),
      );
      return;
    }
    final percent = await showApplyHmoPercentDialog(
      context,
      defaultPercent: detail.patientHmoDefaultCoveragePercent,
    );
    if (percent == null || !mounted) return;
    setState(() => _coverageBusy = true);
    try {
      await _invoiceService.applyHmoCoverage(
        invoiceId: detail.id,
        scope: 'INVOICE',
        percentOverride: percent,
      );
      await _loadBillingData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('HMO split applied')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _coverageBusy = false);
    }
  }

  Future<void> _applyDiscountPolicy(String policyId) async {
    final detail = _billingDetail;
    final staff = ref.read(authProvider).staff;
    if (detail == null || !canApplyDiscount(staff) || policyId.trim().isEmpty) {
      return;
    }
    setState(() => _coverageBusy = true);
    try {
      await _invoiceService.applyDiscountCoverage(
        invoiceId: detail.id,
        policyId: policyId,
        scope: 'INVOICE',
      );
      await _loadBillingData();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Discount applied')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _coverageBusy = false);
    }
  }

  Future<void> _reverseCoverage(InvoiceCoverage coverage) async {
    final detail = _billingDetail;
    final staff = ref.read(authProvider).staff;
    if (detail == null || !canReverseCoverage(staff)) return;
    final isHmo = coverage.kind.trim().toUpperCase() == 'HMO';
    if (isHmo && !isHmoCoverageReversibleWithin24h(coverage)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'HMO coverage can only be reversed within 24 hours of apply.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    final confirmed = isHmo
        ? await showUncoverHmoDialog(context)
        : await _confirmDiscountReverse();
    if (confirmed == null || !mounted) return;
    setState(() => _coverageBusy = true);
    try {
      await _invoiceService.reverseCoverage(
        invoiceId: detail.id,
        coverageId: coverage.id,
        reason: confirmed.reason,
      );
      await _loadBillingData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _coverageBusy = false);
    }
  }

  Future<UncoverHmoResult?> _confirmDiscountReverse() {
    return showDialog<UncoverHmoResult>(
      context: context,
      builder: (ctx) => const _ReverseCoverageDialog(),
    );
  }

  List<PopupMenuEntry<String>> _lineRefundMenuEntries(BillingInvoiceItem line) {
    final staff = ref.read(authProvider).staff;
    if (!canRequestInvoiceItemRefund(staff)) return const [];

    final entries = <PopupMenuEntry<String>>[];
    if (line.refundPending &&
        canCancelInvoiceItemRefundRequest(staff, line.activeRefundRequest)) {
      entries.add(
        const PopupMenuItem<String>(
          value: 'cancel_refund',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.cancel_outlined, size: 22),
            title: Text('Cancel refund request'),
          ),
        ),
      );
      return entries;
    }

    final tooltip = invoiceItemRefundTooltip(line);
    entries.add(
      PopupMenuItem<String>(
        value: 'request_refund',
        enabled: invoiceLineEligibleForRefundRequest(line),
        child: Tooltip(
          message: tooltip ?? '',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.undo_outlined, size: 22),
            title: const Text('Request refund'),
            subtitle: tooltip != null
                ? Text(tooltip, style: const TextStyle(fontSize: 11))
                : null,
          ),
        ),
      ),
    );
    return entries;
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
    if (canEditRecurringInvoiceItemStartDate(
      ref.read(authProvider).staff,
      line,
    )) {
      entries.add(
        const PopupMenuItem<String>(
          value: 'edit_recurring_start',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.edit_calendar_outlined, size: 22),
            title: Text('Edit start date'),
            subtitle: Text(
              'Change recurring start and recalculate amount',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ),
      );
    }
    final refundEntries = _lineRefundMenuEntries(line);
    if (refundEntries.isNotEmpty) {
      entries.add(const PopupMenuDivider());
      entries.addAll(refundEntries);
    }
    final colorScheme = Theme.of(context).colorScheme;
    if (canDeleteInpatientInvoice(ref.read(authProvider).staff)) {
      entries.add(const PopupMenuDivider());
      entries.add(
        PopupMenuItem<String>(
          value: 'delete_line',
          child: ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_outline,
              size: 22,
              color: colorScheme.error,
            ),
            title: Text(
              'Delete item',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ),
      );
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
            if (canEditRecurringInvoiceItemStartDate(
              ref.read(authProvider).staff,
              line,
            )) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit_calendar_outlined),
                title: const Text('Edit start date'),
                subtitle: const Text(
                  'Change recurring start and recalculate amount',
                ),
                onTap: () => Navigator.pop(ctx, 'edit_recurring_start'),
              ),
            ],
            if (_lineRefundMenuEntries(line).isNotEmpty) ...[
              const Divider(height: 1),
              if (line.refundPending &&
                  canCancelInvoiceItemRefundRequest(
                    ref.read(authProvider).staff,
                    line.activeRefundRequest,
                  ))
                ListTile(
                  leading: const Icon(Icons.cancel_outlined),
                  title: const Text('Cancel refund request'),
                  onTap: () => Navigator.pop(ctx, 'cancel_refund'),
                )
              else
                ListTile(
                  leading: const Icon(Icons.undo_outlined),
                  title: const Text('Request refund'),
                  subtitle: invoiceItemRefundTooltip(line) != null
                      ? Text(invoiceItemRefundTooltip(line)!)
                      : null,
                  enabled: invoiceLineEligibleForRefundRequest(line),
                  onTap: invoiceLineEligibleForRefundRequest(line)
                      ? () => Navigator.pop(ctx, 'request_refund')
                      : null,
                ),
            ],
            if (canDeleteInpatientInvoice(ref.read(authProvider).staff)) ...[
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.delete_outline,
                  color: Theme.of(ctx).colorScheme.error,
                ),
                title: Text(
                  'Delete item',
                  style: TextStyle(color: Theme.of(ctx).colorScheme.error),
                ),
                onTap: () => Navigator.pop(ctx, 'delete_line'),
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
    String patientUuid,
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
                        patientId: patientUuid,
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
                    backgroundColor: DepartmentColors.outpatientClinic
                        .withValues(alpha: 0.15),
                    child: Icon(
                      Icons.radar,
                      color: DepartmentColors.outpatientClinic,
                    ),
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
                    backgroundColor: DepartmentColors.billing.withValues(
                      alpha: 0.15,
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: DepartmentColors.billing,
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
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  title: const Text('Add consumables'),
                  subtitle: const Text(
                    'Purchases store items — price and quantity',
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showAddConsumablesModal(context);
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
    final staff = ref.watch(authProvider).staff;
    final detail = _billingDetail;

    if (_loading || _loadError != null || detail == null) {
      final subtitle = _loadError != null
          ? 'Could not load this invoice'
          : _loading
          ? 'Loading invoice'
          : 'Invoice data unavailable';
      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: ResponsiveBody(
          center: false,
          builder: (context, bp) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _pageHeader(
                subtitle: subtitle,
                compact: bp.isMobile,
                trailing: [
                  if (_loadError != null)
                    IconButton(
                      tooltip: 'Retry',
                      visualDensity: VisualDensity.compact,
                      onPressed: _loadBillingData,
                      icon: const Icon(Icons.refresh),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(child: _gatewayBody(colorScheme)),
            ],
          ),
        ),
      );
    }

    final patientUuid = detail.patientId.trim().isNotEmpty
        ? detail.patientId
        : (selectedPatient?.id ?? '');
    final snap = _BillSnapshot(
      patientUuid: patientUuid,
      patientDisplayId: resolveTenCharDisplayId([
        detail.patientDisplayId,
        selectedPatient?.patientId,
      ]),
      invoiceDisplayId: resolveTenCharDisplayId([detail.invoiceDisplayId]),
      patientName: widget.patientName.trim().isNotEmpty
          ? widget.patientName.trim()
          : (selectedPatient?.displayName ?? ''),
      charges: chargesFromBillingDetail(detail),
      totalCharges: detail.totalAmount,
      totalPayments: detail.amountPaid,
      balanceDue: (detail.effectivePayable - detail.amountPaid) > 0
          ? (detail.effectivePayable - detail.amountPaid)
          : 0,
      invoice: detail,
      canDelete: canDeleteInpatientInvoice(staff),
    );

    return PopScope(
      canPop: _allowRouteLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      floatingActionButton: _billFab(snap),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Stack(
        children: [
          ResponsiveBody(
        center: false,
        builder: (context, bp) {
          final width = bp.maxWidth > 0
              ? bp.maxWidth
              : MediaQuery.sizeOf(context).width;
          final showRail = width >= AppBreakpoints.desktopMin;
          final useCards = width < _billCardBreakpoint;
          final main = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _pageHeader(
                subtitle: snap.patientName.isEmpty
                    ? 'Invoice ${snap.invoiceDisplayId}'
                    : '${snap.patientName} · ${snap.invoiceDisplayId}',
                compact: useCards,
                status: _balanceChip(snap),
                trailing: _headerActions(snap, compact: useCards),
              ),
              const SizedBox(height: 10),
              _categoryStrip(snap),
              const SizedBox(height: 10),
              _filterRow(snap, compact: useCards, showRail: showRail),
              const SizedBox(height: 10),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  layoutBuilder: (current, previous) => Stack(
                    fit: StackFit.expand,
                    children: [
                      ...previous,
                      if (current != null) current,
                    ],
                  ),
                  transitionBuilder: (child, animation) {
                    final curved = CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    );
                    return FadeTransition(
                      opacity: curved,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.035, 0),
                          end: Offset.zero,
                        ).animate(curved),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey('${_tabController.index}|$_categoryFilter'),
                    child: _activePane(snap, useCards: useCards),
                  ),
                ),
              ),
            ],
          );
          if (!showRail) return main;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 9, child: main),
              const SizedBox(width: 12),
              Expanded(flex: 3, child: _rail(snap)),
            ],
          );
        },
      ),
          Positioned.fill(child: _fabScrim()),
        ],
      ),
      ),
    );
  }

  Widget _gatewayBody(ColorScheme colorScheme) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HeltySolidIcon(
                icon: Icons.error_outline,
                color: colorScheme.error,
                size: 36,
                iconSize: 20,
              ),
              const SizedBox(height: 12),
              Text(_loadError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: _loadBillingData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return const Center(child: Text('Invoice data unavailable.'));
  }

  Widget _pageHeader({
    required String subtitle,
    required bool compact,
    Widget? status,
    List<Widget> trailing = const [],
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final title = Row(
      children: [
        if (context.router.canPop())
          IconButton(
            tooltip: 'Back',
            visualDensity: VisualDensity.compact,
            onPressed: () => context.router.maybePop(),
            icon: const Icon(Icons.arrow_back),
          ),
        const HeltySolidIcon(
          icon: Icons.receipt_long_outlined,
          color: _accentIndigo,
          size: 34,
          iconSize: 18,
          radius: AppTheme.radiusMd,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PATIENT BILLING',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: _accentIndigo,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.9,
                ),
              ),
              Text(
                'Inpatient Bill',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  height: 1.1,
                ),
              ),
              HeltyEllipsisText(
                text: subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              if (compact && status != null) ...[
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerLeft, child: status),
              ],
            ],
          ),
        ),
      ],
    );
    final tools = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!compact && status != null) ...[status, const SizedBox(width: 4)],
        ...trailing,
      ],
    );
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          const SizedBox(height: 8),
          Align(alignment: Alignment.centerLeft, child: tools),
        ],
      );
    }
    return Row(
      children: [
        Expanded(child: title),
        tools,
      ],
    );
  }

  Widget _balanceChip(_BillSnapshot snap) {
    final position = _positionAfterWallet(snap);
    if (position == null) {
      final left = snap.invoice.effectivePayable - snap.invoice.amountPaid;
      final owing = left > 0.001;
      return HeltyStatusChip(
        label: owing ? 'Still to pay' : 'Settled',
        color: owing ? _accentRed : _accentGreen,
      );
    }
    if (position > 0.001) {
      return const HeltyStatusChip(label: 'Still to pay', color: _accentRed);
    }
    if (position < -0.001) {
      return const HeltyStatusChip(label: 'Money left', color: _accentGreen);
    }
    return const HeltyStatusChip(label: 'Settled', color: _accentGreen);
  }

  List<Widget> _headerActions(_BillSnapshot snap, {required bool compact}) {
    Future<void> exportInvoice({bool share = false}) async {
      final layout = await _chooseInvoicePdfLayout(
        title: share ? 'Save as PDF' : 'Print invoice',
      );
      if (layout == null || !mounted) return;
      final itemized = layout == _InvoicePdfLayout.itemized;
      if (share) {
        await _shareInvoice(
          patientDisplayId: snap.patientDisplayId,
          invoiceDisplayId: snap.invoiceDisplayId,
          effectivePatientName: snap.patientName,
          charges: snap.charges,
          totalCharges: snap.totalCharges,
          totalPayments: snap.totalPayments,
          balanceDue: snap.balanceDue,
          walletBalance: _wallet?.balance ?? 0,
          itemized: itemized,
        );
      } else {
        await _printInvoice(
          patientDisplayId: snap.patientDisplayId,
          invoiceDisplayId: snap.invoiceDisplayId,
          effectivePatientName: snap.patientName,
          charges: snap.charges,
          totalCharges: snap.totalCharges,
          totalPayments: snap.totalPayments,
          balanceDue: snap.balanceDue,
          walletBalance: _wallet?.balance ?? 0,
          itemized: itemized,
        );
      }
    }

    final refresh = IconButton(
      tooltip: 'Reload invoice',
      visualDensity: VisualDensity.compact,
      onPressed: _loadBillingData,
      icon: const Icon(Icons.refresh),
    );
    if (compact) {
      return [
        refresh,
        PopupMenuButton<String>(
          tooltip: 'Invoice actions',
          onSelected: (value) {
            if (value == 'print') {
              exportInvoice();
            } else if (value == 'share') {
              exportInvoice(share: true);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'print', child: Text('Print invoice')),
            PopupMenuItem(value: 'share', child: Text('Save as PDF')),
          ],
        ),
      ];
    }
    return [
      refresh,
      IconButton(
        tooltip: 'Print invoice',
        visualDensity: VisualDensity.compact,
        onPressed: () => exportInvoice(),
        icon: const Icon(Icons.print_outlined),
      ),
      IconButton(
        tooltip: 'Save as PDF',
        visualDensity: VisualDensity.compact,
        onPressed: () => exportInvoice(share: true),
        icon: const Icon(Icons.ios_share_rounded),
      ),
    ];
  }

  /// Patient's share minus wallet and payments. Positive means still owing.
  /// Null while the wallet has not loaded.
  double? _positionAfterWallet(_BillSnapshot snap) {
    final wallet = _wallet?.balance;
    if (wallet == null) return null;
    return snap.invoice.effectivePayable - (wallet + snap.invoice.amountPaid);
  }

  double _activeCoverageSum(BillingInvoiceDetail invoice, String kind) {
    final wanted = kind.trim().toUpperCase();
    var sum = 0.0;
    for (final coverage in invoice.coverages) {
      if (coverage.kind.trim().toUpperCase() != wanted) continue;
      final status = coverage.status.trim().toUpperCase();
      if (status == 'REVERSED' ||
          status == 'CANCELLED' ||
          status == 'VOIDED') {
        continue;
      }
      sum += coverage.computedAmount;
    }
    return sum;
  }

  Widget _categoryStrip(_BillSnapshot snap) {
    final groups = _billGroups(snap.charges);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppBreakpoints.tabletMin;
        if (!wide) {
          return SizedBox(
            height: 74,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: groups.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) =>
                  SizedBox(width: 176, child: _categoryTile(groups[i])),
            ),
          );
        }
        return Row(
          children: [
            for (var i = 0; i < groups.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(child: _categoryTile(groups[i])),
            ],
          ],
        );
      },
    );
  }

  Widget _categoryTile(_BillGroup group) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final selected = _categoryFilter == group.key;
    return AnimatedScale(
      scale: selected ? 1 : 0.985,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: selected ? group.color.withValues(alpha: 0.10) : cs.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: selected
                ? group.color
                : cs.outline.withValues(alpha: 0.22),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            onTap: () => _selectCategory(group.key),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              child: Row(
          children: [
            HeltySolidIcon(
              icon: group.icon,
              color: group.color,
              size: 28,
              iconSize: 15,
              radius: 8,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HeltyEllipsisText(
                    text: group.label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected ? group.color : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  HeltyEllipsisText(
                    text: group.total.toFinancial(isMoney: true),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.onSurface,
                      height: 1.15,
                    ),
                  ),
                  HeltyEllipsisText(
                    text:
                        '${group.count} lines · paid ${group.paid.toFinancial(isMoney: true)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _selectCategory(String key) {
    if (_categoryFilter == key && _tabController.index == 0) return;
    setState(() {
      _categoryFilter = key;
      _listSkip = 0;
    });
    if (_tabController.index != 0) _tabController.animateTo(0);
  }

  Widget _filterRow(
    _BillSnapshot snap, {
    required bool compact,
    required bool showRail,
  }) {
    final button = IconButton(
      tooltip: showRail ? 'Filters' : 'Filters and actions',
      onPressed: () => _openFilters(
        snap,
        includeCategory: compact,
        includeActions: !showRail,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      icon: const HeltySolidIcon(
        icon: Icons.tune,
        color: _accentPurple,
        size: 32,
        iconSize: 16,
        radius: 8,
      ),
    );
    final search = _searchField();
    final tabs = _ledgerTabs();
    if (compact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: search),
              const SizedBox(width: 8),
              button,
            ],
          ),
          const SizedBox(height: 8),
          tabs,
        ],
      );
    }
    return Row(
      children: [
        Expanded(flex: 4, child: search),
        const SizedBox(width: 8),
        Expanded(flex: 5, child: tabs),
        const SizedBox(width: 8),
        button,
      ],
    );
  }

  Widget _ledgerTabs() {
    const tabs = [
      (0, 'Charges', Icons.receipt_long_outlined, _accentIndigo),
      (1, 'Payments', Icons.payments_outlined, _accentGreen),
      (2, 'Refunds', Icons.assignment_return_outlined, _accentPink),
    ];
    return Row(
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          Expanded(
            child: _ledgerTab(
              index: tabs[i].$1,
              label: tabs[i].$2,
              icon: tabs[i].$3,
              color: tabs[i].$4,
            ),
          ),
        ],
      ],
    );
  }

  Widget _ledgerTab({
    required int index,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final selected = _tabController.index == index;
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      height: 40,
      decoration: BoxDecoration(
        color: selected ? color : cs.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(
          color: selected ? color : cs.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          onTap: () {
            if (_tabController.index != index) _tabController.animateTo(index);
            setState(() => _listSkip = 0);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? Colors.white : color),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? Colors.white : cs.onSurface,
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    required String hint,
    required IconData icon,
    required Color iconColor,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      isDense: true,
      prefixIcon: Padding(
        padding: const EdgeInsets.all(6),
        child: HeltySolidIcon(
          icon: icon,
          color: iconColor,
          size: 22,
          iconSize: 13,
          radius: 6,
        ),
      ),
      prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
      filled: true,
      fillColor: cs.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      labelStyle: const TextStyle(fontSize: 11),
    );
  }

  String get _searchHint {
    switch (_tabController.index) {
      case 1:
        return 'Method, source, or note';
      case 2:
        return 'Item, status, or reason';
      default:
        return 'Description or category';
    }
  }

  Widget _searchField() {
    return TextField(
      controller: _lineSearchCtrl,
      style: const TextStyle(fontSize: 12),
      decoration: _fieldDecoration(
        label: 'Search',
        hint: _searchHint,
        icon: Icons.search,
        iconColor: _accentIndigo,
      ),
    );
  }

  Widget _categoryDropdown({VoidCallback? onUpdated}) {
    return DropdownButtonFormField<String>(
      key: ValueKey('cat-$_categoryFilter'),
      initialValue: _categoryFilter,
      isExpanded: true,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _fieldDecoration(
        label: 'Category',
        hint: '',
        icon: Icons.category_outlined,
        iconColor: _accentPink,
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All categories')),
        DropdownMenuItem(value: 'daily', child: Text('Daily charges')),
        DropdownMenuItem(value: 'pharmacy', child: Text('Pharmacy')),
        DropdownMenuItem(value: 'diagnostics', child: Text('Diagnostics')),
        DropdownMenuItem(value: 'supplies', child: Text('Supplies')),
        DropdownMenuItem(value: 'other', child: Text('Other')),
      ],
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          _categoryFilter = v;
          _listSkip = 0;
        });
        onUpdated?.call();
      },
    );
  }

  Widget _settlementDropdown({VoidCallback? onUpdated}) {
    return DropdownButtonFormField<String>(
      key: ValueKey('settle-$_settlementFilter'),
      initialValue: _settlementFilter,
      isExpanded: true,
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: _fieldDecoration(
        label: 'Settlement',
        hint: '',
        icon: Icons.flag_outlined,
        iconColor: _accentAmber,
      ),
      items: const [
        DropdownMenuItem(value: 'all', child: Text('All lines')),
        DropdownMenuItem(value: 'due', child: Text('Outstanding')),
        DropdownMenuItem(value: 'paid', child: Text('Paid')),
      ],
      onChanged: (v) {
        if (v == null) return;
        setState(() {
          _settlementFilter = v;
          _listSkip = 0;
        });
        onUpdated?.call();
      },
    );
  }

  Future<void> _openFilters(
    _BillSnapshot snap, {
    required bool includeCategory,
    required bool includeActions,
  }) {
    final body = StatefulBuilder(
      builder: (context, setLocal) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Category and settlement apply to charges.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          if (includeCategory) ...[
            _categoryDropdown(onUpdated: () => setLocal(() {})),
            const SizedBox(height: 10),
          ],
          _settlementDropdown(onUpdated: () => setLocal(() {})),
        ],
      ),
    );
    if (includeActions) {
      return showHeltySlidePanel(
        context: context,
        body: body,
        below: _billStatement(snap, fill: false),
      );
    }
    final width = MediaQuery.sizeOf(context).width;
    final maxWidth = width - 32 < 560 ? width - 32 : 560.0;
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (ctx) => Dialog(
        alignment: Alignment.topRight,
        insetPadding: const EdgeInsets.fromLTRB(16, 88, 16, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const HeltySolidIcon(
                      icon: Icons.tune,
                      color: _accentPurple,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filters',
                      style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.of(ctx).maybePop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                body,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _rail(_BillSnapshot snap) => _billStatement(snap, fill: true);

  Widget _fabScrim() {
    return AnimatedBuilder(
      animation: _fabController,
      builder: (context, _) {
        final open = _fabController.value > 0;
        return IgnorePointer(
          ignoring: !open,
          child: GestureDetector(
            onTap: _fabController.reverse,
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.28 * _fabController.value),
            ),
          ),
        );
      },
    );
  }

  void _toggleBillActions() {
    if (_fabController.status == AnimationStatus.dismissed ||
        _fabController.status == AnimationStatus.reverse) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  List<HeltySlideAction> _fabActions(_BillSnapshot snap) {
    final actions = _slideActions(snap);
    if (snap.canDelete) {
      final cs = Theme.of(context).colorScheme;
      actions.add(
        HeltySlideAction(
          label: 'Delete invoice',
          icon: Icons.delete_forever_outlined,
          colors: [cs.error, const Color(0xFFB91C1C)],
          onPressed: _deletingInvoice
              ? null
              : () => _deleteInvoiceAndAllItems(
                  invoiceDisplayId: snap.invoiceDisplayId,
                  detail: snap.invoice,
                ),
        ),
      );
    }
    return actions;
  }

  Widget _billFab(_BillSnapshot snap) {
    final actions = _fabActions(snap);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < actions.length; i++)
          _dialItem(actions[i], i, actions.length),
        const SizedBox(height: 4),
        FloatingActionButton(
          heroTag: 'inpatient-bill-actions',
          tooltip: 'Bill actions',
          backgroundColor: _accentIndigo,
          onPressed: _toggleBillActions,
          child: AnimatedIcon(
            icon: AnimatedIcons.menu_close,
            progress: _fabController,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _dialItem(HeltySlideAction action, int index, int count) {
    final fromBottom = count - 1 - index;
    final start = (fromBottom * 0.07).clamp(0.0, 0.55);
    final enabled = action.onPressed != null;
    final color = enabled
        ? action.colors.first
        : Theme.of(context).colorScheme.outline;
    final row = Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            elevation: 3,
            borderRadius: BorderRadius.circular(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FloatingActionButton.small(
            heroTag: 'inpatient-bill-$index-${action.label}',
            backgroundColor: color,
            elevation: enabled ? 4 : 0,
            tooltip: action.label,
            onPressed: enabled
                ? () {
                    _fabController.reverse();
                    action.onPressed!();
                  }
                : null,
            child: Icon(action.icon, color: Colors.white, size: 18),
          ),
        ],
      ),
    );
    return AnimatedBuilder(
      animation: _fabController,
      builder: (context, child) {
        final t = Interval(
          start,
          1,
          curve: Curves.easeOutCubic,
        ).transform(_fabController.value.clamp(0.0, 1.0));
        return IgnorePointer(
          ignoring: t < 0.05,
          child: Opacity(
            opacity: t,
            child: Align(
              alignment: Alignment.centerRight,
              heightFactor: t,
              child: child,
            ),
          ),
        );
      },
      child: row,
    );
  }

  Widget _billStatement(_BillSnapshot snap, {required bool fill}) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final invoice = snap.invoice;
    final position = _positionAfterWallet(snap);
    final owing = position != null && position > 0.001;
    final leftover = position != null && position < -0.001;
    final heroColor = position == null
        ? _accentIndigo
        : (owing ? _accentRed : _accentGreen);
    final heroTitle = position == null
        ? 'Balance after wallet'
        : owing
        ? 'Still to pay'
        : leftover
        ? 'Money left over'
        : 'Settled';
    final heroValue = position == null
        ? '—'
        : (owing ? position : position.abs()).toFinancial(isMoney: true);
    final walletText = _wallet == null
        ? 'wallet not loaded'
        : _wallet!.balance.toFinancial(isMoney: true);
    final heroHint = position == null
        ? 'Patient\'s share minus the wallet and payments. The wallet has not loaded yet.'
        : owing
        ? 'Patient\'s share − ($walletText + payments). This much is still unpaid.'
        : leftover
        ? 'The wallet and payments are more than the patient\'s share. This much is left.'
        : 'The wallet and payments cover the patient\'s share.';
    final leftOnBill = invoice.effectivePayable - invoice.amountPaid;
    final leftOwing = leftOnBill > 0.001;
    final leftAhead = leftOnBill < -0.001;
    final hmoName = invoice.patientHmoName?.trim() ?? '';
    final hmoPercent = invoice.patientHmoDefaultCoveragePercent;
    final insurance = _activeCoverageSum(invoice, 'HMO');
    final discount = _activeCoverageSum(invoice, 'DISCOUNT');
    final insuranceHint = hmoName.isEmpty
        ? 'No insurer is linked to this patient'
        : hmoPercent == null
        ? hmoName
        : '$hmoName · ${hmoPercent.round()}% of eligible charges';

    final header = Row(
      children: [
        HeltySolidIcon(
          icon: owing
              ? Icons.warning_amber_rounded
              : Icons.account_balance_outlined,
          color: heroColor,
          size: 28,
          iconSize: 15,
          radius: 8,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Where this bill stands',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                invoice.status.trim().isEmpty ? 'Invoice' : invoice.status,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    final hero = _BreathingWash(
      color: heroColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              heroTitle,
              style: theme.textTheme.labelLarge?.copyWith(
                color: heroColor,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              heroValue,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: heroColor,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              heroHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );

    final lines = <Widget>[
      _moneyRow(
        title: 'Services rendered',
        value: invoice.totalAmount.toFinancial(isMoney: true),
        hint: 'Total value of care charged on this bill',
        icon: Icons.medical_services_outlined,
        color: _accentBlue,
      ),
      _moneyRow(
        title: 'Payments received',
        value: invoice.amountPaid.toFinancial(isMoney: true),
        hint: '${_mergedInvoicePayments.length} payments recorded on this bill',
        icon: Icons.payments_outlined,
        color: _accentGreen,
      ),
      _moneyRow(
        title: 'Wallet balance',
        value: _wallet == null
            ? '—'
            : _wallet!.balance.toFinancial(isMoney: true),
        hint: _wallet == null
            ? 'Not loaded yet'
            : 'Money the patient can still spend',
        icon: Icons.savings_outlined,
        color: _accentTeal,
      ),
      _moneyRow(
        title: 'Insurance',
        value: insurance <= 0.001
            ? 'None'
            : insurance.toFinancial(isMoney: true),
        hint: insuranceHint,
        icon: Icons.health_and_safety_outlined,
        color: _accentPurple,
      ),
      _moneyRow(
        title: 'Discount',
        value: discount <= 0.001 ? 'None' : discount.toFinancial(isMoney: true),
        hint: discount <= 0.001
            ? 'No discount applied'
            : 'Amount taken off the price',
        icon: Icons.discount_outlined,
        color: _accentPink,
      ),
      _moneyRow(
        title: 'Amount covered',
        value: invoice.coveredAmount.toFinancial(isMoney: true),
        hint: 'Insurance and discount together',
        icon: Icons.verified_outlined,
        color: _accentPurple,
      ),
      _moneyRow(
        title: 'Patient\'s share',
        value: invoice.effectivePayable.toFinancial(isMoney: true),
        hint: 'Services rendered, after insurance and discount',
        icon: Icons.person_outline,
        color: _accentIndigo,
      ),
      _moneyRow(
        title: leftAhead ? 'Paid ahead on the bill' : 'Left on this bill',
        value: leftOnBill.abs().toFinancial(isMoney: true),
        hint: leftOwing
            ? 'Patient\'s share minus payments. The wallet is not counted yet.'
            : leftAhead
            ? 'Payments are already more than the patient\'s share.'
            : 'Payments match the patient\'s share.',
        icon: Icons.receipt_long_outlined,
        color: leftOwing ? _accentRed : _accentGreen,
        valueColor: leftOwing ? _accentRed : _accentGreen,
      ),
      const SizedBox(height: 8),
      Text(
        'Insurance and discount',
        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
      ),
      if (_coverageBusy) ...[
        const SizedBox(height: 8),
        const LinearProgressIndicator(minHeight: 2),
      ],
      const SizedBox(height: 8),
      _coverageActions(invoice),
      const SizedBox(height: 8),
      _coverageList(invoice, scroll: false),
    ];

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        const SizedBox(height: 10),
        hero,
        const SizedBox(height: 4),
        if (fill)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 6, bottom: 88),
              children: lines,
            ),
          )
        else
          ...lines,
      ],
    );

    if (!fill) return body;
    return Card(
      margin: EdgeInsets.zero,
      child: SizedBox.expand(
        child: Padding(padding: const EdgeInsets.all(12), child: body),
      ),
    );
  }

  Widget _moneyRow({
    required String title,
    required String value,
    required String hint,
    required IconData icon,
    required Color color,
    Color? valueColor,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeltySolidIcon(
            icon: icon,
            color: color,
            size: 28,
            iconSize: 14,
            radius: 8,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  hint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  List<HeltySlideAction> _slideActions(_BillSnapshot snap) {
    final invoice = snap.invoice;
    final due = (invoice.effectivePayable - invoice.amountPaid) > 0.001;
    final hasRecurring = invoice.invoiceItems.any((e) => e.isRecurringDaily);
    final payLabel = _selectedLineIdsForPay.isEmpty
        ? 'Pay bill'
        : 'Pay selected (${_selectedLineIdsForPay.length})';
    return [
      HeltySlideAction(
        label: 'Add service',
        icon: Icons.add,
        colors: const [_accentBlue, _accentIndigo],
        onPressed: () =>
            _showAddActionSheet(context, snap.patientUuid, snap.patientName),
      ),
      HeltySlideAction(
        label: payLabel,
        icon: Icons.payments_outlined,
        colors: const [_accentGreen, _accentTeal],
        onPressed: due ? _paySelectedOrAll : null,
      ),
      HeltySlideAction(
        label: 'Deposit wallet',
        icon: Icons.account_balance_wallet_outlined,
        colors: const [_accentTeal, _accentBlue],
        onPressed: snap.patientUuid.isEmpty
            ? null
            : () => WalletDepositDialog.show(
                context,
                ref: ref,
                patientUuid: snap.patientUuid,
                patientName: snap.patientName,
                chartNumber: snap.patientDisplayId,
                onSuccess: _loadBillingData,
              ),
      ),
      HeltySlideAction(
        label: 'Wallet history',
        icon: Icons.history,
        colors: const [_accentIndigo, _accentPurple],
        onPressed: snap.patientUuid.isEmpty
            ? null
            : () => context.router.push(
                PatientWalletHistoryRoute(
                  patientUuid: snap.patientUuid,
                  patientName: snap.patientName,
                  chartNumber: snap.patientDisplayId,
                ),
              ),
      ),
      HeltySlideAction(
        label: 'Pause or resume',
        icon: Icons.pause_circle_outline,
        colors: const [_accentAmber, _accentPink],
        onPressed: hasRecurring
            ? () => _showRecurringControlDialog(context, invoice)
            : null,
      ),
      HeltySlideAction(
        label: 'Discharge',
        icon: Icons.logout,
        colors: const [_accentPink, _accentPurple],
        onPressed: () =>
            _showDischargeDialog(context, snap.patientUuid, snap.patientName),
      ),
    ];
  }

  void _paySelectedOrAll() {
    final invoice = _billingDetail;
    if (invoice == null) return;
    if ((invoice.effectivePayable - invoice.amountPaid) <= 0.001) return;
    final lines = _selectedLineIdsForPay.isEmpty
        ? invoice.invoiceItems.toList()
        : invoice.invoiceItems
              .where((e) => _selectedLineIdsForPay.contains(e.id))
              .toList();
    if (lines.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No bill lines to pay')));
      return;
    }
    _openPayBillForItems(lines);
  }

  Widget _activePane(_BillSnapshot snap, {required bool useCards}) {
    switch (_tabController.index) {
      case 1:
        return _paymentsPane(useCards: useCards);
      case 2:
        return _refundsPane(snap, useCards: useCards);
      default:
        return _chargesPane(snap, useCards: useCards);
    }
  }

  ({int skip, int end, bool hasMore}) _window(int length) {
    if (length <= 0) return (skip: 0, end: 0, hasMore: false);
    final skip = _listSkip >= length ? 0 : _listSkip;
    final end = skip + _billPageSize > length ? length : skip + _billPageSize;
    return (skip: skip, end: end, hasMore: end < length);
  }

  void _goPrev(int skip) {
    final next = skip - _billPageSize;
    setState(() => _listSkip = next < 0 ? 0 : next);
  }

  void _goNext(int total, int skip) {
    final next = skip + _billPageSize;
    if (next >= total) return;
    setState(() => _listSkip = next);
  }

  bool _chargeInCategory(ChargeItem item) {
    switch (_categoryFilter) {
      case 'daily':
        return item.category == ChargeCategory.daily;
      case 'pharmacy':
        return item.category == ChargeCategory.pharmacy;
      case 'diagnostics':
        return item.category == ChargeCategory.lab ||
            item.category == ChargeCategory.radiology;
      case 'supplies':
        return item.category == ChargeCategory.supplies;
      case 'other':
        return item.category == ChargeCategory.other ||
            item.category == ChargeCategory.surgery;
      default:
        return true;
    }
  }

  bool _chargeInSettlement(ChargeItem item) {
    switch (_settlementFilter) {
      case 'due':
        return !item.isLineFullyPaid;
      case 'paid':
        return item.isLineFullyPaid;
      default:
        return true;
    }
  }

  List<ChargeItem> _filteredCharges(_BillSnapshot snap) {
    final source =
        _lineQuery.isEmpty &&
            _categoryFilter == 'all' &&
            _settlementFilter == 'all'
        ? snap.charges
        : [
            for (final item in snap.charges)
              if (_chargeMatches(item, snap.invoice)) item,
          ];
    final list = [...source];
    list.sort((a, b) {
      final order = _groupOrder(a.category).compareTo(_groupOrder(b.category));
      if (order != 0) return order;
      return a.date.compareTo(b.date);
    });
    return list;
  }

  String _groupKey(ChargeCategory category) {
    switch (category) {
      case ChargeCategory.daily:
        return 'daily';
      case ChargeCategory.pharmacy:
        return 'pharmacy';
      case ChargeCategory.lab:
      case ChargeCategory.radiology:
        return 'diagnostics';
      case ChargeCategory.supplies:
        return 'supplies';
      case ChargeCategory.surgery:
      case ChargeCategory.other:
        return 'other';
    }
  }

  int _groupOrder(ChargeCategory category) {
    return switch (_groupKey(category)) {
      'daily' => 0,
      'pharmacy' => 1,
      'diagnostics' => 2,
      'supplies' => 3,
      _ => 4,
    };
  }

  ({String label, IconData icon, Color color}) _groupMeta(String key) {
    return switch (key) {
      'daily' => (
        label: 'Daily charges',
        icon: Icons.bed_outlined,
        color: _accentIndigo,
      ),
      'pharmacy' => (
        label: 'Pharmacy',
        icon: Icons.medication_outlined,
        color: _accentGreen,
      ),
      'diagnostics' => (
        label: 'Diagnostics',
        icon: Icons.biotech_outlined,
        color: _accentPurple,
      ),
      'supplies' => (
        label: 'Supplies',
        icon: Icons.inventory_2_outlined,
        color: _accentTeal,
      ),
      _ => (
        label: 'Other charges',
        icon: Icons.receipt_outlined,
        color: _accentBlue,
      ),
    };
  }

  List<_BillGroup> _billGroups(List<ChargeItem> charges) {
    final groups = <_BillGroup>[
      _BillGroup(
        key: 'all',
        label: 'Whole bill',
        icon: Icons.account_balance_outlined,
        color: _accentIndigo,
        total: chargeSectionTotal(charges),
        paid: chargeSectionPaid(charges),
        count: charges.length,
      ),
    ];
    for (final key in ['daily', 'pharmacy', 'diagnostics', 'supplies', 'other']) {
      final items = [
        for (final item in charges)
          if (_groupKey(item.category) == key) item,
      ];
      if (items.isEmpty && _categoryFilter != key) continue;
      final meta = _groupMeta(key);
      groups.add(
        _BillGroup(
          key: key,
          label: meta.label,
          icon: meta.icon,
          color: meta.color,
          total: chargeSectionTotal(items),
          paid: chargeSectionPaid(items),
          count: items.length,
        ),
      );
    }
    return groups;
  }

  bool _chargeMatches(ChargeItem item, BillingInvoiceDetail invoice) {
    if (!_chargeInCategory(item) || !_chargeInSettlement(item)) return false;
    if (_lineQuery.isEmpty) return true;
    final line = _billingLineForCharge(item, invoice);
    final hay = [
      item.description,
      chargeCategoryLabel(item.category),
      _chargeDetailLine(item, line),
      line?.createdByName ?? '',
    ].join(' ').toLowerCase();
    return hay.contains(_lineQuery);
  }

  String _chargeDetailLine(ChargeItem item, BillingInvoiceItem? line) {
    if (line != null && line.isRecurringDaily) {
      final daily = line.unitPrice.toFinancial(isMoney: true);
      final startAt = _activeUsageSegment(line)?.startAt;
      if (startAt == null) {
        final state = line.usageSegments.isEmpty ? 'Recurring daily' : 'Paused';
        return '$state · $daily/day';
      }
      final days = _inclusiveCalendarDays(startAt, DateTime.now());
      final state = _isRecurringUsageActive(line) ? 'Running' : 'Paused';
      final dayLabel = days == 1 ? 'day' : 'days';
      return '$state · ${_formatDate(startAt.toLocal())} · $days $dayLabel · $daily/day';
    }
    final parts = <String>[_formatDate(item.date)];
    if (item.quantity > 1) {
      parts.add('Qty ${item.quantity}');
      parts.add('${item.amount.toFinancial(isMoney: true)} / unit');
    }
    final by = line?.createdByName?.trim() ?? '';
    if (by.isNotEmpty) parts.add('Added by $by');
    return parts.join(' · ');
  }

  (String, Color) _chargeStatus(ChargeItem item, BillingInvoiceItem? line) {
    if (line?.refundPending == true) return ('Refund pending', _accentAmber);
    if (item.isLineFullyPaid) return ('Paid', _accentGreen);
    if (item.amountPaid > 0.001) return ('Partial', _accentBlue);
    return ('Due', _accentPink);
  }

  Color _categoryColor(ChargeCategory category) {
    switch (category) {
      case ChargeCategory.daily:
        return _accentIndigo;
      case ChargeCategory.pharmacy:
        return _accentGreen;
      case ChargeCategory.lab:
      case ChargeCategory.radiology:
        return _accentPurple;
      case ChargeCategory.supplies:
        return _accentTeal;
      case ChargeCategory.surgery:
      case ChargeCategory.other:
        return _accentBlue;
    }
  }

  Widget _chargesPane(_BillSnapshot snap, {required bool useCards}) {
    final rows = _filteredCharges(snap);
    final window = _window(rows.length);
    final page = rows.sublist(window.skip, window.end);
    final due = chargeSectionDue(rows);
    final empty = snap.charges.isEmpty
        ? 'No charges on this invoice yet.'
        : 'No charges match these filters.';
    return _dataSurface(
      useCards: useCards,
      minWidth: 1040,
      emptyMessage: empty,
      total: rows.length,
      skip: window.skip,
      hasMore: window.hasMore,
      shown: page.length,
      footer: _countLabel(
        skip: window.skip,
        shown: page.length,
        total: rows.length,
        noun: 'lines',
        extra: 'Due ${due.toFinancial(isMoney: true)}',
      ),
      ribbon: _paneRibbon(
        title: 'Itemized charges',
        caption: 'Grouped by category. Paid and used stay on each line.',
        color: _accentIndigo,
        icon: Icons.receipt_long_outlined,
      ),
      tableHeader: _chargeHeader(),
      tableRow: (index) => _withGroupBanner(
        index: index,
        page: page,
        rows: rows,
        child: _chargeTableRow(
          page[index],
          snap.invoice,
          zebraIndex: window.skip + index,
        ),
      ),
      card: (index) => _withGroupBanner(
        index: index,
        page: page,
        rows: rows,
        child: _chargeCard(
          page[index],
          snap.invoice,
          indexLabel: '${window.skip + index + 1}',
        ),
      ),
    );
  }

  Widget _withGroupBanner({
    required int index,
    required List<ChargeItem> page,
    required List<ChargeItem> rows,
    required Widget child,
  }) {
    final key = _groupKey(page[index].category);
    final previous = index == 0 ? null : _groupKey(page[index - 1].category);
    if (previous == key) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _groupBanner(key, rows),
        child,
      ],
    );
  }

  Widget _groupBanner(String key, List<ChargeItem> rows) {
    final items = [
      for (final item in rows)
        if (_groupKey(item.category) == key) item,
    ];
    final meta = _groupMeta(key);
    final theme = Theme.of(context);
    return Container(
      color: meta.color.withValues(alpha: 0.10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          HeltySolidIcon(
            icon: meta.icon,
            color: meta.color,
            size: 22,
            iconSize: 12,
            radius: 6,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              meta.label,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            'Paid ${chargeSectionPaid(items).toFinancial(isMoney: true)}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: _accentGreen,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            chargeSectionTotal(items).toFinancial(isMoney: true),
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paneRibbon({
    required String title,
    required String caption,
    required Color color,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          HeltySolidIcon(
            icon: icon,
            color: color,
            size: 26,
            iconSize: 14,
            radius: 7,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  caption,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chargeHeader() {
    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  const SizedBox(width: 40),
                  _colGap(),
                  _head('DESCRIPTION', flex: 4),
                  _colGap(),
                  _head('CATEGORY', flex: 3),
                  _colGap(),
                  _head('DETAILS', flex: 5),
                  _colGap(),
                  _head('AMOUNT', flex: 3, end: true),
                  _colGap(),
                  const SizedBox(width: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chargeTableRow(
    ChargeItem item,
    BillingInvoiceDetail invoice, {
    required int zebraIndex,
  }) {
    final line = _billingLineForCharge(item, invoice);
    final cs = Theme.of(context).colorScheme;
    final status = _chargeStatus(item, line);
    return Material(
      color: zebraIndex.isOdd
          ? cs.onSurface.withValues(alpha: 0.035)
          : Colors.transparent,
      child: InkWell(
        onDoubleTap: line == null || item.isLineFullyPaid
            ? null
            : () => _showLinePaymentBottomSheet(line, item),
        onLongPress: line == null || item.isLineFullyPaid
            ? null
            : () => _showLinePaymentBottomSheet(line, item),
        onSecondaryTapDown: line == null || item.isLineFullyPaid
            ? null
            : (d) => _showLinePaymentMenuAt(d.globalPosition, line, item),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(color: status.$2, child: const SizedBox(width: 4)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _lineCheckbox(item),
                      _colGap(),
                      Expanded(
                        flex: 4,
                        child: HeltyEllipsisText(
                          text: item.description,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      _colGap(),
                      Expanded(
                        flex: 3,
                        child: HeltyEllipsisChip(
                          label: chargeCategoryLabel(item.category),
                          color: _categoryColor(item.category),
                        ),
                      ),
                      _colGap(),
                      Expanded(flex: 5, child: _detailText(item, line)),
                      _colGap(),
                      Expanded(flex: 3, child: _amountCell(item, line)),
                      _colGap(),
                      _lineActions(line, item),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chargeCard(
    ChargeItem item,
    BillingInvoiceDetail invoice, {
    required String indexLabel,
  }) {
    final line = _billingLineForCharge(item, invoice);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final status = _chargeStatus(item, line);
    return HeltySurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onLongPress: line == null || item.isLineFullyPaid
            ? null
            : () => _showLinePaymentBottomSheet(line, item),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ColoredBox(color: status.$2, child: const SizedBox(width: 4)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _lineCheckbox(item),
                          const SizedBox(width: 8),
                          Text(
                            indexLabel,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: HeltyEllipsisText(
                              text: item.description,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _lineActions(line, item),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _detailText(item, line),
                      const SizedBox(height: 8),
                      HeltyEllipsisChip(
                        label: chargeCategoryLabel(item.category),
                        color: _categoryColor(item.category),
                      ),
                      const SizedBox(height: 8),
                      _amountCell(item, line),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lineCheckbox(ChargeItem item) {
    final selected = _selectedLineIdsForPay.contains(item.invoiceLineItemId);
    return SizedBox(
      width: 40,
      height: 40,
      child: Center(
        child: Checkbox(
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          value: selected,
          onChanged: (v) {
            setState(() {
              if (v == true) {
                _selectedLineIdsForPay.add(item.invoiceLineItemId);
              } else {
                _selectedLineIdsForPay.remove(item.invoiceLineItemId);
              }
            });
          },
        ),
      ),
    );
  }

  String _paidIndication(ChargeItem item) {
    final paid = item.amountPaid.toFinancial(isMoney: true);
    if (item.amountPaid <= 0.001) return 'Unpaid';
    if (item.isLineFullyPaid) return 'Paid $paid';
    return 'Part paid $paid';
  }

  Color _paidIndicationColor(ChargeItem item) {
    if (item.amountPaid <= 0.001) return _accentPink;
    if (item.isLineFullyPaid) return _accentGreen;
    return _accentBlue;
  }

  String _usedFigure(ChargeItem item, BillingInvoiceItem? line) {
    if (line != null && line.isRecurringDaily) {
      final days = _usedDays(line);
      if (days <= 0) return 'None';
      final dayLabel = days == 1 ? 'day' : 'days';
      return '$days $dayLabel';
    }
    if (item.quantity <= 1) return '1';
    return '× ${item.quantity}';
  }

  String _usedIndication(ChargeItem item, BillingInvoiceItem? line) {
    final figure = _usedFigure(item, line);
    if (figure == 'None') return 'Not used';
    return 'Used $figure';
  }

  Color _usedIndicationColor(ChargeItem item, BillingInvoiceItem? line) {
    if (line != null && line.isRecurringDaily && _usedDays(line) <= 0) {
      return Theme.of(context).colorScheme.outline;
    }
    return _accentTeal;
  }

  Widget _detailText(ChargeItem item, BillingInvoiceItem? line) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _chargeDetailLine(item, line),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        HeltyEllipsisChip(
          label: _paidIndication(item),
          color: _paidIndicationColor(item),
        ),
        const SizedBox(height: 4),
        HeltyEllipsisChip(
          label: _usedIndication(item, line),
          color: _usedIndicationColor(item, line),
        ),
      ],
    );
  }

  Widget _amountCell(ChargeItem item, BillingInvoiceItem? line) {
    final theme = Theme.of(context);
    final covered = line?.lineCovered ?? 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          item.displayLineTotal.toFinancial(isMoney: true),
          textAlign: TextAlign.end,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: item.paymentProgress,
            minHeight: 4,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            color: _paidIndicationColor(item),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: _amountMark(
            'Paid',
            item.amountPaid.toFinancial(isMoney: true),
            _paidIndicationColor(item),
          ),
        ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerRight,
          child: _amountMark(
            'Used',
            _usedFigure(item, line),
            _usedIndicationColor(item, line),
          ),
        ),
        if (covered > 0.001) ...[
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerRight,
            child: _amountMark(
              'Covered',
              covered.toFinancial(isMoney: true),
              _accentPurple,
            ),
          ),
        ],
      ],
    );
  }

  Widget _amountMark(String label, String value, Color color) {
    final theme = Theme.of(context);
    final shown = value.trim().isEmpty ? '—' : value.trim();
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(
            text: '  $shown',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.end,
    );
  }

  Widget _lineActions(BillingInvoiceItem? line, ChargeItem item) {
    if (line == null) {
      return const SizedBox(width: 40);
    }
    if (_deletingLineIds.contains(line.id)) {
      return const SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Builder(
      builder: (anchor) => IconButton(
        tooltip: 'More actions',
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        onPressed: () => _openLineMenu(anchor, line, item),
        icon: Icon(
          Icons.more_vert,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  void _openLineMenu(
    BuildContext anchor,
    BillingInvoiceItem line,
    ChargeItem item,
  ) {
    final box = anchor.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final origin = box.localToGlobal(Offset.zero);
    _showLinePaymentMenuAt(origin + Offset(0, box.size.height), line, item);
  }

  Widget _paymentsPane({required bool useCards}) {
    final rows = _filteredPayments();
    final window = _window(rows.length);
    final page = rows.sublist(window.skip, window.end);
    return _dataSurface(
      useCards: useCards,
      minWidth: 860,
      emptyMessage: _mergedInvoicePayments.isEmpty
          ? 'No payments recorded yet.'
          : 'No payments match this search.',
      total: rows.length,
      skip: window.skip,
      hasMore: window.hasMore,
      shown: page.length,
      footer: _countLabel(
        skip: window.skip,
        shown: page.length,
        total: rows.length,
        noun: 'payments',
      ),
      ribbon: _paneRibbon(
        title: 'Payment ledger',
        caption: 'Money recorded against this invoice.',
        color: _accentGreen,
        icon: Icons.payments_outlined,
      ),
      tableHeader: _ledgerHeader(
        const ['METHOD', 'DATE', 'DETAILS', 'AMOUNT'],
        flex: const [3, 2, 5, 2],
        endLast: true,
      ),
      tableRow: (index) {
        final row = page[index];
        return _ledgerTableRow(
          zebraIndex: window.skip + index,
          stripe: _accentGreen,
          cells: [
            _ledgerText(_paymentTitle(row), strong: true),
            _ledgerText(_paymentWhen(row)),
            _ledgerText(_paymentDetails(row)),
            _ledgerText(
              row.amount.toFinancial(isMoney: true),
              strong: true,
              end: true,
              color: _accentGreen,
            ),
          ],
          flex: const [3, 2, 5, 2],
        );
      },
      card: (index) {
        final row = page[index];
        return _ledgerCard(
          stripe: _accentGreen,
          title: _paymentTitle(row),
          detail: '${_paymentWhen(row)} · ${_paymentDetails(row)}',
          trailing: row.amount.toFinancial(isMoney: true),
          trailingColor: _accentGreen,
        );
      },
    );
  }

  List<BillingInvoicePayment> _filteredPayments() {
    if (_lineQuery.isEmpty) return _mergedInvoicePayments;
    return [
      for (final row in _mergedInvoicePayments)
        if (_paymentHaystack(row).contains(_lineQuery)) row,
    ];
  }

  String _paymentHaystack(BillingInvoicePayment row) {
    return [
      row.method ?? '',
      row.source,
      row.notes ?? '',
      row.receivedByName ?? '',
      row.createdByName ?? '',
      row.reference ?? '',
    ].join(' ').toLowerCase();
  }

  String _paymentTitle(BillingInvoicePayment row) {
    final method = row.method?.trim() ?? '';
    if (method.isNotEmpty) return method;
    return 'Invoice payment';
  }

  String _paymentWhen(BillingInvoicePayment row) {
    final when = row.paidAt ?? row.createdAt;
    if (when == null) return '—';
    return _formatDate(when);
  }

  String _paymentDetails(BillingInvoicePayment row) {
    final parts = <String>[];
    if (row.source.trim().isNotEmpty) parts.add(row.source.trim());
    final received = row.receivedByName?.trim() ?? '';
    if (received.isNotEmpty) {
      parts.add('Received by $received');
    } else {
      final id = row.receivedById?.trim() ?? '';
      if (id.isNotEmpty) parts.add('Received by $id');
    }
    final created = row.createdByName?.trim() ?? '';
    if (created.isNotEmpty && created != received) {
      parts.add('Created by $created');
    }
    final note = row.notes?.trim() ?? '';
    if (note.isNotEmpty) parts.add(note);
    if (row.walletTransactionId?.trim().isNotEmpty == true) {
      parts.add('Wallet');
    }
    if (parts.isEmpty) return '—';
    return parts.join(' · ');
  }

  Widget _refundsPane(_BillSnapshot snap, {required bool useCards}) {
    final historical = snap.invoice.refunds;
    if (_refundRequestsLoading &&
        _refundRequests.isEmpty &&
        historical.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_refundRequestsError != null &&
        _refundRequests.isEmpty &&
        historical.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_refundRequestsError!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _loadRefundRequests,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    final rows = _filteredRefunds(snap.invoice);
    final window = _window(rows.length);
    final page = rows.sublist(window.skip, window.end);
    final empty = historical.isEmpty && _refundRequests.isEmpty
        ? 'No refund requests or completed refunds for this invoice.'
        : 'No refunds match this search.';
    return _dataSurface(
      useCards: useCards,
      minWidth: 980,
      emptyMessage: empty,
      total: rows.length,
      skip: window.skip,
      hasMore: window.hasMore,
      shown: page.length,
      footer: _countLabel(
        skip: window.skip,
        shown: page.length,
        total: rows.length,
        noun: 'refunds',
      ),
      ribbon: _paneRibbon(
        title: 'Refund ledger',
        caption: 'Requests and completed refunds on this invoice.',
        color: _accentPink,
        icon: Icons.assignment_return_outlined,
      ),
      tableHeader: _ledgerHeader(
        const ['ITEM', 'STATUS', 'REASON', 'WHEN', 'AMOUNT'],
        flex: const [4, 2, 4, 2, 2],
        endLast: true,
      ),
      tableRow: (index) {
        final row = page[index];
        return _ledgerTableRow(
          zebraIndex: window.skip + index,
          stripe: row.color,
          cells: [
            _ledgerText(row.title, strong: true),
            HeltyEllipsisChip(label: row.status, color: row.color),
            _ledgerText(row.reason),
            _ledgerText(row.when),
            _ledgerText(row.amount, strong: true, end: true),
          ],
          flex: const [4, 2, 4, 2, 2],
        );
      },
      card: (index) {
        final row = page[index];
        return _ledgerCard(
          stripe: row.color,
          title: row.title,
          detail: '${row.when} · ${row.reason}',
          chip: row.status,
          chipColor: row.color,
          trailing: row.amount,
        );
      },
    );
  }

  List<_RefundLine> _filteredRefunds(BillingInvoiceDetail invoice) {
    final rows = <_RefundLine>[
      for (final refund in invoice.refunds)
        _RefundLine(
          title: 'Completed refund',
          status: 'Refunded',
          reason: (refund.reason ?? '').trim(),
          when: refund.createdAt == null ? '—' : _formatDate(refund.createdAt!),
          amount: refund.amount.toFinancial(isMoney: true),
          color: _accentGreen,
        ),
      for (final request in _refundRequests)
        _RefundLine(
          title: _refundTitle(request, invoice),
          status: request.status,
          reason: _refundReason(request),
          when: request.submittedAt == null
              ? '—'
              : _formatDate(request.submittedAt!),
          amount: '—',
          color: _toneForStatus(request.status),
        ),
    ];
    if (_lineQuery.isEmpty) return rows;
    return [
      for (final row in rows)
        if ('${row.title} ${row.status} ${row.reason} ${row.when}'
            .toLowerCase()
            .contains(_lineQuery))
          row,
    ];
  }

  String _refundTitle(
    BillingInvoiceRefundRequest request,
    BillingInvoiceDetail invoice,
  ) {
    final desc = request.lineDescription?.trim() ?? '';
    if (desc.isNotEmpty) return desc;
    final itemId = request.invoiceItemId;
    if (itemId != null) {
      for (final line in invoice.invoiceItems) {
        if (line.id == itemId) return line.displayLabel;
      }
    }
    return itemId ?? '—';
  }

  String _refundReason(BillingInvoiceRefundRequest request) {
    final parts = <String>[];
    if (request.reason.trim().isNotEmpty) parts.add(request.reason.trim());
    final reject = request.rejectReason?.trim() ?? '';
    if (reject.isNotEmpty) parts.add('Rejection: $reject');
    final by = request.requestedBy?.trim() ?? '';
    if (by.isNotEmpty) parts.add(by);
    return parts.join(' · ');
  }

  Color _toneForStatus(String status) {
    final value = status.toLowerCase();
    if (value.contains('reject') ||
        value.contains('cancel') ||
        value.contains('fail')) {
      return _accentPink;
    }
    if (value.contains('approv') ||
        value.contains('complete') ||
        value.contains('refund') ||
        value.contains('paid') ||
        value.contains('settle')) {
      return _accentGreen;
    }
    if (value.contains('pend') ||
        value.contains('submit') ||
        value.contains('open')) {
      return _accentAmber;
    }
    return _accentBlue;
  }

  Widget _ledgerHeader(
    List<String> labels, {
    required List<int> flex,
    required bool endLast,
  }) {
    return Container(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      child: Row(
        children: [
          const SizedBox(width: 4),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Row(
                children: [
                  for (var i = 0; i < labels.length; i++) ...[
                    if (i > 0) _colGap(),
                    _head(
                      labels[i],
                      flex: flex[i],
                      end: endLast && i == labels.length - 1,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ledgerTableRow({
    required int zebraIndex,
    required Color stripe,
    required List<Widget> cells,
    required List<int> flex,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: zebraIndex.isOdd
          ? cs.onSurface.withValues(alpha: 0.035)
          : Colors.transparent,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(color: stripe, child: const SizedBox(width: 4)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    for (var i = 0; i < cells.length; i++) ...[
                      if (i > 0) _colGap(),
                      Expanded(flex: flex[i], child: cells[i]),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ledgerCard({
    required Color stripe,
    required String title,
    required String detail,
    required String trailing,
    Color? trailingColor,
    String? chip,
    Color? chipColor,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return HeltySurfaceCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(color: stripe, child: const SizedBox(width: 4)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: HeltyEllipsisText(
                            text: title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        HeltyEllipsisText(
                          text: trailing,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: trailingColor ?? cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    HeltyEllipsisText(
                      text: detail,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    if (chip != null && chipColor != null) ...[
                      const SizedBox(height: 8),
                      HeltyEllipsisChip(label: chip, color: chipColor),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ledgerText(
    String text, {
    bool strong = false,
    bool end = false,
    Color? color,
  }) {
    final theme = Theme.of(context);
    return HeltyEllipsisText(
      text: text,
      align: end ? TextAlign.end : TextAlign.start,
      style: (strong ? theme.textTheme.titleSmall : theme.textTheme.bodySmall)
          ?.copyWith(
            fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
            color:
                color ?? (strong ? null : theme.colorScheme.onSurfaceVariant),
          ),
    );
  }

  Widget _dataSurface({
    required bool useCards,
    required double minWidth,
    required String emptyMessage,
    required int total,
    required int skip,
    required bool hasMore,
    required int shown,
    required String footer,
    Widget? ribbon,
    required Widget tableHeader,
    required Widget Function(int index) tableRow,
    required Widget Function(int index) card,
  }) {
    final pager = _pager(
      skip: skip,
      shown: shown,
      total: total,
      hasMore: hasMore,
      label: footer,
    );
    final body = shown == 0
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        : useCards
        ? ListView.builder(itemCount: shown, itemBuilder: (_, i) => card(i))
        : ListView.separated(
            itemCount: shown,
            separatorBuilder: (_, _) => Divider(
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.08),
            ),
            itemBuilder: (_, i) => tableRow(i),
          );

    if (useCards) {
      return Column(
        children: [
          if (ribbon != null) ribbon,
          Expanded(child: body),
          pager,
        ],
      );
    }

    return HeltySurfaceCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          if (ribbon != null) ribbon,
          Expanded(
            child: LayoutBuilder(
              builder: (context, inner) {
                final tableWidth = inner.maxWidth < minWidth
                    ? minWidth
                    : inner.maxWidth;
                final sheet = SizedBox(
                  width: tableWidth,
                  height: inner.maxHeight,
                  child: Column(
                    children: [
                      tableHeader,
                      Expanded(child: body),
                    ],
                  ),
                );
                if (inner.maxWidth >= minWidth) return sheet;
                return _BillHorizontalScroll(child: sheet);
              },
            ),
          ),
          pager,
        ],
      ),
    );
  }

  String _countLabel({
    required int skip,
    required int shown,
    required int total,
    required String noun,
    String? extra,
  }) {
    if (total == 0) return 'No $noun to display';
    final start = skip + 1;
    final end = skip + shown;
    final base = 'Showing $start–$end of $total $noun';
    if (extra == null || extra.isEmpty) return base;
    return '$base · $extra';
  }

  Widget _pager({
    required int skip,
    required int shown,
    required int total,
    required bool hasMore,
    required String label,
  }) {
    final cs = Theme.of(context).colorScheme;
    final page = total == 0 ? 1 : (skip ~/ _billPageSize) + 1;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: HeltyEllipsisText(
              text: label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          IconButton(
            tooltip: 'Previous page',
            onPressed: skip > 0 ? () => _goPrev(skip) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$page',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: 'Next page',
            onPressed: hasMore ? () => _goNext(total, skip) : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _head(String label, {required int flex, bool end = false}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: end ? TextAlign.end : TextAlign.start,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withValues(alpha: 0.55),
        ),
      ),
    );
  }

  Widget _colGap() => const SizedBox(width: 20);

  Widget _coverageActions(BillingInvoiceDetail? detail) {
    final staff = ref.read(authProvider).staff;
    final hasActiveHmo =
        detail != null && activeHmoInvoiceCoverage(detail.coverages) != null;
    final canSplit =
        detail != null &&
        canSplitWithHmo(staff) &&
        detail.status.toUpperCase() != 'PAID' &&
        (detail.patientHmoId ?? '').trim().isNotEmpty &&
        !hasActiveHmo;
    final canDiscount =
        detail != null &&
        canApplyDiscount(staff) &&
        detail.status.toUpperCase() != 'PAID';
    final policiesByReason = <String, List<DiscountPolicy>>{};
    for (final policy in _discountPolicies) {
      policiesByReason.putIfAbsent(policy.reason, () => []).add(policy);
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilledButton.tonalIcon(
          style: FilledButton.styleFrom(visualDensity: VisualDensity.compact),
          onPressed: canSplit && !_coverageBusy ? _applyHmoSplit : null,
          icon: const Icon(Icons.local_hospital_outlined, size: 16),
          label: const Text('Split with HMO'),
        ),
        Tooltip(
          message: _discountPolicies.isEmpty
              ? 'No active discount policies'
              : 'Apply a discount policy',
          child: PopupMenuButton<String>(
            enabled:
                canDiscount && !_coverageBusy && _discountPolicies.isNotEmpty,
            onSelected: _applyDiscountPolicy,
            itemBuilder: (context) {
              final entries = <PopupMenuEntry<String>>[];
              final keys = policiesByReason.keys.toList()..sort();
              for (final reason in keys) {
                entries.add(
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Text(
                      reason,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                );
                for (final policy in policiesByReason[reason]!) {
                  entries.add(
                    PopupMenuItem<String>(
                      value: policy.id,
                      child: Text('${policy.name} (${policy.value})'),
                    ),
                  );
                }
              }
              return entries;
            },
            child: const Chip(
              avatar: Icon(Icons.discount_outlined, size: 16),
              label: Text('Apply discount'),
              visualDensity: VisualDensity.compact,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  Widget _coverageList(BillingInvoiceDetail? detail, {required bool scroll}) {
    final theme = Theme.of(context);
    if (detail == null || detail.coverages.isEmpty) {
      return Text(
        'No coverage or discount applied yet.',
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    final staff = ref.read(authProvider).staff;
    final canReverse = canReverseCoverage(staff);
    final tiles = [
      for (final coverage in detail.coverages)
        _coverageTile(coverage, canReverse: canReverse),
    ];
    if (!scroll) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: tiles,
      );
    }
    return ListView(children: tiles);
  }

  Widget _coverageTile(InvoiceCoverage coverage, {required bool canReverse}) {
    final isHmo = coverage.kind.trim().toUpperCase() == 'HMO';
    final status = coverage.status.toUpperCase();
    final canUndo =
        canReverse &&
        status != 'SETTLED' &&
        status != 'REVERSED' &&
        (!isHmo || isHmoCoverageReversibleWithin24h(coverage));
    final windowLabel = isHmo ? formatHmoReverseWindowLabel(coverage) : '';
    final tip = [
      '${coverage.mode ?? '-'} ${coverage.value ?? coverage.percent ?? ''}',
      coverage.appliedByName ?? coverage.appliedById ?? '',
      if (windowLabel.isNotEmpty) windowLabel,
    ].where((part) => part.trim().isNotEmpty).join(' · ');
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Tooltip(
        message: tip,
        waitDuration: const Duration(milliseconds: 350),
        child: Row(
          children: [
            Expanded(
              child: HeltyEllipsisText(
                text:
                    '${coverage.kind} · ${coverage.scope} · ${coverage.status}',
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(width: 8),
            HeltyEllipsisText(
              text: coverage.computedAmount.toFinancial(isMoney: true),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (canUndo)
              IconButton(
                tooltip: isHmo ? 'Uncover HMO' : 'Reverse coverage',
                visualDensity: VisualDensity.compact,
                onPressed: _coverageBusy
                    ? null
                    : () => _reverseCoverage(coverage),
                icon: const Icon(Icons.undo_outlined, size: 18),
              ),
          ],
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

  void _showAddConsumablesModal(BuildContext context) {
    final invoiceId = widget.invoiceId.trim();
    if (invoiceId.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _AddConsumablesSheet(
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
    final payload = await showDischargeAdmissionDialog(context);
    if (payload == null || !mounted) return;
    try {
      final admissionId = await resolveActiveAdmissionId(
        _admissionService,
        patientId,
      );
      if (admissionId == null || admissionId.isEmpty) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text('No active admission found for this patient.'),
          ),
        );
        return;
      }
      final updated = await performClinicalDischarge(
        service: _admissionService,
        admissionId: admissionId,
        payload: payload,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text(dischargeSuccessMessage(updated))));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        this.context,
      ).showSnackBar(SnackBar(content: Text('Discharge failed: $e')));
    }
  }
}

class _BillSnapshot {
  const _BillSnapshot({
    required this.patientUuid,
    required this.patientDisplayId,
    required this.invoiceDisplayId,
    required this.patientName,
    required this.charges,
    required this.totalCharges,
    required this.totalPayments,
    required this.balanceDue,
    required this.invoice,
    required this.canDelete,
  });

  final String patientUuid;
  final String patientDisplayId;
  final String invoiceDisplayId;
  final String patientName;
  final List<ChargeItem> charges;
  final double totalCharges;
  final double totalPayments;
  final double balanceDue;
  final BillingInvoiceDetail invoice;
  final bool canDelete;
}

class _BillGroup {
  const _BillGroup({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.total,
    required this.paid,
    required this.count,
  });

  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final double total;
  final double paid;
  final int count;
}

class _RefundLine {
  const _RefundLine({
    required this.title,
    required this.status,
    required this.reason,
    required this.when,
    required this.amount,
    required this.color,
  });

  final String title;
  final String status;
  final String reason;
  final String when;
  final String amount;
  final Color color;
}

// ==========================================
// Add Other Bills modal (services from backend)
// ==========================================

class _ReverseCoverageDialog extends StatefulWidget {
  const _ReverseCoverageDialog();

  @override
  State<_ReverseCoverageDialog> createState() => _ReverseCoverageDialogState();
}

class _ReverseCoverageDialogState extends State<_ReverseCoverageDialog> {
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reverse coverage'),
      content: TextField(
        controller: _reasonCtrl,
        decoration: const InputDecoration(labelText: 'Reason (optional)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final reason = _reasonCtrl.text.trim();
            Navigator.pop(
              context,
              UncoverHmoResult(reason: reason.isEmpty ? null : reason),
            );
          },
          child: const Text('Reverse'),
        ),
      ],
    );
  }
}

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
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Service has no valid id — cannot add to invoice'),
          backgroundColor: Theme.of(context).colorScheme.error,
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
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${service.name} x${result.qty} to bill'),
          ),
        );
        widget.onAdded();
      }
    } catch (e) {
      if (mounted) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

// ==========================================
// Add consumables modal (purchases catalog)
// ==========================================

class _AddConsumablesSheet extends StatefulWidget {
  const _AddConsumablesSheet({
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
  State<_AddConsumablesSheet> createState() => _AddConsumablesSheetState();
}

class _AddConsumablesSheetState extends State<_AddConsumablesSheet> {
  bool _busy = false;

  Future<void> _onConfirm(
    PurchaseItem item,
    String locationId,
    int qty,
    double unitPrice,
  ) async {
    final itemId = item.id?.trim() ?? '';
    if (itemId.isEmpty) return;
    setState(() => _busy = true);
    try {
      await widget.invoiceService.addBillingItem(
        invoiceId: widget.invoiceId,
        payload: AddInvoiceItemPayload(
          purchaseItemId: itemId,
          purchasesLocationId: locationId,
          unitPrice: unitPrice,
          quantity: qty,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.itemName} x$qty added to bill')),
      );
      widget.onAdded();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add consumable: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.45,
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
                      'Add consumables',
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
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  children: [
                    Text(
                      'Select a purchases store, search items, set unit price and quantity, then add to this invoice.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    PurchasesConsumableBillingPanel(
                      confirmButtonLabel: 'Add to bill',
                      busy: _busy,
                      onConfirm: _onConfirm,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Horizontal table scroller. The scrollbar must use this same controller.
class _BillHorizontalScroll extends StatefulWidget {
  const _BillHorizontalScroll({required this.child});

  final Widget child;

  @override
  State<_BillHorizontalScroll> createState() => _BillHorizontalScrollState();
}

class _BillHorizontalScrollState extends State<_BillHorizontalScroll> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scrollbar(
      controller: _controller,
      thumbVisibility: true,
      notificationPredicate: (notification) =>
          notification.metrics.axis == Axis.horizontal,
      child: SingleChildScrollView(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        child: widget.child,
      ),
    );
  }
}

class _BreathingWash extends StatefulWidget {
  const _BreathingWash({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  State<_BreathingWash> createState() => _BreathingWashState();
}

class _BreathingWashState extends State<_BreathingWash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_pulse.value);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.08 + (0.10 * t)),
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            border: Border.all(
              color: widget.color.withValues(alpha: 0.35 + (0.35 * t)),
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.12 + (0.22 * t)),
                blurRadius: 10 + (14 * t),
                spreadRadius: 0,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
