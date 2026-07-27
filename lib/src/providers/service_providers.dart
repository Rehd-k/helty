import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../clinical_packages/services/clinical_package_service.dart';
import '../models/service_model.dart';
import '../obstetrics/services/obstetrics_service.dart';
import '../radiology/services/radiology_service.dart';
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

final obstetricsServiceProvider = Provider<ObstetricsService>((ref) {
  return ObstetricsService();
});

final clinicalPackageServiceProvider = Provider<ClinicalPackageService>((ref) {
  return ClinicalPackageService();
});

final radiologyServiceProvider = Provider<RadiologyService>((ref) {
  return RadiologyService();
});
