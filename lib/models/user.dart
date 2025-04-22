class User {
  final int? id;
  final String name;
  final String email;
  final String? password;
  final String? profilePicture;
  final DateTime createdAt;

  User({
    this.id,
    required this.name,
    required this.email,
    this.password,
    this.profilePicture,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Create a User from a map (for database operations)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      name: map['name'],
      email: map['email'],
      password: map['password'],
      profilePicture: map['profilePicture'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  // Convert a User to a map (for database operations)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'password': password,
      'profilePicture': profilePicture,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create a copy of this User with the given fields replaced with the new values
  User copyWith({
    int? id,
    String? name,
    String? email,
    String? password,
    String? profilePicture,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      profilePicture: profilePicture ?? this.profilePicture,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
