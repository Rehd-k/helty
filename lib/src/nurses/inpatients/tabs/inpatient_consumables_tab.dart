import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/billings/widgets/purchases_consumable_billing_panel.dart';
import 'package:helty/src/models/invoice_billing_models.dart';
import 'package:helty/src/nurses/inpatients/widgets/inpatient_view_scope.dart';
import 'package:helty/src/nurses/inpatients/widgets/section_card.dart';
import 'package:helty/src/providers/invoices_providers.dart';
import 'package:helty/src/purchases/models/purchases_model.dart';

class InpatientConsumablesScreen extends ConsumerStatefulWidget {
  const InpatientConsumablesScreen({super.key});

  @override
  ConsumerState<InpatientConsumablesScreen> createState() =>
      _InpatientConsumablesScreenState();
}

class _InpatientConsumablesScreenState
    extends ConsumerState<InpatientConsumablesScreen> {
  bool _billing = false;

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
        SnackBar(
          content: Text(
            '${item.itemName} x$qty added to invoice',
          ),
        ),
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
      child: SectionCard(
        title: 'Bill consumables',
        subtitle:
            'Select a purchases store, search items, choose quantity, then add to the patient invoice.',
        child: PurchasesConsumableBillingPanel(
          confirmButtonLabel: 'Add to bill',
          busy: _billing,
          onConfirm: _billConsumable,
        ),
      ),
    );
  }
}
