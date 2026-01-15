import 'role.dart';

class AdminUserResponse {
  final int id;
  final String name;
  final String email;
  final Role role;

  AdminUserResponse({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory AdminUserResponse.fromJson(Map<String, dynamic> json) {
    return AdminUserResponse(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: Role.fromString(json['role'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toJson(),
    };
  }
}
