import 'package:dio/dio.dart';

import '../../services/api_service.dart';
import '../data/cmd_mock_data.dart';
import '../models/cmd_models.dart';
import 'cmd_endpoints.dart';

/// Command-center API facade. Currently returns [CmdMockData] while REST contracts stabilize.
/// Wire each method to `_dio.get`/`post` and model `fromJson` when the backend is available.
class CmdCommandService {
  CmdCommandService({Dio? dio, this.useMockData = true}) : _dio = dio ?? ApiService().dio;

  final Dio _dio;
  final bool useMockData;

  Future<T> _mockOr<T>(Future<T> Function() real, T mock) async {
    await Future<void>.delayed(const Duration(milliseconds: 140));
    if (useMockData) return mock;
    return real();
  }

  /// GET [CmdEndpoints.dashboard]
  Future<CmdExecutiveDashboardBundle> fetchExecutiveDashboard() {
    return _mockOr(
      () async {
        final response = await _dio.get<Map<String, dynamic>>(CmdEndpoints.dashboard);
        throw UnimplementedError(
          'Parse ${CmdEndpoints.dashboard}: ${response.data}',
        );
      },
      CmdMockData.executiveDashboard(),
    );
  }

  /// GET [CmdEndpoints.hospitalOverview]
  Future<CmdHospitalOverview> fetchHospitalOverview() {
    return _mockOr(
      () async {
        await _dio.get(CmdEndpoints.hospitalOverview);
        throw UnimplementedError('Parse ${CmdEndpoints.hospitalOverview}');
      },
      CmdMockData.hospitalOverview(),
    );
  }

  /// GET [CmdEndpoints.financialOverview]
  Future<CmdFinancialOverview> fetchFinancialOverview() {
    return _mockOr(
      () async {
        await _dio.get(CmdEndpoints.financialOverview);
        throw UnimplementedError('Parse ${CmdEndpoints.financialOverview}');
      },
      CmdMockData.financialOverview(),
    );
  }

  /// GET [CmdEndpoints.staffOversight]
  Future<CmdStaffOversight> fetchStaffOversight() {
    return _mockOr(
      () async {
        await _dio.get(CmdEndpoints.staffOversight);
        throw UnimplementedError('Parse ${CmdEndpoints.staffOversight}');
      },
      CmdMockData.staffOversight(),
    );
  }

  /// GET [CmdEndpoints.bedsSnapshot]
  Future<CmdBedsSnapshot> fetchBedsSnapshot() {
    return _mockOr(
      () async {
        await _dio.get(CmdEndpoints.bedsSnapshot);
        throw UnimplementedError('Parse ${CmdEndpoints.bedsSnapshot}');
      },
      CmdMockData.bedsSnapshot(),
    );
  }

  /// GET [CmdEndpoints.labMonitoring]
  Future<CmdLabMonitoring> fetchLabMonitoring() {
    return _mockOr(
      () async {
        await _dio.get(CmdEndpoints.labMonitoring);
        throw UnimplementedError('Parse ${CmdEndpoints.labMonitoring}');
      },
      CmdMockData.labMonitoring(),
    );
  }

  /// GET [CmdEndpoints.alerts]
  Future<List<CmdIncident>> fetchIncidents() {
    return _mockOr(
      () async {
        await _dio.get(CmdEndpoints.alerts);
        throw UnimplementedError('Parse ${CmdEndpoints.alerts}');
      },
      CmdMockData.incidents(),
    );
  }

  /// GET [CmdEndpoints.reportTemplates]
  Future<List<CmdReportTemplate>> fetchReportTemplates() {
    return _mockOr(
      () async {
        await _dio.get(CmdEndpoints.reportTemplates);
        throw UnimplementedError('Parse ${CmdEndpoints.reportTemplates}');
      },
      CmdMockData.reportTemplates(),
    );
  }

  /// GET [CmdEndpoints.auditLogs] + [CmdEndpoints.complianceChecklist] (combined in mock)
  Future<CmdAuditComplianceBundle> fetchAuditCompliance() {
    return _mockOr(
      () async {
        await _dio.get(CmdEndpoints.auditLogs);
        throw UnimplementedError('Parse audit + compliance bundle');
      },
      CmdMockData.auditCompliance(),
    );
  }

  /// GET [CmdEndpoints.approvalsPending]
  Future<List<CmdApprovalRequest>> fetchPendingApprovals() {
    return _mockOr(
      () async {
        await _dio.get(CmdEndpoints.approvalsPending);
        throw UnimplementedError('Parse ${CmdEndpoints.approvalsPending}');
      },
      CmdMockData.approvals(),
    );
  }

  /// GET [CmdEndpoints.settingsOverview]
  Future<CmdSettingsOverview> fetchSettingsOverview() {
    return _mockOr(
      () async {
        await _dio.get(CmdEndpoints.settingsOverview);
        throw UnimplementedError('Parse ${CmdEndpoints.settingsOverview}');
      },
      CmdMockData.settingsOverview(),
    );
  }

  /// GET [CmdEndpoints.communications]
  Future<List<CmdAnnouncement>> fetchAnnouncements() {
    return _mockOr(
      () async {
        await _dio.get(CmdEndpoints.communications);
        throw UnimplementedError('Parse ${CmdEndpoints.communications}');
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
        await _dio.get(CmdEndpoints.patientExperience);
        throw UnimplementedError('Parse ${CmdEndpoints.patientExperience}');
      },
      CmdMockData.patientExperience(),
    );
  }
}
