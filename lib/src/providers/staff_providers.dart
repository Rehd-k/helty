import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/staff_model.dart';
import '../models/ward_models.dart';
import '../services/department_service.dart';
import '../services/staff_service.dart';
import '../services/ward_service.dart';

// ── Department Providers ─────────────────────────────────────────────────────

final departmentServiceProvider = Provider<DepartmentService>(
  (ref) => DepartmentService(),
);

final departmentListProvider = FutureProvider.family<List<Department>, String?>(
  (ref, query) async {
    final service = ref.read(departmentServiceProvider);
    return service.fetchDepartments(query: query);
  },
);

final wardServiceProvider = Provider<WardService>((ref) => WardService());

final wardListProvider = FutureProvider<List<Ward>>((ref) async {
  final service = ref.read(wardServiceProvider);
  return service.fetchWards();
});

// ── Staff Providers ──────────────────────────────────────────────────────────

final staffServiceProvider = Provider<StaffService>((ref) => StaffService());

final staffListProvider =
    FutureProvider.family<
      List<Staff>,
      ({String? query, String? staffRole, String? departmentId, int limit})
    >((ref, params) async {
      final service = ref.read(staffServiceProvider);
      return service.fetchStaff(
        query: params.query,
        staffRole: params.staffRole,
        departmentId: params.departmentId,
        limit: params.limit,
      );
    });

final currentStaffDetailProvider = FutureProvider.family<Staff, String>((
  ref,
  id,
) async {
  final service = ref.read(staffServiceProvider);
  return service.getStaffById(id);
});
