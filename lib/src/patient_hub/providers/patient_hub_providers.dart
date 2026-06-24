import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../dialysis/models/dialysis_models.dart';
import '../../paitients/patient_model.dart';
import '../../patient_chart/models/patient_chart_models.dart';
import '../../theatre/models/theatre_models.dart';
import '../models/patient_hub_models.dart';
import '../services/patient_hub_service.dart';

final patientHubServiceProvider = Provider<PatientHubService>(
  (ref) => PatientHubService(),
);

/// Shared date range for historical hub tabs.
final patientHubDateRangeProvider =
    StateProvider<PatientHubDateRange>((ref) => const PatientHubDateRange());

final patientHubHeaderProvider =
    FutureProvider.family<PatientChartResponse, String>((ref, patientUuid) {
  return ref.watch(patientHubServiceProvider).getChartHeader(patientUuid);
});

final patientHubProfileProvider =
    FutureProvider.family<Patient, String>((ref, patientUuid) {
  return ref.watch(patientHubServiceProvider).getFullProfile(patientUuid);
});

class HubSectionRequest {
  const HubSectionRequest({
    required this.patientUuid,
    required this.includeKeys,
    this.skip = 0,
    this.limit = 50,
    this.fromDate,
    this.toDate,
  });

  final String patientUuid;
  final List<String> includeKeys;
  final int skip;
  final int limit;
  final DateTime? fromDate;
  final DateTime? toDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HubSectionRequest &&
          patientUuid == other.patientUuid &&
          _listEq(includeKeys, other.includeKeys) &&
          skip == other.skip &&
          limit == other.limit &&
          fromDate == other.fromDate &&
          toDate == other.toDate;

  @override
  int get hashCode => Object.hash(
        patientUuid,
        Object.hashAll(includeKeys),
        skip,
        limit,
        fromDate,
        toDate,
      );
}

bool _listEq(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

final patientHubSectionProvider = FutureProvider.family<
    PatientChartResponse,
    HubSectionRequest>((ref, request) {
  final limit = request.limit > patientHubMaxTake
      ? patientHubMaxTake
      : request.limit;
  return ref.watch(patientHubServiceProvider).getClinicalSection(
        request.patientUuid,
        include: request.includeKeys,
        limit: limit,
        skip: request.skip,
        fromDate: request.fromDate,
        toDate: request.toDate,
      );
});

class HubModuleHistoryRequest {
  const HubModuleHistoryRequest({
    required this.patientUuid,
    this.fromDate,
    this.toDate,
  });

  final String patientUuid;
  final DateTime? fromDate;
  final DateTime? toDate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HubModuleHistoryRequest &&
          patientUuid == other.patientUuid &&
          fromDate == other.fromDate &&
          toDate == other.toDate;

  @override
  int get hashCode => Object.hash(patientUuid, fromDate, toDate);
}

final patientHubDialysisHistoryProvider = FutureProvider.family<
    DialysisSessionsResponse,
    HubModuleHistoryRequest>((ref, request) {
  return ref.read(patientHubServiceProvider).getDialysisHistory(
        request.patientUuid,
        fromDate: request.fromDate,
        toDate: request.toDate,
        take: patientHubMaxTake,
      );
});

final patientHubTheatreHistoryProvider = FutureProvider.family<
    SurgeryRequestsResponse,
    HubModuleHistoryRequest>((ref, request) {
  return ref.read(patientHubServiceProvider).getTheatreHistory(
        request.patientUuid,
        fromDate: request.fromDate,
        toDate: request.toDate,
        take: patientHubMaxTake,
      );
});
