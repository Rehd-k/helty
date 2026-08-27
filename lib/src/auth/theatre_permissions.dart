import '../models/staff_model.dart';
import '../models/super_admin_department_preview.dart';

/// Mirrors backend theatre access tiers (see docs/theatre-module-api.md).

const _theatreRoles = {
  'THEATRE',
  'THEATRE_HEAD',
  'THEATRE_NURSE',
  'THEATRE_SCRUB',
  'THEATRE_ANAESTHETIST',
  'THEATRE_RECEPTIONIST',
};

const _theatreClinicalRoles = {
  'THEATRE',
  'THEATRE_HEAD',
  'THEATRE_NURSE',
  'THEATRE_SCRUB',
  'THEATRE_ANAESTHETIST',
};

const _bookSurgeryRoles = {
  'CONSULTANT',
  'INPATIENT_DOCTOR',
  'ONG',
  ..._theatreRoles,
};

String _normalizedRole(Staff staff) =>
    staff.staffRole.trim().toUpperCase().replaceAll('-', '_');

bool _hasRole(Staff? staff, Set<String> roles) {
  if (staff == null) return false;
  return roles.contains(_normalizedRole(staff));
}

bool _isTheatreAccount(Staff? staff) {
  if (staff == null) return false;
  return staff.accountType == AccountType.theatre;
}

/// Mirrors backend `ONG` / `INPATIENT_DOCTOR` tokens: any physician except
/// medical students may book surgery from an encounter.
bool _isEncounterPhysician(Staff staff) {
  if (staff.accountType != AccountType.physician) return false;
  return _normalizedRole(staff) != 'MEDICAL_STUDENT';
}

/// Book / view surgery requests (doctor + theatre staff).
bool canBookSurgeryRequests(Staff? staff) {
  if (staff == null) return false;
  if (staffIsSuperAdmin(staff)) return true;
  if (_isTheatreAccount(staff)) return true;
  if (_isEncounterPhysician(staff)) return true;
  return _hasRole(staff, _bookSurgeryRoles);
}

/// All theatre department staff (+ super admin) may use the module shell.
bool canAccessTheatreModule(Staff? staff) {
  if (staff == null) return false;
  if (staffIsSuperAdmin(staff)) return true;
  if (_isTheatreAccount(staff)) return true;
  return _hasRole(staff, _theatreRoles);
}

/// Start/complete cases, consumables, transfer (not OP notes).
bool canManageTheatreClinical(Staff? staff) {
  if (staff == null) return false;
  if (staffIsSuperAdmin(staff)) return true;
  return _hasRole(staff, _theatreClinicalRoles);
}

/// Doctors (except medical students) and theatre clinical staff may write OP notes.
bool canWriteOperativeNotes(Staff? staff) {
  if (staff == null) return false;
  if (staffIsSuperAdmin(staff)) return true;
  if (canManageTheatreClinical(staff)) return true;
  if (_isEncounterPhysician(staff)) return true;
  return _hasRole(staff, {'CONSULTANT', 'INPATIENT_DOCTOR', 'ONG'});
}

/// Send completed case to billing.
bool canBillTheatreCase(Staff? staff) {
  if (staff == null) return false;
  if (staffIsSuperAdmin(staff)) return true;
  return _hasRole(staff, {'THEATRE_HEAD', 'THEATRE_RECEPTIONIST'});
}

/// Create / update theatre rooms.
bool canManageTheatreRooms(Staff? staff) {
  if (staff == null) return false;
  if (staffIsSuperAdmin(staff)) return true;
  return _hasRole(staff, {'THEATRE_HEAD'});
}
