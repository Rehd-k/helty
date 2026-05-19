import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/patient_chart_models.dart';
import '../services/patient_chart_service.dart';

final patientChartServiceProvider = Provider<PatientChartService>(
  (ref) => PatientChartService(),
);

/// Chart header (no include) for a patient UUID.
final patientChartHeaderProvider =
    FutureProvider.family<PatientChartResponse, String>((ref, patientUuid) {
  return ref.watch(patientChartServiceProvider).getChart(patientUuid);
});

/// Lazy section load: patient UUID + comma-joined include keys + skip for pagination.
class ChartSectionRequest {
  const ChartSectionRequest({
    required this.patientUuid,
    required this.includeKey,
    this.skip = 0,
    this.limit = 20,
  });

  final String patientUuid;
  final String includeKey;
  final int skip;
  final int limit;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSectionRequest &&
          patientUuid == other.patientUuid &&
          includeKey == other.includeKey &&
          skip == other.skip &&
          limit == other.limit;

  @override
  int get hashCode => Object.hash(patientUuid, includeKey, skip, limit);
}

final patientChartSectionProvider = FutureProvider.family<
    PatientChartResponse,
    ChartSectionRequest>((ref, request) {
  return ref.watch(patientChartServiceProvider).getChart(
        request.patientUuid,
        include: request.includeKey.split(','),
        limit: request.limit,
        skip: request.skip,
      );
});
