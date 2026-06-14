import 'package:helty/src/models/invoice_billing_models.dart';

enum ChargeCategory {
  daily,
  pharmacy,
  lab,
  radiology,
  surgery,
  supplies,
  other,
}

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

String chargeCategoryLabel(ChargeCategory category) {
  switch (category) {
    case ChargeCategory.daily:
      return 'Daily Charge';
    case ChargeCategory.pharmacy:
      return 'Pharmacy and Medications';
    case ChargeCategory.supplies:
      return 'Supplies & Purchases';
    case ChargeCategory.lab:
    case ChargeCategory.radiology:
      return 'Laboratory and Investigations';
    case ChargeCategory.surgery:
    case ChargeCategory.other:
      return 'Others';
  }
}

ChargeCategory chargeCategoryForBillingItem(BillingInvoiceItem item) {
  if (item.isRecurringDaily) return ChargeCategory.daily;
  if (item.isDrugLine) return ChargeCategory.pharmacy;
  if (item.isPurchaseItemLine) return ChargeCategory.supplies;
  if (item.isConsumableLine) return ChargeCategory.pharmacy;
  final name = (item.serviceCategoryName ?? '').trim().toLowerCase();
  if (name == 'laboratory tests' ||
      name == 'laboratory' ||
      name == 'radiology & imaging') {
    return ChargeCategory.lab;
  }
  return ChargeCategory.other;
}

List<ChargeItem> chargesFromBillingDetail(BillingInvoiceDetail? inv) {
  if (inv == null) return [];
  final created = inv.createdAt ?? DateTime.now();

  return [
    for (final item in inv.invoiceItems)
      ChargeItem(
        id: '${inv.id}-${item.id}',
        invoiceLineItemId: item.id,
        description: item.displayLabel,
        amount: item.unitPrice,
        quantity: item.quantity,
        date: created,
        category: chargeCategoryForBillingItem(item),
        lineTotal: item.lineTotal,
        amountPaid: item.lineItemAmountPaid,
        lineAmountDue: item.lineAmountDue,
      ),
  ];
}
