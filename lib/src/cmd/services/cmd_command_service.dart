import 'package:dio/dio.dart';

import '../../services/api_service.dart';
import '../models/cmd_from_json.dart';
import '../models/cmd_models.dart';
import 'cmd_endpoints.dart';

/// Command-center API facade that parses live JSON from [CmdEndpoints]
/// using [parseCmd*] in [cmd_from_json.dart].
class CmdCommandService {
  CmdCommandService({Dio? dio}) : _dio = dio ?? ApiService().dio;

  final Dio _dio;

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    return Map<String, dynamic>.from(data as Map);
  }

  List<dynamic> _asList(dynamic data) {
    if (data is List<dynamic>) return data;
    return (data as List).cast<dynamic>();
  }

  /// GET [CmdEndpoints.dashboard]
  Future<CmdExecutiveDashboardBundle> fetchExecutiveDashboard() async {
    final response = await _dio.get<dynamic>(CmdEndpoints.dashboard);
    return parseCmdExecutiveDashboardBundle(_asMap(response.data));
  }

  /// GET [CmdEndpoints.hospitalOverview]
  Future<CmdHospitalOverview> fetchHospitalOverview() async {
    final response = await _dio.get<dynamic>(CmdEndpoints.hospitalOverview);
    return parseCmdHospitalOverview(_asMap(response.data));
  }

  /// GET [CmdEndpoints.financialOverview]
  Future<CmdFinancialOverview> fetchFinancialOverview() async {
    final response = await _dio.get<dynamic>(CmdEndpoints.financialOverview);
    return parseCmdFinancialOverview(_asMap(response.data));
  }

  /// GET [CmdEndpoints.staffOversight]
  Future<CmdStaffOversight> fetchStaffOversight() async {
    final response = await _dio.get<dynamic>(CmdEndpoints.staffOversight);
    return parseCmdStaffOversight(_asMap(response.data));
  }

  /// GET [CmdEndpoints.bedsSnapshot]
  Future<CmdBedsSnapshot> fetchBedsSnapshot() async {
    final response = await _dio.get<dynamic>(CmdEndpoints.bedsSnapshot);
    return parseCmdBedsSnapshot(_asMap(response.data));
  }

  /// GET [CmdEndpoints.labMonitoring]
  Future<CmdLabMonitoring> fetchLabMonitoring() async {
    final response = await _dio.get<dynamic>(CmdEndpoints.labMonitoring);
    return parseCmdLabMonitoring(_asMap(response.data));
  }

  /// GET [CmdEndpoints.alerts]
  Future<List<CmdIncident>> fetchIncidents() async {
    final response = await _dio.get<dynamic>(CmdEndpoints.alerts);
    return parseCmdIncidentList(_asList(response.data));
  }

  /// GET [CmdEndpoints.reportTemplates]
  Future<List<CmdReportTemplate>> fetchReportTemplates() async {
    final response = await _dio.get<dynamic>(CmdEndpoints.reportTemplates);
    return parseCmdReportTemplateList(_asList(response.data));
  }

  /// GET [CmdEndpoints.auditLogs]
  Future<CmdAuditComplianceBundle> fetchAuditCompliance() async {
    final response = await _dio.get<dynamic>(CmdEndpoints.auditLogs);
    return parseCmdAuditComplianceBundle(_asMap(response.data));
  }

  /// GET [CmdEndpoints.approvalsPending]
  Future<List<CmdApprovalRequest>> fetchPendingApprovals() async {
    final response = await _dio.get<dynamic>(CmdEndpoints.approvalsPending);
    return parseCmdApprovalRequestList(_asList(response.data));
  }

  /// GET [CmdEndpoints.settingsOverview]
  Future<CmdSettingsOverview> fetchSettingsOverview() async {
    final response = await _dio.get<dynamic>(CmdEndpoints.settingsOverview);
    return parseCmdSettingsOverview(_asMap(response.data));
  }

  /// GET [CmdEndpoints.communications]
  Future<List<CmdAnnouncement>> fetchAnnouncements() async {
    final response = await _dio.get<dynamic>(CmdEndpoints.communications);
    return parseCmdAnnouncementList(_asList(response.data));
  }

  /// POST [CmdEndpoints.communicationsBroadcast]
  Future<void> sendBroadcast({
    required String title,
    required String body,
    required String audience,
    required String priority,
  }) async {
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
  Future<CmdPatientExperienceOverview> fetchPatientExperience() async {
    final response = await _dio.get<dynamic>(CmdEndpoints.patientExperience);
    return parseCmdPatientExperienceOverview(_asMap(response.data));
  }
}
