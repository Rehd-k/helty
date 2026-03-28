/// Planned REST paths for the CMD / command-center API.
/// Base URL comes from [ApiService]; these are relative to that root.
/// Replace mock implementations in [CmdCommandService] with real calls.
abstract final class CmdEndpoints {
  static const dashboard = '/cmd/dashboard';
  static const hospitalOverview = '/cmd/hospital/overview';
  static const financialOverview = '/cmd/financial/overview';
  static const staffOversight = '/cmd/staff/oversight';
  static const bedsSnapshot = '/cmd/beds/snapshot';
  static const labMonitoring = '/cmd/lab/monitoring';
  static const alerts = '/cmd/alerts';
  static const reportTemplates = '/cmd/reports/templates';
  static const auditLogs = '/cmd/audit/logs';
  static const complianceChecklist = '/cmd/audit/compliance-checklist';
  static const approvalsPending = '/cmd/approvals/pending';
  static const communications = '/cmd/communications';
  static const communicationsBroadcast = '/cmd/communications/broadcast';
  static const patientExperience = '/cmd/patient-experience';
  static const settingsOverview = '/cmd/settings/overview';
}
