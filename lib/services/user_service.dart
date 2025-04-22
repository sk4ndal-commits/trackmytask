import 'package:trackmytasks/models/user.dart';
import 'package:trackmytasks/services/database_service.dart';
import 'package:trackmytasks/services/auth_service.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  static UserService get instance => _instance;

  UserService._internal();

  final DatabaseService _databaseService = DatabaseService.instance;
  final AuthService _authService = AuthService.instance;

  // Get the current logged-in user from AuthService
  User? get currentUser => _authService.currentUser;

  // Check if a user is logged in using AuthService
  bool get isLoggedIn => _authService.isLoggedIn;

  // Get all users
  Future<List<User>> getAllUsers() async {
    return await _databaseService.getUsers();
  }

  // Get user by ID
  Future<User?> getUserById(int id) async {
    return await _databaseService.getUser(id);
  }

  // Update user profile - delegates to AuthService
  Future<User> updateProfile(User updatedUser) async {
    return await _authService.updateProfile(updatedUser);
  }
}
