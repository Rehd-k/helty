import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_exception.dart';
import '../models/staff_model.dart';
import '../repositories/auth_repository.dart';
import '../services/auth_service.dart';

String authFlowErrorMessage(Object e) {
  if (e is DioException) {
    final inner = e.error;
    if (inner is AppException) return inner.message;
  }
  if (e is AppException) return e.message;
  return e.toString();
}

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

  Future<bool> login({
    required String emailOrPhone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repo.login(
        emailOrPhone: emailOrPhone,
        password: password,
      );

      state = state.copyWith(staff: response.staff, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: authFlowErrorMessage(e));
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
      state = state.copyWith(isLoading: false, error: authFlowErrorMessage(e));
      return false;
    }
  }

  // ── Forgot Password ────────────────────────────────────────────────────────

  /// Returns the API message on success, or `null` on failure ([state.error] set).
  ///
  /// When [manageLoading] is false, [AuthState.isLoading] is unchanged (e.g. “Request new code”
  /// from the reset screen should not disable the main submit button).
  Future<String?> forgotPassword({
    required String email,
    bool manageLoading = true,
  }) async {
    state = state.copyWith(
      isLoading: manageLoading ? true : state.isLoading,
      clearError: true,
      clearSuccess: true,
    );
    try {
      final message = await _repo.forgotPassword(email: email);
      if (manageLoading) {
        state = state.copyWith(isLoading: false);
      }
      return message;
    } catch (e) {
      final code = e is DioException ? e.response?.statusCode : null;
      final msg = code == 503
          ? 'We could not send email right now. Please try again in a few minutes.'
          : authFlowErrorMessage(e);
      state = state.copyWith(
        isLoading: manageLoading ? false : state.isLoading,
        error: msg,
      );
      return null;
    }
  }

  // ── Reset Password ─────────────────────────────────────────────────────────

  Future<bool> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearSuccess: true,
    );
    try {
      await _repo.resetPassword(
        email: email,
        code: code,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final isInvalidCode = e is DioException &&
          (e.response?.statusCode == 401 || e.error is UnauthorizedException);
      final msg = isInvalidCode
          ? 'Invalid or expired code. Request a new code from your administrator.'
          : authFlowErrorMessage(e);
      state = state.copyWith(isLoading: false, error: msg);
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
