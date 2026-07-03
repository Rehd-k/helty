import '../../models/staff_model.dart';
import '../../models/super_admin_department_preview.dart';
import '../../providers/super_admin_preview_provider.dart';

/// True when the viewer acts as head of pharmacy — either by their own role or
/// via an active super-admin "view as pharmacy head" preview. Mirrors the head
/// check used in `stock_transfer.dart`.
bool isPharmacyHead(Staff? staff, SuperAdminPreviewState preview) {
  if (staffIsSuperAdmin(staff) && preview.isActive) {
    final r = (preview.previewRole ?? '').toLowerCase().trim();
    final at = (preview.previewAccountType ?? '').toLowerCase().trim();
    return r == 'pharmacy_head' || at == 'pharmacy_head';
  }
  final r = staff?.staffRole.toLowerCase().replaceAll('-', '_') ?? '';
  final pr = staff?.pharmacyRole?.toLowerCase().replaceAll('-', '_') ?? '';
  return r == 'pharmacy_head' || pr == 'pharmacy_head';
}

/// Gate for pharmacy financial reports (profit, COGS, inventory valuation).
/// Restricted to the head of pharmacy; super admins retain access.
bool canViewPharmacyFinancialReports(Staff? staff, SuperAdminPreviewState preview) {
  if (staffIsSuperAdmin(staff)) return true;
  return isPharmacyHead(staff, preview);
}
