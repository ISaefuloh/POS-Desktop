class User {
  final int? id;
  final String name;
  final String username;
  final String role;
  final String? password; // nullable

  User({
    this.id,
    required this.name,
    required this.username,
    required this.role,
    this.password,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      username: json['username'],
      role: json['role'],
      // password tidak ada di response, jadi tidak diambil
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'username': username,
      'password': password, // dipakai saat create/login
      'role': role,
    };
  }
}
