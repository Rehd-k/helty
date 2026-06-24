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

bool _hasRole(Staff? staff, Set<String> roles) {
  if (staff == null) return false;
  final r = staff.staffRole.trim().toUpperCase().replaceAll('-', '_');
  return roles.contains(r);
}

bool _isTheatreAccount(Staff? staff) {
  if (staff == null) return false;
  return staff.accountType == AccountType.theatre;
}

/// Book / view surgery requests (doctor + theatre staff).
bool canBookSurgeryRequests(Staff? staff) {
  if (staff == null) return false;
  if (staffIsSuperAdmin(staff)) return true;
  if (_isTheatreAccount(staff)) return true;
  return _hasRole(staff, _bookSurgeryRoles);
}

/// All theatre department staff (+ super admin) may use the module shell.
bool canAccessTheatreModule(Staff? staff) {
  if (staff == null) return false;
  if (staffIsSuperAdmin(staff)) return true;
  if (_isTheatreAccount(staff)) return true;
  return _hasRole(staff, _theatreRoles);
}

/// Start/complete cases, notes, consumables, transfer.
bool canManageTheatreClinical(Staff? staff) {
  if (staff == null) return false;
  if (staffIsSuperAdmin(staff)) return true;
  return _hasRole(staff, _theatreClinicalRoles);
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
