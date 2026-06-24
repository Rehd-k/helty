import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/billings/widgets/purchases_consumable_billing_panel.dart';
import 'package:helty/src/core/extensions/number.extention.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/providers/invoices_providers.dart';
import 'package:helty/src/purchases/models/purchases_model.dart';
import 'package:helty/src/store/utils/consumable_invoice_helper.dart';

class InpatientConsumablesScreen extends ConsumerStatefulWidget {
  const InpatientConsumablesScreen({super.key});

  @override
  ConsumerState<InpatientConsumablesScreen> createState() =>
      _InpatientConsumablesScreenState();
}

class _InpatientConsumablesScreenState
    extends ConsumerState<InpatientConsumablesScreen> {
  bool _billing = false;

  void _invalidateBilledList(String patientId, {String? invoiceId}) {
    ref.invalidate(patientBillingInvoicesProvider(patientId));
    if (invoiceId != null && invoiceId.isNotEmpty) {
      ref.invalidate(billingInvoiceProvider(invoiceId));
    }
  }

  List<BillingInvoiceItem> _purchaseItemLines(BillingInvoiceDetail detail) {
    final lines = detail.invoiceItems
        .where((item) => item.isPurchaseItemLine)
        .toList();
    lines.sort((a, b) {
      final ta = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final tb = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return tb.compareTo(ta);
    });
    return lines;
  }

  Widget _emptyBilledList() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'No consumables on this invoice yet.',
        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
      ),
    );
  }

  Widget _billedListTable(List<BillingInvoiceItem> lines) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: ['Item', 'Qty', 'Unit price', 'Total']
            .map(
              (c) => DataColumn(
                label: Text(
                  c,
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            )
            .toList(),
        rows: lines
            .map(
              (item) => DataRow(
                cells: [
                  DataCell(Text(item.displayLabel)),
                  DataCell(Text('${item.quantity}')),
                  DataCell(Text(item.unitPrice.toFinancial(isMoney: true))),
                  DataCell(Text(item.lineTotal.toFinancial(isMoney: true))),
                ],
              ),
            )
            .toList(),
      ),
    );
  }

  String? _invoiceSubtitle(BillingInvoiceDetail detail) {
    final displayId = detail.invoiceDisplayId?.trim();
    if (displayId != null && displayId.isNotEmpty) {
      return 'Invoice $displayId · ${detail.status}';
    }
    return 'Open invoice · ${detail.status}';
  }

  Widget _buildBilledConsumablesSection(String patientId) {
    final invoicesAsync = ref.watch(patientBillingInvoicesProvider(patientId));

    return invoicesAsync.when(
      loading: () => SectionCard(
        title: 'Billed consumables',
        child: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SectionCard(
        title: 'Billed consumables',
        child: Column(
          children: [
            Text(e.toString(), textAlign: TextAlign.center),
            TextButton(
              onPressed: () => _invalidateBilledList(patientId),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (invoices) {
        final open = pickOpenInvoice(invoices);
        if (open == null) {
          return SectionCard(
            title: 'Billed consumables',
            subtitle: 'Open invoice',
            child: _emptyBilledList(),
          );
        }

        final detailAsync = ref.watch(billingInvoiceProvider(open.id));
        return detailAsync.when(
          loading: () => SectionCard(
            title: 'Billed consumables',
            child: const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (e, _) => SectionCard(
            title: 'Billed consumables',
            child: Column(
              children: [
                Text(e.toString(), textAlign: TextAlign.center),
                TextButton(
                  onPressed: () =>
                      _invalidateBilledList(patientId, invoiceId: open.id),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          data: (detail) {
            final lines = _purchaseItemLines(detail);
            return SectionCard(
              title: 'Billed consumables',
              subtitle: _invoiceSubtitle(detail),
              child: lines.isEmpty
                  ? _emptyBilledList()
                  : _billedListTable(lines),
            );
          },
        );
      },
    );
  }

  Future<void> _billConsumable(
    PurchaseItem item,
    String locationId,
    int qty,
    double unitPrice,
  ) async {
    final scope = InpatientViewScope.of(context);
    final patientId = scope?.patientId ?? '';
    if (patientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient context not available yet.')),
      );
      return;
    }
    final itemId = item.id?.trim() ?? '';
    if (itemId.isEmpty) return;

    setState(() => _billing = true);
    try {
      final notifier = ref.read(invoiceNotifierProvider.notifier);
      final invoice = await notifier.getOrCreateBillingInvoice(
        patientId: patientId,
        staffId: scope?.staffId,
        encounterId: scope?.encounterId,
      );
      await notifier.addBillingItem(
        invoiceId: invoice.id,
        payload: AddInvoiceItemPayload(
          purchaseItemId: itemId,
          purchasesLocationId: locationId,
          unitPrice: unitPrice,
          quantity: qty,
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.itemName} x$qty added to invoice')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not add consumable to bill: $e')),
      );
    } finally {
      if (mounted) setState(() => _billing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scope = InpatientViewScope.of(context);
    final admissionId = scope?.admissionId;
    final patientId = scope?.patientId ?? '';

    if (admissionId == null || admissionId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'Open this patient with an admission to bill consumables.',
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (patientId.isNotEmpty) _buildBilledConsumablesSection(patientId),
          if (patientId.isNotEmpty) const SizedBox(height: 16),
          SectionCard(
            title: 'Bill consumables',
            subtitle:
                'Select a purchases store, search items, choose quantity, then add to the patient invoice.',
            child: PurchasesConsumableBillingPanel(
              confirmButtonLabel: 'Add to bill',
              busy: _billing,
              onConfirm: _billConsumable,
            ),
          ),
        ],
      ),
    );
  }
}
