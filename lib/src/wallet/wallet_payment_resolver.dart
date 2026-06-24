import '../models/invoice_billing_models.dart';
import '../services/invoice_service.dart';

class WalletPaymentResolver {
  WalletPaymentResolver(this._invoiceService);

  final InvoiceService _invoiceService;

  Future<String?> resolvePaymentId(BillingWalletTransaction transaction) async {
    final invoiceId =
        transaction.invoiceId ?? transaction.invoice?.id;
    if (invoiceId == null || invoiceId.trim().isEmpty) return null;
    final payments = await _invoiceService.getInvoicePayments(invoiceId);
    for (final payment in payments) {
      if (payment.walletTransactionId == transaction.id) {
        return payment.id;
      }
    }
    return null;
  }
}
