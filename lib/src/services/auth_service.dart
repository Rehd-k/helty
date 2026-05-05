import 'package:dio/dio.dart';

import '../models/auth_response.dart';
import '../models/staff_model.dart';
import 'api_service.dart';

/// All authentication-related API calls.
class AuthService {
  AuthService() : _dio = ApiService().dio;
  final Dio _dio;

  // ── Login ───────────────────────────────────────────────────────────────────

  /// POST /auth/login  →  { accessToken, refreshToken?, staff }
  Future<AuthResponse> login({
    required String emailOrPhone,
    required String password,
  }) async {
    final resp = await _dio.post(
      '/auth/login',
      data: {'emailOrPhone': emailOrPhone, 'password': password},
    );
    return AuthResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Register ────────────────────────────────────────────────────────────────

  /// POST /auth/register  →  { accessToken, refreshToken?, staff }
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
    final resp = await _dio.post(
      '/staff',
      data: {
        'staffId': staffId,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
        'password': password,
        if (email != null) 'email': email,
        if (phone != null) 'phone': phone,
        if (departmentId != null) 'departmentId': departmentId,
        if (accountType != null) 'accountType': accountType.name.toUpperCase(),
      },
    );
    final raw = resp.data;
    if (raw is! Map<String, dynamic>) {
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        message: 'Register: expected a JSON object response',
      );
    }

    // Same shape as login: { accessToken, refreshToken?, staff }
    if (raw['accessToken'] is String && raw['staff'] is Map<String, dynamic>) {
      return AuthResponse.fromJson(raw);
    }

    // POST /staff often returns the created Staff only (no JWT).
    Map<String, dynamic>? staffJson;
    if (raw['staff'] is Map<String, dynamic>) {
      staffJson = raw['staff'] as Map<String, dynamic>;
    } else if (raw.containsKey('id') &&
        raw.containsKey('staffId') &&
        raw['accessToken'] == null) {
      staffJson = raw;
    }

    if (staffJson != null) {
      final trimmedEmail = email?.trim() ?? '';
      if (trimmedEmail.isNotEmpty) {
        return login(emailOrPhone: trimmedEmail, password: password);
      }
      throw DioException(
        requestOptions: resp.requestOptions,
        response: resp,
        message:
            'Account created. Add an email on registration to sign in automatically, '
            'or sign in manually once the API returns a token.',
      );
    }

    throw DioException(
      requestOptions: resp.requestOptions,
      response: resp,
      message: 'Register: unrecognized response shape',
    );
  }

  // ── Forgot / Reset Password ─────────────────────────────────────────────────

  /// POST /auth/forgot-password  →  { message }
  ///
  /// **503** — email delivery failed (SMTP configured but sending failed).
  Future<String> forgotPassword({required String email}) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/forgot-password',
      data: {'email': email.trim()},
    );
    final data = resp.data;
    return data?['message'] as String? ??
        'If an account exists for this email, a verification code has been issued.';
  }

  /// POST /auth/reset-password  with staff code flow:
  /// `{ email, code, newPassword }`
  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final resp = await _dio.post<Map<String, dynamic>>(
      '/auth/reset-password',
      data: {
        'email': email.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
      },
    );
    final data = resp.data;
    return data?['message'] as String? ?? 'Password updated.';
  }

  // ── Current Staff ───────────────────────────────────────────────────────────

  /// GET /auth/me  →  Staff (requires valid token)
  Future<Staff> getMe() async {
    final resp = await _dio.get('/auth/me');
    return Staff.fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Logout ──────────────────────────────────────────────────────────────────

  /// POST /auth/logout
  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }
}
