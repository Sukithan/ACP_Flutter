class User {
  final int id;
  final String name;
  final String email;
  final List<String> roles;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      roles: json['roles'] != null
          ? List<String>.from(
              json['roles'].map(
                (role) => (role is Map)
                    ? (role['name']?.toString() ?? '')
                    : role.toString(),
              ),
            )
          : [],
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is double) return value.toInt();
    return null;
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'roles': roles};
  }

  bool hasRole(String role) {
    return roles.contains(role);
  }
}
