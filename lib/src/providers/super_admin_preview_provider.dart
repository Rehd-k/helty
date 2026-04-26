import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/staff_model.dart';
import '../models/super_admin_department_preview.dart';

class SuperAdminPreviewState {
  const SuperAdminPreviewState({
    this.previewAccountType,
    this.previewRole,
    this.previewBannerLabel,
  });

  final String? previewAccountType;
  final String? previewRole;
  final String? previewBannerLabel;

  bool get isActive =>
      previewAccountType != null &&
      previewRole != null &&
      previewBannerLabel != null;
}

class SuperAdminPreviewNotifier extends StateNotifier<SuperAdminPreviewState> {
  SuperAdminPreviewNotifier() : super(const SuperAdminPreviewState());

  /// Client-only “view as” for shell navigation; only applies to super admins.
  void setPreview(
    Staff? staff, {
    required String accountType,
    required String role,
    required String bannerLabel,
  }) {
    if (!staffIsSuperAdmin(staff)) return;
    state = SuperAdminPreviewState(
      previewAccountType: accountType.toLowerCase().trim(),
      previewRole: role.toLowerCase().trim(),
      previewBannerLabel: bannerLabel,
    );
  }

  void clear() {
    state = const SuperAdminPreviewState();
  }
}

final superAdminPreviewProvider =
    StateNotifierProvider<SuperAdminPreviewNotifier, SuperAdminPreviewState>(
      (ref) => SuperAdminPreviewNotifier(),
    );
