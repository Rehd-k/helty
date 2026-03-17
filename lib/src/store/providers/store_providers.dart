import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/store_models.dart';
import '../services/store_api_service.dart';

final storeApiServiceProvider = Provider<StoreApiService>((ref) {
  return StoreApiService();
});

final storeCategoriesFutureProvider =
    FutureProvider<StoreCategoriesResponse>((ref) {
  return ref.watch(storeApiServiceProvider).getCategories();
});

final storeLocationsFutureProvider =
    FutureProvider<StoreLocationsResponse>((ref) {
  return ref.watch(storeApiServiceProvider).getLocations();
});

/// Parameters for store items list (category filter, active filter, pagination).
/// Implements equality so Riverpod's family provider reuses the same request
/// when params are unchanged (avoids duplicate API calls on rebuild).
class StoreItemsParams {
  const StoreItemsParams({
    this.categoryId,
    this.isActive,
    this.limit = 20,
    this.skip = 0,
  });
  final String? categoryId;
  final bool? isActive;
  final int limit;
  final int skip;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StoreItemsParams &&
          runtimeType == other.runtimeType &&
          categoryId == other.categoryId &&
          isActive == other.isActive &&
          limit == other.limit &&
          skip == other.skip;

  @override
  int get hashCode => Object.hash(categoryId, isActive, limit, skip);
}

final storeItemsFutureProvider =
    FutureProvider.family<StoreItemsResponse, StoreItemsParams>((ref, params) {
  return ref.watch(storeApiServiceProvider).getItems(
        categoryId: params.categoryId,
        isActive: params.isActive,
        limit: params.limit,
        skip: params.skip,
      );
});
