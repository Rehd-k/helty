import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models/cmd_models.dart';
import 'services/cmd_command_service.dart';

final cmdCommandServiceProvider = Provider<CmdCommandService>((ref) {
  return CmdCommandService();
});

final cmdExecutiveDashboardProvider =
    FutureProvider.autoDispose<CmdExecutiveDashboardBundle>((ref) async {
  final svc = ref.watch(cmdCommandServiceProvider);
  return svc.fetchExecutiveDashboard();
});

final cmdHospitalOverviewProvider =
    FutureProvider.autoDispose<CmdHospitalOverview>((ref) async {
  final svc = ref.watch(cmdCommandServiceProvider);
  return svc.fetchHospitalOverview();
});

final cmdFinancialOverviewProvider =
    FutureProvider.autoDispose<CmdFinancialOverview>((ref) async {
  final svc = ref.watch(cmdCommandServiceProvider);
  return svc.fetchFinancialOverview();
});

final cmdStaffOversightProvider =
    FutureProvider.autoDispose<CmdStaffOversight>((ref) async {
  final svc = ref.watch(cmdCommandServiceProvider);
  return svc.fetchStaffOversight();
});

final cmdBedsSnapshotProvider = FutureProvider.autoDispose<CmdBedsSnapshot>((
  ref,
) async {
  final svc = ref.watch(cmdCommandServiceProvider);
  return svc.fetchBedsSnapshot();
});

final cmdLabMonitoringProvider =
    FutureProvider.autoDispose<CmdLabMonitoring>((ref) async {
  final svc = ref.watch(cmdCommandServiceProvider);
  return svc.fetchLabMonitoring();
});

final cmdIncidentsProvider = FutureProvider.autoDispose<List<CmdIncident>>((
  ref,
) async {
  final svc = ref.watch(cmdCommandServiceProvider);
  return svc.fetchIncidents();
});

final cmdReportTemplatesProvider =
    FutureProvider.autoDispose<List<CmdReportTemplate>>((ref) async {
  final svc = ref.watch(cmdCommandServiceProvider);
  return svc.fetchReportTemplates();
});

final cmdAuditComplianceProvider =
    FutureProvider.autoDispose<CmdAuditComplianceBundle>((ref) async {
  final svc = ref.watch(cmdCommandServiceProvider);
  return svc.fetchAuditCompliance();
});

final cmdPendingApprovalsProvider =
    FutureProvider.autoDispose<List<CmdApprovalRequest>>((ref) async {
  final svc = ref.watch(cmdCommandServiceProvider);
  return svc.fetchPendingApprovals();
});

final cmdSettingsOverviewProvider =
    FutureProvider.autoDispose<CmdSettingsOverview>((ref) async {
  final svc = ref.watch(cmdCommandServiceProvider);
  return svc.fetchSettingsOverview();
});

final cmdAnnouncementsProvider =
    FutureProvider.autoDispose<List<CmdAnnouncement>>((ref) async {
  final svc = ref.watch(cmdCommandServiceProvider);
  return svc.fetchAnnouncements();
});

final cmdPatientExperienceProvider =
    FutureProvider.autoDispose<CmdPatientExperienceOverview>((ref) async {
  final svc = ref.watch(cmdCommandServiceProvider);
  return svc.fetchPatientExperience();
});

/// Approvals + integrations/settings for CMD system control screen.
final cmdSystemControlProvider = FutureProvider.autoDispose<
    (List<CmdApprovalRequest>, CmdSettingsOverview)>((ref) async {
  final svc = ref.watch(cmdCommandServiceProvider);
  final approvals = await svc.fetchPendingApprovals();
  final settings = await svc.fetchSettingsOverview();
  return (approvals, settings);
});
