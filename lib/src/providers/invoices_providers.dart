// lib/src/providers/invoices_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/invoice.dart';
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
    page: filter.page,
    limit: filter.limit,
  );
});

// Simple filter class so we can pass parameters cleanly
class InvoiceFilter {
  final String? patientId;
  final String? status;
  final int page;
  final int limit;

  const InvoiceFilter({
    this.patientId,
    this.status,
    this.page = 1,
    this.limit = 20,
  });

  // Optional: override == and hashCode if you want caching to work better
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceFilter &&
          runtimeType == other.runtimeType &&
          patientId == other.patientId &&
          status == other.status &&
          page == other.page &&
          limit == other.limit;

  @override
  int get hashCode =>
      patientId.hashCode ^ status.hashCode ^ page.hashCode ^ limit.hashCode;
}

// ────────────────────────────────────────────────
// Single invoice by ID
// ────────────────────────────────────────────────
final invoiceProvider = FutureProvider.family<Invoice, String>((ref, id) async {
  final service = ref.watch(invoiceServiceProvider);
  return service.getInvoice(id);
});

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
}

// Provider for the notifier
final invoiceNotifierProvider =
    StateNotifierProvider<InvoiceNotifier, AsyncValue<Invoice?>>(
      (ref) => InvoiceNotifier(ref),
    );
