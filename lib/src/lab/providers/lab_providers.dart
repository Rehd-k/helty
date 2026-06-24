import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/lab_models.dart';
import '../services/lab_api_service.dart';
import '../utils/lab_reference_evaluation.dart';

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

/// Cached future for orders list; auto-dispose refetches when the dashboard is reopened.
final labOrdersFutureProvider = FutureProvider.autoDispose
    .family<LabOrdersResponse, LabOrdersParams>((ref, params) {
      return ref
          .watch(labApiServiceProvider)
          .getOrders(
            fromDate: params.from,
            toDate: params.to,
            skip: params.skip,
            take: params.take,
          );
    });

/// Cached future for a single order by id.
final labOrderByIdProvider = FutureProvider.family<LabOrder, String>((
  ref,
  orderId,
) async {
  final api = ref.watch(labApiServiceProvider);
  final order = await api.getOrderById(orderId);
  return enrichLabOrderWithResultEvaluations(order, api);
});

/// Merges [GET /lab/results] evaluations onto nested order results.
Future<LabOrder> enrichLabOrderWithResultEvaluations(
  LabOrder order,
  LabApiService api,
) async {
  final enrichedItems = await Future.wait(
    order.items.map((item) async {
      if (item.results.isEmpty) return item;

      final freshResults = await api.getResults(item.id);
      final evalByFieldId = {
        for (final r in freshResults) r.fieldId: r.referenceEvaluation,
      };
      final fields = item.fields ?? item.testVersion?.fields ?? [];
      final fieldMap = {for (final f in fields) f.id: f};

      final mergedResults = item.results.map((r) {
        final serverEval =
            r.referenceEvaluation ?? evalByFieldId[r.fieldId];
        final refRange =
            r.field?.referenceRange ?? fieldMap[r.fieldId]?.referenceRange;
        final resolved = resolveLabReferenceEvaluation(
          value: r.value,
          referenceRange: refRange,
          serverEvaluation: serverEval,
        );
        if (resolved == r.referenceEvaluation) return r;
        return r.copyWith(referenceEvaluation: resolved);
      }).toList();

      return item.copyWith(results: mergedResults);
    }),
  );

  return order.copyWith(items: enrichedItems);
}

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
final labCategoriesFutureProvider = FutureProvider<LabCategoriesResponse>((
  ref,
) {
  return ref.watch(labApiServiceProvider).getCategories(take: 200);
});

/// Cached future for tests so FutureBuilder is not given a new future each build.
final labTestsFutureProvider = FutureProvider<LabTestsResponse>((ref) {
  return ref.watch(labApiServiceProvider).getTests(take: 200);
});

/// Cached future for antibiotics catalog (admin config).
final labAntibioticsFutureProvider = FutureProvider<LabAntibioticsResponse>((
  ref,
) {
  return ref.watch(labApiServiceProvider).getAntibiotics(take: 200);
});

/// Cached future for AST result options (admin config).
final labAstResultOptionsFutureProvider =
    FutureProvider<LabAstResultOptionsResponse>((ref) {
      return ref.watch(labApiServiceProvider).getAstResultOptions(take: 200);
    });
