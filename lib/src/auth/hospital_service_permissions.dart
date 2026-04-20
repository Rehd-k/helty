import '../models/staff_model.dart';

/// Who may create, update, or delete rows in the hospital [Service] catalog
/// (System Setup → Services, Add Service screen, etc.).
///
/// Billing staff and similar roles can bill services but must not edit the catalog.
bool canManageHospitalServices(Staff? staff) {
  if (staff == null) return false;
  final r = staff.role.trim().toLowerCase().replaceAll('-', '_');
  if (r == 'super_admin' ||
      r == 'billing_head' ||
      r == 'accounting_head' ||
      r == 'account_head') {
    return true;
  }
  if (staff.accountType == AccountType.super_admin) return true;
  return false;
}
