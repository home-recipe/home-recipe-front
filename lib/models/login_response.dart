import 'role.dart';

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final Role role;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String? ?? json['access_token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? json['refresh_token'] as String? ?? '',
      role: Role.fromString(json['role'] as String? ?? 'USER'),
    );
  }
}

