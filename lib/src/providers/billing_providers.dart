import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/billing_service.dart';

// ── Billing Providers ────────────────────────────────────────────────────────

final billingServiceProvider = Provider<BillingService>(
  (ref) => BillingService(),
);

final billListProvider =
    FutureProvider.family<List<Bill>, ({String? patientId, String? status})>((
      ref,
      params,
    ) async {
      final service = ref.read(billingServiceProvider);
      return service.fetchBills(
        patientId: params.patientId,
        status: params.status,
      );
    });

final patientBillsProvider = FutureProvider.family<List<Bill>, String>((
  ref,
  patientId,
) async {
  final service = ref.read(billingServiceProvider);
  return service.getBillsForPatient(patientId);
});

final billDetailProvider = FutureProvider.family<Bill, String>((
  ref,
  billId,
) async {
  final service = ref.read(billingServiceProvider);
  return service.getBillById(billId);
});
