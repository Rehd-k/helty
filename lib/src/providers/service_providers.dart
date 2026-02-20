import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/service_model.dart';
import '../services/service_service.dart';

final serviceServiceProvider = Provider<ServiceService>((ref) {
  return ServiceService();
});

final serviceListProvider = FutureProvider.family<List<ServiceModel>, String?>((
  ref,
  query,
) async {
  final service = ref.read(serviceServiceProvider);
  return service.fetchServices(query: query);
});

final serviceDetailProvider = FutureProvider.family<ServiceModel, String>((
  ref,
  id,
) async {
  final service = ref.read(serviceServiceProvider);
  return service.getServiceById(id);
});
