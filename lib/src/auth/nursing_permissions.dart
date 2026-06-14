import '../models/staff_model.dart';
import '../models/super_admin_department_preview.dart';
import '../nursing/models/nursing_models.dart';

// Capability constants (mirror backend nursing capabilities).
const kCapViewHospitalDashboard = 'view_hospital_dashboard';
const kCapViewUnitDashboard = 'view_unit_dashboard';
const kCapViewLineDashboard = 'view_line_dashboard';
const kCapManageShiftRoster = 'manage_shift_roster';
const kCapViewOwnRoster = 'view_own_roster';
const kCapAssignInpatientPatients = 'assign_inpatient_patients';
const kCapAssignOutpatientPatients = 'assign_outpatient_patients';
const kCapClinicalNursingWrites = 'clinical_nursing_writes';

const _chargeNurseRoles = {
  'WARD_CHARGE_NURSE',
  'ICU_CHARGE_NURSE',
  'EMERGENCY_CHARGE_NURSE',
  'OPD_CHARGE_NURSE',
  'ONG_CHARGE_NURSE',
};

const _inpatientChargeRoles = {
  'WARD_CHARGE_NURSE',
  'ICU_CHARGE_NURSE',
  'EMERGENCY_CHARGE_NURSE',
  'ONG_CHARGE_NURSE',
};

const _outpatientChargeRoles = {
  'OPD_CHARGE_NURSE',
  'ONG_CHARGE_NURSE',
};

String _normalizeRole(String? role) => normalizeNursingStaffRole(role);

bool _hasRole(Staff? staff, Set<String> roles) {
  if (staff == null) return false;
  return roles.contains(_normalizeRole(staff.staffRole));
}

bool _isNurseAccount(Staff? staff) {
  if (staff == null) return false;
  return staff.accountType == AccountType.nurse;
}

/// Any nursing staff (account type NURSE or known nursing roles).
bool isNursingStaff(Staff? staff) {
  if (staff == null) return false;
  if (staffIsSuperAdmin(staff)) return false;
  if (_isNurseAccount(staff)) return true;
  final r = _normalizeRole(staff.staffRole);
  if (r == 'MATRON' ||
      _chargeNurseRoles.contains(r) ||
      r == 'INPATIENT_NURSE' ||
      r == 'OUTPATIENT_NURSE') {
    return true;
  }
  final at = staff.accountType?.name.toLowerCase() ?? '';
  return at == 'head_nurse' ||
      at == 'inpatient_nurse' ||
      at == 'outpatient_nurse';
}

bool isMatron(Staff? staff) => _hasRole(staff, {'MATRON'});

bool isChargeNurse(Staff? staff) => _hasRole(staff, _chargeNurseRoles);

/// Line/unit nurses — not Matron and not a charge nurse.
bool isRegularNurse(Staff? staff) =>
    isNursingStaff(staff) && !isMatron(staff) && !isChargeNurse(staff);

bool isLineNurse(Staff? staff) =>
    _hasRole(staff, {'INPATIENT_NURSE', 'OUTPATIENT_NURSE'});

bool isInpatientLineNurse(Staff? staff) =>
    _hasRole(staff, {'INPATIENT_NURSE'});

bool isOutpatientLineNurse(Staff? staff) =>
    _hasRole(staff, {'OUTPATIENT_NURSE'});

bool isWardIcuErChargeNurse(Staff? staff) =>
    _hasRole(staff, _inpatientChargeRoles);

bool isOpdOngChargeNurse(Staff? staff) =>
    _hasRole(staff, _outpatientChargeRoles);

bool isEmergencyChargeNurse(Staff? staff) =>
    _hasRole(staff, {'EMERGENCY_CHARGE_NURSE'});

bool isOngChargeNurse(Staff? staff) =>
    _hasRole(staff, {'ONG_CHARGE_NURSE'});

bool hasNursingCapability(NursingDashboardMe? me, String capability) {
  if (me != null && me.capabilities.isNotEmpty) {
    return me.hasCapability(capability);
  }
  return false;
}

bool _roleHasCapability(Staff? staff, String capability) {
  if (staff == null) return false;
  if (staffIsSuperAdmin(staff)) return true;
  final r = _normalizeRole(staff.staffRole);

  switch (capability) {
    case kCapViewHospitalDashboard:
      return r == 'MATRON';
    case kCapViewUnitDashboard:
      return r == 'MATRON' || _chargeNurseRoles.contains(r);
    case kCapViewLineDashboard:
      return r == 'INPATIENT_NURSE' || r == 'OUTPATIENT_NURSE';
    case kCapManageShiftRoster:
      return r == 'MATRON' || _chargeNurseRoles.contains(r);
    case kCapViewOwnRoster:
      return isNursingStaff(staff);
    case kCapAssignInpatientPatients:
      return r == 'MATRON' || _inpatientChargeRoles.contains(r);
    case kCapAssignOutpatientPatients:
      return r == 'MATRON' || _outpatientChargeRoles.contains(r);
    case kCapClinicalNursingWrites:
      return isNursingStaff(staff);
    default:
      return false;
  }
}

bool nursingCan(
  Staff? staff,
  NursingDashboardMe? me,
  String capability,
) {
  if (hasNursingCapability(me, capability)) return true;
  return _roleHasCapability(staff, capability);
}

bool canManageShiftRoster(Staff? staff, [NursingDashboardMe? me]) =>
    nursingCan(staff, me, kCapManageShiftRoster);

bool canAssignInpatientPatients(Staff? staff, [NursingDashboardMe? me]) =>
    nursingCan(staff, me, kCapAssignInpatientPatients);

bool canAssignOutpatientPatients(Staff? staff, [NursingDashboardMe? me]) =>
    nursingCan(staff, me, kCapAssignOutpatientPatients);

bool canViewHospitalDashboard(Staff? staff, [NursingDashboardMe? me]) =>
    nursingCan(staff, me, kCapViewHospitalDashboard);

bool canViewUnitDashboard(Staff? staff, [NursingDashboardMe? me]) =>
    nursingCan(staff, me, kCapViewUnitDashboard);

bool canViewLineDashboard(Staff? staff, [NursingDashboardMe? me]) =>
    nursingCan(staff, me, kCapViewLineDashboard);

/// Charge nurse roles require departmentId on registration.
bool nursingRoleRequiresDepartment(String staffRole) {
  final r = _normalizeRole(staffRole);
  return _chargeNurseRoles.contains(r);
}

/// Matron must not have departmentId.
bool nursingRoleForbidsDepartment(String staffRole) {
  return _normalizeRole(staffRole) == 'MATRON';
}
