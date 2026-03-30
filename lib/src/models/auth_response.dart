import 'staff_model.dart';

/// Response returned by /auth/login and /auth/register.
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.staff,
    this.refreshToken,
  });

  final String accessToken;
  final String? refreshToken;
  final Staff staff;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final token = json['accessToken'] as String?;
    if (token == null || token.isEmpty) {
      throw FormatException(
        'AuthResponse: missing accessToken (expected login-shaped envelope)',
      );
    }
    final staffRaw = json['staff'];
    if (staffRaw is! Map<String, dynamic>) {
      throw FormatException('AuthResponse: missing or invalid staff object');
    }
    return AuthResponse(
      accessToken: token,
      refreshToken: json['refreshToken'] != null
          ? json['refreshToken'] as String
          : null,
      staff: Staff.fromJson(staffRaw),
    );
  }
}
