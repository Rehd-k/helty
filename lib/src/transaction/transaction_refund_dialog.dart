import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/auth/billing_permissions.dart';
import 'package:helty/src/billings/widgets/invoice_item_refund_dialogs.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/models/staff_model.dart';
import 'package:helty/src/providers/auth_provider.dart';
import 'package:helty/src/services/invoice_service.dart';

/// Item-refund flow from the transactions ledger: loads the linked invoice,
/// lists lines for selection (when more than one), then submits a refund request.
Future<bool> showTransactionRefundDialog({
  required BuildContext context,
  required Map<String, dynamic> transaction,
}) async {
  final invoiceId = (transaction['invoiceId'] as String?)?.trim() ?? '';
  if (invoiceId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'This transaction is not linked to an invoice. Open the patient bill to request a line refund.',
        ),
      ),
    );
    return false;
  }

  final result = await showDialog<bool>(
    context: context,
    builder: (_) => TransactionRefundDialog(
      transaction: transaction,
      invoiceId: invoiceId,
    ),
  );
  return result == true;
}

class TransactionRefundDialog extends ConsumerStatefulWidget {
  const TransactionRefundDialog({
    super.key,
    required this.transaction,
    required this.invoiceId,
  });

  final Map<String, dynamic> transaction;
  final String invoiceId;

  @override
  ConsumerState<TransactionRefundDialog> createState() =>
      _TransactionRefundDialogState();
}

class _TransactionRefundDialogState
    extends ConsumerState<TransactionRefundDialog> {
  final InvoiceService _invoiceService = InvoiceService();

  bool _loading = true;
  String? _error;
  BillingInvoiceDetail? _invoice;
  String? _selectedItemId;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final detail = await _invoiceService.getBillingInvoice(widget.invoiceId);
      if (!mounted) return;
      final items = _visibleItems(detail);
      String? initial;
      final eligible = items.where(invoiceLineEligibleForRefundRequest).toList();
      if (eligible.length == 1) {
        initial = eligible.first.id;
      } else if (items.length == 1) {
        initial = items.first.id;
      }
      setState(() {
        _invoice = detail;
        _selectedItemId = initial;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// Prefer lines tied to this payment's services; fall back to all invoice lines.
  List<BillingInvoiceItem> _visibleItems(BillingInvoiceDetail detail) {
    final services = widget.transaction['services'];
    if (services is! List || services.isEmpty) {
      return detail.invoiceItems;
    }

    final serviceNames = services
        .whereType<Map>()
        .map((s) => (s['name'] as String? ?? '').trim().toLowerCase())
        .where((n) => n.isNotEmpty)
        .toSet();

    if (serviceNames.isEmpty) return detail.invoiceItems;

    final matched = detail.invoiceItems.where((line) {
      final label = line.displayLabel.trim().toLowerCase();
      return serviceNames.any(
        (name) => label.contains(name) || name.contains(label),
      );
    }).toList();

    return matched.isNotEmpty ? matched : detail.invoiceItems;
  }

  BillingInvoiceItem? get _selectedItem {
    final id = _selectedItemId;
    if (id == null || _invoice == null) return null;
    for (final line in _invoice!.invoiceItems) {
      if (line.id == id) return line;
    }
    return null;
  }

  Future<void> _submitRefund(BillingInvoiceItem line) async {
    final reason = await showInvoiceItemRefundReasonDialog(context);
    if (reason == null || !mounted) return;

    setState(() => _submitting = true);
    try {
      await _invoiceService.submitItemRefundRequest(
        invoiceId: widget.invoiceId,
        itemId: line.id,
        reason: reason,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on InvoiceRefundRequestException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        await _loadInvoice();
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cancelRefund(BillingInvoiceItem line) async {
    final requestId = line.activeRefundRequest?.id;
    if (requestId == null) return;
    final confirmed = await showCancelInvoiceItemRefundDialog(context);
    if (!confirmed || !mounted) return;

    setState(() => _submitting = true);
    try {
      await _invoiceService.cancelItemRefundRequest(
        invoiceId: widget.invoiceId,
        itemId: line.id,
        requestId: requestId,
      );
      if (!mounted) return;
      await _loadInvoice();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund request cancelled.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _onPrimaryAction() async {
    final line = _selectedItem;
    if (line == null) return;
    final staff = ref.read(authProvider).staff;

    if (line.refundPending &&
        canCancelInvoiceItemRefundRequest(staff, line.activeRefundRequest)) {
      await _cancelRefund(line);
      return;
    }

    if (!invoiceLineEligibleForRefundRequest(line)) {
      final msg = invoiceItemRefundTooltip(line);
      if (msg != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
      return;
    }

    await _submitRefund(line);
  }

  @override
  Widget build(BuildContext context) {
    final tranId = widget.transaction['tranId']?.toString() ?? '';
    final patientName = widget.transaction['patientName']?.toString() ?? '';
    final theme = Theme.of(context);
    final staff = ref.watch(authProvider).staff;

    return AlertDialog(
      title: const Text('Make a refund'),
      content: SizedBox(
        width: 520,
        child: _loading
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
            ? Text(_error!)
            : _buildItemList(theme, staff, tranId, patientName),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (!_loading && _error == null && _invoice != null)
          FilledButton(
            onPressed: _submitting || _selectedItem == null ? null : _onPrimaryAction,
            child: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_primaryActionLabel(staff)),
          ),
      ],
    );
  }

  String _primaryActionLabel(Staff? staff) {
    final line = _selectedItem;
    if (line != null &&
        line.refundPending &&
        canCancelInvoiceItemRefundRequest(staff, line.activeRefundRequest)) {
      return 'Cancel request';
    }
    return 'Request refund';
  }

  Widget _buildItemList(
    ThemeData theme,
    Staff? staff,
    String tranId,
    String patientName,
  ) {
    final invoice = _invoice!;
    final items = _visibleItems(invoice);
    if (items.isEmpty) {
      return const Text('No billable lines found on this invoice.');
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Transaction $tranId • $patientName',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (invoice.invoiceDisplayId != null) ...[
          const SizedBox(height: 4),
          Text(
            'Invoice ${invoice.invoiceDisplayId}',
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        Text(
          items.length == 1
              ? 'Confirm the line to refund:'
              : 'Select the invoice line to refund:',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final line = items[index];
              final eligible = invoiceLineEligibleForRefundRequest(line);
              final canCancel = line.refundPending &&
                  canCancelInvoiceItemRefundRequest(
                    staff,
                    line.activeRefundRequest,
                  );
              final selectable = eligible || canCancel;
              final tooltip = invoiceItemRefundTooltip(line);
              final subtitle = [
                'Total ${line.lineTotal.toFinancial(isMoney: true)}'
                    ' • Paid ${line.lineItemAmountPaid.toFinancial(isMoney: true)}',
                if (line.refundPending) 'Pending accountant approval',
                if (!line.refundable && tooltip != null) tooltip,
              ].join('\n');

              return RadioListTile<String>(
                value: line.id,
                groupValue: _selectedItemId,
                onChanged: selectable
                    ? (v) => setState(() => _selectedItemId = v)
                    : null,
                title: Text(line.displayLabel),
                subtitle: Text(subtitle),
                secondary: line.refundPending
                    ? Icon(Icons.hourglass_top, color: theme.colorScheme.error)
                    : null,
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Refund requests require account head approval before the line is removed and any payment is reversed.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
