import '../../dialysis/models/dialysis_models.dart';
import '../../dialysis/services/dialysis_api_service.dart';
import '../../paitients/patient_model.dart';
import '../../paitients/patient_service.dart';
import '../../patient_chart/models/archived_encounter_models.dart';
import '../../patient_chart/models/patient_chart_models.dart';
import '../../patient_chart/services/patient_chart_service.dart';
import '../../theatre/models/theatre_models.dart';
import '../../theatre/services/theatre_api_service.dart';
import '../models/patient_hub_models.dart';
import '../permissions/patient_hub_permissions.dart';

class PatientHubService {
  PatientHubService({
    PatientChartService? chartService,
    PatientService? patientService,
    DialysisApiService? dialysisService,
    TheatreApiService? theatreService,
  })  : _chartService = chartService ?? PatientChartService(),
        _patientService = patientService ?? PatientService(),
        _dialysisService = dialysisService ?? DialysisApiService(),
        _theatreService = theatreService ?? TheatreApiService();

  final PatientChartService _chartService;
  final PatientService _patientService;
  final DialysisApiService _dialysisService;
  final TheatreApiService _theatreService;

  Future<Patient> getFullProfile(String patientUuid) =>
      _patientService.getPatientById(patientUuid);

  Future<PatientChartResponse> getChartHeader(String patientUuid) =>
      _chartService.getChart(patientUuid);

  Future<PatientChartResponse> getClinicalSection(
    String patientUuid, {
    required List<String> include,
    int limit = 50,
    int skip = 0,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final safe = filterClinicalChartIncludes(include);
    if (safe.isEmpty) {
      throw ArgumentError('No valid clinical chart sections requested');
    }
    return _chartService.getChart(
      patientUuid,
      include: safe,
      limit: limit,
      skip: skip,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  Future<DialysisSessionsResponse> getDialysisHistory(
    String patientUuid, {
    DateTime? fromDate,
    DateTime? toDate,
    int skip = 0,
    int take = 50,
  }) =>
      _dialysisService.getSessions(
        patientId: patientUuid,
        fromDate: fromDate,
        toDate: toDate,
        skip: skip,
        take: take > patientHubMaxTake ? patientHubMaxTake : take,
      );

  Future<SurgeryRequestsResponse> getTheatreHistory(
    String patientUuid, {
    DateTime? fromDate,
    DateTime? toDate,
    int skip = 0,
    int take = 50,
  }) =>
      _theatreService.getSurgeryRequests(
        patientId: patientUuid,
        fromDate: fromDate,
        toDate: toDate,
        skip: skip,
        take: take > patientHubMaxTake ? patientHubMaxTake : take,
      );

  Future<List<PatientArchivedEncounter>> listArchivedEncounters(
    String patientUuid,
  ) =>
      _chartService.listArchivedEncounters(patientUuid);
}
