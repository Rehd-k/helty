import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_category_model.dart';
import '../services/service_category_service.dart';

final serviceCategoryServiceProvider = Provider<ServiceCategoryService>(
  (ref) => ServiceCategoryService(),
);

final serviceCategoryListProvider =
    FutureProvider.family<List<ServiceCategory>, String?>((ref, query) async {
      final service = ref.read(serviceCategoryServiceProvider);
      return service.fetchCategories(query: query);
    });

final serviceCategoryDetailProvider =
    FutureProvider.family<ServiceCategory, String>((ref, id) async {
      final service = ref.read(serviceCategoryServiceProvider);
      return service.getCategoryById(id);
    });
