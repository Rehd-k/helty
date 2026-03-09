import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/lab_api_service.dart';

final labApiServiceProvider = Provider<LabApiService>((ref) {
  return LabApiService();
});

/// Cached future for categories so FutureBuilder is not given a new future each build.
final labCategoriesFutureProvider = FutureProvider<LabCategoriesResponse>((ref) {
  return ref.watch(labApiServiceProvider).getCategories(take: 200);
});

/// Cached future for tests so FutureBuilder is not given a new future each build.
final labTestsFutureProvider = FutureProvider<LabTestsResponse>((ref) {
  return ref.watch(labApiServiceProvider).getTests(take: 200);
});
