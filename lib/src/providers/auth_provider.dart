import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/staff_model.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';

// ── Repository provider ──────────────────────────────────────────────────────

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(AuthService());
});

// ── State ────────────────────────────────────────────────────────────────────

class AuthState {
  const AuthState({
    this.staff,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  final Staff? staff;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  bool get isAuthenticated => staff != null;

  AuthState copyWith({
    Staff? staff,
    bool clearStaff = false,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) => AuthState(
    staff: clearStaff ? null : staff ?? this.staff,
    isLoading: isLoading ?? this.isLoading,
    error: clearError ? null : error ?? this.error,
    successMessage: clearSuccess ? null : successMessage ?? this.successMessage,
  );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  // ── Login ──────────────────────────────────────────────────────────────────

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repo.login(email: email, password: password);

      state = state.copyWith(staff: response.staff, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Register ───────────────────────────────────────────────────────────────

  Future<bool> register({
    required String staffId,
    required String firstName,
    required String lastName,
    required String role,
    required String password,
    String? email,
    String? phone,
    String? departmentId,
    AccountType? accountType,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repo.register(
        staffId: staffId,
        firstName: firstName,
        lastName: lastName,
        role: role,
        password: password,
        email: email,
        phone: phone,
        departmentId: departmentId,
        accountType: accountType,
      );
      state = state.copyWith(staff: response.staff, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Forgot Password ────────────────────────────────────────────────────────

  Future<bool> forgotPassword({required String email}) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final message = await _repo.forgotPassword(email: email);
      state = state.copyWith(isLoading: false, successMessage: message);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Reset Password ─────────────────────────────────────────────────────────

  Future<bool> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final message = await _repo.resetPassword(
        token: token,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false, successMessage: message);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ── Restore session ────────────────────────────────────────────────────────

  Future<void> restoreSession() async {
    final hasToken = await _repo.isAuthenticated();
    if (!hasToken) return;
    try {
      final staff = await _repo.getMe();
      state = state.copyWith(staff: staff);
    } catch (_) {
      // Token may be expired; silently clear so guard redirects to login.
      await _repo.logout();
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);
}

// ── Providers ─────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});

/// Convenience provider to get just the current staff.
final currentStaffProvider = Provider<Staff?>((ref) {
  return ref.watch(authProvider).staff;
});
