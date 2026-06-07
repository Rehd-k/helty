import 'staff_model.dart';
import 'staff_registration_options.dart';

/// Whether the signed-in user is a super admin (navigation preview allowed).
bool staffIsSuperAdmin(Staff? staff) {
  if (staff == null) return false;
  if (staff.accountType == AccountType.super_admin) return true;
  final r = staff.staffRole.trim().toLowerCase().replaceAll('-', '_');
  return r == 'super_admin';
}

/// One department tile on the Super Admin hub: preview uses leadership-style role
/// where defined in [kStaffRolesByCategory].
class SuperAdminHubDepartment {
  const SuperAdminHubDepartment({
    required this.category,
    required this.tileTitle,
    required this.previewAccountType,
    required this.previewRole,
    required this.previewBannerLabel,
  });

  final StaffAccountCategory category;
  final String tileTitle;

  /// Values passed to shell menu + [initialRouteForRole] (API-style lowercase).
  final String previewAccountType;
  final String previewRole;

  /// Shown in the preview banner (e.g. "Billing (Head)").
  final String previewBannerLabel;
}

/// All account groups except [StaffAccountCategory.superAdmin], in hub display order.
const List<SuperAdminHubDepartment> kSuperAdminHubDepartments = [
  SuperAdminHubDepartment(
    category: StaffAccountCategory.billing,
    tileTitle: 'Billing',
    previewAccountType: 'billing',
    previewRole: 'billing_head',
    previewBannerLabel: 'Billing (Head)',
  ),
  SuperAdminHubDepartment(
    category: StaffAccountCategory.account,
    tileTitle: 'Accounts & Audit',
    previewAccountType: 'accounting',
    previewRole: 'account_head',
    previewBannerLabel: 'Accounts & Audit (Head)',
  ),
  SuperAdminHubDepartment(
    category: StaffAccountCategory.hmo,
    tileTitle: 'HMO Desk',
    previewAccountType: 'hmo',
    previewRole: 'hmo_staff',
    previewBannerLabel: 'HMO Desk',
  ),
  SuperAdminHubDepartment(
    category: StaffAccountCategory.pharmacy,
    tileTitle: 'Pharmacy',
    previewAccountType: 'pharmacy',
    previewRole: 'pharmacy_head',
    previewBannerLabel: 'Pharmacy (Head)',
  ),
  SuperAdminHubDepartment(
    category: StaffAccountCategory.nurse,
    tileTitle: 'Nurse',
    previewAccountType: 'nurse',
    previewRole: 'head_nurse',
    previewBannerLabel: 'Nursing (Head)',
  ),
  SuperAdminHubDepartment(
    category: StaffAccountCategory.physician,
    tileTitle: 'Physician',
    previewAccountType: 'physician',
    previewRole: 'consultant',
    previewBannerLabel: 'Physician (Consultant)',
  ),
  SuperAdminHubDepartment(
    category: StaffAccountCategory.laboratory,
    tileTitle: 'Laboratory',
    previewAccountType: 'laboratory',
    previewRole: 'lab_head',
    previewBannerLabel: 'Laboratory (Head)',
  ),
  SuperAdminHubDepartment(
    category: StaffAccountCategory.radiology,
    tileTitle: 'Radiology',
    previewAccountType: 'radiology',
    previewRole: 'radiology_head',
    previewBannerLabel: 'Radiology (Head)',
  ),
  SuperAdminHubDepartment(
    category: StaffAccountCategory.dialysis,
    tileTitle: 'Dialysis',
    previewAccountType: 'dialysis',
    previewRole: 'dialysis_head',
    previewBannerLabel: 'Dialysis (Head)',
  ),
  SuperAdminHubDepartment(
    category: StaffAccountCategory.store,
    tileTitle: 'Store',
    previewAccountType: 'store',
    previewRole: 'head_of_store',
    previewBannerLabel: 'Store (Head)',
  ),
  SuperAdminHubDepartment(
    category: StaffAccountCategory.purchases,
    tileTitle: 'Purchases',
    previewAccountType: 'purchases',
    previewRole: 'purchases_head',
    previewBannerLabel: 'Purchases (Head)',
  ),
  SuperAdminHubDepartment(
    category: StaffAccountCategory.medicalRecords,
    tileTitle: 'Medical Records',
    previewAccountType: 'medical_records',
    previewRole: 'medical_records',
    previewBannerLabel: 'Medical Records',
  ),
  SuperAdminHubDepartment(
    category: StaffAccountCategory.frontDesk,
    tileTitle: 'Front Desk',
    previewAccountType: 'front_desk',
    previewRole: 'front_desk',
    previewBannerLabel: 'Front Desk',
  ),
  SuperAdminHubDepartment(
    category: StaffAccountCategory.ict,
    tileTitle: 'ICT',
    previewAccountType: 'ict',
    previewRole: 'ict_staff',
    previewBannerLabel: 'ICT',
  ),
  SuperAdminHubDepartment(
    category: StaffAccountCategory.cmd,
    tileTitle: 'CMD',
    previewAccountType: 'cmd',
    previewRole: 'cmd',
    previewBannerLabel: 'CMD',
  ),
  SuperAdminHubDepartment(
    category: StaffAccountCategory.cmac,
    tileTitle: 'CMAC',
    previewAccountType: 'cmac',
    previewRole: 'cmac',
    previewBannerLabel: 'CMAC',
  ),
];
