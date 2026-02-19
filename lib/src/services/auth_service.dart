import 'dart:developer';

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
    required String email,
    required String password,
  }) async {
    final resp = await _dio.post(
      '/auth/login',
      data: {'email': email, 'password': password},
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
        if (accountType != null) 'accountType': accountType.name,
      },
    );
    return AuthResponse.fromJson(resp.data as Map<String, dynamic>);
  }

  // ── Forgot / Reset Password ─────────────────────────────────────────────────

  /// POST /auth/forgot-password  →  { message }
  Future<String> forgotPassword({required String email}) async {
    final resp = await _dio.post(
      '/auth/forgot-password',
      data: {'email': email},
    );
    final data = resp.data as Map<String, dynamic>;
    return data['message'] as String? ?? 'Reset link sent.';
  }

  /// POST /auth/reset-password  →  { message }
  Future<String> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final resp = await _dio.post(
      '/auth/reset-password',
      data: {'token': token, 'password': newPassword},
    );
    final data = resp.data as Map<String, dynamic>;
    return data['message'] as String? ?? 'Password updated.';
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
