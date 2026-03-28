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
// List of invoices (with optional filters)
// ────────────────────────────────────────────────
final invoicesProvider = FutureProvider.family<List<Invoice>, InvoiceFilter>((
  ref,
  filter,
) async {
  final service = ref.watch(invoiceServiceProvider);
  return service.getInvoices(
    patientId: filter.patientId,
    status: filter.status,
    query: filter.query,
    category: filter.category,
    from: filter.from,
    to: filter.to,
    page: filter.page,
    limit: filter.limit,
  );
});

// Simple filter class so we can pass parameters cleanly
class InvoiceFilter {
  final String? patientId;
  final String? status;
  final String? query;
  final String? category;
  final DateTime? from;
  final DateTime? to;
  final int page;
  final int limit;

  const InvoiceFilter({
    this.patientId,
    this.status,
    this.query,
    this.category,
    this.from,
    this.to,
    this.page = 1,
    this.limit = 100,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceFilter &&
          runtimeType == other.runtimeType &&
          patientId == other.patientId &&
          status == other.status &&
          query == other.query &&
          category == other.category &&
          from == other.from &&
          to == other.to &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(
        patientId,
        status,
        query,
        category,
        from,
        to,
        page,
        limit,
      );
}

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

      // Invalidate lists and single if needed
      ref.invalidate(invoicesProvider);
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

      // Refresh related providers
      ref.invalidate(invoiceProvider(id));
      ref.invalidate(invoicesProvider);
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
    if (existing.isNotEmpty) {
      final latest = existing.first;
      final detail = await service.getBillingInvoice(latest.id);
      ref.invalidate(billingInvoiceProvider(latest.id));
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
    ref.invalidate(invoicesProvider);
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
