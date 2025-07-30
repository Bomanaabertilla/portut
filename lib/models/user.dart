class User {
  final String username;
  final String password;
  final String displayName;

  User({
    required this.username,
    required this.password,
    required this.displayName,
  });

  // Convert User to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'displayName': displayName,
    };
  }

  // Create User from Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      displayName: map['displayName'] ?? '',
    );
  }

  // Create a copy of User with updated fields
  User copyWith({
    String? username,
    String? password,
    String? displayName,
  }) {
    return User(
      username: username ?? this.username,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
    );
  }
} 