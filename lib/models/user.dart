class User {
  final String username;
  final String password;
  final String displayName;
  final String? bio;
  final String? location;
  final String? website;
  final String? birthDate;
  final String? avatarPath;
  final String? coverPath;

  User({
    required this.username,
    required this.password,
    required this.displayName,
    this.bio,
    this.location,
    this.website,
    this.birthDate,
    this.avatarPath,
    this.coverPath,
  });

  // Convert User to Map for storage
  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'password': password,
      'displayName': displayName,
      'bio': bio,
      'location': location,
      'website': website,
      'birthDate': birthDate,
      'avatarPath': avatarPath,
      'coverPath': coverPath,
    };
  }

  // Create User from Map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      displayName: map['displayName'] ?? '',
      bio: map['bio'],
      location: map['location'],
      website: map['website'],
      birthDate: map['birthDate'],
      avatarPath: map['avatarPath'],
      coverPath: map['coverPath'],
    );
  }

  get uid => null;

  // Create a copy of User with updated fields
  User copyWith({
    String? username,
    String? password,
    String? displayName,
    String? bio,
    String? location,
    String? website,
    String? birthDate,
    String? avatarPath,
    String? coverPath,
  }) {
    return User(
      username: username ?? this.username,
      password: password ?? this.password,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      website: website ?? this.website,
      birthDate: birthDate ?? this.birthDate,
      avatarPath: avatarPath ?? this.avatarPath,
      coverPath: coverPath ?? this.coverPath,
    );
  }
}