import 'package:helty/src/models/staff_model.dart';

bool _hasRole(Staff? staff, Set<String> roles) {
  if (staff == null) return false;
  final staffRole = staff.staffRole.trim().toUpperCase();
  return roles.contains(staffRole);
}

bool _hasAccountType(Staff? staff, Set<AccountType> allowed) {
  if (staff == null) return false;
  final at = staff.accountType;
  return at != null && allowed.contains(at);
}

/// Staff who may manage patient-app devices and family links
/// (`docs/staff-app.md`: FRONT_DESK / MEDICAL_RECORDS; CMD / SUPER_ADMIN).
bool canManagePatientAppAccess(Staff? staff) =>
    _hasAccountType(staff, {
      AccountType.front_desk,
      AccountType.medical_records,
      AccountType.cmd,
      AccountType.super_admin,
    }) ||
    _hasRole(staff, {
      'FRONT_DESK',
      'FRONTDESK',
      'MEDICAL_RECORDS',
      'CMD',
      'SUPER_ADMIN',
    });
