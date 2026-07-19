/// Relative paths for frontdesk patient device + family APIs
/// (base URL from [ApiService]). See `docs/staff-app.md`.
abstract final class PatientAccessEndpoints {
  static const patientDevices = '/frontdesk/patient-devices';

  static String approveDevice(String id) =>
      '/frontdesk/patient-devices/$id/approve';

  static String patientDevice(String id) => '/frontdesk/patient-devices/$id';

  static String patientDevicesFor(String patientId) =>
      '/frontdesk/patients/$patientId/devices';

  static String children(String parentId) =>
      '/frontdesk/patients/$parentId/children';

  static String child(String parentId, String childId) =>
      '/frontdesk/patients/$parentId/children/$childId';
}
