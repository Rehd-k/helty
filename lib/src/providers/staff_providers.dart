import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/department_service.dart';
import '../services/staff_service.dart';
import '../models/staff_model.dart';

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

// ── Staff Providers ──────────────────────────────────────────────────────────

final staffServiceProvider = Provider<StaffService>((ref) => StaffService());

final staffListProvider =
    FutureProvider.family<
      List<Staff>,
      ({String? query, String? role, String? departmentId})
    >((ref, params) async {
      final service = ref.read(staffServiceProvider);
      return service.fetchStaff(
        query: params.query,
        role: params.role,
        departmentId: params.departmentId,
      );
    });

final currentStaffDetailProvider = FutureProvider.family<Staff, String>((
  ref,
  id,
) async {
  final service = ref.read(staffServiceProvider);
  return service.getStaffById(id);
});
