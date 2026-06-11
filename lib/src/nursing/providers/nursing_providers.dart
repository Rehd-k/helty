import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/nursing_permissions.dart';
import '../../models/staff_model.dart';
import '../../providers/auth_provider.dart';
import '../models/nursing_models.dart';
import '../services/nursing_api_service.dart';

final nursingApiServiceProvider = Provider<NursingApiService>((ref) {
  return NursingApiService();
});

/// Cached nursing bootstrap from `GET /nurses/dashboard/me`.
class NursingBootstrapNotifier extends StateNotifier<AsyncValue<NursingDashboardMe?>> {
  NursingBootstrapNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> load() async {
    final staff = _ref.read(authProvider).staff;
    if (!isNursingStaff(staff)) {
      state = const AsyncValue.data(null);
      return;
    }
    state = const AsyncValue.loading();
    try {
      final service = _ref.read(nursingApiServiceProvider);
      final me = await service.fetchMe();
      state = AsyncValue.data(me);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void clear() {
    state = const AsyncValue.data(null);
  }
}

final nursingBootstrapProvider =
    StateNotifierProvider<NursingBootstrapNotifier, AsyncValue<NursingDashboardMe?>>(
  (ref) {
    final notifier = NursingBootstrapNotifier(ref);
    ref.listen<Staff?>(currentStaffProvider, (prev, next) {
      if (next == null) {
        notifier.clear();
      } else if (isNursingStaff(next) &&
          (prev?.id != next.id || prev == null)) {
        notifier.load();
      }
    });
    final staff = ref.read(currentStaffProvider);
    if (isNursingStaff(staff)) {
      Future.microtask(notifier.load);
    }
    return notifier;
  },
);

/// Convenience: current bootstrap data (null if not loaded or not nurse).
final nursingBootstrapDataProvider = Provider<NursingDashboardMe?>((ref) {
  return ref.watch(nursingBootstrapProvider).valueOrNull;
});
