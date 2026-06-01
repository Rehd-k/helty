import 'package:helty/src/models/staff_model.dart';

/// Role helpers for ED board action visibility.
class EdRoleHelper {
  EdRoleHelper._();

  static bool canRegister(AccountType? type) {
    if (type == null) return false;
    return type == AccountType.front_desk ||
        type == AccountType.nurse ||
        type == AccountType.medical_records ||
        type == AccountType.physician ||
        type == AccountType.super_admin;
  }

  static bool canTriage(AccountType? type) {
    if (type == null) return false;
    return type == AccountType.nurse ||
        type == AccountType.physician ||
        type == AccountType.super_admin;
  }

  static bool canOpenDoctorWorkspace(AccountType? type) {
    if (type == null) return false;
    return type == AccountType.physician ||
        type == AccountType.super_admin;
  }

  static bool canDisposition(AccountType? type) {
    return canOpenDoctorWorkspace(type);
  }

  static bool isNurseOrFrontDesk(AccountType? type) {
    if (type == null) return false;
    return type == AccountType.nurse ||
        type == AccountType.front_desk ||
        type == AccountType.medical_records;
  }
}
