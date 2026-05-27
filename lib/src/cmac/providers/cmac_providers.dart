import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cmac_analytics_models.dart';
import '../models/cmac_period.dart';
import '../models/cmac_quality_safety_models.dart';
import '../services/cmac_analytics_service.dart';
import '../services/cmac_quality_safety_service.dart';

final cmacAnalyticsServiceProvider = Provider<CmacAnalyticsService>((ref) {
  return CmacAnalyticsService();
});

final cmacQualitySafetyServiceProvider =
    Provider<CmacQualitySafetyService>((ref) {
  return CmacQualitySafetyService();
});

final cmacAnalyticsQueryProvider =
    StateProvider<CmacAnalyticsQuery>((ref) => const CmacAnalyticsQuery());

final qualitySafetyListQueryProvider =
    StateProvider<QualitySafetyListQuery>((ref) {
  return const QualitySafetyListQuery();
});

Future<T> _fetchAnalytics<T>(
  Ref ref,
  Future<T> Function(CmacAnalyticsService svc, CmacAnalyticsQuery q) load,
) {
  final svc = ref.watch(cmacAnalyticsServiceProvider);
  final query = ref.watch(cmacAnalyticsQueryProvider);
  return load(svc, query);
}

final cmacOverviewProvider =
    FutureProvider.autoDispose<CmacOverviewResponse>((ref) async {
  return _fetchAnalytics(ref, (s, q) => s.fetchOverview(q));
});

final cmacInsightsProvider =
    FutureProvider.autoDispose<CmacInsightsResponse>((ref) async {
  return _fetchAnalytics(ref, (s, q) => s.fetchInsights(q));
});

final cmacPatientActivityProvider =
    FutureProvider.autoDispose<CmacPatientActivityResponse>((ref) async {
  return _fetchAnalytics(ref, (s, q) => s.fetchPatientActivity(q));
});

final cmacClinicalProvider =
    FutureProvider.autoDispose<CmacClinicalResponse>((ref) async {
  return _fetchAnalytics(ref, (s, q) => s.fetchClinical(q));
});

final cmacLaboratoryProvider =
    FutureProvider.autoDispose<CmacLaboratoryResponse>((ref) async {
  return _fetchAnalytics(ref, (s, q) => s.fetchLaboratory(q));
});

final cmacPharmacyProvider =
    FutureProvider.autoDispose<CmacPharmacyResponse>((ref) async {
  return _fetchAnalytics(ref, (s, q) => s.fetchPharmacy(q));
});

final cmacOperationsProvider =
    FutureProvider.autoDispose<CmacOperationsResponse>((ref) async {
  return _fetchAnalytics(ref, (s, q) => s.fetchOperations(q));
});

final cmacQualityProvider =
    FutureProvider.autoDispose<CmacQualityResponse>((ref) async {
  return _fetchAnalytics(ref, (s, q) => s.fetchQuality(q));
});

final cmacStaffProvider =
    FutureProvider.autoDispose<CmacStaffResponse>((ref) async {
  return _fetchAnalytics(ref, (s, q) => s.fetchStaff(q));
});

final qualitySafetyListProvider = FutureProvider.autoDispose
    .family<List<QualitySafetyRecord>, QualitySafetyEntity>((ref, entity) async {
  final svc = ref.watch(cmacQualitySafetyServiceProvider);
  final query = ref.watch(qualitySafetyListQueryProvider);
  return svc.list(entity, query);
});

final qualitySafetyDetailProvider = FutureProvider.autoDispose
    .family<QualitySafetyRecord, ({QualitySafetyEntity entity, String id})>(
  (ref, key) async {
    final svc = ref.watch(cmacQualitySafetyServiceProvider);
    return svc.getById(key.entity, key.id);
  },
);
