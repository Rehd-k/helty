import '../nursing/ward_matching.dart';
import 'staff_model.dart';

/// High-level department / account group shown first on registration.
/// Choosing one filters the [StaffRoleOption] list.
enum StaffAccountCategory {
  billing,
  account,
  hmo,
  pharmacy,
  nurse,
  physician,
  laboratory,
  radiology,
  dialysis,
  theatre,
  store,
  purchases,
  medicalRecords,
  frontDesk,
  ict,
  cmd,
  cmac,
  superAdmin,
}

extension StaffAccountCategoryLabels on StaffAccountCategory {
  String get label => switch (this) {
    StaffAccountCategory.billing => 'Billing',
    StaffAccountCategory.account => 'Account',
    StaffAccountCategory.hmo => 'HMO',
    StaffAccountCategory.pharmacy => 'Pharmacy',
    StaffAccountCategory.nurse => 'Nurse',
    StaffAccountCategory.physician => 'Physician',
    StaffAccountCategory.laboratory => 'Laboratory',
    StaffAccountCategory.radiology => 'Radiology',
    StaffAccountCategory.dialysis => 'Dialysis',
    StaffAccountCategory.theatre => 'Theatre',
    StaffAccountCategory.store => 'Store',
    StaffAccountCategory.purchases => 'Purchases',
    StaffAccountCategory.medicalRecords => 'Medical Records',
    StaffAccountCategory.frontDesk => 'Front Desk',
    StaffAccountCategory.ict => 'ICT',
    StaffAccountCategory.cmd => 'CMD',
    StaffAccountCategory.cmac => 'CMAC',
    StaffAccountCategory.superAdmin => 'Super Admin',
  };
}

/// One row in the role dropdown: UI label + values sent to `/staff`.
class StaffRoleOption {
  const StaffRoleOption({
    required this.label,
    required this.accountType,
    required this.staffRole,
  });

  final String label;
  final AccountType accountType;

  /// Stored as `staffRole` on Staff; matches backend `StaffRole` (SCREAMING_SNAKE_CASE).
  final String staffRole;
}

/// Roles available for each [StaffAccountCategory], in display order.
final Map<StaffAccountCategory, List<StaffRoleOption>> kStaffRolesByCategory = {
  StaffAccountCategory.billing: [
    const StaffRoleOption(
      label: 'Billing Head',
      accountType: AccountType.billing,
      staffRole: 'BILLING_HEAD',
    ),
    const StaffRoleOption(
      label: 'Billing Staff',
      accountType: AccountType.billing,
      staffRole: 'BILLING_STAFF',
    ),
  ],
  StaffAccountCategory.account: [
    const StaffRoleOption(
      label: 'Account Head',
      accountType: AccountType.accounting,
      staffRole: 'ACCOUNT_HEAD',
    ),
    const StaffRoleOption(
      label: 'Accounting staff',
      accountType: AccountType.accounting,
      staffRole: 'ACCOUNTING_STAFF',
    ),
  ],
  StaffAccountCategory.hmo: [
    const StaffRoleOption(
      label: 'HMO Desk',
      accountType: AccountType.hmo,
      staffRole: 'HMO_STAFF',
    ),
  ],
  StaffAccountCategory.pharmacy: [
    const StaffRoleOption(
      label: 'Pharmacy Store',
      accountType: AccountType.pharmacy,
      staffRole: 'PHARMACY_STORE',
    ),
    const StaffRoleOption(
      label: 'Pharmacy Dispensary',
      accountType: AccountType.pharmacy,
      staffRole: 'PHARMACY_DISPENSARY',
    ),
    const StaffRoleOption(
      label: 'Pharmacy Head',
      accountType: AccountType.pharmacy,
      staffRole: 'PHARMACY_HEAD',
    ),
  ],
  StaffAccountCategory.nurse: [
    const StaffRoleOption(
      label: 'Matron',
      accountType: AccountType.nurse,
      staffRole: 'MATRON',
    ),
    const StaffRoleOption(
      label: 'Ward Charge Nurse',
      accountType: AccountType.nurse,
      staffRole: 'WARD_CHARGE_NURSE',
    ),
    const StaffRoleOption(
      label: 'ICU Charge Nurse',
      accountType: AccountType.nurse,
      staffRole: 'ICU_CHARGE_NURSE',
    ),
    const StaffRoleOption(
      label: 'Emergency Charge Nurse',
      accountType: AccountType.nurse,
      staffRole: 'EMERGENCY_CHARGE_NURSE',
    ),
    const StaffRoleOption(
      label: 'OPD Charge Nurse',
      accountType: AccountType.nurse,
      staffRole: 'OPD_CHARGE_NURSE',
    ),
    const StaffRoleOption(
      label: 'O&G Charge Nurse',
      accountType: AccountType.nurse,
      staffRole: 'ONG_CHARGE_NURSE',
    ),
    const StaffRoleOption(
      label: 'Inpatient Nurse',
      accountType: AccountType.nurse,
      staffRole: 'INPATIENT_NURSE',
    ),
    const StaffRoleOption(
      label: 'Emergency Nurse',
      accountType: AccountType.nurse,
      staffRole: 'EMERGENCY_NURSE',
    ),
    const StaffRoleOption(
      label: 'ICU Nurse',
      accountType: AccountType.nurse,
      staffRole: 'ICU_NURSE',
    ),
    const StaffRoleOption(
      label: 'O&G Nurse',
      accountType: AccountType.nurse,
      staffRole: 'ONG_NURSE',
    ),
    const StaffRoleOption(
      label: 'Outpatient Nurse',
      accountType: AccountType.nurse,
      staffRole: 'OUTPATIENT_NURSE',
    ),
  ],
  StaffAccountCategory.physician: [
    const StaffRoleOption(
      label: 'Consultant',
      accountType: AccountType.physician,
      staffRole: 'CONSULTANT',
    ),
    const StaffRoleOption(
      label: 'Resident',
      accountType: AccountType.physician,
      staffRole: 'RESIDENT',
    ),
    const StaffRoleOption(
      label: 'Intern',
      accountType: AccountType.physician,
      staffRole: 'INTERN',
    ),
    const StaffRoleOption(
      label: 'Junior resident',
      accountType: AccountType.physician,
      staffRole: 'JUNIOR_RESIDENT',
    ),
    const StaffRoleOption(
      label: 'Senior resident',
      accountType: AccountType.physician,
      staffRole: 'SENIOR_RESIDENT',
    ),
    const StaffRoleOption(
      label: 'Chief resident',
      accountType: AccountType.physician,
      staffRole: 'CHIEF_RESIDENT',
    ),
    const StaffRoleOption(
      label: 'Medical student',
      accountType: AccountType.physician,
      staffRole: 'MEDICAL_STUDENT',
    ),
  ],
  StaffAccountCategory.laboratory: [
    const StaffRoleOption(
      label: 'Lab Head',
      accountType: AccountType.laboratory,
      staffRole: 'LAB_HEAD',
    ),
    const StaffRoleOption(
      label: 'Lab scientist',
      accountType: AccountType.laboratory,
      staffRole: 'LAB_SCIENTIST',
    ),
  ],
  StaffAccountCategory.radiology: [
    const StaffRoleOption(
      label: 'Radiology Head',
      accountType: AccountType.radiology,
      staffRole: 'RADIOLOGY_HEAD',
    ),
    const StaffRoleOption(
      label: 'Radiographer',
      accountType: AccountType.radiology,
      staffRole: 'RADIOGRAPHER',
    ),
    const StaffRoleOption(
      label: 'Radiology receptionist',
      accountType: AccountType.radiology,
      staffRole: 'RADIOLOGY_RECEPTIONIST',
    ),
  ],
  StaffAccountCategory.dialysis: [
    const StaffRoleOption(
      label: 'Dialysis Head',
      accountType: AccountType.dialysis,
      staffRole: 'DIALYSIS_HEAD',
    ),
    const StaffRoleOption(
      label: 'Dialysis Nurse',
      accountType: AccountType.dialysis,
      staffRole: 'DIALYSIS_NURSE',
    ),
    const StaffRoleOption(
      label: 'Dialysis Technician',
      accountType: AccountType.dialysis,
      staffRole: 'DIALYSIS_TECH',
    ),
    const StaffRoleOption(
      label: 'Dialysis Receptionist',
      accountType: AccountType.dialysis,
      staffRole: 'DIALYSIS_RECEPTIONIST',
    ),
  ],
  StaffAccountCategory.theatre: [
    const StaffRoleOption(
      label: 'Theatre Head',
      accountType: AccountType.theatre,
      staffRole: 'THEATRE_HEAD',
    ),
    const StaffRoleOption(
      label: 'Theatre Staff',
      accountType: AccountType.theatre,
      staffRole: 'THEATRE',
    ),
    const StaffRoleOption(
      label: 'Theatre Nurse',
      accountType: AccountType.theatre,
      staffRole: 'THEATRE_NURSE',
    ),
    const StaffRoleOption(
      label: 'Theatre Scrub',
      accountType: AccountType.theatre,
      staffRole: 'THEATRE_SCRUB',
    ),
    const StaffRoleOption(
      label: 'Theatre Anaesthetist',
      accountType: AccountType.theatre,
      staffRole: 'THEATRE_ANAESTHETIST',
    ),
    const StaffRoleOption(
      label: 'Theatre Receptionist',
      accountType: AccountType.theatre,
      staffRole: 'THEATRE_RECEPTIONIST',
    ),
  ],
  StaffAccountCategory.store: [
    const StaffRoleOption(
      label: 'Head of store',
      accountType: AccountType.store,
      staffRole: 'HEAD_OF_STORE',
    ),
    const StaffRoleOption(
      label: 'Storekeeper',
      accountType: AccountType.store,
      staffRole: 'STOREKEEPER',
    ),
  ],
  StaffAccountCategory.purchases: [
    const StaffRoleOption(
      label: 'Purchases Store',
      accountType: AccountType.purchases,
      staffRole: 'PURCHASES_STORE',
    ),
    const StaffRoleOption(
      label: 'Purchases Head',
      accountType: AccountType.purchases,
      staffRole: 'PURCHASES_HEAD',
    ),
  ],
  StaffAccountCategory.medicalRecords: [
    const StaffRoleOption(
      label: 'Medical Records',
      accountType: AccountType.medical_records,
      staffRole: 'MEDICAL_RECORDS',
    ),
  ],
  StaffAccountCategory.frontDesk: [
    const StaffRoleOption(
      label: 'Front Desk',
      accountType: AccountType.front_desk,
      staffRole: 'FRONT_DESK',
    ),
  ],
  StaffAccountCategory.ict: [
    const StaffRoleOption(
      label: 'ICT staff',
      accountType: AccountType.ict,
      staffRole: 'ICT_STAFF',
    ),
  ],
  StaffAccountCategory.cmd: [
    const StaffRoleOption(
      label: 'CMD',
      accountType: AccountType.cmd,
      staffRole: 'CMD',
    ),
  ],
  StaffAccountCategory.cmac: [
    const StaffRoleOption(
      label: 'CMAC',
      accountType: AccountType.cmac,
      staffRole: 'CMAC',
    ),
  ],
  StaffAccountCategory.superAdmin: [
    const StaffRoleOption(
      label: 'Super Admin',
      accountType: AccountType.super_admin,
      staffRole: 'SUPER_ADMIN',
    ),
  ],
};

String _normalizeStaffRole(String role) =>
    role.trim().toLowerCase().replaceAll('-', '_');

/// Validates nursing role + ward/department pairing for staff create/update.
String? validateNursingStaffAssignment({
  required String staffRole,
  String? departmentId,
  String? wardId,
}) {
  final r = staffRole.trim().toUpperCase().replaceAll('-', '_');
  if (r == 'HEAD_NURSE' || r == 'MATRON') {
    if (departmentId != null && departmentId.trim().isNotEmpty) {
      return 'Matron must not be assigned to a department';
    }
    if (wardId != null && wardId.trim().isNotEmpty) {
      return 'Matron must not be assigned to a single ward';
    }
    return null;
  }
  if (isChargeNurseStaffRole(r)) {
    if (departmentId != null && departmentId.trim().isNotEmpty) {
      return 'Charge nurse roles must use wardId, not departmentId';
    }
    if (wardId == null || wardId.trim().isEmpty) {
      return 'Charge nurse role $r requires wardId';
    }
  }
  return null;
}

StaffAccountCategory? accountCategoryForAccountType(AccountType? accountType) {
  if (accountType == null) return null;
  return switch (accountType) {
    AccountType.billing => StaffAccountCategory.billing,
    AccountType.accounting => StaffAccountCategory.account,
    AccountType.hmo => StaffAccountCategory.hmo,
    AccountType.pharmacy => StaffAccountCategory.pharmacy,
    AccountType.nurse => StaffAccountCategory.nurse,
    AccountType.physician => StaffAccountCategory.physician,
    AccountType.laboratory => StaffAccountCategory.laboratory,
    AccountType.radiology => StaffAccountCategory.radiology,
    AccountType.dialysis => StaffAccountCategory.dialysis,
    AccountType.theatre => StaffAccountCategory.theatre,
    AccountType.store => StaffAccountCategory.store,
    AccountType.purchases => StaffAccountCategory.purchases,
    AccountType.medical_records => StaffAccountCategory.medicalRecords,
    AccountType.front_desk => StaffAccountCategory.frontDesk,
    AccountType.ict => StaffAccountCategory.ict,
    AccountType.cmd => StaffAccountCategory.cmd,
    AccountType.cmac => StaffAccountCategory.cmac,
    AccountType.super_admin => StaffAccountCategory.superAdmin,
    AccountType.staff => StaffAccountCategory.frontDesk,
  };
}

List<StaffRoleOption> rolesForAccountType(AccountType accountType) {
  final category = accountCategoryForAccountType(accountType);
  if (category == null) return const [];
  return kStaffRolesByCategory[category] ?? const [];
}

AccountType resolveStaffAccountType(Staff staff) {
  if (staff.accountType != null && staff.accountType!.isDepartmentType) {
    return staff.accountType!;
  }

  final normalizedRole = _normalizeStaffRole(staff.staffRole);
  for (final entry in kStaffRolesByCategory.entries) {
    for (final option in entry.value) {
      if (_normalizeStaffRole(option.staffRole) == normalizedRole) {
        return option.accountType;
      }
    }
  }

  return AccountType.front_desk;
}

/// Resolves account type + role dropdown values for an existing [Staff].
({AccountType accountType, StaffRoleOption role}) resolveStaffRoleSelection(
  Staff staff,
) {
  final normalizedRole = _normalizeStaffRole(staff.staffRole);

  if (normalizedRole == 'head_nurse') {
    final matron = kStaffRolesByCategory[StaffAccountCategory.nurse]!
        .firstWhere((o) => o.staffRole == 'MATRON');
    return (accountType: AccountType.nurse, role: matron);
  }

  for (final entry in kStaffRolesByCategory.entries) {
    for (final option in entry.value) {
      if (_normalizeStaffRole(option.staffRole) == normalizedRole) {
        final accountType =
            staff.accountType != null && staff.accountType!.isDepartmentType
            ? staff.accountType!
            : option.accountType;
        return (accountType: accountType, role: option);
      }
    }
  }

  final accountType = resolveStaffAccountType(staff);
  final roles = rolesForAccountType(accountType);
  return (
    accountType: accountType,
    role: roles.isNotEmpty
        ? roles.first
        : kStaffRolesByCategory[StaffAccountCategory.frontDesk]!.first,
  );
}
