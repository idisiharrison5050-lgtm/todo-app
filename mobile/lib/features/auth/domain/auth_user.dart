class AuthUser {
  const AuthUser({required this.id, required this.name, required this.email, this.token});

  final int id;
  final String name;
  final String email;
  final String? token;

  factory AuthUser.fromJson(Map<String, dynamic> json, {String? token}) {
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      token: token,
    );
  }
}
