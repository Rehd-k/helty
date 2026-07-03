import '../../auth/dialysis_permissions.dart';
import '../../auth/nursing_permissions.dart';
import '../../auth/theatre_permissions.dart';
import '../../models/super_admin_department_preview.dart';
import '../../models/staff_model.dart';
import '../../patient_chart/models/patient_chart_models.dart';
import '../models/patient_hub_models.dart';

/// Clinical chart sections exposed in Patient Hub (no billing).
const patientHubClinicalSections = [
  PatientChartSectionKeys.encounters,
  PatientChartSectionKeys.admissions,
  PatientChartSectionKeys.medicationOrders,
  PatientChartSectionKeys.prescriptions,
  PatientChartSectionKeys.labOrders,
  PatientChartSectionKeys.labRequests,
  PatientChartSectionKeys.labReports,
  PatientChartSectionKeys.radiologyOrders,
  PatientChartSectionKeys.radiologyReports,
  PatientChartSectionKeys.vitals,
  PatientChartSectionKeys.allergies,
  PatientChartSectionKeys.medicalHistories,
  PatientChartSectionKeys.doctorReports,
  PatientChartSectionKeys.archivedEncounters,
];

const _billingSections = {
  PatientChartSectionKeys.invoices,
  PatientChartSectionKeys.payments,
  PatientChartSectionKeys.wallet,
  PatientChartSectionKeys.appointments,
};

/// Ensures no billing keys leak into hub chart requests.
List<String> filterClinicalChartIncludes(List<String> includes) {
  return includes
      .where((k) => !_billingSections.contains(k))
      .where((k) => patientHubClinicalSections.contains(k))
      .toList();
}

bool _isPhysician(Staff staff) {
  final at = staff.accountType?.name.toLowerCase() ?? '';
  final r = staff.staffRole.toLowerCase();
  return at == 'physician' ||
      at == 'consultant' ||
      at == 'inpatient_doctor' ||
      r == 'doctor' ||
      r == 'consultant' ||
      r == 'resident' ||
      r == 'intern' ||
      r == 'junior_resident' ||
      r == 'senior_resident' ||
      r == 'chief_resident' ||
      r == 'medical_student';
}

bool _isLab(Staff staff) {
  final at = staff.accountType?.name.toLowerCase() ?? '';
  final r = staff.staffRole.toLowerCase();
  return at == 'laboratory' ||
      at == 'lab' ||
      r == 'lab_head' ||
      r == 'lab_scientist' ||
      r == 'lab_technician';
}

bool _isPharmacy(Staff staff) {
  final at = staff.accountType?.name.toLowerCase() ?? '';
  return at == 'pharmacy' ||
      at == 'pharmacy_store' ||
      at == 'pharmacy_dispensary' ||
      at == 'pharmacy_head';
}

/// Whether the staff member may open Patient Hub search and patient views.
bool canAccessPatientHub(Staff? staff) {
  if (staff == null) return false;
  if (staffIsSuperAdmin(staff)) return true;

  if (isNursingStaff(staff)) return true;
  if (_isPhysician(staff)) return true;
  if (_isLab(staff)) return true;
  if (staff.accountType == AccountType.radiology) return true;
  if (_isPharmacy(staff)) return true;
  if (canAccessDialysisModule(staff)) return true;
  if (canAccessTheatreModule(staff)) return true;
  if (staff.accountType == AccountType.cmac) return true;
  final r = staff.staffRole.toLowerCase();
  if (r == 'cmac') return true;

  return false;
}

/// Tab definitions visible in Patient Hub (all clinical tabs for hub users).
List<PatientHubTabDef> patientHubTabsForStaff(Staff? staff) {
  if (!canAccessPatientHub(staff)) return const [];
  return patientHubTabDefs;
}

/// Whether the staff member may upload documents from Patient Hub.
bool canUploadDocumentsInPatientHub(Staff? staff) => canAccessPatientHub(staff);
