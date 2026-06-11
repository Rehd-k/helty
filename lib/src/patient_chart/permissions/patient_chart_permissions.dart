import '../../auth/nursing_permissions.dart';
import '../../models/staff_model.dart';
import '../models/patient_chart_models.dart';

/// Sections the current staff may request via chart `include`.
List<String> allowedChartSectionsForStaff(Staff? staff) {
  if (staff == null) return const [];
  final at = staff.accountType?.name.toLowerCase() ?? '';
  final r = staff.staffRole.toLowerCase();

  if (at == 'medical_records' || r == 'medical_records') {
    return PatientChartSectionKeys.all;
  }

  if (isNursingStaff(staff)) {
    return PatientChartSectionKeys.clinicalNurse;
  }

  return const [];
}

/// Tabs visible for staff (intersection with API available sections applied in UI).
List<PatientChartTabDef> chartTabsForStaff(Staff? staff) {
  final allowed = allowedChartSectionsForStaff(staff).toSet();
  return patientChartTabDefs.where((tab) {
    return tab.includeKeys.any(allowed.contains);
  }).toList();
}

bool canUploadArchivedEncounters(Staff? staff) {
  if (staff == null) return false;
  final at = staff.accountType?.name.toLowerCase() ?? '';
  final r = staff.staffRole.toLowerCase();
  return at == 'medical_records' ||
      r == 'medical_records' ||
      at == 'outpatient_nurse' ||
      r == 'outpatient_nurse' ||
      at == 'front_desk' ||
      at == 'frontdesk' ||
      r == 'front_desk' ||
      r == 'receptionist';
}

bool canDeleteArchivedEncounters(Staff? staff) => canUploadArchivedEncounters(staff);

bool staffHasPatientChartAccess(Staff? staff) {
  if (staff == null) return false;
  final at = staff.accountType?.name.toLowerCase() ?? '';
  final r = staff.staffRole.toLowerCase();
  return at == 'medical_records' ||
      r == 'medical_records' ||
      isNursingStaff(staff);
}
