String walletReferenceLabel(String? reference) {
  final ref = (reference ?? '').trim();
  if (ref.isEmpty) return '—';
  if (ref == 'deposit') return 'Wallet deposit';
  if (ref == 'invoice_payment' || ref == 'invoice_payment_allocation') {
    return 'Invoice payment';
  }
  if (ref.startsWith('refund_item_')) return 'Item refund to wallet';
  return ref;
}

String walletTransactionTypeLabel(String type) {
  switch (type.toUpperCase()) {
    case 'CREDIT':
      return 'Deposit / Credit';
    case 'DEBIT':
      return 'Payment';
    default:
      return type;
  }
}
