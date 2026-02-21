class LoginResponse {
  final String code;

  LoginResponse({
    required this.code,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      code: json['code'] as String? ?? '',
    );
  }
}

