import '../models/staff_model.dart';
import '../models/super_admin_department_preview.dart';

/// Mirrors backend `dialysis.constants.ts` access tiers.
///
/// - [canAccessDialysisModule] — `DIALYSIS_ACCESS` (list/create/detail sessions)
/// - [canPerformDialysisClinical] — `DIALYSIS_CLINICAL_ACCESS` (start/complete, consumables)
/// - [canCancelDialysisSession] — `DIALYSIS_HEAD_ACCESS` (cancel only)

const _dialysisRoles = {
  'DIALYSIS_HEAD',
  'DIALYSIS_NURSE',
  'DIALYSIS_TECH',
  'DIALYSIS_TECHNICIAN', // legacy client registration token
  'DIALYSIS_RECEPTIONIST',
};

const _dialysisClinicalRoles = {
  'DIALYSIS_HEAD',
  'DIALYSIS_NURSE',
  'DIALYSIS_TECH',
  'DIALYSIS_TECHNICIAN',
};

bool _hasRole(Staff? staff, Set<String> roles) {
  if (staff == null) return false;
  final r = staff.staffRole.trim().toUpperCase().replaceAll('-', '_');
  return roles.contains(r);
}

bool _isDialysisAccount(Staff? staff) {
  if (staff == null) return false;
  return staff.accountType == AccountType.dialysis;
}

/// All dialysis department staff (+ super admin) may use the module shell.
bool canAccessDialysisModule(Staff? staff) {
  if (staff == null) return false;
  if (staffIsSuperAdmin(staff)) return true;
  if (_isDialysisAccount(staff)) return true;
  return _hasRole(staff, _dialysisRoles);
}

/// Start/complete sessions and add consumables.
bool canPerformDialysisClinical(Staff? staff) {
  if (staff == null) return false;
  if (staffIsSuperAdmin(staff)) return true;
  return _hasRole(staff, _dialysisClinicalRoles);
}

/// Cancel an in-flight session (`status: CANCELLED`).
bool canCancelDialysisSession(Staff? staff) {
  if (staff == null) return false;
  if (staffIsSuperAdmin(staff)) return true;
  return _hasRole(staff, {'DIALYSIS_HEAD'});
}
