import '../core/storage/token_storage.dart';
import '../models/auth_response.dart';
import '../models/staff_model.dart';
import '../services/auth_service.dart';

/// Orchestrates AuthService calls + token persistence.
/// This is the single source of truth a provider should talk to.
class AuthRepository {
  AuthRepository(this._authService);

  final AuthService _authService;

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _authService.login(email: email, password: password);
    await _persist(response);
    return response;
  }

  Future<AuthResponse> register({
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
    final response = await _authService.register(
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
    await _persist(response);
    return response;
  }

  Future<String> forgotPassword({required String email}) =>
      _authService.forgotPassword(email: email);

  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) => _authService.resetPassword(token: token, newPassword: newPassword);

  Future<Staff> getMe() => _authService.getMe();

  Future<void> logout() async {
    try {
      await _authService.logout();
    } catch (_) {
      // Best-effort — always clear tokens locally.
    } finally {
      await TokenStorage.clearAll();
    }
  }

  Future<bool> isAuthenticated() => TokenStorage.hasToken();

  // ── Private ─────────────────────────────────────────────────────────────────

  Future<void> _persist(AuthResponse response) async {
    await TokenStorage.saveAccessToken(response.accessToken);
    if (response.refreshToken != null) {
      await TokenStorage.saveRefreshToken(response.refreshToken!);
    }
  }
}
