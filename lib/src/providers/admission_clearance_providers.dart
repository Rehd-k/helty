import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:helty/src/models/admission_billing_clearance_models.dart';
import 'package:helty/src/services/admission_service.dart';

final admissionServiceProvider = Provider<AdmissionService>((ref) {
  return AdmissionService();
});

typedef PendingClearanceQuery = ({int skip, int take});

final pendingBillingClearanceProvider =
    FutureProvider.family<PendingBillingClearancePage, PendingClearanceQuery>((
      ref,
      query,
    ) async {
      final service = ref.watch(admissionServiceProvider);
      return service.listPendingBillingClearance(
        skip: query.skip,
        take: query.take,
      );
    });

final pendingNursesClearanceProvider =
    FutureProvider.family<PendingNursesClearancePage, PendingClearanceQuery>((
      ref,
      query,
    ) async {
      final service = ref.watch(admissionServiceProvider);
      return service.listPendingNursesClearance(
        skip: query.skip,
        take: query.take,
      );
    });
