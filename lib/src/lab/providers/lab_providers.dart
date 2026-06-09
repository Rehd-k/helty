import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lab_models.dart';
import '../services/lab_api_service.dart';

final labApiServiceProvider = Provider<LabApiService>((ref) {
  return LabApiService();
});

/// Parameters for lab orders list (date range + pagination).
/// Implements equality so Riverpod's family provider reuses the same request
/// when params are unchanged (avoids duplicate API calls on rebuild).
/// Status filtering is applied client-side.
class LabOrdersParams {
  const LabOrdersParams({
    required this.from,
    required this.to,
    this.skip = 0,
    this.take = 100,
  });

  final DateTime from;
  final DateTime to;
  final int skip;
  final int take;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LabOrdersParams &&
          runtimeType == other.runtimeType &&
          from == other.from &&
          to == other.to &&
          skip == other.skip &&
          take == other.take;

  @override
  int get hashCode => Object.hash(from, to, skip, take);
}

/// Cached future for orders list so FutureBuilder is not given a new future each build.
final labOrdersFutureProvider =
    FutureProvider.family<LabOrdersResponse, LabOrdersParams>((ref, params) {
  return ref.watch(labApiServiceProvider).getOrders(
        fromDate: params.from,
        toDate: params.to,
        skip: params.skip,
        take: params.take,
      );
});

/// Cached future for a single order by id.
final labOrderByIdProvider =
    FutureProvider.family<LabOrder, String>((ref, orderId) {
  return ref.watch(labApiServiceProvider).getOrderById(orderId);
});

/// Invalidates cached lab order data after mutations.
void invalidateLabOrderCaches(
  WidgetRef ref, {
  String? orderId,
  LabOrdersParams? listParams,
}) {
  if (orderId != null) ref.invalidate(labOrderByIdProvider(orderId));
  if (listParams != null) ref.invalidate(labOrdersFutureProvider(listParams));
}

/// Cached future for categories so FutureBuilder is not given a new future each build.
final labCategoriesFutureProvider = FutureProvider<LabCategoriesResponse>((ref) {
  return ref.watch(labApiServiceProvider).getCategories(take: 200);
});

/// Cached future for tests so FutureBuilder is not given a new future each build.
final labTestsFutureProvider = FutureProvider<LabTestsResponse>((ref) {
  return ref.watch(labApiServiceProvider).getTests(take: 200);
});

/// Cached future for antibiotics catalog (admin config).
final labAntibioticsFutureProvider =
    FutureProvider<LabAntibioticsResponse>((ref) {
  return ref.watch(labApiServiceProvider).getAntibiotics(take: 200);
});

/// Cached future for AST result options (admin config).
final labAstResultOptionsFutureProvider =
    FutureProvider<LabAstResultOptionsResponse>((ref) {
  return ref.watch(labApiServiceProvider).getAstResultOptions(take: 200);
});
