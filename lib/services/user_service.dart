import '../models/user.dart';
import '../database/database_helper.dart';
import 'dart:developer' as developer;

class UserService {
  final DatabaseHelper _databaseHelper = DatabaseHelper();

  Future<List<User>> getUsersByIds(List<int> userIds) async {
    try {
      developer.log('👥 Fetching users by IDs: $userIds');
      final users = await _databaseHelper.getUsersByIds(userIds);
      developer.log('✅ Found ${users.length} users');
      return users;
    } catch (e) {
      developer.log('❌ Error fetching users by IDs: $e');
      return [];
    }
  }

  Future<User?> getUser(int userId) async {
    try {
      developer.log('👤 Fetching user: $userId');
      final user = await _databaseHelper.getUserById(userId);
      developer.log('✅ User found: ${user?.name}');
      return user;
    } catch (e) {
      developer.log('❌ Error fetching user: $e');
      return null;
    }
  }

  Future<List<User>> getAllUsers() async {
    try {
      developer.log('📊 Fetching all users');
      final users = await _databaseHelper.getAllUsers();
      developer.log('✅ Total users: ${users.length}');
      return users;
    } catch (e) {
      developer.log('❌ Error fetching all users: $e');
      return [];
    }
  }

  Future<List<User>> searchUsers(String query) async {
    try {
      developer.log('🔍 Searching users: $query');
      final allUsers = await _databaseHelper.getAllUsers();
      final results = allUsers.where((user) =>
      user.name.toLowerCase().contains(query.toLowerCase()) ||
          user.email.toLowerCase().contains(query.toLowerCase())
      ).toList();
      developer.log('✅ Search results: ${results.length} users');
      return results;
    } catch (e) {
      developer.log('❌ Error searching users: $e');
      return [];
    }
  }
}