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

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] != null ? json['refreshToken'] as String : null,
    staff: Staff.fromJson(json['staff'] as Map<String, dynamic>),
  );
}
