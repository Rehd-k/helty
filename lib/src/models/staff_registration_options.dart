import 'staff_model.dart';

/// High-level department / account group shown first on registration.
/// Choosing one filters the [StaffRoleOption] list.
enum StaffAccountCategory {
  billing,
  account,
  pharmacy,
  nurse,
  physician,
  laboratory,
  radiology,
  store,
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
    StaffAccountCategory.pharmacy => 'Pharmacy',
    StaffAccountCategory.nurse => 'Nurse',
    StaffAccountCategory.physician => 'Physician',
    StaffAccountCategory.laboratory => 'Laboratory',
    StaffAccountCategory.radiology => 'Radiology',
    StaffAccountCategory.store => 'Store',
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
    required this.role,
  });

  final String label;
  final AccountType accountType;

  /// Stored as `role` on Staff; matches backend `StaffRole` (SCREAMING_SNAKE_CASE).
  final String role;
}

/// Roles available for each [StaffAccountCategory], in display order.
final Map<StaffAccountCategory, List<StaffRoleOption>> kStaffRolesByCategory = {
  StaffAccountCategory.billing: [
    const StaffRoleOption(
      label: 'Billing Head',
      accountType: AccountType.billing,
      role: 'BILLING_HEAD',
    ),
    const StaffRoleOption(
      label: 'Billing Staff',
      accountType: AccountType.billing,
      role: 'BILLING_STAFF',
    ),
  ],
  StaffAccountCategory.account: [
    const StaffRoleOption(
      label: 'Account Head',
      accountType: AccountType.accounting,
      role: 'ACCOUNT_HEAD',
    ),
    const StaffRoleOption(
      label: 'Accounting staff',
      accountType: AccountType.accounting,
      role: 'ACCOUNTING_STAFF',
    ),
  ],
  StaffAccountCategory.pharmacy: [
    const StaffRoleOption(
      label: 'Pharmacy Store',
      accountType: AccountType.pharmacy,
      role: 'PHARMACY_STORE',
    ),
    const StaffRoleOption(
      label: 'Pharmacy Dispensary',
      accountType: AccountType.pharmacy,
      role: 'PHARMACY_DISPENSARY',
    ),
    const StaffRoleOption(
      label: 'Pharmacy Head',
      accountType: AccountType.pharmacy,
      role: 'PHARMACY_HEAD',
    ),
  ],
  StaffAccountCategory.nurse: [
    const StaffRoleOption(
      label: 'Head Nurse',
      accountType: AccountType.nurse,
      role: 'HEAD_NURSE',
    ),
    const StaffRoleOption(
      label: 'Inpatient Nurse',
      accountType: AccountType.nurse,
      role: 'INPATIENT_NURSE',
    ),
    const StaffRoleOption(
      label: 'Outpatient Nurse',
      accountType: AccountType.nurse,
      role: 'OUTPATIENT_NURSE',
    ),
  ],
  StaffAccountCategory.physician: [
    const StaffRoleOption(
      label: 'Consultant',
      accountType: AccountType.physician,
      role: 'CONSULTANT',
    ),
    const StaffRoleOption(
      label: 'Resident',
      accountType: AccountType.physician,
      role: 'RESIDENT',
    ),
    const StaffRoleOption(
      label: 'Intern',
      accountType: AccountType.physician,
      role: 'INTERN',
    ),
    const StaffRoleOption(
      label: 'Junior resident',
      accountType: AccountType.physician,
      role: 'JUNIOR_RESIDENT',
    ),
    const StaffRoleOption(
      label: 'Senior resident',
      accountType: AccountType.physician,
      role: 'SENIOR_RESIDENT',
    ),
    const StaffRoleOption(
      label: 'Chief resident',
      accountType: AccountType.physician,
      role: 'CHIEF_RESIDENT',
    ),
    const StaffRoleOption(
      label: 'Medical student',
      accountType: AccountType.physician,
      role: 'MEDICAL_STUDENT',
    ),
  ],
  StaffAccountCategory.laboratory: [
    const StaffRoleOption(
      label: 'Lab Head',
      accountType: AccountType.laboratory,
      role: 'LAB_HEAD',
    ),
    const StaffRoleOption(
      label: 'Lab scientist',
      accountType: AccountType.laboratory,
      role: 'LAB_SCIENTIST',
    ),
  ],
  StaffAccountCategory.radiology: [
    const StaffRoleOption(
      label: 'Radiology Head',
      accountType: AccountType.radiology,
      role: 'RADIOLOGY_HEAD',
    ),
    const StaffRoleOption(
      label: 'Radiographer',
      accountType: AccountType.radiology,
      role: 'RADIOGRAPHER',
    ),
    const StaffRoleOption(
      label: 'Radiology receptionist',
      accountType: AccountType.radiology,
      role: 'RADIOLOGY_RECEPTIONIST',
    ),
  ],
  StaffAccountCategory.store: [
    const StaffRoleOption(
      label: 'Head of store',
      accountType: AccountType.store,
      role: 'HEAD_OF_STORE',
    ),
    const StaffRoleOption(
      label: 'Storekeeper',
      accountType: AccountType.store,
      role: 'STOREKEEPER',
    ),
  ],
  StaffAccountCategory.medicalRecords: [
    const StaffRoleOption(
      label: 'Medical Records',
      accountType: AccountType.medical_records,
      role: 'MEDICAL_RECORDS',
    ),
  ],
  StaffAccountCategory.frontDesk: [
    const StaffRoleOption(
      label: 'Front Desk',
      accountType: AccountType.front_desk,
      role: 'FRONT_DESK',
    ),
  ],
  StaffAccountCategory.ict: [
    const StaffRoleOption(
      label: 'ICT staff',
      accountType: AccountType.ict,
      role: 'ICT_STAFF',
    ),
  ],
  StaffAccountCategory.cmd: [
    const StaffRoleOption(
      label: 'CMD',
      accountType: AccountType.cmd,
      role: 'CMD',
    ),
  ],
  StaffAccountCategory.cmac: [
    const StaffRoleOption(
      label: 'CMAC',
      accountType: AccountType.cmac,
      role: 'CMAC',
    ),
  ],
  StaffAccountCategory.superAdmin: [
    const StaffRoleOption(
      label: 'Super Admin',
      accountType: AccountType.super_admin,
      role: 'SUPER_ADMIN',
    ),
  ],
};
