import 'package:trackmytasks/models/user.dart';
import 'package:trackmytasks/services/database_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  static AuthService get instance => _instance;

  AuthService._internal();

  final DatabaseService _databaseService = DatabaseService.instance;

  User? _currentUser;

  // Get the current logged-in user
  User? get currentUser => _currentUser;

  // Check if a user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Register a new user
  Future<User> register(String name, String email, String password, {String? profilePicture}) async {
    // Check if user with this email already exists
    final existingUser = await _databaseService.getUserByEmail(email);
    if (existingUser != null) {
      throw Exception('User with this email already exists');
    }

    // Create a new user
    final user = User(
      name: name,
      email: email,
      password: password,
      profilePicture: profilePicture,
    );

    // Insert the user into the database
    final userId = await _databaseService.insertUser(user);

    // Return the user with the assigned ID
    final createdUser = user.copyWith(id: userId);
    _currentUser = createdUser;
    return createdUser;
  }

  // Login a user with email and password
  Future<User> login(String email, String password) async {
    final user = await _databaseService.getUserByEmail(email);
    if (user == null) {
      throw Exception('User not found');
    }

    if (user.password != password) {
      throw Exception('Invalid password');
    }

    _currentUser = user;
    return user;
  }

  // Logout the current user
  void logout() {
    _currentUser = null;
  }

  // Update user profile
  Future<User> updateProfile(User updatedUser) async {
    if (_currentUser == null) {
      throw Exception('No user is logged in');
    }

    await _databaseService.updateUser(updatedUser);
    _currentUser = updatedUser;
    return updatedUser;
  }

  // Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    final user = await _databaseService.getUserByEmail(email);
    if (user == null) {
      throw Exception('User not found');
    }

    // In a real app, this would send an actual email with a reset link
    // For this demo, we'll just simulate the email being sent
    return true;
  }

  // Reset password using email verification (called after email verification)
  Future<bool> resetPassword(String email, String newPassword) async {
    final user = await _databaseService.getUserByEmail(email);
    if (user == null) {
      throw Exception('User not found');
    }

    final updatedUser = user.copyWith(password: newPassword);
    await _databaseService.updateUser(updatedUser);
    return true;
  }
}
