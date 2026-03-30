// lib/src/providers/invoices_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/invoice.dart';
import '../models/invoice_billing_models.dart';
import '../services/invoice_service.dart';

// ────────────────────────────────────────────────
// Main service / repository provider
// ────────────────────────────────────────────────
final invoiceServiceProvider = Provider<InvoiceService>((ref) {
  return InvoiceService();
});

// ────────────────────────────────────────────────
// Single invoice by ID
// ────────────────────────────────────────────────
final invoiceProvider = FutureProvider.family<Invoice, String>((ref, id) async {
  final service = ref.watch(invoiceServiceProvider);
  return service.getInvoice(id);
});

final billingInvoiceProvider =
    FutureProvider.family<BillingInvoiceDetail, String>((ref, invoiceId) async {
  final service = ref.watch(invoiceServiceProvider);
  return service.getBillingInvoice(invoiceId);
});

final patientBillingInvoicesProvider =
    FutureProvider.family<List<Invoice>, String>((ref, patientId) async {
  final service = ref.watch(invoiceServiceProvider);
  return service.getPatientInvoices(patientId);
});

final patientWalletProvider =
    FutureProvider.family<BillingWallet, String>((ref, patientId) async {
  final service = ref.watch(invoiceServiceProvider);
  return service.getWallet(patientId);
});

final walletTransactionsProvider =
    FutureProvider.family<List<BillingWalletTransaction>, String>(
  (ref, patientId) async {
    final service = ref.watch(invoiceServiceProvider);
    return service.getWalletTransactions(patientId);
  },
);

// ────────────────────────────────────────────────
// Notifier for creating / updating invoices
// ────────────────────────────────────────────────
class InvoiceNotifier extends StateNotifier<AsyncValue<Invoice?>> {
  final Ref ref;

  InvoiceNotifier(this.ref) : super(const AsyncData(null));

  Future<Invoice> create({
    required String patientId,
    required String status,
    required List<Map<String, dynamic>> items,
    String? staffId,
  }) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(invoiceServiceProvider);
      final newInvoice = await service.createInvoice(
        patientId: patientId,
        status: status,
        items: items,
        staffId: staffId,
      );

      state = AsyncData(newInvoice);

      ref.invalidate(invoiceProvider(newInvoice.id));

      return newInvoice;
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> updateStatus({
    required String id,
    required String newStatus,
  }) async {
    state = const AsyncLoading();

    try {
      final service = ref.read(invoiceServiceProvider);
      final updated = await service.updateInvoiceStatus(
        id: id,
        status: newStatus,
      );

      state = AsyncData(updated);

      ref.invalidate(invoiceProvider(id));
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  // You can add more methods: addItem, deleteItem, etc.

  Future<BillingInvoiceDetail> getOrCreateBillingInvoice({
    required String patientId,
    String? staffId,
    String? encounterId,
  }) async {
    final service = ref.read(invoiceServiceProvider);
    final existing = await service.getPatientInvoices(patientId);
    final open = _pickOpenBillingInvoice(existing);
    if (open != null) {
      final detail = await service.getBillingInvoice(open.id);
      ref.invalidate(billingInvoiceProvider(open.id));
      return detail;
    }
    final created = await service.createBillingInvoice(
      patientId: patientId,
      staffId: staffId,
      encounterId: encounterId,
    );
    ref.invalidate(patientBillingInvoicesProvider(patientId));
    ref.invalidate(billingInvoiceProvider(created.id));
    return created;
  }

  Future<BillingInvoiceDetail> addBillingItem({
    required String invoiceId,
    required AddInvoiceItemPayload payload,
  }) async {
    final service = ref.read(invoiceServiceProvider);
    final updated = await service.addBillingItem(
      invoiceId: invoiceId,
      payload: payload,
    );
    _invalidateInvoiceState(updated);
    return updated;
  }

  Future<BillingInvoiceDetail> pauseRecurringItem({
    required String invoiceId,
    required String itemId,
  }) async {
    final service = ref.read(invoiceServiceProvider);
    final updated = await service.pauseRecurringItem(
      invoiceId: invoiceId,
      itemId: itemId,
    );
    _invalidateInvoiceState(updated);
    return updated;
  }

  Future<BillingInvoiceDetail> resumeRecurringItem({
    required String invoiceId,
    required String itemId,
  }) async {
    final service = ref.read(invoiceServiceProvider);
    final updated = await service.resumeRecurringItem(
      invoiceId: invoiceId,
      itemId: itemId,
    );
    _invalidateInvoiceState(updated);
    return updated;
  }

  Future<BillingInvoiceDetail> recordPayment({
    required String invoiceId,
    required RecordPaymentPayload payload,
  }) async {
    final service = ref.read(invoiceServiceProvider);
    final updated = await service.recordInvoicePayment(
      invoiceId: invoiceId,
      payload: payload,
    );
    _invalidateInvoiceState(updated, includeWallet: true);
    return updated;
  }

  Future<BillingWallet> depositWallet({
    required String patientId,
    required WalletDepositPayload payload,
  }) async {
    final service = ref.read(invoiceServiceProvider);
    final wallet = await service.depositToWallet(
      patientId: patientId,
      payload: payload,
    );
    ref.invalidate(patientWalletProvider(patientId));
    ref.invalidate(walletTransactionsProvider(patientId));
    return wallet;
  }

  void _invalidateInvoiceState(
    BillingInvoiceDetail invoice, {
    bool includeWallet = false,
  }) {
    ref.invalidate(billingInvoiceProvider(invoice.id));
    ref.invalidate(patientBillingInvoicesProvider(invoice.patientId));
    ref.invalidate(invoiceProvider(invoice.id));
    if (includeWallet) {
      ref.invalidate(patientWalletProvider(invoice.patientId));
      ref.invalidate(walletTransactionsProvider(invoice.patientId));
    }
  }
}

// Provider for the notifier
final invoiceNotifierProvider =
    StateNotifierProvider<InvoiceNotifier, AsyncValue<Invoice?>>(
      (ref) => InvoiceNotifier(ref),
    );

/// Prefer a non-terminal invoice for attaching new lines; [null] if none.
Invoice? _pickOpenBillingInvoice(List<Invoice> list) {
  if (list.isEmpty) return null;
  bool isOpen(Invoice i) {
    final s = i.status.toUpperCase();
    return s != 'PAID' &&
        s != 'FULLY_PAID' &&
        s != 'CANCELLED' &&
        s != 'VOID';
  }

  final open = list.where(isOpen).toList();
  if (open.isEmpty) return null;
  open.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return open.first;
}
