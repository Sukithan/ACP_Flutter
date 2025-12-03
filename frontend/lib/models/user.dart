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
      id: json['id'],
      name: json['name'],
      email: json['email'],
      roles: json['roles'] != null
          ? List<String>.from(json['roles'].map((role) => role['name'] ?? role))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'roles': roles};
  }

  bool hasRole(String role) {
    return roles.contains(role);
  }
}
