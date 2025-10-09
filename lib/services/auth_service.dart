import '../models/user.dart';
import '../database/database_helper.dart';
import 'dart:developer' as developer;

class AuthService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  Future<User?> login(String email, String password) async {
    developer.log('🔐 Login attempt: $email');

    final isValid = await _dbHelper.validateUser(email, password);
    if (isValid) {
      final user = await _dbHelper.getUserByEmail(email);
      developer.log('✅ Login successful: ${user?.name}');
      return user;
    }

    developer.log('❌ Login failed for: $email');
    return null;
  }

  Future<User?> register(User user) async {
    try {
      developer.log('📝 Registration attempt: ${user.email}');

      // Vérifier si l'utilisateur existe déjà
      final existingUser = await _dbHelper.getUserByEmail(user.email);
      if (existingUser != null) {
        developer.log('❌ User already exists: ${user.email}');
        throw Exception('Un utilisateur avec cet email existe déjà');
      }

      // Insérer le nouvel utilisateur
      final userId = await _dbHelper.insertUser(user);
      developer.log('✅ User registered with ID: $userId');

      // Récupérer l'utilisateur créé
      final newUser = await _dbHelper.getUserById(userId);
      developer.log('👤 New user details: ${newUser?.name}');

      return newUser;
    } catch (e) {
      developer.log('❌ Registration error: $e');
      throw Exception('Erreur lors de l\'inscription: $e');
    }
  }
  Future<void> logout() async {
    developer.log('🚪 User logged out');
    // Clear any session data if needed
  }

  Future<User?> getCurrentUser() async {
    developer.log('👤 Getting current user');
    // For demo, return the first user
    final users = await _dbHelper.getAllUsers();
    final user = users.isNotEmpty ? users.first : null;
    developer.log('📊 Current user: ${user?.name}');
    return user;
  }

  Future<bool> updateProfile(User user) async {
    try {
      developer.log('✏️ Updating profile: ${user.name}');

      final result = await _dbHelper.updateUser(user);
      final success = result > 0;

      developer.log('📝 Profile update result: $success');
      return success;
    } catch (e) {
      developer.log('❌ Profile update error: $e');
      return false;
    }
  }

  // Méthode supplémentaire pour tester la connexion
  Future<bool> testDatabaseConnection() async {
    try {
      final users = await _dbHelper.getAllUsers();
      developer.log('✅ Database connection test: SUCCESS (${users.length} users)');
      return true;
    } catch (e) {
      developer.log('❌ Database connection test: FAILED - $e');
      return false;
    }
  }
}