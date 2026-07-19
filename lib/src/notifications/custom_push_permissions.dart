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

/// Staff who may call `POST /notifications/custom` (CMAC / CMD / SUPER_ADMIN).
bool canSendCustomPatientPush(Staff? staff) =>
    _hasAccountType(staff, {
      AccountType.cmac,
      AccountType.cmd,
      AccountType.super_admin,
    }) ||
    _hasRole(staff, {'CMAC', 'CMD', 'SUPER_ADMIN'});
