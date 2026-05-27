abstract final class CmacEndpoints {
  static const analyticsOverview = '/cmac/analytics/overview';
  static const analyticsInsights = '/cmac/analytics/insights';
  static const analyticsPatientActivity = '/cmac/analytics/patient-activity';
  static const analyticsClinical = '/cmac/analytics/clinical';
  static const analyticsLaboratory = '/cmac/analytics/laboratory';
  static const analyticsPharmacy = '/cmac/analytics/pharmacy';
  static const analyticsOperations = '/cmac/analytics/operations';
  static const analyticsQuality = '/cmac/analytics/quality';
  static const analyticsStaff = '/cmac/analytics/staff';

  static String qualityReferrals([String? id]) =>
      id == null ? '/quality-safety/referrals' : '/quality-safety/referrals/$id';
  static String qualityComplaints([String? id]) =>
      id == null
          ? '/quality-safety/complaints'
          : '/quality-safety/complaints/$id';
  static String qualityIncidents([String? id]) =>
      id == null
          ? '/quality-safety/incidents'
          : '/quality-safety/incidents/$id';
  static String qualityInfections([String? id]) =>
      id == null
          ? '/quality-safety/infections'
          : '/quality-safety/infections/$id';
}
