import 'package:dio/dio.dart';

import '../../services/api_service.dart';
import '../data/cmd_mock_data.dart';
import '../models/cmd_from_json.dart';
import '../models/cmd_models.dart';
import 'cmd_endpoints.dart';

/// Command-center API facade. Uses [CmdMockData] when [useMockData] is true;
/// otherwise parses JSON from [CmdEndpoints] using [parseCmd*] in [cmd_from_json.dart].
class CmdCommandService {
  CmdCommandService({Dio? dio, this.useMockData = true}) : _dio = dio ?? ApiService().dio;

  final Dio _dio;
  final bool useMockData;

  Future<T> _mockOr<T>(Future<T> Function() real, T mock) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (useMockData) return mock;
    return real();
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    return Map<String, dynamic>.from(data as Map);
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List<dynamic>) return data;
    return (data as List).cast<dynamic>();
  }

  /// GET [CmdEndpoints.dashboard]
  Future<CmdExecutiveDashboardBundle> fetchExecutiveDashboard() {
    return _mockOr(
      () async {
        final response = await _dio.get<dynamic>(CmdEndpoints.dashboard);
        return parseCmdExecutiveDashboardBundle(_asMap(response.data));
      },
      CmdMockData.executiveDashboard(),
    );
  }

  /// GET [CmdEndpoints.hospitalOverview]
  Future<CmdHospitalOverview> fetchHospitalOverview() {
    return _mockOr(
      () async {
        final response = await _dio.get<dynamic>(CmdEndpoints.hospitalOverview);
        return parseCmdHospitalOverview(_asMap(response.data));
      },
      CmdMockData.hospitalOverview(),
    );
  }

  /// GET [CmdEndpoints.financialOverview]
  Future<CmdFinancialOverview> fetchFinancialOverview() {
    return _mockOr(
      () async {
        final response = await _dio.get<dynamic>(CmdEndpoints.financialOverview);
        return parseCmdFinancialOverview(_asMap(response.data));
      },
      CmdMockData.financialOverview(),
    );
  }

  /// GET [CmdEndpoints.staffOversight]
  Future<CmdStaffOversight> fetchStaffOversight() {
    return _mockOr(
      () async {
        final response = await _dio.get<dynamic>(CmdEndpoints.staffOversight);
        return parseCmdStaffOversight(_asMap(response.data));
      },
      CmdMockData.staffOversight(),
    );
  }

  /// GET [CmdEndpoints.bedsSnapshot]
  Future<CmdBedsSnapshot> fetchBedsSnapshot() {
    return _mockOr(
      () async {
        final response = await _dio.get<dynamic>(CmdEndpoints.bedsSnapshot);
        return parseCmdBedsSnapshot(_asMap(response.data));
      },
      CmdMockData.bedsSnapshot(),
    );
  }

  /// GET [CmdEndpoints.labMonitoring]
  Future<CmdLabMonitoring> fetchLabMonitoring() {
    return _mockOr(
      () async {
        final response = await _dio.get<dynamic>(CmdEndpoints.labMonitoring);
        return parseCmdLabMonitoring(_asMap(response.data));
      },
      CmdMockData.labMonitoring(),
    );
  }

  /// GET [CmdEndpoints.alerts]
  Future<List<CmdIncident>> fetchIncidents() {
    return _mockOr(
      () async {
        final response = await _dio.get<dynamic>(CmdEndpoints.alerts);
        return parseCmdIncidentList(_asList(response.data));
      },
      CmdMockData.incidents(),
    );
  }

  /// GET [CmdEndpoints.reportTemplates]
  Future<List<CmdReportTemplate>> fetchReportTemplates() {
    return _mockOr(
      () async {
        final response = await _dio.get<dynamic>(CmdEndpoints.reportTemplates);
        return parseCmdReportTemplateList(_asList(response.data));
      },
      CmdMockData.reportTemplates(),
    );
  }

  /// GET [CmdEndpoints.auditLogs] + [CmdEndpoints.complianceChecklist] (combined in mock)
  Future<CmdAuditComplianceBundle> fetchAuditCompliance() {
    return _mockOr(
      () async {
        final response = await _dio.get<dynamic>(CmdEndpoints.auditLogs);
        return parseCmdAuditComplianceBundle(_asMap(response.data));
      },
      CmdMockData.auditCompliance(),
    );
  }

  /// GET [CmdEndpoints.approvalsPending]
  Future<List<CmdApprovalRequest>> fetchPendingApprovals() {
    return _mockOr(
      () async {
        final response = await _dio.get<dynamic>(CmdEndpoints.approvalsPending);
        return parseCmdApprovalRequestList(_asList(response.data));
      },
      CmdMockData.approvals(),
    );
  }

  /// GET [CmdEndpoints.settingsOverview]
  Future<CmdSettingsOverview> fetchSettingsOverview() {
    return _mockOr(
      () async {
        final response = await _dio.get<dynamic>(CmdEndpoints.settingsOverview);
        return parseCmdSettingsOverview(_asMap(response.data));
      },
      CmdMockData.settingsOverview(),
    );
  }

  /// GET [CmdEndpoints.communications]
  Future<List<CmdAnnouncement>> fetchAnnouncements() {
    return _mockOr(
      () async {
        final response = await _dio.get<dynamic>(CmdEndpoints.communications);
        return parseCmdAnnouncementList(_asList(response.data));
      },
      CmdMockData.announcements(),
    );
  }

  /// POST [CmdEndpoints.communicationsBroadcast] — stub
  Future<void> sendBroadcast({
    required String title,
    required String body,
    required String audience,
    required String priority,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (useMockData) return;
    await _dio.post<void>(
      CmdEndpoints.communicationsBroadcast,
      data: {
        'title': title,
        'body': body,
        'audience': audience,
        'priority': priority,
      },
    );
  }

  /// GET [CmdEndpoints.patientExperience]
  Future<CmdPatientExperienceOverview> fetchPatientExperience() {
    return _mockOr(
      () async {
        final response = await _dio.get<dynamic>(CmdEndpoints.patientExperience);
        return parseCmdPatientExperienceOverview(_asMap(response.data));
      },
      CmdMockData.patientExperience(),
    );
  }
}
