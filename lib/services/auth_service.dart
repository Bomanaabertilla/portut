import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class AuthService {
  static const String _usersKey = 'users';
  static const String _currentUserKey = 'current_user';

  // Get all registered users
  Future<List<User>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getStringList(_usersKey) ?? [];
    
    return usersJson
        .map((userJson) => User.fromMap(json.decode(userJson)))
        .toList();
  }

  // Register a new user
  Future<bool> registerUser(User user) async {
    try {
      final users = await getUsers();
      
      // Check if username already exists
      if (users.any((existingUser) => existingUser.username == user.username)) {
        return false; // Username already exists
      }

      // Validate password (at least 6 characters)
      if (user.password.length < 6) {
        return false; // Password too short
      }

      // Add new user
      users.add(user);
      
      // Save updated users list
      final prefs = await SharedPreferences.getInstance();
      final usersJson = users.map((u) => json.encode(u.toMap())).toList();
      await prefs.setStringList(_usersKey, usersJson);
      
      return true; // Registration successful
    } catch (e) {
      print('Error registering user: $e');
      return false;
    }
  }

  // Login user
  Future<User?> loginUser(String username, String password) async {
    try {
      final users = await getUsers();
      
      final user = users.firstWhere(
        (u) => u.username == username && u.password == password,
        orElse: () => throw Exception('User not found'),
      );

      // Save current user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserKey, json.encode(user.toMap()));
      
      return user;
    } catch (e) {
      return null; // Login failed
    }
  }

  // Get current logged in user
  Future<User?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_currentUserKey);
      
      if (userJson != null) {
        return User.fromMap(json.decode(userJson));
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user profile details & avatar/cover paths
  Future<bool> updateUserProfile(User updatedUser) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final users = await getUsers();
      final index = users.indexWhere((u) => u.username == updatedUser.username);
      if (index != -1) {
        users[index] = updatedUser;
        final usersJson = users.map((u) => json.encode(u.toMap())).toList();
        await prefs.setStringList(_usersKey, usersJson);
      }
      await prefs.setString(_currentUserKey, json.encode(updatedUser.toMap()));
      return true;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }

  // Logout user
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
  }

  // Check if username exists
  Future<bool> isUsernameTaken(String username) async {
    final users = await getUsers();
    return users.any((user) => user.username == username);
  }

  // Validate password requirements (at least 8 chars, 1 uppercase, 1 lowercase, 1 digit, 1 special char)
  bool validatePassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password);
  }
}