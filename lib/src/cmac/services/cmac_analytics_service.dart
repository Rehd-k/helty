import 'package:dio/dio.dart';

import '../../services/api_service.dart';
import '../models/cmac_analytics_models.dart';
import '../models/cmac_from_json.dart';
import '../models/cmac_period.dart';
import 'cmac_endpoints.dart';

class CmacAnalyticsService {
  CmacAnalyticsService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  final Dio _dio;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    return Map<String, dynamic>.from(data as Map);
  }

  Future<T> _get<T>(
    String path,
    CmacAnalyticsQuery query,
    T Function(Map<String, dynamic>) parse,
  ) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: query.toQueryParams(),
    );
    return parse(_asMap(response.data));
  }

  Future<CmacOverviewResponse> fetchOverview(CmacAnalyticsQuery query) =>
      _get(CmacEndpoints.analyticsOverview, query, parseCmacOverview);

  Future<CmacInsightsResponse> fetchInsights(CmacAnalyticsQuery query) async {
    final response = await _dio.get<dynamic>(
      CmacEndpoints.analyticsInsights,
      queryParameters: query.toQueryParams(),
    );
    final parsed = parseCmacInsightsFromBody(response.data);
    if (response.data is List) {
      return CmacInsightsResponse(
        period: query.period.apiValue,
        asOf: query.asOf,
        insights: parsed.insights,
      );
    }
    return parsed;
  }

  Future<CmacPatientActivityResponse> fetchPatientActivity(
    CmacAnalyticsQuery query,
  ) =>
      _get(
        CmacEndpoints.analyticsPatientActivity,
        query,
        parseCmacPatientActivity,
      );

  Future<CmacClinicalResponse> fetchClinical(CmacAnalyticsQuery query) =>
      _get(CmacEndpoints.analyticsClinical, query, parseCmacClinical);

  Future<CmacLaboratoryResponse> fetchLaboratory(CmacAnalyticsQuery query) =>
      _get(CmacEndpoints.analyticsLaboratory, query, parseCmacLaboratory);

  Future<CmacPharmacyResponse> fetchPharmacy(CmacAnalyticsQuery query) =>
      _get(CmacEndpoints.analyticsPharmacy, query, parseCmacPharmacy);

  Future<CmacOperationsResponse> fetchOperations(CmacAnalyticsQuery query) =>
      _get(CmacEndpoints.analyticsOperations, query, parseCmacOperations);

  Future<CmacQualityResponse> fetchQuality(CmacAnalyticsQuery query) =>
      _get(CmacEndpoints.analyticsQuality, query, parseCmacQuality);

  Future<CmacStaffResponse> fetchStaff(CmacAnalyticsQuery query) =>
      _get(CmacEndpoints.analyticsStaff, query, parseCmacStaff);
}
