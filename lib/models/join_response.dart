class JoinResponse {
  final String name;
  final String email;
  final String role;

  JoinResponse({
    required this.name,
    required this.email,
    required this.role,
  });

  factory JoinResponse.fromJson(Map<String, dynamic> json) {
    return JoinResponse(
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
    );
  }
}




