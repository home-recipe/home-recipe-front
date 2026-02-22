class LoginRequest {
  final String email;
  final String password;
  final String? codeChallenge;

  LoginRequest({
    required this.email,
    required this.password,
    this.codeChallenge,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'email': email,
      'password': password,
    };
    if (codeChallenge != null) {
      json['challenge'] = codeChallenge;
    }
    return json;
  }
}

