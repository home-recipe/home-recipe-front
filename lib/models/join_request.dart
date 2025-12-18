class JoinRequest {
  final String name;
  final String password;
  final String email;

  JoinRequest({
    required this.name,
    required this.password,
    required this.email,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'password': password,
      'email': email,
    };
  }
}




