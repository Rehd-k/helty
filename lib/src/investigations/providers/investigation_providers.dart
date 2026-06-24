import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../lab/providers/lab_providers.dart';
import '../../providers/service_providers.dart';
import '../models/investigation_models.dart';
import '../models/investigation_query_params.dart';

final labInvestigationsSummaryProvider = FutureProvider.autoDispose
    .family<InvestigationSummary, InvestigationsQueryParams>((ref, params) {
  return ref.watch(labApiServiceProvider).getInvestigationsSummary(params);
});

final labInvestigationsListProvider = FutureProvider.autoDispose
    .family<InvestigationListResponse, InvestigationsQueryParams>((ref, params) {
  return ref.watch(labApiServiceProvider).getInvestigations(params);
});

final radiologyInvestigationsSummaryProvider = FutureProvider.autoDispose
    .family<InvestigationSummary, InvestigationsQueryParams>((ref, params) {
  return ref.watch(radiologyServiceProvider).getInvestigationsSummary(params);
});

final radiologyInvestigationsListProvider = FutureProvider.autoDispose
    .family<InvestigationListResponse, InvestigationsQueryParams>((ref, params) {
  return ref.watch(radiologyServiceProvider).getInvestigations(params);
});

void invalidateInvestigationCaches(
  WidgetRef ref, {
  InvestigationsQueryParams? labParams,
  InvestigationsQueryParams? radParams,
}) {
  if (labParams != null) {
    ref.invalidate(labInvestigationsSummaryProvider(labParams));
    ref.invalidate(labInvestigationsListProvider(labParams));
  }
  if (radParams != null) {
    ref.invalidate(radiologyInvestigationsSummaryProvider(radParams));
    ref.invalidate(radiologyInvestigationsListProvider(radParams));
  }
}
